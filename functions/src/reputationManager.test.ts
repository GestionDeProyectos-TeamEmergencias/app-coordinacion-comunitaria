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

  it("should decrement reputation when incident is verifiedAsFalse", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user2": { data: { reputationScore: 50 } },
      "incidents/incident2": { data: { verifiedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user2", { verifiedAsFalse: false }, { verifiedAsFalse: true }, "incident2");

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
      "incidents/incident4": { data: { verifiedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user4", { verifiedAsFalse: false }, { verifiedAsFalse: true }, "incident4");

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

  it("should early return if status and verifiedAsFalse did not change", async () => {
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
      "incidents/incident6": { data: { verifiedAsFalse: true } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user6", { verifiedAsFalse: false }, { verifiedAsFalse: true }, "incident6");

    expect(store["users/user6"].data?.reputationScore).toBe(85);
  });
});
