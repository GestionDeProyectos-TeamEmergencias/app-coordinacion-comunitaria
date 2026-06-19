import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Umbral de bloqueo automático: al llegar a este número de reportes falsos, el
// usuario pasa a status="blocked". Exportado para que tests y la calibración
// futura (T-NLP-06) puedan referenciarlo.
export const MAX_FALSE_REPORTS_THRESHOLD = 3;

type UserUpdate = {
  [k: string]: unknown;
  falseReportsCount: number;
  status?: "blocked";
};

/**
 * Marca un incidente como reporte falso, incrementa el contador del usuario
 * y, si supera el umbral, lo bloquea automáticamente. [T-AUTH-07, RF-MOD-03]
 *
 * Idempotencia: usa el flag `moderatedAsFalse` en el incidente para que un
 * mismo reporte no se cuente dos veces si el admin invoca repetidamente.
 */
export const moderateFalseReport = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "El usuario debe estar autenticado.",
    );
  }

  const { incidentId, userId } = request.data ?? {};

  if (typeof incidentId !== "string" || typeof userId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Se requieren incidentId y userId como strings.",
    );
  }

  const callerId = request.auth.uid;
  const db = admin.firestore();

  const callerDoc = await db.collection("users").doc(callerId).get();
  if (!callerDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Usuario llamador no encontrado.",
    );
  }
  const callerData = callerDoc.data();
  const callerRole = callerData?.role;
  const callerStatus = callerData?.status;
  if (
    callerStatus !== "active" ||
    (callerRole !== "administrador" && callerRole !== "referente_barrial")
  ) {
    throw new HttpsError(
      "permission-denied",
      "No tienes permisos para moderar reportes.",
    );
  }

  const incidentRef = db.collection("incidents").doc(incidentId);
  const userRef = db.collection("users").doc(userId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const incidentSnap = await transaction.get(incidentRef);
      if (!incidentSnap.exists) {
        throw new HttpsError("not-found", "El incidente no existe.");
      }
      const incidentData = incidentSnap.data() ?? {};
      // Idempotencia: si ya se moderó como falso, no aplicar de nuevo.
      if (incidentData.moderatedAsFalse === true) {
        return { alreadyModerated: true, blocked: false };
      }

      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "El usuario reportado no existe.");
      }
      const userData = userSnap.data() ?? {};
      const currentFalseReports =
        typeof userData.falseReportsCount === "number"
          ? userData.falseReportsCount
          : 0;
      const newFalseReportsCount = currentFalseReports + 1;
      const blocked = newFalseReportsCount >= MAX_FALSE_REPORTS_THRESHOLD;

      transaction.update(incidentRef, {
        status: "falso",
        moderatedAsFalse: true,
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderatedBy: callerId,
      });

      const userUpdate: UserUpdate = { falseReportsCount: newFalseReportsCount };
      if (blocked) {
        userUpdate.status = "blocked";
      }
      transaction.update(userRef, userUpdate);

      return { alreadyModerated: false, blocked };
    });

    logger.info("Incident moderated as false report", {
      incidentId,
      userId,
      callerId,
      blocked: result.blocked,
      alreadyModerated: result.alreadyModerated,
    });

    return {
      success: true,
      blocked: result.blocked,
      alreadyModerated: result.alreadyModerated,
    };
  } catch (error) {
    // Re-propagar HttpsError tal cual para no perder contexto en el cliente.
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to moderate false report", {
      incidentId,
      userId,
      callerId,
      error,
    });
    throw new HttpsError("internal", "Error al procesar la moderación.");
  }
});

/**
 * Desbloquea manualmente a un usuario: revierte `status` a "active" y resetea
 * el contador de reportes falsos. Solo para administradores activos. [T-AUTH-07]
 */
export const unblockUser = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "El usuario debe estar autenticado.",
    );
  }

  const { userId } = request.data ?? {};
  if (typeof userId !== "string") {
    throw new HttpsError("invalid-argument", "Se requiere userId como string.");
  }

  const callerId = request.auth.uid;
  const db = admin.firestore();

  const callerDoc = await db.collection("users").doc(callerId).get();
  const callerData = callerDoc.data();
  if (
    !callerDoc.exists ||
    callerData?.role !== "administrador" ||
    callerData?.status !== "active"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Solo un administrador activo puede desbloquear usuarios.",
    );
  }

  const userRef = db.collection("users").doc(userId);
  try {
    await userRef.update({
      status: "active",
      falseReportsCount: 0,
      unblockedAt: admin.firestore.FieldValue.serverTimestamp(),
      unblockedBy: callerId,
    });
    logger.info("User unblocked", { userId, callerId });
    return { success: true };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to unblock user", { userId, callerId, error });
    throw new HttpsError("internal", "Error al desbloquear usuario.");
  }
});
