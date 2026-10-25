#!/usr/bin/env node
/*
 * Backfill del custom claim `role` (B2): copia users/{uid}.role a Auth.
 * DRY-RUN por defecto; escribe solo con --apply. Se niega a correr contra
 * luxelane-4e7ae salvo con --i-understand-this-writes-to-production-luxelane-4e7ae.
 *
 *   npm run build
 *   node scripts/backfill-role-claims.js --project staging            # dry-run
 *   node scripts/backfill-role-claims.js --project staging --apply    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST y FIREBASE_AUTH_EMULATOR_HOST trabaja contra
 * los emuladores. No revoca sesiones: el claim llega con el siguiente token
 * (como mucho en una hora) y las reglas aceptan el rol de Firestore mientras.
 */
const admin = require('firebase-admin');
const { checkTarget } = require('../lib/migrations/production_guard');
const { planRoleClaim } = require('../lib/migrations/role_claims');

async function main() {
  const { project, apply, production } = checkTarget(process.argv.slice(2), process.env.FIRESTORE_EMULATOR_HOST);
  console.log(`Proyecto: ${project}${production ? ' (PRODUCCIÓN)' : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);
  admin.initializeApp({ projectId: project });
  const db = admin.firestore();
  const auth = admin.auth();
  let examined = 0, changed = 0, missing = 0;
  const users = await db.collection('users').select('role').get();
  for (const doc of users.docs) {
    examined++;
    let user;
    try {
      user = await auth.getUser(doc.id);
    } catch {
      missing++;
      console.log(`  ${doc.id}: sin cuenta en Auth, se omite`);
      continue;
    }
    const change = planRoleClaim(doc.id, doc.data().role, user.customClaims);
    if (!change) continue;
    changed++;
    console.log(`  ${doc.id}: role ${change.from ?? '(ninguno)'} → ${change.to}`);
    if (apply) await auth.setCustomUserClaims(doc.id, { ...(user.customClaims ?? {}), role: change.to });
  }
  console.log(`Usuarios: ${examined}; claims a cambiar: ${changed}; sin cuenta en Auth: ${missing}.`);
  console.log(apply ? 'Cambios aplicados.' : 'DRY-RUN: no se escribió nada. Repite con --apply para aplicar.');
}

main().catch((e) => { console.error(`Error: ${e.message}`); process.exit(1); });
