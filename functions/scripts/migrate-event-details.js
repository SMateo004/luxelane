#!/usr/bin/env node
/*
 * Saca de bookings/{id}/events lo que solo debe ver central (motivo del
 * admin, farFromPickup, arrivalCheck) y lo pasa a eventDetails/{mismo id}
 * (A8.7). Los eventos de incidents/{id}/events no se tocan.
 *
 * Por defecto es DRY-RUN: solo informa qué haría. Escribe únicamente con
 * --apply.
 *
 *   npm run build
 *   node scripts/migrate-event-details.js --project <id>            # dry-run
 *   node scripts/migrate-event-details.js --project <id> --apply    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST definido trabaja contra el emulador.
 */
const admin = require('firebase-admin');
const { planEventDetail } = require('../lib/migrations/event_details');

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
  let examined = 0, moved = 0;
  const events = await db.collectionGroup('events').get();
  let batch = db.batch(), pending = 0;
  for (const doc of events.docs) {
    // Solo bookings/{id}/events.
    if (doc.ref.parent.parent?.parent.id !== 'bookings') continue;
    examined++;
    const plan = planEventDetail(doc.data());
    if (!plan) continue;
    moved++;
    console.log(`  ${doc.ref.path}: ${plan.remove.join(', ')} → eventDetails`);
    if (!apply) continue;
    batch.set(doc.ref.parent.parent.collection('eventDetails').doc(doc.id), plan.detail, { merge: true });
    batch.update(doc.ref, Object.fromEntries(plan.remove.map((k) => [k, admin.firestore.FieldValue.delete()])));
    pending += 2;
    if (pending >= 400) { await batch.commit(); batch = db.batch(); pending = 0; }
  }
  if (apply && pending) await batch.commit();
  console.log(`Eventos de reserva revisados: ${examined}; con datos solo para central: ${moved}.`);
  if (!apply && moved) console.log('Nada escrito (dry-run). Repite con --apply para aplicar.');
}

main().catch((e) => { console.error(e.message ?? e); process.exit(1); });
