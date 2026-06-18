import {
  AlgorithmConfig,
  AlgorithmConfigPatchSchema,
  AlgorithmConfigSchema,
  CONFIG_DOC_PATH,
  DEFAULT_ALGORITHM_CONFIG,
  getAlgorithmConfig,
  invalidateAlgorithmConfigCache,
  loadAlgorithmConfig,
  saveAlgorithmConfig,
} from "./algorithmConfig";

// ── Fake Firestore mínimo para tests deterministas ──────────────────────────

interface FakeDoc {
  data?: Record<string, unknown>;
}

function buildFakeFirestore(initialDocs: Record<string, FakeDoc> = {}) {
  const store: Record<string, FakeDoc> = { ...initialDocs };
  let getCallCount = 0;

  function buildDocRef(path: string) {
    return {
      async get() {
        getCallCount++;
        const entry = store[path];
        return {
          exists: !!entry,
          data: () => entry?.data,
        };
      },
      async set(data: Record<string, unknown>, options?: { merge?: boolean }) {
        if (options?.merge && store[path]?.data) {
          store[path] = { data: { ...store[path].data, ...data } };
        } else {
          store[path] = { data };
        }
      },
    };
  }

  const firestore = {
    doc(path: string) {
      return buildDocRef(path);
    },
    async runTransaction<T>(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      handler: (tx: any) => Promise<T>
    ): Promise<T> {
      const tx = {
        get: (ref: ReturnType<typeof buildDocRef>) => ref.get(),
        set: (
          ref: ReturnType<typeof buildDocRef>,
          data: Record<string, unknown>,
          options?: { merge?: boolean }
        ) => {
          // eslint-disable-next-line @typescript-eslint/no-floating-promises
          ref.set(data, options);
        },
      };
      return handler(tx);
    },
  };

  return { firestore, store, getCallCount: () => getCallCount };
}

describe("AlgorithmConfig (T-NLP-06)", () => {
  beforeEach(() => {
    invalidateAlgorithmConfigCache();
  });

  describe("DEFAULT_ALGORITHM_CONFIG", () => {
    it("respeta el schema estricto", () => {
      expect(() => AlgorithmConfigSchema.parse(DEFAULT_ALGORITHM_CONFIG))
        .not.toThrow();
    });

    it("incluye las tres categorías de riesgo vital esperadas", () => {
      expect(Object.keys(DEFAULT_ALGORITHM_CONFIG.vitalRiskTerms))
        .toEqual(expect.arrayContaining(["medico", "seguridad", "desastre"]));
    });
  });

  describe("getAlgorithmConfig (fresh read)", () => {
    it("retorna los defaults cuando el documento no existe", async () => {
      const { firestore } = buildFakeFirestore({});
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const config = await getAlgorithmConfig(firestore as any);
      expect(config).toEqual(DEFAULT_ALGORITHM_CONFIG);
    });

    it("mergea valores de Firestore por encima de defaults", async () => {
      const { firestore } = buildFakeFirestore({
        [CONFIG_DOC_PATH]: {
          data: {
            priorityThresholds: { urgente: 90, alta: 70, media: 40 },
          },
        },
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const config = await getAlgorithmConfig(firestore as any);
      expect(config.priorityThresholds).toEqual({ urgente: 90, alta: 70, media: 40 });
      // El resto sigue viniendo de los defaults.
      expect(config.categoryBaseScores).toEqual(DEFAULT_ALGORITHM_CONFIG.categoryBaseScores);
    });

    it("cae a defaults si Firestore tiene datos inválidos", async () => {
      const { firestore } = buildFakeFirestore({
        [CONFIG_DOC_PATH]: {
          data: {
            priorityThresholds: { urgente: "no-numero" },
          },
        },
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const config = await getAlgorithmConfig(firestore as any);
      expect(config).toEqual(DEFAULT_ALGORITHM_CONFIG);
    });
  });

  describe("loadAlgorithmConfig (cache)", () => {
    it("usa caché para evitar leer Firestore en cada llamada", async () => {
      const { firestore, getCallCount } = buildFakeFirestore({
        [CONFIG_DOC_PATH]: { data: {} },
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      expect(getCallCount()).toBe(1);
    });

    it("invalidateAlgorithmConfigCache fuerza una nueva lectura", async () => {
      const { firestore, getCallCount } = buildFakeFirestore({
        [CONFIG_DOC_PATH]: { data: {} },
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      invalidateAlgorithmConfigCache();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      expect(getCallCount()).toBe(2);
    });
  });

  describe("saveAlgorithmConfig", () => {
    it("persiste el patch, retorna config mergeada y registra updatedBy", async () => {
      const { firestore, store } = buildFakeFirestore({});
      const updated = await saveAlgorithmConfig(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore as any,
        {
          priorityThresholds: { urgente: 95 },
        },
        "admin-uid-1"
      );

      expect(updated.priorityThresholds.urgente).toBe(95);
      // Los campos no tocados quedan con defaults.
      expect(updated.priorityThresholds.alta).toBe(
        DEFAULT_ALGORITHM_CONFIG.priorityThresholds.alta
      );
      const persisted = store[CONFIG_DOC_PATH].data as Record<string, unknown> & {
        updatedBy: string;
      };
      expect(persisted.updatedBy).toBe("admin-uid-1");
    });

    it("rechaza patches con tipos inválidos", async () => {
      const { firestore } = buildFakeFirestore({});
      await expect(
        saveAlgorithmConfig(
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          firestore as any,
          { priorityThresholds: { urgente: 150 } as never },
          "admin-uid-1"
        )
      ).rejects.toThrow();
    });

    it("invalida el caché tras escribir para que el siguiente load lea fresco", async () => {
      const { firestore, getCallCount } = buildFakeFirestore({
        [CONFIG_DOC_PATH]: { data: {} },
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await loadAlgorithmConfig(firestore as any);
      const before = getCallCount();
      await saveAlgorithmConfig(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore as any,
        { priorityThresholds: { media: 25 } },
        "admin"
      );
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const reloaded = await loadAlgorithmConfig(firestore as any);
      expect(getCallCount()).toBeGreaterThan(before);
      expect(reloaded.priorityThresholds.media).toBe(25);
    });
  });

  describe("AlgorithmConfigPatchSchema", () => {
    it("acepta un patch parcial vacío", () => {
      expect(() => AlgorithmConfigPatchSchema.parse({})).not.toThrow();
    });

    it("rechaza un threshold fuera de rango", () => {
      const invalid = { priorityThresholds: { urgente: 200 } };
      expect(() => AlgorithmConfigPatchSchema.parse(invalid)).toThrow();
    });

    it("acepta sólo un subset de pesos", () => {
      const partial: { priorityWeights: Partial<AlgorithmConfig["priorityWeights"]> } = {
        priorityWeights: { duplicateNearbyPoints: 7 },
      };
      expect(() => AlgorithmConfigPatchSchema.parse(partial)).not.toThrow();
    });
  });
});
