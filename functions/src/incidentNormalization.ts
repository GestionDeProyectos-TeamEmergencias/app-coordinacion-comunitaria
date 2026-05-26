import type { firestore as FirestoreAdmin } from "firebase-admin";

export type SourceTypeNormalized = "quick_button" | "voice" | "form";
export type CategoryNormalized =
  | "pavimentacion"
  | "alumbrado_electrico"
  | "saneamiento"
  | "espacios_verdes"
  | "infraestructura_vial"
  | "otro"
  | null;

export interface NormalizedIncidentEvent {
  eventId: string;
  schemaVersion: "1.0.0";
  sourceType: SourceTypeNormalized;
  timestamp: string;
  userId: string;
  location: {
    latitude: number;
    longitude: number;
    accuracy: number | null;
  };
  description: string | null;
  category: CategoryNormalized;
  photoUrl: string | null;
}

export interface NormalizationResult {
  normalizedEvent: NormalizedIncidentEvent;
  warnings: string[];
}

const SOURCE_TYPE_MAP: Record<string, SourceTypeNormalized> = {
  quick: "quick_button",
  quick_button: "quick_button",
  voice: "voice",
  form: "form",
};

const CATEGORY_MAP: Record<string, Exclude<CategoryNormalized, null>> = {
  electrico: "alumbrado_electrico",
  alumbrado_electrico: "alumbrado_electrico",
  vial: "infraestructura_vial",
  infraestructura_vial: "infraestructura_vial",
  pavimentacion: "pavimentacion",
  sanitario: "saneamiento",
  saneamiento: "saneamiento",
  espacios_verdes: "espacios_verdes",
  seguridad: "otro",
  otro: "otro",
};

export function normalizeIncidentEvent(
  incidentId: string,
  data: FirestoreAdmin.DocumentData
): NormalizationResult {
  const warnings: string[] = [];

  const userId = typeof data.userId === "string" ? data.userId : "";
  if (!userId) {
    throw new Error("Missing userId");
  }

  const timestamp = parseTimestamp(data.timestamp);
  if (!timestamp) {
    throw new Error("Missing or invalid timestamp");
  }

  const location = parseLocation(data);

  const sourceTypeRaw = typeof data.sourceType === "string" ? data.sourceType : "";
  const sourceType = SOURCE_TYPE_MAP[sourceTypeRaw] ?? "quick_button";
  if (!SOURCE_TYPE_MAP[sourceTypeRaw]) {
    warnings.push("sourceType defaulted to quick_button");
  }

  const description = typeof data.description === "string" ? data.description : null;
  const photoUrl = typeof data.photoUrl === "string" ? data.photoUrl : null;

  let category: CategoryNormalized = null;
  if (typeof data.category === "string") {
    category = CATEGORY_MAP[data.category] ?? null;
    if (!CATEGORY_MAP[data.category]) {
      warnings.push("category not recognized, set to null");
    }
  }

  return {
    normalizedEvent: {
      eventId: incidentId,
      schemaVersion: "1.0.0",
      sourceType,
      timestamp: timestamp.toISOString(),
      userId,
      location,
      description,
      category,
      photoUrl,
    },
    warnings,
  };
}

function parseTimestamp(value: unknown): Date | null {
  if (!value) {
    return null;
  }

  if (typeof value === "object" && value !== null) {
    const maybeTimestamp = value as { toDate?: () => Date };
    if (typeof maybeTimestamp.toDate === "function") {
      return maybeTimestamp.toDate();
    }
  }

  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  if (typeof value === "number") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  return null;
}

function parseLocation(data: FirestoreAdmin.DocumentData): NormalizedIncidentEvent["location"] {
  const rawLocation = typeof data.location === "object" && data.location !== null
    ? (data.location as { latitude?: unknown; longitude?: unknown; accuracy?: unknown })
    : null;

  const latitudeValue = rawLocation?.latitude ?? data.latitude;
  const longitudeValue = rawLocation?.longitude ?? data.longitude;
  const accuracyValue = rawLocation?.accuracy ?? data.accuracy ?? null;

  const latitude = toNumber(latitudeValue, "latitude");
  const longitude = toNumber(longitudeValue, "longitude");
  const accuracy = accuracyValue === null || accuracyValue === undefined
    ? null
    : toNumber(accuracyValue, "accuracy");

  if (latitude < -90 || latitude > 90) {
    throw new Error("Invalid latitude");
  }

  if (longitude < -180 || longitude > 180) {
    throw new Error("Invalid longitude");
  }

  return {
    latitude,
    longitude,
    accuracy,
  };
}

function toNumber(value: unknown, fieldName: string): number {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }
  throw new Error(`Invalid ${fieldName}`);
}
