import {
  executeBroadcast,
  MAX_BROADCAST_RADIUS_METERS,
} from "./adminBroadcast";
import * as admin from "firebase-admin";

// ── Fakes ────────────────────────────────────────────────────────────────────
// Tests sobre `executeBroadcast` (función pura) en lugar de la API privada
// `(broadcastNotification as any).run(...)` de firebase-functions.

interface FakeUserDoc {
  data: Record<string, unknown>;
}

function buildFakeFirestoreWithUsers(activeUsers: FakeUserDoc[]) {
  const broadcastsAdded: Record<string, unknown>[] = [];
  let lastQueryFilter: { field: string; op: string; value: unknown } | null =
    null;

  const firestore = {
    collection(name: string) {
      if (name === "users") {
        return {
          where(field: string, op: string, value: unknown) {
            lastQueryFilter = { field, op, value };
            return {
              async get() {
                // Adaptamos cada FakeUserDoc a un QueryDocumentSnapshot mínimo
                // (con `.data()` como método) para que coincida con la API real
                // de Firestore que consume `executeBroadcast`.
                return {
                  forEach: (
                    cb: (doc: { data: () => Record<string, unknown> }) => void,
                  ) =>
                    activeUsers.forEach((u) => cb({ data: () => u.data })),
                };
              },
            };
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
  };

  return {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    firestore: firestore as any,
    broadcastsAdded,
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
});
