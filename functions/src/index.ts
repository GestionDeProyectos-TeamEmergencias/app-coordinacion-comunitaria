import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

import { normalizeIncidentEvent } from "./incidentNormalization";
import { buildEnrichment } from "./incidentEnrichment";
import { detectDuplicateIncidents } from "./incidentDuplicates";
import { vitalRiskDetectionFlow } from "./vitalRiskDetection";
import {
  semanticExtractionFlow,
  mapSemanticCategoryToNormalized,
  SemanticExtractionResult,
} from "./semanticExtraction";
import { priorityCalculationFlow, PriorityResult } from "./priorityCalculation";
import {
  findNearbyReferentes,
  sendIncidentAlertToReferentes,
} from "./pushNotifications";
import { loadCoverageConfig, isWithinCoverage } from "./coverageValidation";
import {
  AlgorithmConfigPatchSchema,
  getAlgorithmConfig,
  loadAlgorithmConfig,
  saveAlgorithmConfig,
} from "./algorithmConfig";
import {
  appendAuditEntry,
  persistProcessedIncident,
} from "./incidentPersistence";

import { moderateFalseReport, unblockUser } from "./moderation";

admin.initializeApp();

export { moderateFalseReport, unblockUser };

export const normalizeIncident = onDocumentCreated(
  "incidents/{incidentId}",
  async (event) => {
    const incidentId = event.params.incidentId as string;
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Missing incident snapshot", { incidentId });
      return;
    }

    const data = snapshot.data();
    if (data.normalizedAt || data.normalizedEvent) {
      return;
    }

    const firestore = admin.firestore();

    try {
      // T-NLP-08: Auditoría — registra que el documento llegó al pipeline.
      await appendAuditEntry(firestore, incidentId, "received");

      const { normalizedEvent, warnings } = normalizeIncidentEvent(
        incidentId,
        data,
      );
      await appendAuditEntry(firestore, incidentId, "normalized", {
        warnings,
      });

      // T-AUTH-07: Rechazar reportes de usuarios bloqueados o inactivos.
      const authorSnap = await firestore
        .collection("users")
        .doc(normalizedEvent.userId)
        .get();
      const authorStatus = authorSnap.data()?.status;
      if (authorStatus !== "active") {
        logger.warn("Incident rejected: author not active", {
          incidentId,
          userId: normalizedEvent.userId,
          authorStatus,
        });
        await firestore.collection("incidents").doc(incidentId).update({
          normalizedEvent,
          normalizationWarnings: warnings,
          status: "rechazado_autor_inactivo",
          processedAt: FieldValue.serverTimestamp(),
        });
        await appendAuditEntry(
          firestore,
          incidentId,
          "author_inactive_rejected",
          { userId: normalizedEvent.userId, authorStatus },
        );
        return;
      }
      await appendAuditEntry(firestore, incidentId, "author_validated");

      // T-AUTH-06: Validacion geografica de cobertura
      const coverageConfig = await loadCoverageConfig(firestore);
      if (
        !isWithinCoverage(
          normalizedEvent.location.latitude,
          normalizedEvent.location.longitude,
          coverageConfig,
        )
      ) {
        logger.warn("Incident outside coverage area", {
          incidentId,
          latitude: normalizedEvent.location.latitude,
          longitude: normalizedEvent.location.longitude,
        });

        await firestore
          .collection("incidents")
          .doc(incidentId)
          .update({
            normalizedEvent,
            normalizationWarnings: warnings,
            status: "rechazado_fuera_de_cobertura",
            coverageRejection: {
              reason: "Ubicacion fuera del area de cobertura configurada",
              incidentLocation: normalizedEvent.location,
              coverageCenter: {
                latitude: coverageConfig.centerLat,
                longitude: coverageConfig.centerLng,
              },
              coverageRadiusMeters: coverageConfig.radiusMeters,
              rejectedAt: new Date().toISOString(),
            },
            processedAt: FieldValue.serverTimestamp(),
          });

        await appendAuditEntry(firestore, incidentId, "coverage_rejected", {
          latitude: normalizedEvent.location.latitude,
          longitude: normalizedEvent.location.longitude,
        });
        return; // Cortar pipeline
      }
      await appendAuditEntry(firestore, incidentId, "coverage_validated");

      const now = new Date();
      const enrichment = await buildEnrichment(
        firestore,
        normalizedEvent.userId,
        now,
      );
      await appendAuditEntry(firestore, incidentId, "enrichment_built");

      const duplicateCheck = await detectDuplicateIncidents(firestore, {
        incidentId,
        latitude: normalizedEvent.location.latitude,
        longitude: normalizedEvent.location.longitude,
        timestamp: new Date(normalizedEvent.timestamp),
        radiusMeters: getDuplicateRadiusMeters(),
        windowHours: getDuplicateWindowHours(),
      });
      await appendAuditEntry(firestore, incidentId, "duplicate_check_done", {
        nearbyCount: duplicateCheck.nearbyCount,
      });

      // Carga la config calibrable desde Firestore (cacheada 60s). [T-NLP-06]
      const algorithmConfig = await loadAlgorithmConfig(firestore);

      // Detección de riesgo vital (T-NLP-05) — Cortocircuito temprano del pipeline
      const vitalRisk = await vitalRiskDetectionFlow({
        description: normalizedEvent.description,
        config: algorithmConfig,
      });

      if (vitalRisk.isVitalRisk) {
        logger.warn("Vital risk detected — interrupting pipeline", {
          incidentId,
          riskCategory: vitalRisk.riskCategory,
          matchedTerms: vitalRisk.matchedTerms,
        });

        await firestore
          .collection("incidents")
          .doc(incidentId)
          .update({
            normalizedEvent,
            normalizationWarnings: warnings,
            enrichment,
            duplicateCheck,
            status: "vital_risk_detected",
            vitalRisk: {
              ...vitalRisk,
              detectedAt: new Date().toISOString(),
            },
            processedAt: FieldValue.serverTimestamp(),
          });
        await appendAuditEntry(
          firestore,
          incidentId,
          "vital_risk_interrupted",
          { riskCategory: vitalRisk.riskCategory },
        );

        return; // ❌ Interrumpir flujo — No generar alerta comunitaria
      }
      await appendAuditEntry(firestore, incidentId, "vital_risk_evaluated");

      // Ejecución del flujo de extracción semántica (T-NLP-03)
      let semanticExtraction:
        | (SemanticExtractionResult & { extractedAt: string })
        | null = null;
      try {
        const semanticResult = await semanticExtractionFlow({
          description: normalizedEvent.description,
        });

        // Si la categoría normalizada original es nula, la enriquecemos con la extraída por el LLM
        if (!normalizedEvent.category && semanticResult.category) {
          normalizedEvent.category = mapSemanticCategoryToNormalized(
            semanticResult.category,
          );
        }

        semanticExtraction = {
          category: semanticResult.category,
          intention: semanticResult.intention,
          detectedTerms: semanticResult.detectedTerms,
          extractedAt: new Date().toISOString(),
        };
        await appendAuditEntry(firestore, incidentId, "semantic_extracted", {
          category: semanticResult.category,
        });
      } catch (semanticError) {
        logger.warn("Semantic extraction failed, continuing without it", {
          incidentId,
          error: semanticError,
        });
        await appendAuditEntry(
          firestore,
          incidentId,
          "semantic_extraction_failed",
        );
      }

      // Ejecución del cálculo de prioridad (T-NLP-04)
      let priorityCalculation:
        | (PriorityResult & { calculatedAt: string })
        | null = null;
      try {
        const priorityResult = await priorityCalculationFlow({
          semanticExtraction,
          category: normalizedEvent.category,
          enrichment,
          duplicateCheck,
          config: algorithmConfig,
        });

        priorityCalculation = {
          ...priorityResult,
          calculatedAt: new Date().toISOString(),
        };
        await appendAuditEntry(firestore, incidentId, "priority_calculated", {
          priority: priorityResult.priority,
          priorityScore: priorityResult.priorityScore,
        });
      } catch (priorityError) {
        logger.warn("Priority calculation failed", {
          incidentId,
          error: priorityError,
        });
        await appendAuditEntry(
          firestore,
          incidentId,
          "priority_calculation_failed",
        );
      }

      // T-NLP-08: Persistencia centralizada (transacción atómica) que garantiza
      // el schema completo y `status: "recibido"` en el flujo exitoso. Devuelve
      // los issues validados in-memory sin hacer un GET adicional.
      const persistResult = await persistProcessedIncident({
        firestore,
        incidentId,
        normalizedEvent,
        warnings,
        enrichment,
        duplicateCheck,
        semanticExtraction,
        priorityCalculation,
      });
      await appendAuditEntry(firestore, incidentId, "persisted", {
        statusSet: persistResult.statusSet,
      });
      if (persistResult.issues.length > 0) {
        logger.warn("Incident persisted with missing required fields", {
          incidentId,
          issues: persistResult.issues,
        });
      }

      // T-NLP-07: Envío de alertas push a referentes cercanos si se calculó la prioridad
      if (priorityCalculation) {
        // Obtenemos el radio desde las variables de entorno (por defecto 2000 metros)
        const radiusMeters = Number(process.env.ALERT_RADIUS_METERS ?? "2000");

        // Buscamos referentes en el área
        const referentes = await findNearbyReferentes(
          firestore,
          normalizedEvent.location.latitude,
          normalizedEvent.location.longitude,
          radiusMeters,
        );

        // Si hay referentes, enviamos las notificaciones
        if (referentes.length > 0) {
          await sendIncidentAlertToReferentes(
            admin.messaging(),
            incidentId,
            priorityCalculation.priority,
            normalizedEvent.location.latitude,
            normalizedEvent.location.longitude,
            referentes,
          );
          await appendAuditEntry(firestore, incidentId, "alerts_dispatched", {
            referentes: referentes.length,
          });
        }
      }
    } catch (error) {
      logger.error("Normalization failed", { incidentId, error });
      await firestore
        .collection("incidents")
        .doc(incidentId)
        .update({
          normalizationError: {
            message: error instanceof Error ? error.message : "Unknown error",
            at: FieldValue.serverTimestamp(),
          },
        });
      await appendAuditEntry(firestore, incidentId, "pipeline_failed", {
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  },
);

function getDuplicateRadiusMeters(): number {
  const value = Number(process.env.DUPLICATE_RADIUS_METERS ?? "100");
  return Number.isFinite(value) && value > 0 ? value : 100;
}

function getDuplicateWindowHours(): number {
  const value = Number(process.env.DUPLICATE_WINDOW_HOURS ?? "24");
  return Number.isFinite(value) && value > 0 ? value : 24;
}

// ── Calibración del algoritmo (T-NLP-06) ────────────────────────────────────
// Endpoints callables que permiten al administrador leer y actualizar el
// diccionario de palabras clave y los pesos del motor de priorización sin
// redeploy de Cloud Functions. La config persiste en Firestore (config/algorithm)
// y los flows la consultan con caché de 60s.

export async function assertCallerIsAdmin(
  firestore: admin.firestore.Firestore,
  uid: string | undefined,
): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Autenticación requerida.");
  }
  const userDoc = await firestore.collection("users").doc(uid).get();
  const data = userDoc.data();
  if (
    !userDoc.exists ||
    data?.role !== "administrador" ||
    data?.status !== "active"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Solo el administrador activo puede modificar la calibración del algoritmo.",
    );
  }
}

export const getAlgorithmConfigCallable = onCall(async (request) => {
  const firestore = admin.firestore();
  await assertCallerIsAdmin(firestore, request.auth?.uid);
  const config = await getAlgorithmConfig(firestore);
  return { config };
});

export const updateAlgorithmConfigCallable = onCall(async (request) => {
  const firestore = admin.firestore();
  await assertCallerIsAdmin(firestore, request.auth?.uid);
  const parsed = AlgorithmConfigPatchSchema.safeParse(request.data?.patch);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Patch inválido para la calibración del algoritmo.",
      parsed.error.flatten(),
    );
  }
  const updated = await saveAlgorithmConfig(
    firestore,
    parsed.data,
    request.auth!.uid,
  );
  logger.info("Algorithm config updated", { updatedBy: request.auth!.uid });
  return { config: updated };
});

export { updateUserReputationOnValidation } from "./reputationManager";
export { aggregateReactionsOnWritten } from "./reactionsAggregator";
export {
  notifyClosurePending,
  autoConfirmExpiredClosures,
} from "./closureConfirmation";

// ── Derivación a 911/107 — chequeo síncrono pre-envío (D-03) ────────────────
// Permite al cliente Flutter consultar si la descripción de un reporte dispara
// riesgo vital ANTES de crear el incident. Si la respuesta es `isVitalRisk:
// true`, el cliente muestra el diálogo de derivación a 911/107 y NO persiste
// el reporte, evitando ensuciar Firestore con documentos `vital_risk_detected`.
// El backend mantiene su check defensivo en `normalizeIncident` por si llega
// un incident desde un cliente que skipea el callable. [RF-PRI-05]

export const checkVitalRiskCallable = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Autenticación requerida para evaluar riesgo vital.",
    );
  }

  const description = request.data?.description;
  if (typeof description !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "`description` debe ser un string (puede ser vacío).",
    );
  }

  // Trim defensivo para evitar trivializar el dictionary contra whitespace.
  const trimmed = description.trim();

  const firestore = admin.firestore();
  const config = await loadAlgorithmConfig(firestore);
  const result = await vitalRiskDetectionFlow({
    description: trimmed.length === 0 ? null : trimmed,
    config,
  });

  return {
    isVitalRisk: result.isVitalRisk,
    matchedTerms: result.matchedTerms,
    riskCategory: result.riskCategory,
    emergencyNumbers: result.emergencyNumbers,
    reason: result.reason,
  };
});
