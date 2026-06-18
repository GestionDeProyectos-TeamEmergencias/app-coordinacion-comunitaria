import { vitalRiskDetectionFlow, normalizeText, VITAL_RISK_TERMS } from "./vitalRiskDetection";

describe("Vital Risk Detection (T-NLP-05)", () => {
  // ── Casos de riesgo vital ───────────────────────────────────────────────────

  it("detects vital risk in medical emergency text", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Me estoy infartando",
    });

    expect(result.isVitalRisk).toBe(true);
    expect(result.matchedTerms).toContain("infartando");
    expect(result.riskCategory).toBe("medico");
    expect(result.emergencyNumbers).toContain("107");
    expect(result.reason).toContain("Riesgo vital detectado");
  });

  it("detects vital risk in violence/crime text", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Hay un tiroteo en la calle",
    });

    expect(result.isVitalRisk).toBe(true);
    expect(result.matchedTerms).toContain("tiroteo");
    expect(result.riskCategory).toBe("seguridad");
    expect(result.emergencyNumbers).toContain("911");
    expect(result.reason).toContain("Riesgo vital detectado");
  });

  it("detects vital risk in disaster/fire text", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Se prendió fuego la casa del vecino",
    });

    expect(result.isVitalRisk).toBe(true);
    // "prendió fuego" normalizado sin acento coincide con "prendio fuego" del diccionario
    expect(result.matchedTerms).toContain("prendio fuego");
    expect(result.riskCategory).toBe("desastre");
    expect(result.emergencyNumbers).toContain("911");
  });

  // ── Casos sin riesgo vital (incidentes urbanos normales) ────────────────────

  it("returns no risk for normal urban incident text", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Hay un bache en la esquina de mi casa",
    });

    expect(result.isVitalRisk).toBe(false);
    expect(result.matchedTerms).toHaveLength(0);
    expect(result.riskCategory).toBe("none");
    expect(result.emergencyNumbers).toHaveLength(0);
    expect(result.reason).toContain("No se detectaron términos de riesgo vital");
  });

  // ── Texto mixto (urbano + riesgo vital) ─────────────────────────────────────

  it("detects vital risk in mixed urban + emergency text", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Hay un poste caído en la vereda y se ve un incendio en el edificio de al lado",
    });

    expect(result.isVitalRisk).toBe(true);
    expect(result.matchedTerms).toContain("incendio");
    // La seguridad tiene prioridad: el flujo se interrumpe
  });

  // ── Edge cases ──────────────────────────────────────────────────────────────

  it("handles null description gracefully", async () => {
    const result = await vitalRiskDetectionFlow({
      description: null,
    });

    expect(result.isVitalRisk).toBe(false);
    expect(result.matchedTerms).toHaveLength(0);
    expect(result.reason).toContain("Sin descripción textual");
  });

  it("handles empty string description", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "",
    });

    expect(result.isVitalRisk).toBe(false);
    expect(result.matchedTerms).toHaveLength(0);
    expect(result.reason).toContain("Sin descripción textual");
  });

  it("normalizes accents and uppercase before matching", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "HAY UNA EXPLOSIÓN EN LA ESQUINA",
    });

    expect(result.isVitalRisk).toBe(true);
    expect(result.matchedTerms).toContain("explosion");
    expect(result.riskCategory).toBe("seguridad");
  });

  it("detects multiple terms from different categories", async () => {
    const result = await vitalRiskDetectionFlow({
      description: "Hay un tiroteo y alguien está desangrando en la calle",
    });

    expect(result.isVitalRisk).toBe(true);
    expect(result.matchedTerms).toContain("tiroteo");
    expect(result.matchedTerms).toContain("desangrando");
    expect(result.matchedTerms.length).toBeGreaterThanOrEqual(2);
  });

  // ── Tests de la función normalizeText ───────────────────────────────────────

  describe("normalizeText utility", () => {
    it("converts to lowercase", () => {
      expect(normalizeText("TIROTEO")).toBe("tiroteo");
    });

    it("removes diacritics/accents", () => {
      expect(normalizeText("explosión")).toBe("explosion");
      expect(normalizeText("convulsión")).toBe("convulsion");
    });

    it("handles combined uppercase + accents", () => {
      expect(normalizeText("EXPLOSIÓN")).toBe("explosion");
    });
  });

  // ── Validación del diccionario ──────────────────────────────────────────────

  describe("VITAL_RISK_TERMS dictionary", () => {
    it("contains the three expected categories", () => {
      expect(Object.keys(VITAL_RISK_TERMS)).toEqual(
        expect.arrayContaining(["medico", "seguridad", "desastre"])
      );
    });

    it("has no empty term arrays", () => {
      for (const [_category, terms] of Object.entries(VITAL_RISK_TERMS)) {
        expect(terms.length).toBeGreaterThan(0);
      }
    });

    it("has no duplicate terms within a category", () => {
      for (const [_category, terms] of Object.entries(VITAL_RISK_TERMS)) {
        const uniqueTerms = new Set(terms);
        expect(uniqueTerms.size).toBe(terms.length);
      }
    });
  });
});
