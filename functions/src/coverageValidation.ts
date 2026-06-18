import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// -- T-AUTH-06: Validacion geografica de cobertura --
// Modulo puro con la logica de validacion de cobertura geografica.
// El centro y radio por defecto corresponden a la ciudad de Junin, Buenos Aires.

export interface CoverageConfig {
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
}

// Centro por defecto: Junin, Buenos Aires, Argentina
export const DEFAULT_COVERAGE_CONFIG: CoverageConfig = {
  centerLat: -34.5895,
  centerLng: -60.9442,
  radiusMeters: 5000,
};

/**
 * Carga la configuracion de cobertura desde Firestore (doc config/coverage).
 * Si el documento no existe o tiene datos invalidos, retorna los valores por defecto.
 */
export async function loadCoverageConfig(
  firestore: admin.firestore.Firestore
): Promise<CoverageConfig> {
  try {
    const docRef = firestore.collection("config").doc("coverage");
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      logger.info("Coverage config doc not found, using defaults");
      return { ...DEFAULT_COVERAGE_CONFIG };
    }

    const data = snapshot.data();

    if (
      data &&
      typeof data.centerLat === "number" &&
      typeof data.centerLng === "number" &&
      typeof data.radiusMeters === "number" &&
      Number.isFinite(data.centerLat) &&
      Number.isFinite(data.centerLng) &&
      Number.isFinite(data.radiusMeters) &&
      data.radiusMeters > 0
    ) {
      return {
        centerLat: data.centerLat,
        centerLng: data.centerLng,
        radiusMeters: data.radiusMeters,
      };
    }

    logger.warn("Coverage config doc has invalid data, using defaults", { data });
    return { ...DEFAULT_COVERAGE_CONFIG };
  } catch (error) {
    logger.error("Failed to load coverage config, using defaults", { error });
    return { ...DEFAULT_COVERAGE_CONFIG };
  }
}

/**
 * Calcula la distancia entre dos puntos geograficos usando la formula de Haversine.
 * Retorna la distancia en metros.
 */
export function calculateHaversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Radio de la Tierra en metros
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Determina si un punto (lat, lng) esta dentro del area de cobertura definida
 * por la configuracion (centro + radio). Usa comparacion estricta <= (inclusiva).
 */
export function isWithinCoverage(
  lat: number,
  lng: number,
  config: CoverageConfig
): boolean {
  const distance = calculateHaversineDistance(
    lat,
    lng,
    config.centerLat,
    config.centerLng
  );
  return distance <= config.radiusMeters;
}
