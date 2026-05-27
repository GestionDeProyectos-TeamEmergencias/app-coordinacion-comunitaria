import type { firestore as FirestoreAdmin } from "firebase-admin";

export interface UserEnrichment {
  role: string | null;
  status: string | null;
  reputationScore: number | null;
}

export interface HistoryEnrichment {
  totalReports: number;
  reportsLast30Days: number;
}

export interface EnrichmentResult {
  user: UserEnrichment;
  history: HistoryEnrichment;
}

export async function buildEnrichment(
  firestore: FirestoreAdmin.Firestore,
  userId: string,
  now: Date
): Promise<EnrichmentResult> {
  const [user, history] = await Promise.all([
    loadUserProfile(firestore, userId),
    loadIncidentHistory(firestore, userId, now),
  ]);

  return { user, history };
}

async function loadUserProfile(
  firestore: FirestoreAdmin.Firestore,
  userId: string
): Promise<UserEnrichment> {
  const snapshot = await firestore.collection("users").doc(userId).get();
  if (!snapshot.exists) {
    return {
      role: null,
      status: null,
      reputationScore: null,
    };
  }

  const data = snapshot.data() ?? {};

  return {
    role: typeof data.role === "string" ? data.role : null,
    status: typeof data.status === "string" ? data.status : null,
    reputationScore: typeof data.reputationScore === "number" ? data.reputationScore : null,
  };
}

async function loadIncidentHistory(
  firestore: FirestoreAdmin.Firestore,
  userId: string,
  now: Date
): Promise<HistoryEnrichment> {
  const since = new Date(now.getTime());
  since.setDate(since.getDate() - 30);

  const [totalCountSnap, recentCountSnap] = await Promise.all([
    firestore
      .collection("incidents")
      .where("userId", "==", userId)
      .count()
      .get(),
    firestore
      .collection("incidents")
      .where("userId", "==", userId)
      .where("timestamp", ">=", since)
      .count()
      .get(),
  ]);

  return {
    totalReports: totalCountSnap.data().count,
    reportsLast30Days: recentCountSnap.data().count,
  };
}
