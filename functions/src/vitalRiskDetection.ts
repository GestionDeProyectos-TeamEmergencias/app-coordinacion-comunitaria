import { z } from "genkit";
import { ai } from "./genkit";

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

// ── Diccionario de términos de alta criticidad ────────────────────────────────
// Estructura preparada para ser migrada a Firestore en T-NLP-06

export const VITAL_RISK_TERMS: Record<string, string[]> = {
  // Salud / Emergencia médica → 107 (SAME)
  medico: [
    "infarto", "infartando", "convulsion", "convulsionando",
    "inconsciente", "desmayado", "paro cardiaco", "no respira",
    "hemorragia", "desangrando", "sobredosis", "ahogando",
    "electrocutado", "electrocucion", "intoxicacion",
  ],
  // Violencia / Crimen → 911
  seguridad: [
    "tiroteo", "disparos", "disparo", "baleado",
    "apunalado", "acuchillado", "navajazo",
    "asalto armado", "secuestro", "rehen", "rehenes",
    "amenaza de bomba", "explosion", "arma de fuego",
    "robo a mano armada",
  ],
  // Incendio / Desastre → 911
  desastre: [
    "incendio", "se prende fuego", "prendio fuego",
    "derrumbe", "colapso", "edificio colapsado",
    "inundacion grave", "atrapado", "persona atrapada",
    "personas atrapadas", "derrumbe de edificio",
  ],
};

// Mapa de categoría de riesgo → números de emergencia
const EMERGENCY_NUMBERS: Record<string, string[]> = {
  medico: ["107", "911"],
  seguridad: ["911"],
  desastre: ["911", "100"],
};

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
    }),
    outputSchema: VitalRiskSchema,
  },
  async (input): Promise<VitalRiskResult> => {
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

    // Iterar sobre cada categoría de riesgo y buscar coincidencias
    for (const [category, terms] of Object.entries(VITAL_RISK_TERMS)) {
      for (const term of terms) {
        const normalizedTerm = normalizeText(term);
        if (normalizedDescription.includes(normalizedTerm)) {
          matchedTerms.push(term);
          // Priorizar la primera categoría detectada (orden del diccionario)
          if (detectedCategory === "none") {
            detectedCategory = category as "medico" | "seguridad" | "desastre";
          }
        }
      }
    }

    if (matchedTerms.length > 0) {
      return {
        isVitalRisk: true,
        matchedTerms,
        riskCategory: detectedCategory,
        emergencyNumbers: EMERGENCY_NUMBERS[detectedCategory] ?? ["911"],
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
