import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

import { normalizeIncidentEvent } from "./incidentNormalization";
import { buildEnrichment } from "./incidentEnrichment";
import { detectDuplicateIncidents } from "./incidentDuplicates";

admin.initializeApp();

// Inicializacion de Genkit con el plugin de Google Gen AI
const ai = genkit({
  plugins: [googleAI()],
});

// Definición del esquema tipado esperado para la clasificación
const IncidentClassificationSchema = z.object({
  category: z.enum(["Vandalismo", "Infraestructura", "Seguridad", "Otro"]),
  priority: z.enum(["Baja", "Media", "Alta"]),
  reasoning: z.string().describe("Breve justificación de la clasificación"),
});

export const classifyIncident = onRequest(async (req, res) => {
  try {
    const description = req.body.description || req.query.description || "Hubo un corte de luz en la calle principal";
    
    // Generación de contenido con esquema tipado usando Gemini 2.5 Flash-Lite
    const response = await ai.generate({
      model: googleAI.model('gemini-2.5-flash-lite'),
      prompt: `Actúa como un asistente para un sistema de coordinación comunitaria. 
      Analiza el siguiente reporte de incidente vecinal y clasifícalo.
      Reporte: "${description}"`,
      output: {
        schema: IncidentClassificationSchema
      }
    });

    res.status(200).json({ 
      success: true,
      report: description,
      classification: response.output 
    });
  } catch (error: any) {
    logger.error("Error al procesar el incidente con Genkit", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

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

      await firestore.collection("incidents").doc(incidentId).update({
        normalizedEvent,
        normalizationWarnings: warnings,
        enrichment,
        duplicateCheck,
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
