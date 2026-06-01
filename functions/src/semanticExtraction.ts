import { z } from "genkit";
import { ai } from "./genkit";
import { googleAI } from "@genkit-ai/google-genai";
import { CategoryNormalized } from "./incidentNormalization";

// Definición del esquema tipado esperado para los términos detectados
export const DetectedTermSchema = z.object({
  term: z.string().describe("Palabra clave significativa del incidente (ej. 'bache', 'luminaria', 'basura')."),
  weight: z.number().min(0).max(1).describe("Peso o relevancia semántica del término en una escala de 0.0 a 1.0.")
});

// Definición del esquema tipado esperado para la extracción semántica (T-NLP-03)
export const SemanticExtractionSchema = z.object({
  category: z.enum([
    "eléctrico",
    "vial",
    "sanitario",
    "espacios verdes",
    "seguridad",
    "otro"
  ]).describe("La categoría del incidente urbano basada en el análisis semántico."),
  
  intention: z.string().describe(
    "Breve frase resumida que represente la intención directa del reporte en español (ej. 'Reportar bache profundo'). Máximo 10 palabras."
  ),
  
  detectedTerms: z.array(DetectedTermSchema).describe(
    "Lista de términos o palabras clave detectados en la descripción con sus pesos de relevancia (requisito RF-PRI-01)."
  )
});

export type SemanticExtractionResult = z.infer<typeof SemanticExtractionSchema>;

export interface FullSemanticExtraction {
  category: "eléctrico" | "vial" | "sanitario" | "espacios verdes" | "seguridad" | "otro";
  intention: string;
  detectedTerms: Array<{ term: string; weight: number }>;
  extractedAt: string;
}

/**
 * Mapea la categoría semántica extraída por la IA a la categoría normalizada interna del sistema.
 */
export function mapSemanticCategoryToNormalized(
  category: "eléctrico" | "vial" | "sanitario" | "espacios verdes" | "seguridad" | "otro"
): Exclude<CategoryNormalized, null> {
  switch (category) {
    case "eléctrico":
      return "alumbrado_electrico";
    case "vial":
      return "infraestructura_vial";
    case "sanitario":
      return "saneamiento";
    case "espacios verdes":
      return "espacios_verdes";
    case "seguridad":
    case "otro":
    default:
      return "otro";
  }
}

/**
 * Genkit Flow para la extracción semántica de categoría e intención (T-NLP-03)
 */
export const semanticExtractionFlow = ai.defineFlow(
  {
    name: "semanticExtractionFlow",
    inputSchema: z.object({
      description: z.string().nullable().optional()
    }),
    outputSchema: SemanticExtractionSchema
  },
  async (input) => {
    const description = input.description?.trim();

    // Caso de borde: Si la descripción está vacía, no invocamos la IA para ahorrar recursos y latencia
    if (!description) {
      return {
        category: "otro" as const,
        intention: "Reporte rápido sin descripción textual",
        detectedTerms: []
      };
    }

    // Invocación a Gemini 2.5 Flash-Lite a través del SDK de Genkit con esquema tipado
    const response = await ai.generate({
      model: googleAI.model("gemini-2.5-flash-lite"),
      prompt: `
        Actúas como un clasificador semántico experto en un sistema de gestión comunitaria urbana no crítica.
        Analiza la descripción del incidente urbano reportado por un vecino y extrae la categoría semántica, la intención y las palabras clave estructuradas.

        Criterios de clasificación por categoría:
        1. 'eléctrico': Luces de calle apagadas o rotas, chispas en postes, cables sueltos o expuestos en la vía pública, transformadores con desperfectos.
        2. 'vial': Baches, pozos profundos en el asfalto, veredas levantadas o rotas, semáforos fuera de servicio, carteles de pare/tránsito dañados o faltantes.
        3. 'sanitario': Acumulación de basura o residuos domiciliarios en la vereda, pérdidas de agua corriente, desbordes cloacales, animales muertos en vía pública.
        4. 'espacios verdes': Ramas caídas obstruyendo el tránsito, árboles caídos, maleza muy alta en plazas o veredas públicas, parques desatendidos.
        5. 'seguridad': Pintadas o grafitis vandálicos, vidrios rotos en paradas de autobús, plazas totalmente oscuras por lámparas rotas que generan inseguridad.
        6. 'otro': Reportes de incidentes no clasificados en las anteriores categorías de mantenimiento urbano.

        Instrucción de Palabras Clave (detectedTerms):
        Extrae las palabras clave más significativas que definen la problemática (sustantivos o adjetivos de acción, no preposiciones o artículos). Asigna un peso representativo (0.0 a 1.0) que denote el impacto del término (ej. 'bache': 1.0, 'profundo': 0.8, 'pozo': 1.0, 'cable': 0.9).

        Ejemplos de análisis:
        - "Hay un pozo gigante en el cruce de Rivadavia y Belgrano, los autos se lo llevan puesto."
          Respuesta esperada: { "category": "vial", "intention": "Reportar pozo profundo en el cruce de calles", "detectedTerms": [{"term": "pozo", "weight": 1.0}, {"term": "cruce", "weight": 0.5}, {"term": "autos", "weight": 0.4}] }
        - "La lámpara del poste frente a mi casa parpadea y hace un zumbido raro."
          Respuesta esperada: { "category": "eléctrico", "intention": "Solicitar reparación de luminaria de alumbrado parpadeante", "detectedTerms": [{"term": "lámpara", "weight": 0.9}, {"term": "parpadea", "weight": 0.8}, {"term": "poste", "weight": 0.6}] }

        Descripción del incidente a analizar:
        "${description}"
      `,
      output: {
        schema: SemanticExtractionSchema
      }
    });

    const output = response.output;
    if (!output) {
      throw new Error("No se pudo obtener una respuesta válida de Gemini.");
    }

    return output;
  }
);
