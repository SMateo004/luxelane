#!/usr/bin/env node
/*
 * Nombra administrador a una cuenta existente (B9): custom claim `role`,
 * users/{uid}.role, sesiones revocadas y entrada en admin_logs.
 *
 * DRY-RUN por defecto: solo escribe con --apply. Exige --project (no hay
 * proyecto por defecto) y se niega a tocar luxelane-4e7ae salvo con
 * --i-understand-this-writes-to-production-luxelane-4e7ae.
 *
 *   cd functions && npm run build && cd ..
 *   node scripts/promote_admin.mjs --project staging --email persona@ejemplo.com \
 *     --reason "primer admin del piloto" --operator "Nombre Apellido"          # dry-run
 *   node scripts/promote_admin.mjs … --apply                                    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST y FIREBASE_AUTH_EMULATOR_HOST trabaja contra
 * los emuladores. Credenciales: las de Application Default Credentials.
 */
import { createRequire } from 'node:module';

// firebase-admin y el código compilado viven en functions/.
const require = createRequire(new URL('../functions/package.json', import.meta.url));
const admin = require('firebase-admin');
const { checkTarget } = require('./lib/migrations/production_guard.js');
const { parsePromoteArgs, promoteAdmin } = require('./lib/migrations/promote_admin.js');

async function main() {
  const argv = process.argv.slice(2);
  const { project, apply, production } = checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST);
  const args = parsePromoteArgs(argv);
  console.log(`Proyecto: ${project}${production ? ' (PRODUCCIÓN)' : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);
  admin.initializeApp({ projectId: project });
  const plan = await promoteAdmin({ db: admin.firestore(), auth: admin.auth() }, args, apply);
  console.log(`Cuenta ${plan.uid}: rol ${plan.fromRole ?? '(ninguno)'}, claim ${plan.fromClaim ?? '(ninguno)'} → admin`);
  if (!plan.changes) console.log('Ya es admin: no hay nada que cambiar.');
  else console.log(apply ? 'Hecho: claim, documento, sesiones revocadas y auditoría.'
    : 'DRY-RUN: no se escribió nada. Repite con --apply para aplicar.');
}

main().then(() => process.exit(0)).catch((e) => { console.error(`Error: ${e.message}`); process.exit(1); });
