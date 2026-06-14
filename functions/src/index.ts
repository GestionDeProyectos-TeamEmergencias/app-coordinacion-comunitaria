import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

import { normalizeIncidentEvent } from "./incidentNormalization";
import { buildEnrichment } from "./incidentEnrichment";
import { detectDuplicateIncidents } from "./incidentDuplicates";
import { vitalRiskDetectionFlow } from "./vitalRiskDetection";
import { semanticExtractionFlow, mapSemanticCategoryToNormalized, SemanticExtractionResult } from "./semanticExtraction";
import { priorityCalculationFlow, PriorityResult } from "./priorityCalculation";

admin.initializeApp();



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
      const { normalizedEvent, warnings } = normalizeIncidentEvent(
        incidentId,
        data
      );

      const now = new Date();
      const enrichment = await buildEnrichment(
        firestore,
        normalizedEvent.userId,
        now
      );

      const duplicateCheck = await detectDuplicateIncidents(firestore, {
        incidentId,
        latitude: normalizedEvent.location.latitude,
        longitude: normalizedEvent.location.longitude,
        timestamp: new Date(normalizedEvent.timestamp),
        radiusMeters: getDuplicateRadiusMeters(),
        windowHours: getDuplicateWindowHours(),
      });

      // Detección de riesgo vital (T-NLP-05) — Cortocircuito temprano del pipeline
      const vitalRisk = await vitalRiskDetectionFlow({
        description: normalizedEvent.description,
      });

      if (vitalRisk.isVitalRisk) {
        logger.warn("Vital risk detected — interrupting pipeline", {
          incidentId,
          riskCategory: vitalRisk.riskCategory,
          matchedTerms: vitalRisk.matchedTerms,
        });

        await firestore.collection("incidents").doc(incidentId).update({
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

        return; // ❌ Interrumpir flujo — No generar alerta comunitaria
      }

      // Ejecución del flujo de extracción semántica (T-NLP-03)
      let semanticExtraction: (SemanticExtractionResult & { extractedAt: string }) | null = null;
      try {
        const semanticResult = await semanticExtractionFlow({
          description: normalizedEvent.description,
        });

        // Si la categoría normalizada original es nula, la enriquecemos con la extraída por el LLM
        if (!normalizedEvent.category && semanticResult.category) {
          normalizedEvent.category = mapSemanticCategoryToNormalized(semanticResult.category);
        }

        semanticExtraction = {
          category: semanticResult.category,
          intention: semanticResult.intention,
          detectedTerms: semanticResult.detectedTerms,
          extractedAt: new Date().toISOString(),
        };
      } catch (semanticError) {
        logger.warn("Semantic extraction failed, continuing without it", {
          incidentId,
          error: semanticError,
        });
      }

      // Ejecución del cálculo de prioridad (T-NLP-04)
      let priorityCalculation: (PriorityResult & { calculatedAt: string }) | null = null;
      try {
        const priorityResult = await priorityCalculationFlow({
          semanticExtraction,
          category: normalizedEvent.category,
          enrichment,
          duplicateCheck,
        });

        priorityCalculation = {
          ...priorityResult,
          calculatedAt: new Date().toISOString(),
        };
      } catch (priorityError) {
        logger.warn("Priority calculation failed", {
          incidentId,
          error: priorityError,
        });
      }

      await firestore.collection("incidents").doc(incidentId).update({
        normalizedEvent,
        normalizationWarnings: warnings,
        enrichment,
        duplicateCheck,
        ...(semanticExtraction ? { semanticExtraction } : {}),
        ...(priorityCalculation ? { priority: priorityCalculation.priority, priorityScore: priorityCalculation.priorityScore, priorityCalculation } : {}),
        normalizedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error("Normalization failed", { incidentId, error });
      await firestore.collection("incidents").doc(incidentId).update({
        normalizationError: {
          message: error instanceof Error ? error.message : "Unknown error",
          at: FieldValue.serverTimestamp(),
        },
      });
    }
  }
);

function getDuplicateRadiusMeters(): number {
  const value = Number(process.env.DUPLICATE_RADIUS_METERS ?? "100");
  return Number.isFinite(value) && value > 0 ? value : 100;
}

function getDuplicateWindowHours(): number {
  const value = Number(process.env.DUPLICATE_WINDOW_HOURS ?? "24");
  return Number.isFinite(value) && value > 0 ? value : 24;
}
