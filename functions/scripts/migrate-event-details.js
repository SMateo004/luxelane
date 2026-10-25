#!/usr/bin/env node
/*
 * Saca de bookings/{id}/events lo que solo debe ver central (motivo del
 * admin, farFromPickup, arrivalCheck) y lo pasa a eventDetails/{mismo id}
 * (A8.7). Los eventos de incidents/{id}/events no se tocan.
 *
 * Desde 0.2 también saca el uid del admin del actor del evento (queda
 * actor.role = 'admin') y quita acknowledgedBy/closedBy de los incidentes.
 *
 * Por defecto es DRY-RUN: solo informa qué haría. Escribe únicamente con
 * --apply. Se niega a correr contra luxelane-4e7ae salvo con
 * --i-understand-this-writes-to-production-luxelane-4e7ae.
 *
 *   npm run build
 *   node scripts/migrate-event-details.js --project <id>            # dry-run
 *   node scripts/migrate-event-details.js --project <id> --apply    # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST definido trabaja contra el emulador.
 */
const admin = require('firebase-admin');
const { checkTarget } = require('../lib/migrations/production_guard');
const { planEventDetail, planIncidentCleanup } = require('../lib/migrations/event_details');

async function main() {
  const { project, apply, production } = checkTarget(process.argv.slice(2), process.env.FIRESTORE_EMULATOR_HOST);
  const emulator = process.env.FIRESTORE_EMULATOR_HOST;
  console.log(`Proyecto: ${project}${production ? ' (PRODUCCIÓN)' : ''}${emulator ? ` (emulador ${emulator})` : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();
  let examined = 0, moved = 0;
  const events = await db.collectionGroup('events').get();
  let batch = db.batch(), pending = 0;
  const flush = async () => { if (pending >= 400) { await batch.commit(); batch = db.batch(); pending = 0; } };
  for (const doc of events.docs) {
    // Solo bookings/{id}/events.
    if (doc.ref.parent.parent?.parent.id !== 'bookings') continue;
    examined++;
    const plan = planEventDetail(doc.data());
    if (!plan) continue;
    moved++;
    const what = [...plan.remove, ...(plan.actor ? ['actor.uid'] : [])];
    console.log(`  ${doc.ref.path}: ${what.join(', ')} → eventDetails`);
    if (!apply) continue;
    batch.set(doc.ref.parent.parent.collection('eventDetails').doc(doc.id), plan.detail, { merge: true });
    batch.update(doc.ref, {
      ...Object.fromEntries(plan.remove.map((k) => [k, admin.firestore.FieldValue.delete()])),
      ...(plan.actor ? { actor: plan.actor } : {}),
    });
    pending += 2;
    await flush();
  }
  // Incidentes: sin el uid del admin en el documento que lee quien lo disparó (0.2).
  let incidents = 0;
  for (const doc of (await db.collection('incidents').get()).docs) {
    const remove = planIncidentCleanup(doc.data());
    if (remove.length === 0) continue;
    incidents++;
    console.log(`  ${doc.ref.path}: quitar ${remove.join(', ')}`);
    if (!apply) continue;
    batch.update(doc.ref, Object.fromEntries(remove.map((k) => [k, admin.firestore.FieldValue.delete()])));
    pending += 1;
    await flush();
  }
  if (apply && pending) await batch.commit();
  console.log(`Eventos de reserva revisados: ${examined}; con datos solo para central: ${moved}.`);
  console.log(`Incidentes con el uid del admin: ${incidents}.`);
  if (!apply && (moved || incidents)) console.log('Nada escrito (dry-run). Repite con --apply para aplicar.');
}

main().catch((e) => { console.error(e.message ?? e); process.exit(1); });
