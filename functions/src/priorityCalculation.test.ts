import { priorityCalculationFlow } from "./priorityCalculation";
import { SemanticExtractionResult } from "./semanticExtraction";
import { EnrichmentResult } from "./incidentEnrichment";
import { DuplicateCheckResult } from "./incidentDuplicates";
import { CategoryNormalized } from "./incidentNormalization";

describe("Priority Calculation (T-NLP-04)", () => {
  const dummyEnrichment: EnrichmentResult = {
    user: { role: "vecino", status: "active", reputationScore: 50 },
    history: { totalReports: 5, reportsLast30Days: 1 },
  };

  const dummyDuplicate: DuplicateCheckResult = {
    isDuplicate: false,
    nearbyCount: 0,
    nearbyIds: [],
    radiusMeters: 100,
    windowHours: 24,
  };

  const dummySemantic: SemanticExtractionResult = {
    category: "vial",
    intention: "reportar bache",
    detectedTerms: [],
  };

  it("calculates baseline score using only normalized category", async () => {
    const result = await priorityCalculationFlow({
      category: "alumbrado_electrico" as CategoryNormalized,
      semanticExtraction: null,
      enrichment: dummyEnrichment,
      duplicateCheck: dummyDuplicate,
    });

    expect(result.priorityScore).toBe(40);
    expect(result.priority).toBe("media");
    expect(result.reason).toContain("Categoría 'alumbrado_electrico'");
  });

  it("increases score based on semantic keywords weights", async () => {
    const semanticWithTerms: SemanticExtractionResult = {
      ...dummySemantic,
      detectedTerms: [
        { term: "cables", weight: 0.9 },
        { term: "chispa", weight: 0.8 },
      ],
    };

    const result = await priorityCalculationFlow({
      category: "alumbrado_electrico" as CategoryNormalized,
      semanticExtraction: semanticWithTerms,
      enrichment: dummyEnrichment,
      duplicateCheck: dummyDuplicate,
    });

    // Base 40 + (0.9*10) + (0.8*10) = 40 + 9 + 8 = 57
    expect(result.priorityScore).toBe(57);
    expect(result.priority).toBe("media");
    expect(result.reason).toContain("Términos clave detectados");
  });

  it("assigns 'urgente' priority when duplicates and high reputation max out score", async () => {
    const highRepEnrichment: EnrichmentResult = {
      ...dummyEnrichment,
      user: { ...dummyEnrichment.user, reputationScore: 90 },
    };

    const manyDuplicates: DuplicateCheckResult = {
      ...dummyDuplicate,
      isDuplicate: true,
      nearbyCount: 5,
    };

    const result = await priorityCalculationFlow({
      category: "infraestructura_vial" as CategoryNormalized, // base 40
      semanticExtraction: {
        ...dummySemantic,
        detectedTerms: [
          { term: "pozo", weight: 1.0 }, // +10
          { term: "peligro", weight: 1.0 }, // +10
        ],
      },
      enrichment: highRepEnrichment, // +10
      duplicateCheck: manyDuplicates, // 5 * 5 = +25 (max 20) -> +20
    });

    // 40 + 20 + 10 + 20 = 90 -> 'urgente'
    expect(result.priorityScore).toBe(90);
    expect(result.priority).toBe("urgente");
  });

  it("penalizes low reputation scenarios", async () => {
    const lowRepEnrichment: EnrichmentResult = {
      ...dummyEnrichment,
      user: { ...dummyEnrichment.user, reputationScore: 10 },
    };

    const result = await priorityCalculationFlow({
      category: "espacios_verdes" as CategoryNormalized, // base 20
      semanticExtraction: null,
      enrichment: lowRepEnrichment, // -10 penalty
      duplicateCheck: dummyDuplicate,
    });

    // 20 - 10 = 10 -> 'baja'
    expect(result.priorityScore).toBe(10);
    expect(result.priority).toBe("baja");
  });

  it("doesn't exceed 100 or drop below 0", async () => {
    const lowRepEnrichment: EnrichmentResult = {
      ...dummyEnrichment,
      user: { ...dummyEnrichment.user, reputationScore: 10 },
    };

    const res1 = await priorityCalculationFlow({
      category: "otro" as CategoryNormalized, // base 10
      semanticExtraction: null,
      enrichment: lowRepEnrichment, // -10 penalty
      duplicateCheck: dummyDuplicate, // 0
    });
    expect(res1.priorityScore).toBe(0); // 10 - 10 = 0 (bounded)

    const highRepEnrichment: EnrichmentResult = {
      ...dummyEnrichment,
      user: { ...dummyEnrichment.user, reputationScore: 100 },
    };
    const maxDuplicates: DuplicateCheckResult = {
      ...dummyDuplicate,
      nearbyCount: 20, // +20 max
    };
    const res2 = await priorityCalculationFlow({
      category: "alumbrado_electrico" as CategoryNormalized, // base 40
      semanticExtraction: {
        ...dummySemantic,
        detectedTerms: [
          { term: "a", weight: 1.0 }, // 10
          { term: "b", weight: 1.0 }, // 10
          { term: "c", weight: 1.0 }, // 10
          { term: "d", weight: 1.0 }, // Top 3 only = 30
        ],
      },
      enrichment: highRepEnrichment, // +10
      duplicateCheck: maxDuplicates, // +20
    });
    
    // 40 + 30 + 10 + 20 = 100
    expect(res2.priorityScore).toBe(100);
    expect(res2.priority).toBe("urgente");
  });
});
