import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { loadAlgorithmConfig } from "./algorithmConfig";

// ── Lógica pura: cálculo de confirmationScore y validación comunitaria ──────
// Exportada para que se pueda testear sin tocar Firestore. [F-04]

export interface AggregatedReactionCounts {
  confirmsCount: number;
  disputesCount: number;
  confirmationScore: number;
  communityValidated: boolean;
}

export interface CommunityValidationThresholds {
  threshold: number;
  minReactions: number;
}

/**
 * Calcula `confirmationScore = confirms / (confirms + disputes)` y el flag
 * `communityValidated` según el umbral configurable. [F-04 / RF-MOD-?-extra]
 *
 * Borde:
 * - Sin votos → score 0, no validado.
 * - Solo disputes → score 0, no validado.
 * - Solo confirms → score 1, validado si llega a `minReactions`.
 * - Score >= threshold pero total < minReactions → no validado todavía
 *   (defensa contra "1 voto y validamos").
 */
export function computeReactionAggregates(
  confirms: number,
  disputes: number,
  thresholds: CommunityValidationThresholds
): AggregatedReactionCounts {
  const total = confirms + disputes;
  const score = total === 0 ? 0 : confirms / total;
  const validated = total >= thresholds.minReactions && score >= thresholds.threshold;
  return {
    confirmsCount: confirms,
    disputesCount: disputes,
    confirmationScore: score,
    communityValidated: validated,
  };
}

// ── Trigger ─────────────────────────────────────────────────────────────────

export const aggregateReactionsOnWritten = onDocumentWritten(
  "incidents/{incidentId}/reactions/{userId}",
  async (event) => {
    const incidentId = event.params.incidentId as string;
    const firestore = admin.firestore();

    try {
      const [reactionsSnap, config] = await Promise.all([
        firestore
          .collection("incidents")
          .doc(incidentId)
          .collection("reactions")
          .get(),
        loadAlgorithmConfig(firestore),
      ]);

      let confirms = 0;
      let disputes = 0;
      for (const doc of reactionsSnap.docs) {
        const type = doc.data().type;
        if (type === "confirm") confirms++;
        else if (type === "dispute") disputes++;
      }

      const aggregates = computeReactionAggregates(
        confirms,
        disputes,
        config.communityValidation
      );

      await firestore.collection("incidents").doc(incidentId).update({
        confirmsCount: aggregates.confirmsCount,
        disputesCount: aggregates.disputesCount,
        confirmationScore: aggregates.confirmationScore,
        communityValidated: aggregates.communityValidated,
        communityValidatedAt: aggregates.communityValidated
          ? admin.firestore.FieldValue.serverTimestamp()
          : admin.firestore.FieldValue.delete(),
      });

      logger.info("Reactions aggregated", {
        incidentId,
        ...aggregates,
      });
    } catch (error) {
      logger.error("Failed to aggregate reactions", { incidentId, error });
    }
  }
);
