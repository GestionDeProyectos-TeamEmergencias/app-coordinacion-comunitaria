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
  beforeStatus: string | undefined,
  afterStatus: string | undefined,
  incidentId: string
) {
  if (!beforeStatus || !afterStatus || beforeStatus === afterStatus) {
    return;
  }

  const userRef = firestore.collection("users").doc(userId);

  // Identify if the status change is a validation or a rejection
  let delta = 0;

  // Positive validation: transiting from 'recibido' to a confirmed state
  if (
    beforeStatus === "recibido" &&
    ["programado", "en_reparacion", "solucionado"].includes(afterStatus)
  ) {
    delta = REPUTATION_INCREMENT;
  }
  // Negative validation (rejection/false): preparing for T-AUTH-07
  else if (["rechazado", "falso"].includes(afterStatus)) {
    delta = -REPUTATION_DECREMENT;
  }

  if (delta === 0) {
    return; // No reputation change needed
  }

  try {
    await firestore.runTransaction(async (transaction) => {
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
      beforeData.status,
      afterData.status,
      event.params.incidentId
    );
  }
);
