#!/usr/bin/env node
/*
 * Quita los segundos factores (TOTP) de una cuenta que perdió su teléfono
 * (C4): sesiones revocadas y entrada en admin_logs. La persona vuelve a
 * entrar con su contraseña y da de alta el factor de nuevo.
 *
 * DRY-RUN por defecto: solo escribe con --apply. Exige --project (no hay
 * proyecto por defecto) y se niega a tocar luxelane-4e7ae salvo con
 * --i-understand-this-writes-to-production-luxelane-4e7ae.
 *
 *   cd functions && npm run build && cd ..
 *   node scripts/reset_mfa.mjs --project staging --email persona@ejemplo.com \
 *     --reason "perdió el teléfono; identidad confirmada por <cómo>" --operator "Nombre"   # dry-run
 *   node scripts/reset_mfa.mjs … --apply                                                    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST y FIREBASE_AUTH_EMULATOR_HOST trabaja contra
 * los emuladores. Credenciales: las de Application Default Credentials.
 */
import { createRequire } from 'node:module';

// firebase-admin y el código compilado viven en functions/.
const require = createRequire(new URL('../functions/package.json', import.meta.url));
const admin = require('firebase-admin');
const { checkTarget } = require('./lib/migrations/production_guard.js');
const { parsePromoteArgs } = require('./lib/migrations/promote_admin.js');
const { resetMfa } = require('./lib/migrations/reset_mfa.js');

async function main() {
  const argv = process.argv.slice(2);
  const { project, apply, production } = checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST);
  const args = parsePromoteArgs(argv);
  console.log(`Proyecto: ${project}${production ? ' (PRODUCCIÓN)' : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);
  admin.initializeApp({ projectId: project });
  const plan = await resetMfa({ db: admin.firestore(), auth: admin.auth() }, args, apply);
  console.log(`Cuenta ${plan.uid} (rol ${plan.role ?? 'sin rol'}): factores ${plan.factors.join(', ') || '(ninguno)'}`);
  if (plan.factors.length === 0) console.log('No tiene segundo factor: no hay nada que quitar.');
  else console.log(apply ? 'Hecho: factores retirados, sesiones revocadas y auditoría.'
    : 'DRY-RUN: no se escribió nada. Repite con --apply para aplicar.');
}

main().then(() => process.exit(0)).catch((e) => { console.error(`Error: ${e.message}`); process.exit(1); });
