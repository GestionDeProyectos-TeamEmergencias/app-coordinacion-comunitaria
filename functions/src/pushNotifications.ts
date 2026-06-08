import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export interface Referente {
  uid: string;
  fcmTokens: string[];
  location?: {
    latitude: number;
    longitude: number;
  };
}

export interface PushPayload {
  title: string;
  body: string;
  data: {
    incidentId: string;
    priority: string;
    latitude: string;
    longitude: string;
  };
}

/**
 * Filtra los referentes usando la fórmula de Haversine para calcular la distancia.
 */
export function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Radio de la Tierra en metros
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distancia en metros
}

/**
 * Consulta a Firestore los usuarios con rol 'referente_barrial' y filtra los que
 * estén dentro del radio especificado (en metros) respecto a las coordenadas del incidente.
 */
export async function findNearbyReferentes(
  firestore: admin.firestore.Firestore,
  latitude: number,
  longitude: number,
  radiusMeters: number
): Promise<Referente[]> {
  try {
    // Al no tener extensiones geoespaciales complejas todavía, nos traemos todos los referentes
    // (en producción con gran escala se usarían geohashes).
    const snapshot = await firestore
      .collection("users")
      .where("role", "==", "referente_barrial")
      .get();

    const referentes: Referente[] = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      // Validamos que tenga tokens para recibir notificaciones
      if (!data.fcmTokens || !Array.isArray(data.fcmTokens) || data.fcmTokens.length === 0) {
        return;
      }

      if (data.location && typeof data.location.latitude === "number" && typeof data.location.longitude === "number") {
        const distance = calculateDistance(
          latitude,
          longitude,
          data.location.latitude,
          data.location.longitude
        );

        if (distance <= radiusMeters) {
          referentes.push({
            uid: doc.id,
            fcmTokens: data.fcmTokens,
            location: data.location,
          });
        }
      }
    });

    return referentes;
  } catch (error) {
    logger.error("Error finding nearby referentes", { error });
    return [];
  }
}

/**
 * Envía las notificaciones push usando Firebase Cloud Messaging (Multicast).
 */
export async function sendIncidentAlertToReferentes(
  messaging: admin.messaging.Messaging,
  incidentId: string,
  priority: string,
  latitude: number,
  longitude: number,
  referentes: Referente[]
): Promise<admin.messaging.BatchResponse | null> {
  // Extraemos todos los tokens planos en un solo array
  const allTokens = referentes.flatMap((ref) => ref.fcmTokens);

  if (allTokens.length === 0) {
    logger.info("No FCM tokens found for nearby referentes", { incidentId });
    return null;
  }

  // Preparamos el payload
  const payload: admin.messaging.MulticastMessage = {
    tokens: allTokens,
    notification: {
      title: "Nuevo Incidente Reportado",
      body: `Incidente prioridad: ${priority.toUpperCase()}`,
    },
    data: {
      incidentId: incidentId,
      priority: priority,
      latitude: latitude.toString(),
      longitude: longitude.toString(),
      click_action: "FLUTTER_NOTIFICATION_CLICK", // Clave para la app móvil
    },
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: "default",
        },
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(payload);
    logger.info("Successfully sent push notifications", {
      incidentId,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
    return response;
  } catch (error) {
    logger.error("Failed to send push notifications", { incidentId, error });
    return null;
  }
}
