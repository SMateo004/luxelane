#!/usr/bin/env node
/*
 * Migra reservas existentes: datos del invitado de `notes` a `guest`, y
 * solicitudes abiertas para las reservas pendientes.
 *
 * Por defecto es DRY-RUN: solo informa qué haría. Escribe únicamente con
 * --apply.
 *
 *   npm run build
 *   node scripts/migrate-booking-pii.js --project <id>            # dry-run
 *   node scripts/migrate-booking-pii.js --project <id> --apply    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST definido trabaja contra el emulador.
 */
const admin = require('firebase-admin');
const { describePlan, planBookingMigration } = require('../lib/migrations/booking_pii');

function parseArgs(argv) {
  const args = { project: null, apply: false };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--project') args.project = argv[++i] ?? null;
    else if (argv[i] === '--apply') args.apply = true;
    else throw new Error(`Argumento desconocido: ${argv[i]}`);
  }
  if (!args.project) throw new Error('Falta --project <id>. No hay proyecto por defecto.');
  return args;
}

async function main() {
  const { project, apply } = parseArgs(process.argv.slice(2));
  const emulator = process.env.FIRESTORE_EMULATOR_HOST;
  if (project.startsWith('demo-') && !emulator) {
    throw new Error('Un proyecto demo-* solo existe en el emulador: define FIRESTORE_EMULATOR_HOST.');
  }
  console.log(`Proyecto: ${project}${emulator ? ` (emulador ${emulator})` : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();
  const openIds = new Set((await db.collection('openRequests').select().get()).docs.map((d) => d.id));

  let examined = 0, guests = 0, requests = 0;
  let last = null;
  for (;;) {
    let q = db.collection('bookings').orderBy(admin.firestore.FieldPath.documentId()).limit(300);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    const batch = db.batch();
    for (const doc of page.docs) {
      examined++;
      const plan = planBookingMigration(doc.data(), openIds.has(doc.id));
      const actions = describePlan(plan);
      if (!actions.length) continue;
      console.log(`  ${doc.id}: ${actions.join('; ')}`);
      if (plan.guest) {
        guests++;
        batch.update(doc.ref, {
          guest: plan.guest.guest,
          notes: plan.guest.notes ?? admin.firestore.FieldValue.delete(),
        });
      }
      if (plan.openRequest) {
        requests++;
        batch.set(db.collection('openRequests').doc(doc.id), plan.openRequest);
      }
    }
    if (apply) await batch.commit();
    last = page.docs[page.docs.length - 1];
  }

  console.log(`Reservas revisadas: ${examined}`);
  console.log(`Con datos del invitado en notes: ${guests}`);
  console.log(`Pendientes sin solicitud abierta: ${requests}`);
  console.log(apply ? 'Cambios aplicados.' : 'DRY-RUN: no se escribió nada. Repite con --apply para aplicar.');
}

main().catch((e) => {
  console.error(`Error: ${e.message}`);
  process.exit(1);
});
