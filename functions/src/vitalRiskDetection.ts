import { z } from "genkit";
import { ai } from "./genkit";
import { DEFAULT_ALGORITHM_CONFIG, AlgorithmConfig } from "./algorithmConfig";

// ── Esquema de salida (T-NLP-05) ──────────────────────────────────────────────

export const VitalRiskSchema = z.object({
  isVitalRisk: z.boolean()
    .describe("True si se detectó riesgo vital en el texto"),
  matchedTerms: z.array(z.string())
    .describe("Términos de alta criticidad encontrados en la descripción"),
  riskCategory: z.enum(["medico", "seguridad", "desastre", "none"])
    .describe("Categoría de riesgo vital detectada, o 'none' si no aplica"),
  emergencyNumbers: z.array(z.string())
    .describe("Números de emergencia sugeridos al usuario (911, 107)"),
  reason: z.string()
    .describe("Explicación de la detección para trazabilidad y auditoría"),
});

export type VitalRiskResult = z.infer<typeof VitalRiskSchema>;

// ── Diccionario por defecto (T-NLP-05) ───────────────────────────────────────
// Se mantiene exportado para retrocompatibilidad con tests y como fallback
// cuando Firestore no tiene el documento config/algorithm. La fuente de
// verdad efectiva en runtime es AlgorithmConfig.vitalRiskTerms (T-NLP-06).

export const VITAL_RISK_TERMS: Record<string, string[]> =
  DEFAULT_ALGORITHM_CONFIG.vitalRiskTerms;

// ── Utilidades de normalización de texto ──────────────────────────────────────

/**
 * Normaliza un texto removiendo acentos/diacríticos y convirtiendo a lowercase.
 * Esto permite comparar términos sin importar acentuación o capitalización.
 */
export function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

// ── Genkit Flow: Detección de Riesgo Vital (T-NLP-05) ────────────────────────

/**
 * Flow determinista (sin LLM) que analiza la descripción de un incidente contra
 * un diccionario de términos de alta criticidad. Si detecta riesgo vital,
 * interrumpe el flujo del pipeline y retorna datos para mostrar botones de
 * emergencia (911/107) en el frontend.
 *
 * @see RF-PRI-05 en la SRS
 * @see AGENTS.md — Restricción Core: el sistema NO es para emergencias de riesgo vital
 */
export const vitalRiskDetectionFlow = ai.defineFlow(
  {
    name: "vitalRiskDetectionFlow",
    inputSchema: z.object({
      description: z.string().nullable(),
      config: z.custom<AlgorithmConfig | undefined>().optional(),
    }),
    outputSchema: VitalRiskSchema,
  },
  async (input): Promise<VitalRiskResult> => {
    const config = input.config ?? DEFAULT_ALGORITHM_CONFIG;
    const terms = config.vitalRiskTerms;
    const emergencyNumbers = config.emergencyNumbers;

    // Si no hay descripción, no hay riesgo que evaluar
    if (!input.description || input.description.trim().length === 0) {
      return {
        isVitalRisk: false,
        matchedTerms: [],
        riskCategory: "none",
        emergencyNumbers: [],
        reason: "Sin descripción textual para analizar.",
      };
    }

    const normalizedDescription = normalizeText(input.description);
    const matchedTerms: string[] = [];
    let detectedCategory: "medico" | "seguridad" | "desastre" | "none" = "none";

    for (const [category, categoryTerms] of Object.entries(terms)) {
      for (const term of categoryTerms) {
        const normalizedTerm = normalizeText(term);
        if (normalizedDescription.includes(normalizedTerm)) {
          matchedTerms.push(term);
          if (detectedCategory === "none") {
            detectedCategory = category as "medico" | "seguridad" | "desastre";
          }
        }
      }
    }

    if (matchedTerms.length > 0 && detectedCategory !== "none") {
      return {
        isVitalRisk: true,
        matchedTerms,
        riskCategory: detectedCategory,
        emergencyNumbers: emergencyNumbers[detectedCategory] ?? ["911"],
        reason: `Riesgo vital detectado (${detectedCategory}). ` +
          `Términos coincidentes: [${matchedTerms.join(", ")}]. ` +
          `El incidente excede el alcance del sistema de coordinación comunitaria.`,
      };
    }

    return {
      isVitalRisk: false,
      matchedTerms: [],
      riskCategory: "none",
      emergencyNumbers: [],
      reason: "No se detectaron términos de riesgo vital en la descripción.",
    };
  }
);
