// Prepares the Firebase project for the FinBridge app, which talks to Firestore directly.
//
//   npm run firebase:setup            publish firestore.rules, create the demo logins,
//                                     load demo data and the address lists
//   npm run firebase:setup -- --reset same, but first DELETE every FinBridge collection
//                                     (customers, transactions, logs...) and start clean
//
// Uses serviceAccountKey.json (GOOGLE_APPLICATION_CREDENTIALS in .env). Before the first run,
// enable Authentication -> Sign-in method -> Email/Password in the Firebase console.
const fs = require('fs');
const path = require('path');
const config = require('../src/config');
const { createFirestoreStore } = require('../src/db/firestoreStore');
const { seed } = require('../src/seed');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getSecurityRules } = require('firebase-admin/security-rules');

const DEMO_PIN = '123456';
const COLLECTIONS = [
  'agents', 'customers', 'accounts', 'transactions', 'idempotency', 'auditLogs', 'smsOutbox',
  'eodReports', 'floatRequests', 'disputes', 'provinces', 'districts', 'localBodies',
];

// Same address the app signs in with (lib/api/api_client.dart, _email).
const emailFor = (agentId) => `${agentId.toLowerCase()}@finbridge.test`;

async function deleteCollection(db, name) {
  let total = 0;
  for (;;) {
    const snap = await db.collection(name).limit(400).get();
    if (snap.empty) return total;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
  }
}

async function upsertLogin(auth, agentId, role, name) {
  const props = { email: emailFor(agentId), password: DEMO_PIN, displayName: name, disabled: false };
  try {
    await auth.updateUser(agentId, props);
  } catch (err) {
    if (err.code !== 'auth/user-not-found') throw err;
    await auth.createUser({ uid: agentId, ...props });
  }
  await auth.setCustomUserClaims(agentId, { role });
}

async function main() {
  const reset = process.argv.includes('--reset');
  const store = createFirestoreStore({
    projectId: config.firebase.projectId,
    credentialsPath: config.firebase.credentialsPath,
  });
  const db = getFirestore();

  const source = fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8');
  await getSecurityRules().releaseFirestoreRulesetFromSource(source);
  console.log('Published firestore.rules.');

  if (reset) {
    for (const name of COLLECTIONS) {
      const n = await deleteCollection(db, name);
      if (n) console.log(`Deleted ${n} documents from ${name}.`);
    }
  }

  await seed(store);
  const agents = await db.collection('agents').get();
  for (const doc of agents.docs) {
    const a = doc.data();
    // PINs live in Firebase Authentication now; no PIN hash in Firestore.
    if (a.pinHash) await doc.ref.update({ pinHash: FieldValue.delete() });
    await upsertLogin(getAuth(), doc.id, a.role, a.name);
  }
  console.log(`Logins ready for ${agents.docs.map((d) => d.id).join(', ')} (PIN ${DEMO_PIN} for the demo users).`);
  console.log('Demo customers and the address lists are loaded.');
}

main().then(() => process.exit(0)).catch((err) => {
  if (err.code === 'auth/configuration-not-found') {
    console.error('Firebase Authentication is not set up yet. In the Firebase console open Authentication,'
      + ' click Get started, enable Email/Password, then run this again.');
  } else {
    console.error(err);
  }
  process.exit(1);
});
