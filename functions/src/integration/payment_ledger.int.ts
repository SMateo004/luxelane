/**
 * H4: el libro `payments` es de solo anexado. Tras cada paso de pagos se
 * comprueba que ningún asiento desaparece, que su importe, tipo, método,
 * motivo y fecha no cambian, y que lo único que cambia es el cierre de un
 * asiento pendiente, una sola vez. Contra el emulador; importes y números
 * de operación de PRUEBA, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { adminCollectBalance } from '../payment_balance';
import { adminRecordRefund } from '../payment_refund';
import { reconcileFinalAmount } from '../payment_final';

const db = admin.firestore();
const ACTOR = { adminId: 'jefa', adminEmail: null };
const WHY = 'Movimiento visto en el extracto del banco';
type Doc = Record<string, unknown>;

async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'adminAlerts', 'payments', 'paymentOperations', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const snapshot = async (): Promise<Map<string, Doc>> =>
  new Map((await db.collection('payments').get()).docs.map((d) => [d.id, d.data()]));

const IMMUTABLE = ['type', 'bookingId', 'riderId', 'amount', 'currency', 'method', 'reason', 'actor', 'createdAt'];
const CLOSING = ['status', 'externalRef', 'completedAt', 'closedAt', 'closedBy'];

/** Lista de violaciones entre dos fotos del libro. */
function violations(prev: Map<string, Doc>, next: Map<string, Doc>): string[] {
  const out: string[] = [];
  for (const [id, before] of prev) {
    const after = next.get(id);
    if (!after) { out.push(`${id}: borrado`); continue; }
    for (const k of IMMUTABLE) {
      if (JSON.stringify(before[k]) !== JSON.stringify(after[k])) out.push(`${id}: cambió ${k}`);
    }
    if (before.status !== 'pending') {
      if (JSON.stringify(before) !== JSON.stringify(after)) out.push(`${id}: cambió tras cerrarse`);
      continue;
    }
    if (after.status === 'pending') {
      if (JSON.stringify(before) !== JSON.stringify(after)) out.push(`${id}: cambió sin cerrarse`);
      continue;
    }
    if (!['completed', 'superseded'].includes(after.status as string)) out.push(`${id}: estado ${after.status}`);
    for (const k of Object.keys(after)) {
      if (!IMMUTABLE.includes(k) && !CLOSING.includes(k) && JSON.stringify(before[k]) !== JSON.stringify(after[k])) {
        out.push(`${id}: cambió ${k} al cerrarse`);
      }
    }
  }
  return out;
}

async function booking(id: string, finalPrice: number) {
  await db.doc(`bookings/${id}`).set({ riderId: 'ana', status: 'completed', estimatedPrice: 100, finalPrice });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 10000, amountPaid: 10000,
  });
}
const setFinal = (id: string, finalPrice: number) => db.doc(`bookings/${id}`).update({ finalPrice });

beforeEach(clear);
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('libro de pagos de solo anexado (H4)', () => {
  it('diferencia final que cambia, cobro parcial y total del saldo, y devolución', async () => {
    let prev = await snapshot();
    const step = async (what: string, run: () => Promise<unknown>) => {
      await run();
      const next = await snapshot();
      expect({ what, problems: violations(prev, next) }).toEqual({ what, problems: [] });
      prev = next;
    };

    await booking('b1', 112.5);
    await step('A9: saldo de 12,50', () => reconcileFinalAmount(db, 'b1'));
    await step('A9: el importe final baja a 110', async () => { await setFinal('b1', 110); await reconcileFinalAmount(db, 'b1'); });
    await step('G2: cobro parcial', () => adminCollectBalance({ db }, ACTOR,
      { bookingId: 'b1', amount: 4, operationNumber: 'OP 1', method: 'manual_qr', reason: WHY }));
    await step('A9 tras el cobro: nada se rehace', () => reconcileFinalAmount(db, 'b1'));
    await step('G2: el resto', () => adminCollectBalance({ db }, ACTOR,
      { bookingId: 'b1', amount: 6, operationNumber: 'OP 2', method: 'manual_qr', reason: WHY }));

    await booking('b2', 80);
    await step('A9: devolución de 20', () => reconcileFinalAmount(db, 'b2'));
    await step('A9: la devolución cambia a 15', async () => { await setFinal('b2', 85); await reconcileFinalAmount(db, 'b2'); });
    const refundId = ((await db.doc('bookings/b2/payment/state').get()).data()!.refundFinalEntryId) as string;
    await step('A8: central registra la devolución', () => adminRecordRefund({ db }, ACTOR,
      { bookingId: 'b2', entryId: refundId, externalRef: 'DEV 1', reason: WHY }));

    // Sumas: lo completado es el dinero movido; lo pendiente, lo que queda.
    const entries = [...prev.values()];
    const sum = (f: (e: Doc) => boolean) => entries.filter(f).reduce((a, e) => a + Number(e.amount), 0);
    expect(sum((e) => e.bookingId === 'b1' && e.type === 'charge' && e.status === 'completed')).toBe(1000);
    expect(sum((e) => e.bookingId === 'b2' && e.type === 'refund' && e.status === 'completed')).toBe(1500);
    expect(sum((e) => e.status === 'pending')).toBe(0);
    expect((await db.doc('bookings/b1/payment/state').get()).data()).toMatchObject({ amountPaid: 11000, balanceDue: 0 });
  });

  it('un asiento con un id ya usado no se sobrescribe', async () => {
    await booking('b3', 112.5);
    await reconcileFinalAmount(db, 'b3');
    // Alguien intenta volver a crear el mismo asiento con otro importe.
    const { addLedger } = await import('../payment_model');
    await expect(db.runTransaction(async (tx) => {
      addLedger(tx, db, {
        type: 'charge', bookingId: 'b3', riderId: 'ana', amount: 1, method: null, actor: { role: 'system' },
        externalRef: null, reason: 'prueba', status: 'pending', createdAt: admin.firestore.Timestamp.now(),
      }, 'balance_b3');
    })).rejects.toThrow();
    expect((await db.doc('payments/balance_b3').get()).data()).toMatchObject({ amount: 1250 });
  });
});
