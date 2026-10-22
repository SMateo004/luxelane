#!/usr/bin/env node
/*
 * Viajes en curso antes de desplegar las reglas de la verificación en
 * recogida (D1). Solo lee: nunca escribe (siempre es un dry-run).
 * Termina con código 2 si algún viaje avanzó con la app antigua del chófer
 * (sin eventos): con las reglas nuevas se quedaría en su paso.
 *
 *   npm run build
 *   node scripts/trips-in-flight.js --project <id>
 *
 * Nunca contra luxelane-4e7ae (en producción: panel → Operaciones).
 * Con FIRESTORE_EMULATOR_HOST definido trabaja contra el emulador.
 */
const admin = require('firebase-admin');
const { assertTarget, classifyInFlight, IN_FLIGHT, remedyFor } = require('../lib/migrations/trips_in_flight');

function parseArgs(argv) {
  const args = { project: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--project') args.project = argv[++i] ?? null;
    else throw new Error(`Argumento desconocido: ${argv[i]}`);
  }
  if (!args.project) throw new Error('Falta --project <id>. No hay proyecto por defecto.');
  return args;
}

async function main() {
  const { project } = parseArgs(process.argv.slice(2));
  const emulator = process.env.FIRESTORE_EMULATOR_HOST;
  assertTarget(project, emulator);
  console.log(`Proyecto: ${project}${emulator ? ` (emulador ${emulator})` : ''}`);
  console.log('Modo: solo lectura (no escribe nada)');

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();
  const snap = await db.collection('bookings').where('status', 'in', [...IN_FLIGHT]).get();
  const trips = [];
  for (const doc of snap.docs) {
    const events = await doc.ref.collection('events').limit(1).get();
    trips.push({ id: doc.id, status: doc.data().status, serverFlow: !events.empty });
  }
  const report = classifyInFlight(trips);
  console.log(`Viajes activos: ${report.total}`);
  for (const [status, n] of Object.entries(report.byStatus)) console.log(`  ${status}: ${n}`);
  if (!report.blocking.length) {
    console.log('Ningún viaje depende de la app antigua del chófer: se pueden desplegar las reglas.');
    return 0;
  }
  console.log(`Con la app antigua (sin eventos): ${report.blocking.length}`);
  for (const t of report.blocking) console.log(`  ${t.id} (${t.status}): ${remedyFor(t.status)}`);
  console.log('No despliegues las reglas todavía.');
  return 2;
}

main().then((code) => process.exit(code), (e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
