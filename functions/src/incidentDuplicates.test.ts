import { detectDuplicateIncidents } from "./incidentDuplicates";

type MockDoc = {
  id: string;
  data: () => Record<string, unknown>;
};

type MockSnapshot = {
  forEach: (callback: (doc: MockDoc) => void) => void;
};

type MockCollection = {
  where: jest.Mock;
  get: jest.Mock<Promise<MockSnapshot>, []>;
};

type MockFirestore = {
  collection: jest.Mock;
};

function createFirestoreWithDocs(docs: MockDoc[]): MockFirestore {
  const snapshot: MockSnapshot = {
    forEach: (callback) => {
      docs.forEach(callback);
    },
  };

  const collectionRef = {
    where: jest.fn(),
    get: jest.fn(async () => snapshot),
  } as MockCollection;

  collectionRef.where.mockReturnValue(collectionRef);

  return {
    collection: jest.fn(() => collectionRef),
  } as MockFirestore;
}

describe("detectDuplicateIncidents", () => {
  test("marca como duplicado si hay incidente cercano dentro del radio", async () => {
    const firestore = createFirestoreWithDocs([
      {
        id: "incident-near",
        data: () => ({
          location: { latitude: -34.60375, longitude: -58.38155 },
          timestamp: new Date("2026-05-25T12:05:00Z"),
        }),
      },
      {
        id: "incident-far",
        data: () => ({
          location: { latitude: -34.61, longitude: -58.39 },
          timestamp: new Date("2026-05-25T12:10:00Z"),
        }),
      },
    ]);

    const result = await detectDuplicateIncidents(
      firestore as never,
      {
        incidentId: "incident-main",
        latitude: -34.6037,
        longitude: -58.3816,
        timestamp: new Date("2026-05-25T12:00:00Z"),
        radiusMeters: 100,
        windowHours: 24,
      }
    );

    expect(result.isDuplicate).toBe(true);
    expect(result.nearbyIds).toEqual(["incident-near"]);
    expect(result.nearbyCount).toBe(1);
  });

  test("ignora el mismo incidente por id", async () => {
    const firestore = createFirestoreWithDocs([
      {
        id: "incident-main",
        data: () => ({
          location: { latitude: -34.6037, longitude: -58.3816 },
        }),
      },
    ]);

    const result = await detectDuplicateIncidents(
      firestore as never,
      {
        incidentId: "incident-main",
        latitude: -34.6037,
        longitude: -58.3816,
        timestamp: new Date("2026-05-25T12:00:00Z"),
        radiusMeters: 100,
        windowHours: 24,
      }
    );

    expect(result.isDuplicate).toBe(false);
    expect(result.nearbyIds).toEqual([]);
  });
});
