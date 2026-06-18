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
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user1", "recibido", "programado", "incident1");

    expect(store["users/user1"].data?.reputationScore).toBe(55);
  });

  it("should decrement reputation when incident is rejected", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user2": { data: { reputationScore: 50 } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user2", "recibido", "falso", "incident2");

    expect(store["users/user2"].data?.reputationScore).toBe(35);
  });

  it("should not exceed max reputation limit", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user3": { data: { reputationScore: 98 } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user3", "recibido", "solucionado", "incident3");

    expect(store["users/user3"].data?.reputationScore).toBe(100);
  });

  it("should not go below min reputation limit", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user4": { data: { reputationScore: 10 } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user4", "recibido", "rechazado", "incident4");

    expect(store["users/user4"].data?.reputationScore).toBe(0);
  });

  it("should not change reputation if status transition is not relevant", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user5": { data: { reputationScore: 50 } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user5", "programado", "en_reparacion", "incident5");

    expect(store["users/user5"].data?.reputationScore).toBe(50);
  });

  it("should default to 100 if user has no reputationScore", async () => {
    const { firestore, store } = buildFakeFirestore({
      "users/user6": { data: { } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await updateUserReputationLogic(firestore as any, "user6", "recibido", "rechazado", "incident6");

    expect(store["users/user6"].data?.reputationScore).toBe(85);
  });
});
