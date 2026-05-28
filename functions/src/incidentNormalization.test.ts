import { normalizeIncidentEvent } from "./incidentNormalization";

describe("normalizeIncidentEvent", () => {
  test("normaliza un evento valido y mapea sourceType/category", () => {
    const result = normalizeIncidentEvent("incident-1", {
      userId: "user-123",
      timestamp: new Date("2026-05-25T12:00:00Z"),
      sourceType: "quick",
      category: "vial",
      location: {
        latitude: -34.6037,
        longitude: -58.3816,
        accuracy: 5,
      },
      description: "Bache en esquina",
      photoUrl: "https://example.com/photo.jpg",
    });

    expect(result.normalizedEvent.eventId).toBe("incident-1");
    expect(result.normalizedEvent.sourceType).toBe("quick_button");
    expect(result.normalizedEvent.category).toBe("infraestructura_vial");
    expect(result.normalizedEvent.location.latitude).toBe(-34.6037);
    expect(result.warnings).toHaveLength(0);
  });

  test("agrega warning cuando sourceType no es reconocido", () => {
    const result = normalizeIncidentEvent("incident-2", {
      userId: "user-123",
      timestamp: "2026-05-25T12:00:00Z",
      sourceType: "unknown",
      location: {
        latitude: -34.6037,
        longitude: -58.3816,
      },
    });

    expect(result.normalizedEvent.sourceType).toBe("quick_button");
    expect(result.warnings).toContain("sourceType defaulted to quick_button");
  });

  test("lanza error si falta userId", () => {
    expect(() =>
      normalizeIncidentEvent("incident-3", {
        timestamp: "2026-05-25T12:00:00Z",
        sourceType: "form",
        location: {
          latitude: -34.6037,
          longitude: -58.3816,
        },
      })
    ).toThrow("Missing userId");
  });
});
