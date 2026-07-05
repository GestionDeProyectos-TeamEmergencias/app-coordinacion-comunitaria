import {
  CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";
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
  invalidTokens: number;
  message: string;
}

// Constantes operativas exportadas para tests y futura calibración.
export const MAX_TOKENS_PER_BATCH = 500;
export const MAX_BROADCAST_RADIUS_METERS = 100_000;

// Path en Firestore del log de auditoría de broadcasts.
const BROADCASTS_AUDIT_COLLECTION = "broadcasts";

// ── Helper: identifica tokens muertos para limpieza posterior ───────────────

function isUnregisteredTokenError(code: string | undefined): boolean {
  return (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  );
}

// ── Lógica pura testeable [T-NLP-09 review] ─────────────────────────────────
// Extraída del onCall para que los tests no dependan de la API privada
// `(... as any).run(...)` de firebase-functions.

interface ExecuteBroadcastArgs {
  firestore: admin.firestore.Firestore;
  messaging: admin.messaging.Messaging;
  payload: BroadcastPayload;
  caller: { uid: string };
}

export async function executeBroadcast(
  args: ExecuteBroadcastArgs,
): Promise<BroadcastResponse> {
  const { firestore, messaging, payload, caller } = args;
  const { title, body, area } = payload;

  // Filtro de usuarios: solo activos (consistente con T-AUTH-04 / T-AUTH-07).
  // Un usuario bloqueado, pending o rejected no debe recibir broadcasts.
  const snapshot = await firestore
    .collection("users")
    .where("status", "==", "active")
    .get();

  // Mapping token → userId para poder limpiar tokens muertos después del envío.
  // Antes era un Set<string> que perdía esa información.
  const tokenToUser = new Map<string, string>();

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (
      !data.fcmTokens ||
      !Array.isArray(data.fcmTokens) ||
      data.fcmTokens.length === 0
    ) {
      return;
    }

    if (area) {
      // Posición de referencia del usuario para el filtro zonal:
      //   - `homeLat/Lng`: ubicación de interés del VECINO (opt-in en perfil).
      //   - `coverageLat/Lng`: zona de cobertura del REFERENTE BARRIAL (D-01).
      // Tomamos la primera disponible. Si el user no tiene ninguna, se lo
      // skippea del broadcast zonal (sigue recibiendo los globales).
      const lat =
        typeof data.homeLat === "number"
          ? data.homeLat
          : typeof data.coverageLat === "number"
            ? data.coverageLat
            : undefined;
      const lng =
        typeof data.homeLng === "number"
          ? data.homeLng
          : typeof data.coverageLng === "number"
            ? data.coverageLng
            : undefined;
      if (lat === undefined || lng === undefined) {
        return;
      }
      const distance = calculateDistance(
        area.latitude,
        area.longitude,
        lat,
        lng,
      );
      if (distance > area.radiusMeters) {
        return;
      }
    }

    data.fcmTokens.forEach((token: string) => {
      tokenToUser.set(token, doc.id);
    });
  });

  const tokensArray = Array.from(tokenToUser.keys());

  if (tokensArray.length === 0) {
    logger.info("No tokens matched the broadcast criteria", { area });
    await persistBroadcastAudit(firestore, {
      title,
      body,
      area,
      sentBy: caller.uid,
      successCount: 0,
      failureCount: 0,
      invalidTokens: 0,
    });
    return {
      successCount: 0,
      failureCount: 0,
      invalidTokens: 0,
      message: "No se encontraron usuarios válidos en la zona o sistema.",
    };
  }

  let totalSuccess = 0;
  let totalFailure = 0;
  // Tokens dados de baja detectados durante el envío — se reportan al cliente
  // y quedan registrados en el audit para que un proceso futuro los limpie.
  const invalidTokens: string[] = [];

  for (let i = 0; i < tokensArray.length; i += MAX_TOKENS_PER_BATCH) {
    const batchTokens = tokensArray.slice(i, i + MAX_TOKENS_PER_BATCH);
    const message: admin.messaging.MulticastMessage = {
      tokens: batchTokens,
      notification: { title, body },
      data: { type: "admin_broadcast" },
      android: { priority: "high" },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            sound: "default",
          },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    totalSuccess += response.successCount;
    totalFailure += response.failureCount;

    // Detectar tokens muertos.
    response.responses.forEach((r, idx) => {
      if (!r.success && isUnregisteredTokenError(r.error?.code)) {
        invalidTokens.push(batchTokens[idx]);
      }
    });
  }

  logger.info("Broadcast notification sent", {
    adminUid: caller.uid,
    title,
    successCount: totalSuccess,
    failureCount: totalFailure,
    invalidTokens: invalidTokens.length,
  });

  // Limpieza de tokens muertos: `arrayRemove` en el user al que pertenecía
  // cada token inválido. Evita que los arrays `fcmTokens` acumulen basura.
  // Es best-effort: si la limpieza falla, no afecta el resultado del envío.
  if (invalidTokens.length > 0) {
    await cleanupInvalidTokens(firestore, invalidTokens, tokenToUser);
  }

  await persistBroadcastAudit(firestore, {
    title,
    body,
    area,
    sentBy: caller.uid,
    successCount: totalSuccess,
    failureCount: totalFailure,
    invalidTokens: invalidTokens.length,
    invalidTokenSamples: invalidTokens.slice(0, 50),
  });

  return {
    successCount: totalSuccess,
    failureCount: totalFailure,
    invalidTokens: invalidTokens.length,
    message: `Notificación enviada a ${totalSuccess} dispositivos.`,
  };
}

interface BroadcastAuditEntry {
  title: string;
  body: string;
  area?: BroadcastPayload["area"];
  sentBy: string;
  successCount: number;
  failureCount: number;
  invalidTokens: number;
  invalidTokenSamples?: string[];
}

async function cleanupInvalidTokens(
  firestore: admin.firestore.Firestore,
  invalidTokens: string[],
  tokenToUser: Map<string, string>,
): Promise<void> {
  // Agrupar tokens por user para hacer un solo arrayRemove por doc.
  const byUser = new Map<string, string[]>();
  for (const token of invalidTokens) {
    const userId = tokenToUser.get(token);
    if (!userId) continue;
    const acc = byUser.get(userId) ?? [];
    acc.push(token);
    byUser.set(userId, acc);
  }

  if (byUser.size === 0) return;

  // Firestore admite hasta 500 ops por batch; agrupamos por las dudas, aunque
  // en la práctica los tokens muertos por broadcast son pocos.
  let batch = firestore.batch();
  let ops = 0;
  for (const [userId, tokens] of byUser.entries()) {
    batch.update(firestore.collection("users").doc(userId), {
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokens),
    });
    ops++;
    if (ops >= 500) {
      try {
        await batch.commit();
      } catch (e) {
        logger.warn("Token cleanup batch failed", { error: e });
      }
      batch = firestore.batch();
      ops = 0;
    }
  }
  if (ops > 0) {
    try {
      await batch.commit();
    } catch (e) {
      logger.warn("Token cleanup batch failed", { error: e });
    }
  }
  logger.info("Cleaned up invalid tokens", {
    usersAffected: byUser.size,
    tokensRemoved: invalidTokens.length,
  });
}

async function persistBroadcastAudit(
  firestore: admin.firestore.Firestore,
  entry: BroadcastAuditEntry,
): Promise<void> {
  try {
    await firestore.collection(BROADCASTS_AUDIT_COLLECTION).add({
      ...entry,
      area: entry.area ?? null,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    // Auditoría best-effort: nunca debe romper el flujo del callable.
    logger.warn("Failed to persist broadcast audit entry", { error });
  }
}

// ── Callable público ────────────────────────────────────────────────────────

/**
 * Cloud Function (Callable) para que el administrador envíe notificaciones masivas.
 * Cumple con [T-NLP-09] / RF-ADM-04.
 *
 * Valida autenticación, rol "administrador" activo, y rango de área antes de
 * delegar la lógica de envío a `executeBroadcast()` (función pura testeable).
 */
export const broadcastNotification = onCall<BroadcastPayload>(
  async (
    request: CallableRequest<BroadcastPayload>,
  ): Promise<BroadcastResponse> => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "El usuario debe estar autenticado para enviar notificaciones.",
      );
    }

    const firestore = admin.firestore();
    const messaging = admin.messaging();
    const { title, body, area } = request.data ?? ({} as BroadcastPayload);

    if (typeof title !== "string" || typeof body !== "string" || !title || !body) {
      throw new HttpsError(
        "invalid-argument",
        "El título y cuerpo de la notificación son obligatorios.",
      );
    }

    if (area) {
      if (
        typeof area.latitude !== "number" ||
        typeof area.longitude !== "number" ||
        typeof area.radiusMeters !== "number"
      ) {
        throw new HttpsError(
          "invalid-argument",
          "El área debe tener latitude, longitude y radiusMeters numéricos.",
        );
      }
      if (
        area.radiusMeters <= 0 ||
        area.radiusMeters > MAX_BROADCAST_RADIUS_METERS
      ) {
        throw new HttpsError(
          "invalid-argument",
          `El radio debe estar entre 0 y ${MAX_BROADCAST_RADIUS_METERS / 1000} km.`,
        );
      }
    }

    // Autorización: Custom Claims (preferido) con fallback al doc de Firestore.
    // El rol persistido es "administrador" (sin sufijo) y el caller debe estar
    // active — consistente con T-AUTH-07 (`assertCallerIsAdmin` de T-NLP-06).
    let isAdmin = request.auth.token.admin === true;
    if (!isAdmin) {
      const userDoc = await firestore
        .collection("users")
        .doc(request.auth.uid)
        .get();
      const data = userDoc.data();
      if (
        userDoc.exists &&
        data?.role === "administrador" &&
        data?.status === "active"
      ) {
        isAdmin = true;
      }
    }
    if (!isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "Solo el administrador activo puede enviar notificaciones masivas.",
      );
    }

    try {
      return await executeBroadcast({
        firestore,
        messaging,
        payload: { title, body, area },
        caller: { uid: request.auth.uid },
      });
    } catch (error) {
      // Re-propagar HttpsError tal cual para no perder contexto en el cliente.
      if (error instanceof HttpsError) throw error;
      logger.error("Error during broadcast notification", {
        adminUid: request.auth.uid,
        error,
      });
      throw new HttpsError(
        "internal",
        "Ocurrió un error interno al despachar las notificaciones.",
      );
    }
  },
);
