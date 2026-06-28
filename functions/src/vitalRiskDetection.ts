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

// Contextos que indican que el t\u00e9rmino NO describe una emergencia en curso.
// Lista curada y conservadora: deliberadamente NO incluye un "no" gen\u00e9rico,
// porque t\u00e9rminos leg\u00edtimos del diccionario ya lo contienen ("no respira") y
// negarlos a ciegas producir\u00eda falsos negativos peligrosos.
export const NON_EMERGENCY_CONTEXT = [
  "simulacro",
  "evitar",
  "evitando",
  "prevenir",
  "prevencion",
  "en caso de",
];

// Ventana (en caracteres) de texto previo al t\u00e9rmino donde se busca un contexto
// no-emergencia. Corta a prop\u00f3sito para no neutralizar emergencias reales.
const NEGATION_WINDOW_CHARS = 25;

// Precedencia expl\u00edcita de categor\u00edas cuando una descripci\u00f3n matchea varias.
// Antes la categor\u00eda sal\u00eda del orden de iteraci\u00f3n del objeto (accidental).
const CATEGORY_PRECEDENCE = ["medico", "seguridad", "desastre"] as const;

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Busca `term` como palabra completa (l\u00edmite de palabra) dentro de `haystack`.
 * Devuelve el \u00edndice del match o -1. Evita que t\u00e9rminos cortos matcheen dentro
 * de palabras m\u00e1s largas (p. ej. "tiro" no debe matchear "retiro").
 */
function findWordMatch(haystack: string, term: string): number {
  const match = new RegExp(`\\b${escapeRegExp(term)}\\b`).exec(haystack);
  return match ? match.index : -1;
}

function isNonEmergencyContext(haystack: string, matchIndex: number): boolean {
  const windowStart = Math.max(0, matchIndex - NEGATION_WINDOW_CHARS);
  const before = haystack.slice(windowStart, matchIndex);
  return NON_EMERGENCY_CONTEXT.some((ctx) => before.includes(ctx));
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

    // Acumular matches por categoría con límite de palabra, descartando los que
    // aparecen en contexto no-emergencia (simulacro, prevención, etc.).
    const matchedByCategory: Partial<Record<string, string[]>> = {};
    for (const [category, categoryTerms] of Object.entries(terms)) {
      for (const term of categoryTerms) {
        const idx = findWordMatch(normalizedDescription, normalizeText(term));
        if (idx >= 0 && !isNonEmergencyContext(normalizedDescription, idx)) {
          (matchedByCategory[category] ??= []).push(term);
        }
      }
    }

    // Triage por precedencia explícita (antes salía del orden de iteración).
    let detectedCategory: "medico" | "seguridad" | "desastre" | "none" = "none";
    for (const cat of CATEGORY_PRECEDENCE) {
      if (matchedByCategory[cat]?.length) {
        detectedCategory = cat;
        break;
      }
    }

    const matchedTerms = Object.values(matchedByCategory).flat() as string[];

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
