import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

import { normalizeIncidentEvent } from "./incidentNormalization";
import { buildEnrichment } from "./incidentEnrichment";
import { detectDuplicateIncidents } from "./incidentDuplicates";
import { semanticExtractionFlow, mapSemanticCategoryToNormalized, SemanticExtractionResult } from "./semanticExtraction";
import { priorityCalculationFlow, PriorityResult } from "./priorityCalculation";
import { findNearbyReferentes, sendIncidentAlertToReferentes } from "./pushNotifications";

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

      // T-NLP-07: Envío de alertas push a referentes cercanos si se calculó la prioridad
      if (priorityCalculation) {
        // Obtenemos el radio desde las variables de entorno (por defecto 2000 metros)
        const radiusMeters = Number(process.env.ALERT_RADIUS_METERS ?? "2000");
        
        // Buscamos referentes en el área
        const referentes = await findNearbyReferentes(
          firestore,
          normalizedEvent.location.latitude,
          normalizedEvent.location.longitude,
          radiusMeters
        );

        // Si hay referentes, enviamos las notificaciones
        if (referentes.length > 0) {
          await sendIncidentAlertToReferentes(
            admin.messaging(),
            incidentId,
            priorityCalculation.priority,
            normalizedEvent.location.latitude,
            normalizedEvent.location.longitude,
            referentes
          );
        }
      }
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
