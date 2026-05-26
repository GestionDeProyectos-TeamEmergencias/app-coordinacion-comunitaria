import type { firestore as FirestoreAdmin } from "firebase-admin";

export interface DuplicateCheckInput {
  incidentId: string;
  latitude: number;
  longitude: number;
  timestamp: Date;
  radiusMeters: number;
  windowHours: number;
}

export interface DuplicateCheckResult {
  isDuplicate: boolean;
  nearbyCount: number;
  nearbyIds: string[];
  radiusMeters: number;
  windowHours: number;
}

export async function detectDuplicateIncidents(
  firestore: FirestoreAdmin.Firestore,
  input: DuplicateCheckInput
): Promise<DuplicateCheckResult> {
  const windowStart = new Date(input.timestamp.getTime());
  windowStart.setHours(windowStart.getHours() - input.windowHours);

  const windowEnd = new Date(input.timestamp.getTime());
  windowEnd.setHours(windowEnd.getHours() + input.windowHours);

  const snapshot = await firestore
    .collection("incidents")
    .where("timestamp", ">=", windowStart)
    .where("timestamp", "<=", windowEnd)
    .get();

  const nearbyIds: string[] = [];

  snapshot.forEach((doc) => {
    if (doc.id === input.incidentId) {
      return;
    }

    const data = doc.data();
    const latitude = toNumber(
      data.latitude ?? data.location?.latitude ?? data.normalizedEvent?.location?.latitude
    );
    const longitude = toNumber(
      data.longitude ?? data.location?.longitude ?? data.normalizedEvent?.location?.longitude
    );

    if (latitude === null || longitude === null) {
      return;
    }

    const distance = haversineDistanceMeters(
      input.latitude,
      input.longitude,
      latitude,
      longitude
    );

    if (distance <= input.radiusMeters) {
      nearbyIds.push(doc.id);
    }
  });

  return {
    isDuplicate: nearbyIds.length > 0,
    nearbyCount: nearbyIds.length,
    nearbyIds,
    radiusMeters: input.radiusMeters,
    windowHours: input.windowHours,
  };
}

function toNumber(value: unknown): number | null {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }
  return null;
}

function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const earthRadiusMeters = 6371000;

  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return 2 * earthRadiusMeters * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
