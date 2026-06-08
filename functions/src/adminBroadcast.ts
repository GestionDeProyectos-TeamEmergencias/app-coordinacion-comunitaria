import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { calculateDistance } from "./pushNotifications";

export interface BroadcastPayload {
  title: string;
  body: string;
  area?: {
    latitude: number;
    longitude: number;
    radiusMeters: number;
  };
}

export interface BroadcastResponse {
  successCount: number;
  failureCount: number;
  message: string;
}

/**
 * Cloud Function (Callable) para que el administrador envíe notificaciones masivas.
 * Cumple con [T-NLP-09] / RF-ADM-04.
 */
export const broadcastNotification = onCall<BroadcastPayload>(async (request: CallableRequest<BroadcastPayload>): Promise<BroadcastResponse> => {
  // 1. Validación de autenticación
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado para enviar notificaciones.");
  }

  const firestore = admin.firestore();
  const messaging = admin.messaging();
  const { title, body, area } = request.data;

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "El título y cuerpo de la notificación son obligatorios.");
  }

  // 2. Validación de roles (Seguridad)
  // Intentamos validar vía Custom Claims (recomendado para panel admin)
  let isAdmin = request.auth.token.admin === true;

  // Si no tiene claim, verificamos en Firestore (Fallback para entorno en desarrollo / QA)
  if (!isAdmin) {
    const userDoc = await firestore.collection("users").doc(request.auth.uid).get();
    if (userDoc.exists && userDoc.data()?.role === "administrador_vecinal") {
      isAdmin = true;
    }
  }

  if (!isAdmin) {
    throw new HttpsError("permission-denied", "Solo los administradores pueden enviar notificaciones masivas.");
  }

  try {
    // 3. Obtención de todos los usuarios con tokens
    // NOTA: Para producción real a gran escala, se debe implementar paginación / tópicos.
    const snapshot = await firestore.collection("users").get();
    
    const allTokens = new Set<string>();

    snapshot.forEach((doc) => {
      const data = doc.data();
      
      // Debe tener tokens válidos
      if (!data.fcmTokens || !Array.isArray(data.fcmTokens) || data.fcmTokens.length === 0) {
        return;
      }

      // Si hay filtro espacial, verificamos distancia
      if (area) {
        // Si el usuario no tiene ubicación, no le enviamos (por definición de aviso zonal)
        if (!data.location || typeof data.location.latitude !== "number" || typeof data.location.longitude !== "number") {
          return;
        }

        const distance = calculateDistance(
          area.latitude,
          area.longitude,
          data.location.latitude,
          data.location.longitude
        );

        if (distance > area.radiusMeters) {
          return; // Fuera del radio
        }
      }

      // Agregamos todos los tokens del usuario válido al Set (para evitar duplicados)
      data.fcmTokens.forEach((token: string) => allTokens.add(token));
    });

    const tokensArray = Array.from(allTokens);

    if (tokensArray.length === 0) {
      logger.info("No tokens matched the broadcast criteria", { area });
      return {
        successCount: 0,
        failureCount: 0,
        message: "No se encontraron usuarios válidos en la zona o sistema.",
      };
    }

    // 4. Envío Multicast en lotes (máximo 500 por lote según límites de FCM)
    const MAX_TOKENS_PER_BATCH = 500;
    let totalSuccess = 0;
    let totalFailure = 0;

    for (let i = 0; i < tokensArray.length; i += MAX_TOKENS_PER_BATCH) {
      const batchTokens = tokensArray.slice(i, i + MAX_TOKENS_PER_BATCH);
      const payload: admin.messaging.MulticastMessage = {
        tokens: batchTokens,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "admin_broadcast",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
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

      const response = await messaging.sendEachForMulticast(payload);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
    }

    logger.info("Broadcast notification sent", {
      adminUid: request.auth.uid,
      title,
      successCount: totalSuccess,
      failureCount: totalFailure,
    });

    return {
      successCount: totalSuccess,
      failureCount: totalFailure,
      message: `Notificación enviada a ${totalSuccess} dispositivos.`,
    };

  } catch (error) {
    logger.error("Error during broadcast notification", { error });
    throw new HttpsError("internal", "Ocurrió un error interno al despachar las notificaciones.");
  }
});
