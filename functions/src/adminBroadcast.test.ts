import { broadcastNotification } from "./adminBroadcast";
import * as admin from "firebase-admin";

// Mocks
const mockFirestore = {
  collection: jest.fn(),
} as unknown as admin.firestore.Firestore;

const mockMessaging = {
  sendEachForMulticast: jest.fn(),
} as unknown as admin.messaging.Messaging;

// Override firebase-admin para que devuelva los mocks
jest.mock("firebase-admin", () => ({
  firestore: jest.fn(() => mockFirestore),
  messaging: jest.fn(() => mockMessaging),
}));

describe("Admin Broadcast Notifications (T-NLP-09)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const runBroadcast = async (data: any, auth: any) => {
    // Wrap firebase-functions onCall handler for testing
    // onCall returns a function that takes (request: CallableRequest)
    return (broadcastNotification as any).run({
      data,
      auth,
    });
  };

  it("throws unauthenticated if no auth is provided", async () => {
    await expect(runBroadcast({ title: "Hola", body: "Mundo" }, null)).rejects.toThrow(
      "El usuario debe estar autenticado"
    );
  });

  it("throws permission-denied if user is not admin (no claims, no role)", async () => {
    const mockUserDoc = { exists: true, data: () => ({ role: "vecino_informante" }) };
    (mockFirestore.collection as jest.Mock).mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(mockUserDoc),
      }),
    });

    await expect(
      runBroadcast({ title: "Test", body: "Test" }, { uid: "user1", token: {} })
    ).rejects.toThrow("Solo los administradores pueden enviar notificaciones masivas.");
  });

  it("throws invalid-argument if title or body is missing", async () => {
    await expect(
      runBroadcast({ title: "", body: "Mundo" }, { uid: "admin1", token: { admin: true } })
    ).rejects.toThrow("El título y cuerpo de la notificación son obligatorios.");
  });

  it("sends global broadcast successfully (admin claim)", async () => {
    const mockUsers = [
      { data: () => ({ fcmTokens: ["token1"], coverageLat: 0, coverageLng: 0 }) },
      { data: () => ({ fcmTokens: ["token2"] }) }, // No location, still receives global
      { data: () => ({ fcmTokens: [] }) }, // No tokens
    ];

    (mockFirestore.collection as jest.Mock).mockReturnValue({
      get: jest.fn().mockResolvedValue({
        forEach: (cb: any) => mockUsers.forEach(cb),
      }),
    });

    (mockMessaging.sendEachForMulticast as jest.Mock).mockResolvedValue({
      successCount: 2,
      failureCount: 0,
    });

    const result = await runBroadcast(
      { title: "Alerta Global", body: "Cuidado" },
      { uid: "admin_super", token: { admin: true } }
    );

    expect(result.successCount).toBe(2);
    expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    
    const payload = (mockMessaging.sendEachForMulticast as jest.Mock).mock.calls[0][0];
    expect(payload.tokens).toEqual(["token1", "token2"]);
    expect(payload.notification.title).toBe("Alerta Global");
  });

  it("sends zonal broadcast successfully, filtering out of range users", async () => {
    const mockUsers = [
      // Close to Obelisco (~15m away)
      { data: () => ({ fcmTokens: ["token_close"], coverageLat: -34.6038, coverageLng: -58.3817 }) },
      // Casa Rosada (~1140m away) - Out of 500m radius
      { data: () => ({ fcmTokens: ["token_far"], coverageLat: -34.6081, coverageLng: -58.3703 }) },
      // No location - Should not receive zonal broadcast
      { data: () => ({ fcmTokens: ["token_no_loc"] }) },
    ];

    (mockFirestore.collection as jest.Mock).mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({ exists: true, data: () => ({ role: "administrador_vecinal" }) }),
      }),
      get: jest.fn().mockResolvedValue({
        forEach: (cb: any) => mockUsers.forEach(cb),
      }),
    });

    (mockMessaging.sendEachForMulticast as jest.Mock).mockResolvedValue({
      successCount: 1,
      failureCount: 0,
    });

    const result = await runBroadcast(
      { 
        title: "Alerta Zonal", 
        body: "Calle cortada",
        area: { latitude: -34.6037, longitude: -58.3816, radiusMeters: 500 } // Obelisco
      },
      // Admin auth using Firestore role fallback instead of claims
      { uid: "admin_local", token: {} } 
    );

    expect(result.successCount).toBe(1);
    expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    
    const payload = (mockMessaging.sendEachForMulticast as jest.Mock).mock.calls[0][0];
    // Only the close token should be present
    expect(payload.tokens).toEqual(["token_close"]);
  });
});
