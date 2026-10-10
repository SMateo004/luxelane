// Grants the admin role to an existing account (the only way to create an
// admin: the rules never let a user change their own role).
//
//   PROJECT=luxelane-4e7ae EMAIL=you@example.com node scripts/promote_admin.mjs
//
// The account must have registered in the app first. Uses Application
// Default Credentials (`gcloud auth application-default login`) or
// GOOGLE_APPLICATION_CREDENTIALS. Run from the repo root, so firebase-admin
// resolves from functions/node_modules (or `npm i firebase-admin` next to it).
import { createRequire } from 'node:module';

const require = createRequire(new URL('../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const projectId = process.env.PROJECT || 'luxelane-4e7ae';
const email = process.env.EMAIL;
if (!email) {
  console.error('Set EMAIL (the account to promote), e.g. EMAIL=you@example.com');
  process.exit(1);
}

const app = initializeApp({ projectId });
const db = getFirestore(app);
const auth = getAuth(app);

try {
  console.log(`Project ${projectId} · looking up ${email}`);
  const { uid } = await auth.getUserByEmail(email);
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    console.error('The account exists in Auth but has no profile in users/ — finish registration in the app first.');
    process.exit(1);
  }
  console.log(`Current role: ${snap.data().role}`);
  await ref.update({ role: 'admin', isVerified: true, isActive: true });
  console.log('✅ Now an admin.');
  process.exit(0);
} catch (err) {
  console.error(err.code === 'auth/user-not-found' ? 'No account with that e-mail — register in the app first.' : `Error: ${err.message}`);
  process.exit(1);
}
