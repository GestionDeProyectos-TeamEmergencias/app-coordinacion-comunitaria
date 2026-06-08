import { calculateDistance, findNearbyReferentes, sendIncidentAlertToReferentes } from "./pushNotifications";
import * as admin from "firebase-admin";

// Mocks para Firestore
const mockFirestore = {
  collection: jest.fn(),
} as unknown as admin.firestore.Firestore;

// Mocks para Messaging
const mockMessaging = {
  sendEachForMulticast: jest.fn(),
} as unknown as admin.messaging.Messaging;

describe("Push Notifications (T-NLP-07)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("calculateDistance", () => {
    it("calculates haversine distance correctly", () => {
      // Obelisco de Buenos Aires
      const lat1 = -34.6037;
      const lon1 = -58.3816;
      // Casa Rosada
      const lat2 = -34.6081;
      const lon2 = -58.3703;
      
      const distance = calculateDistance(lat1, lon1, lat2, lon2);
      // La distancia real es aprox 1140 metros
      expect(distance).toBeGreaterThan(1100);
      expect(distance).toBeLessThan(1200);
    });
  });

  describe("findNearbyReferentes", () => {
    it("filters referentes by radius and extracts tokens", async () => {
      // Incident at Obelisco
      const incidentLat = -34.6037;
      const incidentLon = -58.3816;

      const mockDocs = [
        {
          id: "user1",
          data: () => ({
            role: "referente_barrial",
            fcmTokens: ["token_1"],
            location: { latitude: -34.6081, longitude: -58.3703 }, // ~1140m away
          }),
        },
        {
          id: "user2",
          data: () => ({
            role: "referente_barrial",
            fcmTokens: ["token_2", "token_3"],
            location: { latitude: -34.6038, longitude: -58.3817 }, // ~15m away
          }),
        },
        {
          id: "user3",
          data: () => ({
            role: "referente_barrial",
            fcmTokens: ["token_4"],
            location: { latitude: -38.0000, longitude: -57.5500 }, // Mar del Plata, very far
          }),
        },
        {
          id: "user_no_tokens",
          data: () => ({
            role: "referente_barrial",
            fcmTokens: [],
            location: { latitude: -34.6038, longitude: -58.3817 }, // Close, but no tokens
          }),
        },
      ];

      const mockQueryGet = jest.fn().mockResolvedValue(mockDocs);
      const mockWhere = jest.fn().mockReturnValue({ get: mockQueryGet });
      (mockFirestore.collection as jest.Mock).mockReturnValue({ where: mockWhere });

      // Test with a 2km radius
      const referentes = await findNearbyReferentes(mockFirestore, incidentLat, incidentLon, 2000);

      expect(mockFirestore.collection).toHaveBeenCalledWith("users");
      expect(mockWhere).toHaveBeenCalledWith("role", "==", "referente_barrial");
      
      expect(referentes).toHaveLength(2); // user1 and user2
      expect(referentes[0].uid).toBe("user1");
      expect(referentes[1].uid).toBe("user2");
      expect(referentes[1].fcmTokens).toEqual(["token_2", "token_3"]);

      // Test with a 50m radius
      const referentesTight = await findNearbyReferentes(mockFirestore, incidentLat, incidentLon, 50);
      expect(referentesTight).toHaveLength(1); // Only user2
      expect(referentesTight[0].uid).toBe("user2");
    });
  });

  describe("sendIncidentAlertToReferentes", () => {
    it("sends multicast message correctly", async () => {
      const mockReferentes = [
        { uid: "user1", fcmTokens: ["tok1"], location: { latitude: 0, longitude: 0 } },
        { uid: "user2", fcmTokens: ["tok2", "tok3"], location: { latitude: 0, longitude: 0 } },
      ];

      (mockMessaging.sendEachForMulticast as jest.Mock).mockResolvedValue({
        successCount: 3,
        failureCount: 0,
        responses: [],
      });

      const response = await sendIncidentAlertToReferentes(
        mockMessaging,
        "INC-123",
        "alta",
        -34.6,
        -58.3,
        mockReferentes
      );

      expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
      
      const payload = (mockMessaging.sendEachForMulticast as jest.Mock).mock.calls[0][0];
      expect(payload.tokens).toEqual(["tok1", "tok2", "tok3"]);
      expect(payload.data.incidentId).toBe("INC-123");
      expect(payload.data.priority).toBe("alta");
      expect(payload.data.latitude).toBe("-34.6");
      expect(payload.data.longitude).toBe("-58.3");
      
      expect(response?.successCount).toBe(3);
    });

    it("returns null if no tokens are found", async () => {
      const response = await sendIncidentAlertToReferentes(
        mockMessaging,
        "INC-123",
        "alta",
        -34.6,
        -58.3,
        [] // empty
      );

      expect(mockMessaging.sendEachForMulticast).not.toHaveBeenCalled();
      expect(response).toBeNull();
    });
  });
});
