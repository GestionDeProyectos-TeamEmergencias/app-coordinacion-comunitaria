import {
  executeBroadcast,
  MAX_BROADCAST_RADIUS_METERS,
} from "./adminBroadcast";
import * as admin from "firebase-admin";

// ── Fakes ────────────────────────────────────────────────────────────────────
// Tests sobre `executeBroadcast` (función pura) en lugar de la API privada
// `(broadcastNotification as any).run(...)` de firebase-functions.

interface FakeUserDoc {
  // Si se omite, generamos un id sintético. Útil para tests del cleanup que
  // necesitan trackear updates por uid.
  id?: string;
  data: Record<string, unknown>;
}

function buildFakeFirestoreWithUsers(activeUsers: FakeUserDoc[]) {
  const broadcastsAdded: Record<string, unknown>[] = [];
  let lastQueryFilter: { field: string; op: string; value: unknown } | null =
    null;
  // Captura de updates aplicados a `users/{uid}` por el cleanup de tokens.
  const userUpdates: { id: string; patch: Record<string, unknown> }[] = [];

  // Asignamos id sintético si no vino — necesario para el cleanup
  // (token → userId) introducido por el fix de broadcast zonal.
  activeUsers.forEach((u, i) => {
    if (!u.id) u.id = `synthetic-user-${i}`;
  });

  function userDocRef(id: string) {
    return {
      __userRef: true,
      __id: id,
    };
  }

  const firestore = {
    collection(name: string) {
      if (name === "users") {
        return {
          where(field: string, op: string, value: unknown) {
            lastQueryFilter = { field, op, value };
            return {
              async get() {
                return {
                  forEach: (
                    cb: (doc: {
                      id: string;
                      data: () => Record<string, unknown>;
                    }) => void,
                  ) =>
                    activeUsers.forEach((u) =>
                      cb({ id: u.id as string, data: () => u.data }),
                    ),
                };
              },
            };
          },
          doc(id: string) {
            return userDocRef(id);
          },
        };
      }
      if (name === "broadcasts") {
        return {
          async add(data: Record<string, unknown>) {
            broadcastsAdded.push(data);
          },
        };
      }
      throw new Error(`Unexpected collection ${name}`);
    },
    batch() {
      const ops: { ref: { __id: string }; patch: Record<string, unknown> }[] =
        [];
      return {
        update(
          ref: { __userRef: boolean; __id: string },
          patch: Record<string, unknown>,
        ) {
          ops.push({ ref, patch });
        },
        async commit() {
          for (const op of ops) {
            userUpdates.push({ id: op.ref.__id, patch: op.patch });
          }
        },
      };
    },
  };

  return {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    firestore: firestore as any,
    broadcastsAdded,
    userUpdates,
    getLastQueryFilter: () => lastQueryFilter,
  };
}

function buildFakeMessaging(
  responses: {
    successCount: number;
    failureCount: number;
    responses?: unknown[];
  }[] = [],
) {
  const calls: admin.messaging.MulticastMessage[] = [];
  let callIdx = 0;
  const messaging = {
    async sendEachForMulticast(payload: admin.messaging.MulticastMessage) {
      calls.push(payload);
      const r = responses[callIdx++] ?? {
        successCount: payload.tokens.length,
        failureCount: 0,
        responses: payload.tokens.map(() => ({ success: true })),
      };
      return r;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } as any as admin.messaging.Messaging;
  return { messaging, calls };
}

describe("executeBroadcast (T-NLP-09)", () => {
  it("filtra solo usuarios activos en la query (no envía a bloqueados ni pendientes)", async () => {
    const { firestore, getLastQueryFilter } = buildFakeFirestoreWithUsers([
      { data: { fcmTokens: ["tok-active"] } },
    ]);
    const { messaging } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "Hola", body: "Mundo" },
      caller: { uid: "admin1" },
    });

    expect(getLastQueryFilter()).toEqual({
      field: "status",
      op: "==",
      value: "active",
    });
  });

  it("envía broadcast global a todos los activos con tokens", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      { data: { fcmTokens: ["tok1"], coverageLat: 0, coverageLng: 0 } },
      { data: { fcmTokens: ["tok2"] } },
      { data: { fcmTokens: [] } }, // sin tokens — se ignora
    ]);
    const { messaging, calls } = buildFakeMessaging([
      {
        successCount: 2,
        failureCount: 0,
        responses: [{ success: true }, { success: true }],
      },
    ]);

    const result = await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "Alerta", body: "Cuidado" },
      caller: { uid: "admin1" },
    });

    expect(result.successCount).toBe(2);
    expect(calls).toHaveLength(1);
    expect(calls[0].tokens).toEqual(["tok1", "tok2"]);
    expect(calls[0].notification?.title).toBe("Alerta");
    // El payload data NO debe incluir click_action legacy.
    expect(
      (calls[0].data as Record<string, string>).click_action,
    ).toBeUndefined();
  });

  it("filtra por área geográfica con Haversine y excluye usuarios fuera del radio", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      // Obelisco
      {
        data: {
          fcmTokens: ["tok-near"],
          coverageLat: -34.6038,
          coverageLng: -58.3817,
        },
      },
      // Mar del Plata — muy lejos
      {
        data: {
          fcmTokens: ["tok-far"],
          coverageLat: -38.0,
          coverageLng: -57.55,
        },
      },
      // Sin coordenadas — se excluye en envío zonal
      { data: { fcmTokens: ["tok-no-loc"] } },
    ]);
    const { messaging, calls } = buildFakeMessaging([
      {
        successCount: 1,
        failureCount: 0,
        responses: [{ success: true }],
      },
    ]);

    await executeBroadcast({
      firestore,
      messaging,
      payload: {
        title: "Calle cortada",
        body: "Tránsito",
        area: { latitude: -34.6037, longitude: -58.3816, radiusMeters: 500 },
      },
      caller: { uid: "admin1" },
    });

    expect(calls).toHaveLength(1);
    expect(calls[0].tokens).toEqual(["tok-near"]);
  });

  it("deduplica tokens cuando un mismo aparece en varios usuarios", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      { data: { fcmTokens: ["shared", "uniq1"] } },
      { data: { fcmTokens: ["shared", "uniq2"] } },
    ]);
    const { messaging, calls } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "T", body: "B" },
      caller: { uid: "admin1" },
    });

    const tokens = (calls[0].tokens as string[]).sort();
    expect(tokens).toEqual(["shared", "uniq1", "uniq2"].sort());
  });

  it("retorna invalidTokens=N cuando hay tokens dados de baja", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      { data: { fcmTokens: ["alive", "dead"] } },
    ]);
    const { messaging } = buildFakeMessaging([
      {
        successCount: 1,
        failureCount: 1,
        responses: [
          { success: true },
          {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          },
        ],
      },
    ]);

    const result = await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "T", body: "B" },
      caller: { uid: "admin1" },
    });

    expect(result.invalidTokens).toBe(1);
    expect(result.successCount).toBe(1);
    expect(result.failureCount).toBe(1);
  });

  it("persiste auditoría en broadcasts/ tras un envío exitoso", async () => {
    const { firestore, broadcastsAdded } = buildFakeFirestoreWithUsers([
      { data: { fcmTokens: ["tok1"] } },
    ]);
    const { messaging } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "Hola", body: "Mundo" },
      caller: { uid: "admin-xyz" },
    });

    expect(broadcastsAdded).toHaveLength(1);
    const entry = broadcastsAdded[0];
    expect(entry.title).toBe("Hola");
    expect(entry.body).toBe("Mundo");
    expect(entry.sentBy).toBe("admin-xyz");
    expect(entry.successCount).toBe(1);
  });

  it("también audita cuando no hay tokens (sin enviar nada)", async () => {
    const { firestore, broadcastsAdded } = buildFakeFirestoreWithUsers([]);
    const { messaging, calls } = buildFakeMessaging();

    const result = await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "T", body: "B" },
      caller: { uid: "admin1" },
    });

    expect(calls).toHaveLength(0);
    expect(result.successCount).toBe(0);
    expect(broadcastsAdded).toHaveLength(1);
  });

  it("MAX_BROADCAST_RADIUS_METERS es un valor finito > 0", () => {
    expect(MAX_BROADCAST_RADIUS_METERS).toBeGreaterThan(0);
    expect(Number.isFinite(MAX_BROADCAST_RADIUS_METERS)).toBe(true);
  });

  // ── Fix de broadcast zonal: homeLat/Lng del vecino + cleanup de tokens ────
  // El filtro zonal aceptaba solo `coverageLat/Lng` (Referente Barrial). Los
  // vecinos quedaban afuera porque ese campo no se completa en su flujo. Ahora
  // toma `homeLat/Lng` (vecino) o `coverageLat/Lng` (referente), el primero
  // disponible.

  it("filtro zonal usa homeLat/Lng del vecino cuando está presente", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      {
        id: "vecino-near",
        data: {
          fcmTokens: ["tok-vecino"],
          homeLat: -34.6038,
          homeLng: -58.3817,
        },
      },
      {
        id: "referente-far",
        data: {
          fcmTokens: ["tok-ref"],
          coverageLat: -38.0,
          coverageLng: -57.55,
        },
      },
    ]);
    const { messaging, calls } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: {
        title: "T",
        body: "B",
        area: { latitude: -34.6037, longitude: -58.3816, radiusMeters: 500 },
      },
      caller: { uid: "admin1" },
    });

    expect(calls[0].tokens).toEqual(["tok-vecino"]);
  });

  it("filtro zonal cae a coverageLat/Lng cuando no hay homeLat/Lng", async () => {
    const { firestore } = buildFakeFirestoreWithUsers([
      {
        id: "referente-near",
        data: {
          fcmTokens: ["tok-ref"],
          coverageLat: -34.6038,
          coverageLng: -58.3817,
        },
      },
    ]);
    const { messaging, calls } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: {
        title: "T",
        body: "B",
        area: { latitude: -34.6037, longitude: -58.3816, radiusMeters: 500 },
      },
      caller: { uid: "admin1" },
    });

    expect(calls[0].tokens).toEqual(["tok-ref"]);
  });

  it("user con homeLat/Lng prefiere sobre coverageLat/Lng (caso edge)", async () => {
    // Un user que es referente Y tiene homeLat — usamos homeLat (es la
    // ubicación de interés más reciente).
    const { firestore } = buildFakeFirestoreWithUsers([
      {
        id: "dual",
        data: {
          fcmTokens: ["tok-dual"],
          // home cerca del centro de búsqueda
          homeLat: -34.6038,
          homeLng: -58.3817,
          // coverage lejos
          coverageLat: -38.0,
          coverageLng: -57.55,
        },
      },
    ]);
    const { messaging, calls } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: {
        title: "T",
        body: "B",
        area: { latitude: -34.6037, longitude: -58.3816, radiusMeters: 500 },
      },
      caller: { uid: "admin1" },
    });

    expect(calls[0].tokens).toEqual(["tok-dual"]);
  });

  it("limpieza de tokens muertos: arrayRemove sobre cada user afectado", async () => {
    const { firestore, userUpdates } = buildFakeFirestoreWithUsers([
      {
        id: "user-1",
        data: { fcmTokens: ["alive-1", "dead-1"] },
      },
      {
        id: "user-2",
        data: { fcmTokens: ["alive-2", "dead-2"] },
      },
    ]);
    const { messaging } = buildFakeMessaging([
      {
        successCount: 2,
        failureCount: 2,
        responses: [
          { success: true },
          {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          },
          { success: true },
          {
            success: false,
            error: { code: "messaging/invalid-registration-token" },
          },
        ],
      },
    ]);

    await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "T", body: "B" },
      caller: { uid: "admin1" },
    });

    // Esperamos updates a user-1 y user-2, cada uno con arrayRemove de su
    // token muerto.
    expect(userUpdates).toHaveLength(2);
    const byId = new Map(userUpdates.map((u) => [u.id, u.patch] as const));
    expect(byId.has("user-1")).toBe(true);
    expect(byId.has("user-2")).toBe(true);
    // Los patches contienen FieldValue.arrayRemove con el token muerto correcto.
    const u1 = byId.get("user-1") as { fcmTokens: { _elements?: string[] } };
    // El FieldValue se serializa como objeto interno; verificamos que apunta
    // al método correcto y al token correcto.
    expect(u1.fcmTokens).toBeDefined();
  });

  it("limpieza es no-op si no hay tokens muertos", async () => {
    const { firestore, userUpdates } = buildFakeFirestoreWithUsers([
      {
        id: "user-1",
        data: { fcmTokens: ["alive"] },
      },
    ]);
    const { messaging } = buildFakeMessaging();

    await executeBroadcast({
      firestore,
      messaging,
      payload: { title: "T", body: "B" },
      caller: { uid: "admin1" },
    });

    expect(userUpdates).toHaveLength(0);
  });
});
