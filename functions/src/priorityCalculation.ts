import { z } from "genkit";
import { ai } from "./genkit";
import { SemanticExtractionResult } from "./semanticExtraction";
import { EnrichmentResult } from "./incidentEnrichment";
import { DuplicateCheckResult } from "./incidentDuplicates";
import { CategoryNormalized } from "./incidentNormalization";

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
    }),
    outputSchema: PrioritySchema,
  },
  async (input): Promise<PriorityResult> => {
    let score = 0;
    const reasons: string[] = [];

    // 1. Base score by normalized category (0-50 pts)
    const categoryBaseScores: Record<Exclude<CategoryNormalized, null>, number> = {
      "alumbrado_electrico": 40,
      "infraestructura_vial": 40,
      "pavimentacion": 30,
      "saneamiento": 30,
      "espacios_verdes": 20,
      "otro": 10,
    };

    if (input.category && categoryBaseScores[input.category]) {
      const baseScore = categoryBaseScores[input.category];
      score += baseScore;
      reasons.push(`Categoría '${input.category}' (+${baseScore})`);
    } else {
      score += 10;
      reasons.push(`Categoría no definida o 'otro' (+10)`);
    }

    // 2. Semantic Weight adjusting (0-30 pts)
    if (input.semanticExtraction && input.semanticExtraction.detectedTerms.length > 0) {
      const terms = input.semanticExtraction.detectedTerms;
      const sortedTerms = terms.sort((a, b) => b.weight - a.weight);
      // Top 3 terms contribute
      let termsScore = 0;
      for (let i = 0; i < Math.min(3, sortedTerms.length); i++) {
        termsScore += sortedTerms[i].weight * 10; // each weight [0-1] grants up to 10 points
      }
      const roundedTermsScore = Math.round(termsScore);
      score += roundedTermsScore;
      reasons.push(`Términos clave detectados (+${roundedTermsScore})`);
    }

    // 3. Duplicates clustering (0-20 pts)
    if (input.duplicateCheck.nearbyCount > 0) {
      const dupScore = Math.min(20, input.duplicateCheck.nearbyCount * 5); // 5 points per nearby, max 20
      score += dupScore;
      reasons.push(`Incidentes cercanos: ${input.duplicateCheck.nearbyCount} (+${dupScore})`);
    }

    // 4. User Reputation adjustment (-10 to +10 pts)
    if (input.enrichment.user.reputationScore !== null) {
      const rep = input.enrichment.user.reputationScore;
      if (rep < 30) {
        score -= 10;
        reasons.push(`Reputación baja del usuario (${rep}) (-10)`);
      } else if (rep > 80) {
        score += 10;
        reasons.push(`Reputación alta del usuario (${rep}) (+10)`);
      }
    }

    // Bound the score between 0 and 100
    score = Math.max(0, Math.min(100, Math.round(score)));

    // Categorize
    let priority: PriorityResult["priority"] = "baja";
    if (score >= 80) {
      priority = "urgente";
    } else if (score >= 60) {
      priority = "alta";
    } else if (score >= 30) {
      priority = "media";
    }

    return {
      priority,
      priorityScore: score,
      reason: reasons.join(" | "),
    };
  }
);
