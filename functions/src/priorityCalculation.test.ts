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

    // Base 40 + round(0.9*13 + 0.8*13) = 40 + 22 = 62  [calibración: mult=13]
    expect(result.priorityScore).toBe(62);
    expect(result.priority).toBe("alta");
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
          { term: "pozo", weight: 1.0 }, // +13
          { term: "peligro", weight: 1.0 }, // +13
        ],
      },
      enrichment: highRepEnrichment, // rep 90 > 70 -> +15
      duplicateCheck: manyDuplicates, // 5 * 5 = +25 (max 20) -> +20
    });

    // 40 + 26 + 15 + 20 = 101 -> clamp 100 -> 'urgente'  [calibración]
    expect(result.priorityScore).toBe(100);
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
      enrichment: lowRepEnrichment, // rep 10 < 45 -> -15 penalty
      duplicateCheck: dummyDuplicate,
    });

    // 20 - 15 = 5 -> 'baja'  [calibración: reputationAdjustment=15]
    expect(result.priorityScore).toBe(5);
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
    expect(res1.priorityScore).toBe(0); // 10 - 15 = -5 -> clamp 0 (bounded)

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
          { term: "a", weight: 1.0 }, // 13
          { term: "b", weight: 1.0 }, // 13
          { term: "c", weight: 1.0 }, // 13
          { term: "d", weight: 1.0 }, // Top 3 only = 39
        ],
      },
      enrichment: highRepEnrichment, // rep 100 > 70 -> +15
      duplicateCheck: maxDuplicates, // +20
    });

    // 40 + 39 + 15 + 20 = 114 -> clamp 100
    expect(res2.priorityScore).toBe(100);
    expect(res2.priority).toBe("urgente");
  });

  // ── Calibración: urgente alcanzable + reputación pondera más ────────────────
  describe("calibración de defaults", () => {
    it("un reporte único textualmente grave alcanza 'urgente' sin duplicados", async () => {
      const result = await priorityCalculationFlow({
        category: "infraestructura_vial" as CategoryNormalized, // base 40
        semanticExtraction: {
          ...dummySemantic,
          detectedTerms: [
            { term: "derrumbe", weight: 0.9 },
            { term: "grietas", weight: 0.9 },
            { term: "peligro", weight: 0.9 },
          ],
        },
        enrichment: dummyEnrichment, // rep 50 -> neutral
        duplicateCheck: dummyDuplicate,
      });

      // 40 + round(0.9*13 * 3 = 35.1) = 75 >= urgente(72)
      expect(result.priorityScore).toBe(75);
      expect(result.priority).toBe("urgente");
    });

    it("penaliza reputación moderadamente baja (40) que antes quedaba neutral", async () => {
      const result = await priorityCalculationFlow({
        category: "infraestructura_vial" as CategoryNormalized, // base 40
        semanticExtraction: null,
        enrichment: {
          ...dummyEnrichment,
          user: { ...dummyEnrichment.user, reputationScore: 40 }, // < 45
        },
        duplicateCheck: dummyDuplicate,
      });

      // 40 - 15 = 25 (antes quedaba en 40: rep 40 > low=30 no penalizaba)
      expect(result.priorityScore).toBe(25);
    });

    it("bonifica reputación alta (75) que antes quedaba neutral", async () => {
      const result = await priorityCalculationFlow({
        category: "infraestructura_vial" as CategoryNormalized, // base 40
        semanticExtraction: null,
        enrichment: {
          ...dummyEnrichment,
          user: { ...dummyEnrichment.user, reputationScore: 75 }, // > 70
        },
        duplicateCheck: dummyDuplicate,
      });

      // 40 + 15 = 55 (antes quedaba en 40: rep 75 < high=80 no bonificaba)
      expect(result.priorityScore).toBe(55);
    });
  });
});
