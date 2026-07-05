import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import { loadAlgorithmConfig } from "./algorithmConfig";

// ── Lógica pura: cálculo de la fecha de vencimiento del cierre ──────────────
// Exportada para test sin tocar Firestore. [F-05]

export function isClosureExpired(
  pendingSince: Date,
  autoConfirmAfterDays: number,
  now: Date = new Date(),
): boolean {
  const elapsedMs = now.getTime() - pendingSince.getTime();
  const thresholdMs = autoConfirmAfterDays * 24 * 60 * 60 * 1000;
  return elapsedMs >= thresholdMs;
}

// ── Push al reportero cuando se inicia la validación bilateral ──────────────

export const notifyClosurePending = onDocumentUpdated(
  "incidents/{incidentId}",
  async (event) => {
    const incidentId = event.params.incidentId as string;
    const before = event.data?.before.data() ?? {};
    const after = event.data?.after.data() ?? {};

    const beforeState = before.closureConfirmation?.state;
    const afterState = after.closureConfirmation?.state;
    // Solo notificar cuando el estado pasa A pendiente (no en otras transiciones).
    if (afterState !== "pendiente" || beforeState === "pendiente") {
      return;
    }

    const reporterId = after.userId;
    if (typeof reporterId !== "string") {
      logger.warn("Closure pending without reporter uid", { incidentId });
      return;
    }

    const firestore = admin.firestore();
    const userSnap = await firestore.collection("users").doc(reporterId).get();
    const tokens = (userSnap.data()?.fcmTokens ?? []) as string[];
    if (tokens.length === 0) {
      logger.info("Reporter has no FCM tokens", { incidentId, reporterId });
      return;
    }

    try {
      const messaging = admin.messaging();
      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "Tu reporte fue marcado como solucionado",
          body: "Confirmá la solución o disputala desde la app.",
        },
        data: {
          incidentId,
          type: "closure_pending",
        },
      });
      logger.info("Closure pending push sent", {
        incidentId,
        reporterId,
        success: response.successCount,
        failure: response.failureCount,
      });
    } catch (error) {
      logger.error("Closure pending push failed", {
        incidentId,
        reporterId,
        error,
      });
    }
  },
);

// ── Auto-cierre programado de pendientes vencidos ───────────────────────────

export const autoConfirmExpiredClosures = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "America/Argentina/Buenos_Aires",
  },
  async () => {
    const firestore = admin.firestore();
    const config = await loadAlgorithmConfig(firestore);
    const threshold = config.closureConfirmation.autoConfirmAfterDays;
    const now = new Date();
    const cutoff = new Date(
      now.getTime() - threshold * 24 * 60 * 60 * 1000,
    );

    // Buscamos pendientes cuya `at` sea anterior al cutoff.
    const snap = await firestore
      .collection("incidents")
      .where("closureConfirmation.state", "==", "pendiente")
      .where("closureConfirmation.at", "<=", admin.firestore.Timestamp.fromDate(cutoff))
      .limit(500)
      .get();

    if (snap.empty) {
      logger.info("No expired closures to auto-confirm");
      return;
    }

    const batch = firestore.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        closureConfirmation: {
          state: "confirmado",
          by: "auto",
          at: admin.firestore.Timestamp.now(),
        },
      });
    }
    await batch.commit();

    logger.info("Auto-confirmed expired closures", {
      count: snap.size,
      thresholdDays: threshold,
    });
  },
);
