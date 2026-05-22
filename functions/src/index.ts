import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { genkit } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

// Inicialización de Genkit con el plugin de Google Gen AI (Gemini)
const ai = genkit({
  plugins: [googleAI()],
});

export const classifyIncident = onRequest(async (req, res) => {
  try {
    const description = req.body.description || req.query.description || "Hubo un corte de luz en la calle principal";
    
    // Smoke test: Generación de contenido con Gemini
    const response = await ai.generate({
      model: googleAI.model('gemini-2.5-flash'),
      prompt: `Actúa como un asistente para un sistema de coordinación comunitaria. Clasifica el siguiente reporte de incidente vecinal en una categoría corta (por ejemplo: Vandalismo, Infraestructura, Seguridad, Otro) y asigna una prioridad (Baja, Media, Alta). Reporte: "${description}"`,
    });

    res.status(200).json({ 
      success: true,
      report: description,
      classification: response.text 
    });
  } catch (error: any) {
    logger.error("Error al procesar el incidente con Genkit", error);
    res.status(500).json({ success: false, error: error.message });
  }
});
