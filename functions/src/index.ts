import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

// Inicialización de Genkit con el plugin de Google Gen AI
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
