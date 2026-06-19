import {
  appendAuditEntry,
  assertIncidentCompleteness,
  INITIAL_STATUS,
  persistProcessedIncident,
} from "./incidentPersistence";

// ── Fake mínimo de Firestore ────────────────────────────────────────────────

interface FakeDoc {
  data?: Record<string, unknown>;
  subcollections?: Record<string, FakeDoc[]>;
}

function buildFakeFirestore(initial: Record<string, FakeDoc> = {}) {
  const store: Record<string, FakeDoc> = { ...initial };

  function buildDocRef(path: string) {
    return {
      async get() {
        const entry = store[path];
        return {
          exists: !!entry,
          data: () => entry?.data,
        };
      },
      async update(data: Record<string, unknown>) {
        if (!store[path]) store[path] = { data: {} };
        store[path] = {
          ...store[path],
          data: { ...(store[path].data ?? {}), ...data },
        };
      },
      collection(name: string) {
        return {
          async add(data: Record<string, unknown>) {
            const parent = store[path];
            if (!parent) {
              store[path] = { subcollections: { [name]: [{ data }] } };
            } else {
              parent.subcollections = parent.subcollections ?? {};
              parent.subcollections[name] = parent.subcollections[name] ?? [];
              parent.subcollections[name].push({ data });
            }
          },
        };
      },
    };
  }

  return {
    firestore: {
      collection(name: string) {
        return {
          doc(id: string) {
            return buildDocRef(`${name}/${id}`);
          },
        };
      },
      async runTransaction<T>(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        handler: (tx: any) => Promise<T>,
      ): Promise<T> {
        const tx = {
          get: (ref: ReturnType<typeof buildDocRef>) => ref.get(),
          update: (
            ref: ReturnType<typeof buildDocRef>,
            data: Record<string, unknown>,
          ) => {
            // eslint-disable-next-line @typescript-eslint/no-floating-promises
            ref.update(data);
          },
        };
        return handler(tx);
      },
    },
    store,
  };
}

describe("incidentPersistence (T-NLP-08)", () => {
  describe("assertIncidentCompleteness", () => {
    it("retorna lista vacía cuando el documento tiene todos los campos", () => {
      const data = {
        normalizedEvent: {
          userId: "u1",
          timestamp: "2026-06-18T10:00:00Z",
          location: { latitude: 0, longitude: 0 },
          category: "infraestructura_vial",
        },
        normalizedAt: { _seconds: 1 },
        priority: "alta",
        priorityScore: 65,
        status: INITIAL_STATUS,
      };
      expect(assertIncidentCompleteness(data)).toEqual([]);
    });

    it("acepta category null (sin categoría detectada)", () => {
      const data = {
        normalizedEvent: {
          userId: "u1",
          timestamp: "2026-06-18T10:00:00Z",
          location: { latitude: 0, longitude: 0 },
          category: null,
        },
        normalizedAt: { _seconds: 1 },
        priority: "media",
        priorityScore: 30,
        status: INITIAL_STATUS,
      };
      expect(assertIncidentCompleteness(data)).toEqual([]);
    });

    it("reporta issue cuando faltan campos críticos", () => {
      const data = {
        normalizedEvent: {
          userId: "u1",
          // timestamp missing
          location: { latitude: 0, longitude: 0 },
          category: null,
        },
        // normalizedAt missing
        // priority missing
        // priorityScore missing
        status: INITIAL_STATUS,
      };
      const issues = assertIncidentCompleteness(data);
      expect(issues).toEqual(
        expect.arrayContaining([
          expect.stringContaining("normalizedEvent.timestamp"),
          expect.stringContaining("normalizedAt"),
          expect.stringContaining("priority"),
          expect.stringContaining("priorityScore"),
        ]),
      );
    });

    it("retorna issue para documento vacío", () => {
      expect(assertIncidentCompleteness(undefined)).toEqual([
        "document is missing or empty",
      ]);
    });
  });

  describe("persistProcessedIncident", () => {
    const baseArgs = {
      incidentId: "inc-1",
      normalizedEvent: {
        eventId: "inc-1",
        schemaVersion: "1.0.0" as const,
        sourceType: "form" as const,
        timestamp: "2026-06-18T10:00:00Z",
        userId: "u1",
        location: { latitude: 0, longitude: 0, accuracy: null },
        description: "bache",
        category: "infraestructura_vial" as const,
        photoUrl: null,
      },
      warnings: [],
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      enrichment: {} as any,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      duplicateCheck: {} as any,
      semanticExtraction: null,
      priorityCalculation: {
        priority: "alta" as const,
        priorityScore: 65,
        reason: "category=vial",
        calculatedAt: "2026-06-18T10:00:01Z",
      },
    };

    it("setea status=recibido cuando no hay status previo y devuelve statusSet=true", async () => {
      const { firestore, store } = buildFakeFirestore({});
      const result = await persistProcessedIncident({
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore: firestore as any,
        ...baseArgs,
      });
      expect(store["incidents/inc-1"].data?.status).toBe(INITIAL_STATUS);
      expect(store["incidents/inc-1"].data?.priority).toBe("alta");
      expect(store["incidents/inc-1"].data?.priorityScore).toBe(65);
      expect(result.statusSet).toBe(true);
      expect(result.issues).toEqual([]);
    });

    it("respeta status existente distinto y devuelve statusSet=false", async () => {
      const { firestore, store } = buildFakeFirestore({
        "incidents/inc-1": { data: { status: "programado" } },
      });
      const result = await persistProcessedIncident({
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore: firestore as any,
        ...baseArgs,
      });
      expect(store["incidents/inc-1"].data?.status).toBe("programado");
      expect(result.statusSet).toBe(false);
      // Debe reportar como issue para que el caller pueda loggearlo.
      expect(result.issues.some((i) => i.includes("status not set"))).toBe(
        true,
      );
    });

    it("omite priority/priorityScore si priorityCalculation es null y reporta issue", async () => {
      const { firestore, store } = buildFakeFirestore({});
      const result = await persistProcessedIncident({
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore: firestore as any,
        ...baseArgs,
        priorityCalculation: null,
      });
      expect(store["incidents/inc-1"].data?.priority).toBeUndefined();
      expect(store["incidents/inc-1"].data?.priorityScore).toBeUndefined();
      // Pero el normalizedEvent y status sí están.
      expect(store["incidents/inc-1"].data?.normalizedEvent).toBeDefined();
      expect(store["incidents/inc-1"].data?.status).toBe(INITIAL_STATUS);
      // Y los issues lo reportan in-memory (sin GET extra).
      expect(
        result.issues.some((i) => i.includes("priorityCalculation")),
      ).toBe(true);
    });
  });

  describe("appendAuditEntry", () => {
    it("agrega una entrada con stage y timestamp", async () => {
      const { firestore, store } = buildFakeFirestore({
        "incidents/inc-1": { data: {} },
      });
      await appendAuditEntry(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        firestore as any,
        "inc-1",
        "normalized",
        { warnings: 2 },
      );
      const entries = store["incidents/inc-1"].subcollections?.audit;
      expect(entries).toHaveLength(1);
      const data = entries![0].data as Record<string, unknown>;
      expect(data.stage).toBe("normalized");
      expect(data.details).toEqual({ warnings: 2 });
    });

    it("no rompe si la subcolección falla (best-effort)", async () => {
      const brokenFirestore = {
        collection() {
          return {
            doc() {
              return {
                collection() {
                  return {
                    async add() {
                      throw new Error("Firestore down");
                    },
                  };
                },
              };
            },
          };
        },
      };
      await expect(
        appendAuditEntry(
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          brokenFirestore as any,
          "inc-1",
          "normalized",
        ),
      ).resolves.toBeUndefined();
    });
  });
});
