import { updateUserReputationLogic } from "./reputationManager";

interface FakeDoc {
  data?: Record<string, unknown>;
}

function buildFakeFirestore(initialDocs: Record<string, FakeDoc> = {}) {
  const store: Record<string, FakeDoc> = { ...initialDocs };

  function buildDocRef(path: string) {
    return {
      async get() {
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
      update(data: Record<string, unknown>) {
        if (store[path]?.data) {
          store[path] = { data: { ...store[path].data, ...data } };
        }
      },
    };
  }

  const firestore = {
    collection(name: string) {
      return {
        doc(uid: string) {
          return buildDocRef(`${name}/${uid}`);
        },
      };
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
        update: (
          ref: ReturnType<typeof buildDocRef>,
          data: Record<string, unknown>
        ) => {
          ref.update(data);
        },
      };
      return handler(tx);
    },
  };

  return { firestore, store };
}

describe("updateUserReputationLogic", () => {
  it("should increment reputation when incident is verified", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user1": { data: { reputationScore: 50 } },
      "incidents/incident1": { data: { status: "programado" } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user1", { status: "recibido" }, { status: "programado" }, "incident1");

    expect(store["users/user1"].data?.reputationScore).toBe(55);
    expect(store["incidents/incident1"].data?.reputationApplied).toBe(true);
  });

  it("should decrement reputation when incident is moderatedAsFalse", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user2": { data: { reputationScore: 50 } },
      "incidents/incident2": { data: { moderatedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user2", { moderatedAsFalse: false }, { moderatedAsFalse: true }, "incident2");

    expect(store["users/user2"].data?.reputationScore).toBe(35);
    expect(store["incidents/incident2"].data?.reputationApplied).toBe(true);
  });

  it("should not exceed max reputation limit", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user3": { data: { reputationScore: 98 } },
      "incidents/incident3": { data: { status: "solucionado" } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user3", { status: "recibido" }, { status: "solucionado" }, "incident3");

    expect(store["users/user3"].data?.reputationScore).toBe(100);
  });

  it("should not go below min reputation limit", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user4": { data: { reputationScore: 10 } },
      "incidents/incident4": { data: { moderatedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user4", { moderatedAsFalse: false }, { moderatedAsFalse: true }, "incident4");

    expect(store["users/user4"].data?.reputationScore).toBe(0);
  });

  it("should increment reputation if transitioning programado -> solucionado for the first time", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user5": { data: { reputationScore: 50 } },
      "incidents/incident5": { data: { status: "solucionado" } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user5", { status: "programado" }, { status: "solucionado" }, "incident5");

    expect(store["users/user5"].data?.reputationScore).toBe(55);
    expect(store["incidents/incident5"].data?.reputationApplied).toBe(true);
  });

  it("should early return if status and moderatedAsFalse did not change", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user8": { data: { reputationScore: 50 } },
      "incidents/incident8": { data: { status: "programado" } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user8", { status: "programado" }, { status: "programado" }, "incident8");

    expect(store["incidents/incident8"].data?.reputationApplied).toBeUndefined();
  });

  it("should not change reputation if reputationApplied is already true (idempotency)", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user7": { data: { reputationScore: 50 } },
      "incidents/incident7": { data: { status: "programado", reputationApplied: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user7", { status: "recibido" }, { status: "programado" }, "incident7");

    expect(store["users/user7"].data?.reputationScore).toBe(50); // Untouched
  });

  it("should not crash if user document is missing", async () => {
    const { firestore, store } = buildFakeFirestore({
      "incidents/incident8": { data: { status: "programado" } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user_missing", { status: "recibido" }, { status: "programado" }, "incident8");

    expect(store["users/user_missing"]).toBeUndefined();
  });

  it("should default to 100 if user has no reputationScore", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user6": { data: { } },
      "incidents/incident6": { data: { moderatedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user6", { moderatedAsFalse: false }, { moderatedAsFalse: true }, "incident6");

    expect(store["users/user6"].data?.reputationScore).toBe(85);
  });

  // ── Tests de integración moderation.ts ↔ reputationManager.ts [D-08] ──────
  // Estos tests **no** setean a mano el campo que el trigger lee. En cambio,
  // simulan exactamente el snapshot `before`/`after` que produce el callable
  // `moderateFalseReport` (moderation.ts:90-95) y verifican que el trigger
  // efectivamente decrementa la reputación. Antes de D-08 estos pasaban en
  // verde pero los datos reales nunca disparaban el camino — el test viejo
  // setea `moderatedAsFalse` a mano y oculta el bug. Estos lo desnudan.
  describe("[D-08] integración con moderation.ts", () => {
    it("decrementa reputación con el shape exacto del callable moderateFalseReport", async () => {
      const { firestore, store } = buildFakeFirestore({
        "users/reporter": { data: { reputationScore: 70, falseReportsCount: 0 } },
        // El incidente está como lo deja moderation.ts después de update():
        // los campos escritos en la transacción moderation.ts:90-95.
        "incidents/incidentX": {
          data: {
            status: "falso",
            moderatedAsFalse: true,
            moderatedAt: new Date().toISOString(),
            moderatedBy: "admin-caller",
            userId: "reporter",
          },
        },
      });

      // before = estado del incident antes del callable (no había sido moderado);
      // after = estado del incident después del update de moderation.ts.
      const before = { status: "recibido", userId: "reporter" };
      const after = {
        status: "falso",
        moderatedAsFalse: true,
        moderatedAt: new Date().toISOString(),
        moderatedBy: "admin-caller",
        userId: "reporter",
      };

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await updateUserReputationLogic(firestore as any, "reporter", before, after, "incidentX");

      expect(store["users/reporter"].data?.reputationScore).toBe(55);
      expect(store["incidents/incidentX"].data?.reputationApplied).toBe(true);
    });

    it("no decrementa de nuevo si moderation.ts es invocado dos veces (idempotencia conjunta)", async () => {
      const { firestore, store } = buildFakeFirestore({
        "users/reporter2": { data: { reputationScore: 70 } },
        "incidents/incidentY": {
          data: {
            status: "falso",
            moderatedAsFalse: true,
            reputationApplied: true,  // ya se aplicó por la primera invocación
            userId: "reporter2",
          },
        },
      });

      // Si moderation.ts es invocado de nuevo, su propia guarda
      // (`if (incidentData.moderatedAsFalse === true) return`) corta antes.
      // Pero si por alguna razón se dispara el trigger de nuevo con el mismo
      // shape, el guard de `reputationApplied` en reputationManager debe
      // evitar el doble decremento.
      const before = { status: "falso", moderatedAsFalse: true, userId: "reporter2" };
      const after = { status: "falso", moderatedAsFalse: true, userId: "reporter2" };

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await updateUserReputationLogic(firestore as any, "reporter2", before, after, "incidentY");

      expect(store["users/reporter2"].data?.reputationScore).toBe(70);
    });
  });
});
