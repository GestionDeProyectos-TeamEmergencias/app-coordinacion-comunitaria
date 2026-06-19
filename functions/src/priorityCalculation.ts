import { z } from "genkit";
import { ai } from "./genkit";
import { SemanticExtractionResult } from "./semanticExtraction";
import { EnrichmentResult } from "./incidentEnrichment";
import { DuplicateCheckResult } from "./incidentDuplicates";
import { CategoryNormalized } from "./incidentNormalization";
import { DEFAULT_ALGORITHM_CONFIG, AlgorithmConfig } from "./algorithmConfig";

export const PrioritySchema = z.object({
  priority: z.enum(["urgente", "alta", "media", "baja"]).describe("Nivel de prioridad operativa"),
  priorityScore: z.number().min(0).max(100).describe("Valor numérico ponderado de 0 a 100"),
  reason: z.string().describe("Trazabilidad de la decisión del motor de reglas"),
});

export type PriorityResult = z.infer<typeof PrioritySchema>;

export const priorityCalculationFlow = ai.defineFlow(
  {
    name: "priorityCalculationFlow",
    inputSchema: z.object({
      semanticExtraction: z.custom<SemanticExtractionResult | null>(),
      category: z.custom<CategoryNormalized>(),
      enrichment: z.custom<EnrichmentResult>(),
      duplicateCheck: z.custom<DuplicateCheckResult>(),
      config: z.custom<AlgorithmConfig | undefined>().optional(),
    }),
    outputSchema: PrioritySchema,
  },
  async (input): Promise<PriorityResult> => {
    const config = input.config ?? DEFAULT_ALGORITHM_CONFIG;
    const { categoryBaseScores, priorityWeights, priorityThresholds } = config;

    let score = 0;
    const reasons: string[] = [];

    // 1. Base score by normalized category
    if (input.category && input.category in categoryBaseScores) {
      const baseScore = categoryBaseScores[input.category];
      score += baseScore;
      reasons.push(`Categoría '${input.category}' (+${baseScore})`);
    } else {
      score += categoryBaseScores.otro;
      reasons.push(`Categoría no definida o 'otro' (+${categoryBaseScores.otro})`);
    }

    // 2. Semantic Weight adjusting
    if (input.semanticExtraction && input.semanticExtraction.detectedTerms.length > 0) {
      const terms = input.semanticExtraction.detectedTerms;
      const sortedTerms = [...terms].sort((a, b) => b.weight - a.weight);
      const limit = Math.min(priorityWeights.semanticTermsLimit, sortedTerms.length);
      let termsScore = 0;
      for (let i = 0; i < limit; i++) {
        termsScore += sortedTerms[i].weight * priorityWeights.semanticTermPointsMultiplier;
      }
      const roundedTermsScore = Math.round(termsScore);
      score += roundedTermsScore;
      reasons.push(`Términos clave detectados (+${roundedTermsScore})`);
    }

    // 3. Duplicates clustering
    if (input.duplicateCheck.nearbyCount > 0) {
      const dupScore = Math.min(
        priorityWeights.duplicateMaxPoints,
        input.duplicateCheck.nearbyCount * priorityWeights.duplicateNearbyPoints
      );
      score += dupScore;
      reasons.push(`Incidentes cercanos: ${input.duplicateCheck.nearbyCount} (+${dupScore})`);
    }

    // 4. User Reputation adjustment
    if (input.enrichment.user.reputationScore !== null) {
      const rep = input.enrichment.user.reputationScore;
      if (rep < priorityWeights.reputationLowThreshold) {
        score -= priorityWeights.reputationAdjustment;
        reasons.push(`Reputación baja del usuario (${rep}) (-${priorityWeights.reputationAdjustment})`);
      } else if (rep > priorityWeights.reputationHighThreshold) {
        score += priorityWeights.reputationAdjustment;
        reasons.push(`Reputación alta del usuario (${rep}) (+${priorityWeights.reputationAdjustment})`);
      }
    }

    score = Math.max(0, Math.min(100, Math.round(score)));

    let priority: PriorityResult["priority"] = "baja";
    if (score >= priorityThresholds.urgente) {
      priority = "urgente";
    } else if (score >= priorityThresholds.alta) {
      priority = "alta";
    } else if (score >= priorityThresholds.media) {
      priority = "media";
    }

    return {
      priority,
      priorityScore: score,
      reason: reasons.join(" | "),
    };
  }
);
