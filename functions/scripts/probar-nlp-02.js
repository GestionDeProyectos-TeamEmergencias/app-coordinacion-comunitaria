// Uso:
//   Set-Location 'C:\Users\Lucas\Code\app-coordinacion-comunitaria\functions'
//   $env:GCLOUD_PROJECT='demo-no-project'
//   $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
//   pnpm run test:nlp-02
// Requiere que los emuladores de Firebase estén corriendo en otra terminal.

const admin = require('firebase-admin');

const projectId = 'demo-no-project';
const firestoreEmulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const userId = 'user-ticket-t-nlp-02';
const runId = Date.now().toString();
const mainIncidentId = `incident-main-${runId}`;
const duplicateIncidentId = `incident-duplicate-${runId}`;

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || projectId;
process.env.FIRESTORE_EMULATOR_HOST = firestoreEmulatorHost;

admin.initializeApp({ projectId });

const firestore = admin.firestore();

async function deleteIfExists(docRef) {
  const snap = await docRef.get();
  if (snap.exists) {
    await docRef.delete();
  }
}

async function waitForDoc(path, predicate, label) {
  for (let attempt = 1; attempt <= 24; attempt++) {
    const snap = await firestore.doc(path).get();
    if (snap.exists && predicate(snap.data())) {
      return snap.data();
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Timeout waiting for ${label}`);
}

async function main() {
  const now = new Date('2026-05-25T12:00:00Z');

  await Promise.all([
    deleteIfExists(firestore.collection('users').doc(userId)),
    deleteIfExists(firestore.collection('incidents').doc('incident-main')),
    deleteIfExists(firestore.collection('incidents').doc('incident-duplicate')),
    deleteIfExists(firestore.collection('incidents').doc('incident-main-2')),
    deleteIfExists(firestore.collection('incidents').doc('incident-duplicate-2')),
  ]);

  await firestore.collection('users').doc(userId).set({
    displayName: 'Usuario Prueba',
    role: 'vecino',
    status: 'active',
    reputationScore: 100,
    createdAt: admin.firestore.Timestamp.fromDate(now),
  });

  await firestore.collection('incidents').doc(mainIncidentId).set({
    eventId: `event-main-${runId}`,
    schemaVersion: '1.0.0',
    sourceType: 'quick',
    timestamp: admin.firestore.Timestamp.fromDate(now),
    userId,
    location: { latitude: -34.6037, longitude: -58.3816, accuracy: 7.5 },
    description: null,
    category: null,
    photoUrl: null,
  });

  await firestore.collection('incidents').doc(duplicateIncidentId).set({
    eventId: `event-dup-${runId}`,
    schemaVersion: '1.0.0',
    sourceType: 'form',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2026-05-25T12:05:00Z')),
    userId,
    location: { latitude: -34.60375, longitude: -58.38155, accuracy: 6.2 },
    description: 'Bache profundo en la avenida',
    category: 'pavimentacion',
    photoUrl: null,
  });

  const main = await waitForDoc(
    `incidents/${mainIncidentId}`,
    (data) => Boolean(data.normalizedEvent && data.enrichment && data.normalizedAt),
    'main incident normalization'
  );

  const duplicate = await waitForDoc(
    `incidents/${duplicateIncidentId}`,
    (data) => Boolean(data.normalizedEvent && data.duplicateCheck && data.normalizedAt),
    'duplicate incident normalization'
  );

  console.log(JSON.stringify({
    main: {
      normalizedEvent: main.normalizedEvent,
      enrichment: main.enrichment,
      duplicateCheck: main.duplicateCheck,
      warnings: main.normalizationWarnings,
      normalizedAt: Boolean(main.normalizedAt),
    },
    duplicate: {
      normalizedEvent: duplicate.normalizedEvent,
      enrichment: duplicate.enrichment,
      duplicateCheck: duplicate.duplicateCheck,
      warnings: duplicate.normalizationWarnings,
      normalizedAt: Boolean(duplicate.normalizedAt),
    },
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});