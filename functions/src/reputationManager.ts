import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const REPUTATION_INCREMENT = 5;
export const REPUTATION_DECREMENT = 15;
export const MAX_REPUTATION = 100;
export const MIN_REPUTATION = 0;

export async function updateUserReputationLogic(
  firestore: admin.firestore.Firestore,
  userId: string,
  beforeData: admin.firestore.DocumentData,
  afterData: admin.firestore.DocumentData,
  incidentId: string
) {
  if (beforeData.status === afterData.status && beforeData.moderatedAsFalse === afterData.moderatedAsFalse) {
    return; // Optimización: no hay cambios que afecten la reputación
  }

  let delta = 0;

  // Positive validation: transiting to a confirmed state
  // La idempotencia (reputationApplied) garantiza que solo se premie una vez.
  if (
    beforeData.status !== afterData.status &&
    ["programado", "en_reparacion", "solucionado"].includes(afterData.status)
  ) {
    delta = REPUTATION_INCREMENT;
  }
  // Negative validation: el campo `moderatedAsFalse` lo escribe `moderation.ts`
  // (callable `moderateFalseReport`) cuando un admin/referente sanciona el
  // reporte. Antes de D-08 este código leía `verifiedAsFalse` — un nombre que
  // nadie escribía — y por eso la reputación nunca bajaba en producción.
  else if (beforeData.moderatedAsFalse !== true && afterData.moderatedAsFalse === true) {
    delta = -REPUTATION_DECREMENT;
  }

  if (delta === 0) {
    return; // No reputation change needed
  }

  try {
    await firestore.runTransaction(async (transaction) => {
      const incidentRef = firestore.collection("incidents").doc(incidentId);
      const incidentDoc = await transaction.get(incidentRef);

      if (incidentDoc.data()?.reputationApplied === true) {
        return; // Idempotency: ya se aplicó reputación por este incidente
      }

      const userRef = firestore.collection("users").doc(userId);
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        logger.warn("User document not found for reputation update", { userId });
        return;
      }

      const userData = userDoc.data();
      let currentScore = typeof userData?.reputationScore === "number" ? userData.reputationScore : MAX_REPUTATION;

      let newScore = currentScore + delta;
      if (newScore > MAX_REPUTATION) {
        newScore = MAX_REPUTATION;
      }
      if (newScore < MIN_REPUTATION) {
        newScore = MIN_REPUTATION;
      }

      if (newScore !== currentScore) {
        transaction.update(userRef, { reputationScore: newScore });
        logger.info(`Updated reputation score for user ${userId}: ${currentScore} -> ${newScore}`, {
          incidentId,
          delta,
        });
      }
      
      // Marcar como aplicado en el incidente para idempotencia
      transaction.update(incidentRef, { reputationApplied: true });
    });
  } catch (error) {
    logger.error("Failed to update user reputation", {
      userId,
      incidentId,
      error,
    });
  }
}

export const updateUserReputationOnValidation = onDocumentUpdated(
  "incidents/{incidentId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    const userId = afterData.userId || afterData.normalizedEvent?.userId;
    if (!userId) {
      logger.warn("Incident updated without userId", { incidentId: event.params.incidentId });
      return;
    }

    const firestore = admin.firestore();
    await updateUserReputationLogic(
      firestore,
      userId,
      beforeData,
      afterData,
      event.params.incidentId
    );
  }
);
