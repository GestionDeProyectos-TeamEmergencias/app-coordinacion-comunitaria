import { semanticExtractionFlow, mapSemanticCategoryToNormalized } from "./semanticExtraction";
import { ai } from "./genkit";

const generateSpy = jest.spyOn(ai, "generate");

describe("Semantic Extraction (T-NLP-03)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("mapSemanticCategoryToNormalized", () => {
    test("mapea las categorías de la IA a las normalizadas del sistema", () => {
      expect(mapSemanticCategoryToNormalized("eléctrico")).toBe("alumbrado_electrico");
      expect(mapSemanticCategoryToNormalized("vial")).toBe("infraestructura_vial");
      expect(mapSemanticCategoryToNormalized("sanitario")).toBe("saneamiento");
      expect(mapSemanticCategoryToNormalized("espacios verdes")).toBe("espacios_verdes");
      expect(mapSemanticCategoryToNormalized("seguridad")).toBe("otro");
      expect(mapSemanticCategoryToNormalized("otro")).toBe("otro");
    });
  });

  describe("semanticExtractionFlow", () => {
    test("retorna datos predeterminados de inmediato y evita llamada a Gemini si la descripción está vacía", async () => {
      const result = await semanticExtractionFlow({ description: "" });

      expect(result).toEqual({
        category: "otro",
        intention: "Reporte rápido sin descripción textual",
        detectedTerms: []
      });

      expect(generateSpy).not.toHaveBeenCalled();
    });

    test("retorna datos predeterminados si la descripción es null o undefined", async () => {
      const result = await semanticExtractionFlow({ description: null });

      expect(result).toEqual({
        category: "otro",
        intention: "Reporte rápido sin descripción textual",
        detectedTerms: []
      });

      expect(generateSpy).not.toHaveBeenCalled();
    });

    test("ejecuta el flow con Gemini y retorna el resultado estructurado si hay descripción", async () => {
      const mockLLMOutput = {
        category: "vial",
        intention: "Reportar bache profundo",
        detectedTerms: [
          { term: "bache", weight: 1.0 },
          { term: "calle", weight: 0.5 }
        ]
      };

      generateSpy.mockResolvedValue({
        output: mockLLMOutput
      } as any);

      const result = await semanticExtractionFlow({
        description: "Hay un bache gigante en la calle principal."
      });

      expect(result).toEqual(mockLLMOutput);
      expect(generateSpy).toHaveBeenCalledTimes(1);
      
      const generateArgs = generateSpy.mock.calls[0][0] as any;
      expect(generateArgs.prompt).toContain("Hay un bache gigante en la calle principal.");
      expect(generateArgs.model).toBe("googleai/gemini-2.5-flash-lite");
    });

    test("lanza error si la respuesta del modelo está vacía o es inválida", async () => {
      generateSpy.mockResolvedValue({
        output: null
      } as any);

      await expect(
        semanticExtractionFlow({ description: "Descripción con error" })
      ).rejects.toThrow("No se pudo obtener una respuesta válida de Gemini.");
    });
  });
});
