import { assertCallerIsAdmin } from "./index";

interface UserDoc {
  role?: string;
  status?: string;
}

function buildFakeFirestore(users: Record<string, UserDoc>) {
  return {
    collection(name: string) {
      return {
        doc(uid: string) {
          return {
            async get() {
              const entry = name === "users" ? users[uid] : undefined;
              return {
                exists: !!entry,
                data: () => entry,
              };
            },
          };
        },
      };
    },
  };
}

describe("assertCallerIsAdmin (T-NLP-06 guard)", () => {
  it("lanza unauthenticated cuando no hay uid", async () => {
    const firestore = buildFakeFirestore({});
    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      assertCallerIsAdmin(firestore as any, undefined)
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("lanza permission-denied cuando el usuario no existe", async () => {
    const firestore = buildFakeFirestore({});
    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      assertCallerIsAdmin(firestore as any, "ghost-uid")
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("lanza permission-denied cuando el rol no es administrador", async () => {
    const firestore = buildFakeFirestore({
      "uid-1": { role: "vecino_informante", status: "active" },
    });
    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      assertCallerIsAdmin(firestore as any, "uid-1")
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("lanza permission-denied cuando el admin no está activo", async () => {
    const firestore = buildFakeFirestore({
      "uid-1": { role: "administrador", status: "blocked" },
    });
    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      assertCallerIsAdmin(firestore as any, "uid-1")
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("acepta a un administrador activo", async () => {
    const firestore = buildFakeFirestore({
      "uid-admin": { role: "administrador", status: "active" },
    });
    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      assertCallerIsAdmin(firestore as any, "uid-admin")
    ).resolves.toBeUndefined();
  });
});
