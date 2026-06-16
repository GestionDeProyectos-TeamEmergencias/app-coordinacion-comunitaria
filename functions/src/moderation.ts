import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const MAX_FALSE_REPORTS_THRESHOLD = 3;

export const moderateFalseReport = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado.");
  }

  const { incidentId, userId } = request.data;

  if (!incidentId || !userId) {
    throw new HttpsError("invalid-argument", "Se requieren incidentId y userId.");
  }

  const callerId = request.auth.uid;
  const db = admin.firestore();
  
  const callerDoc = await db.collection("users").doc(callerId).get();
  if (!callerDoc.exists) {
    throw new HttpsError("permission-denied", "Usuario llamador no encontrado.");
  }
  const callerRole = callerDoc.data()?.role;
  if (callerRole !== "administrador_vecinal" && callerRole !== "referente_barrial") {
    throw new HttpsError("permission-denied", "No tienes permisos para moderar reportes.");
  }

  const incidentRef = db.collection("incidents").doc(incidentId);
  const userRef = db.collection("users").doc(userId);

  try {
    await db.runTransaction(async (transaction) => {
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "El usuario reportado no existe.");
      }

      const userData = userSnap.data() || {};
      const currentFalseReports = (userData.falseReportsCount as number) || 0;
      const newFalseReportsCount = currentFalseReports + 1;
      
      const superarUmbral = newFalseReportsCount >= MAX_FALSE_REPORTS_THRESHOLD;

      transaction.update(incidentRef, {
        status: "falso",
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderatedBy: callerId,
      });

      const userUpdate: any = {
        falseReportsCount: newFalseReportsCount,
      };
      
      if (superarUmbral) {
        userUpdate.status = "blocked";
      }

      transaction.update(userRef, userUpdate);
    });

    return { success: true, message: "Reporte falso moderado exitosamente." };
  } catch (error) {
    console.error("Error en moderation transaction:", error);
    throw new HttpsError("internal", "Error al procesar la moderación.");
  }
});
