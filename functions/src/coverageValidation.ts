import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// -- T-AUTH-06: Validacion geografica de cobertura --
// Modulo puro con la logica de validacion de cobertura geografica.
// El centro y radio por defecto corresponden a la ciudad de Junin, Buenos Aires.

export interface PolygonVertex {
  lat: number;
  lng: number;
}

export interface CoverageConfig {
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
  // Poligono de cobertura opcional (RF-REP-01/RF-ADM-01: "poligono o radio").
  // Si esta presente con >= 3 vertices, la validacion usa point-in-polygon en
  // lugar del circulo. Retrocompatibilidad total: ausente => modo circulo. [F-07]
  polygonPoints?: PolygonVertex[];
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
      const polygonPoints = parsePolygon(data.polygonPoints);
      return {
        centerLat: data.centerLat,
        centerLng: data.centerLng,
        radiusMeters: data.radiusMeters,
        ...(polygonPoints ? { polygonPoints } : {}),
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
 * Parsea y valida `polygonPoints` de Firestore. Ignora entradas invalidas y
 * devuelve `undefined` si quedan menos de 3 vertices validos (cae a circulo,
 * retrocompatibilidad). [F-07]
 */
export function parsePolygon(raw: unknown): PolygonVertex[] | undefined {
  if (!Array.isArray(raw)) return undefined;
  const points: PolygonVertex[] = [];
  for (const item of raw) {
    if (item && typeof item === "object") {
      const obj = item as { lat?: unknown; lng?: unknown };
      if (
        typeof obj.lat === "number" &&
        typeof obj.lng === "number" &&
        Number.isFinite(obj.lat) &&
        Number.isFinite(obj.lng)
      ) {
        points.push({ lat: obj.lat, lng: obj.lng });
      }
    }
  }
  return points.length >= 3 ? points : undefined;
}

/**
 * Point-in-polygon por ray casting (paridad de cruces de una semirrecta
 * horizontal). Trata el borde (lados y vertices) como **dentro**, consistente
 * con el criterio inclusivo (<=) del circulo. Asume el plano lat/lng como
 * euclideo, valido para areas barriales. Espejo de la logica del cliente. [F-07]
 */
export function pointInPolygon(
  lat: number,
  lng: number,
  polygon: PolygonVertex[]
): boolean {
  const x = lng;
  const y = lat;
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lng;
    const yi = polygon[i].lat;
    const xj = polygon[j].lng;
    const yj = polygon[j].lat;

    // Punto exactamente sobre un vertice => dentro.
    if (yi === y && xi === x) return true;
    // Punto sobre el lado (i, j) => dentro.
    if (isOnSegment(x, y, xj, yj, xi, yi)) return true;

    const intersects =
      yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    if (intersects) inside = !inside;
  }
  return inside;
}

/** `true` si (px,py) esta sobre el segmento (a -> b): colineal y en el bbox. */
function isOnSegment(
  px: number,
  py: number,
  ax: number,
  ay: number,
  bx: number,
  by: number
): boolean {
  const eps = 1e-12;
  const cross = (px - ax) * (by - ay) - (py - ay) * (bx - ax);
  if (Math.abs(cross) > eps) return false;
  const withinX = px >= Math.min(ax, bx) - eps && px <= Math.max(ax, bx) + eps;
  const withinY = py >= Math.min(ay, by) - eps && py <= Math.max(ay, by) + eps;
  return withinX && withinY;
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
 * Determina si un punto (lat, lng) esta dentro del area de cobertura. Si la
 * config tiene un poligono valido (>= 3 vertices), usa point-in-polygon; si no,
 * usa el circulo (centro + radio) con comparacion inclusiva <=. [F-07]
 */
export function isWithinCoverage(
  lat: number,
  lng: number,
  config: CoverageConfig
): boolean {
  if (config.polygonPoints && config.polygonPoints.length >= 3) {
    return pointInPolygon(lat, lng, config.polygonPoints);
  }
  const distance = calculateHaversineDistance(
    lat,
    lng,
    config.centerLat,
    config.centerLng
  );
  return distance <= config.radiusMeters;
}
