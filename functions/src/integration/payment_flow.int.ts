/**
 * Pagos A13: el flujo entero contra el emulador, y el índice de los tests
 * que pide A13. Importes, porcentajes y datos de cobro de PRUEBA, ficticios.
 *
 * | Caso de A13                                   | Dónde                                              |
 * |-----------------------------------------------|----------------------------------------------------|
 * | No se ofrece a chóferes sin pago              | payment_dispatch.int.ts, bookings.rules.ts, aquí    |
 * | Pago confirmado una sola vez                  | payment_manual.int.ts, payment_card.int.ts, aquí    |
 * | Importe del cliente ignorado                  | payment_dispatch, payment_card, cancel_booking, aquí|
 * | Expiración con reloj simulado                 | payment_expiry.int.ts                               |
 * | Cancelación en cada etapa, redondeo y tope    | cancel_booking.int.ts, cancellation.test.ts         |
 * | Causa del chófer = 0 %                        | payment_settle.int.ts, no_show.int.ts               |
 * | Reembolso doble rechazado                     | payment_refund.int.ts, aquí                         |
 * | Diferencia final                              | payment_final.int.ts                                |
 * | Usuario ajeno                                 | payment_manual, payment_card, cancel_booking, aquí  |
 * | Sin política = 0 %                            | cancel_booking.int.ts, cancellation.test.ts         |
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { randomUUID } from 'crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import { acceptBooking } from '../index';
import { createBooking } from '../booking_service';
import { startPayment } from '../payment_card';
import { adminConfirmPayment, markPaymentSent } from '../payment_manual';
import { cancelBooking } from '../cancellation';
import { adminRecordRefund } from '../payment_refund';
import { advanceBooking } from '../trip_flow';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.UTC(2026, 9, 26, 12);
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 12000 }] }) })) as unknown as typeof fetch;
const OPS = {
  paymentMethods: { manual_qr: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
  paymentWindowMinutes: 30,
  cancellationPolicy: { stages: [{ fromStatus: 'driver_arriving', percent: 25 }], noShowWaitMinutes: 10 },
};

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'vehicles', 'config', 'pricingRules', 'openRequests', 'adminAlerts', 'payments',
    'paymentRefs', 'paymentOperations', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/beto').set({ role: 'rider', isActive: true });
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: true, online: true, documentsVerified: true });
  await db.doc('config/ops').set(OPS);
  await db.doc('pricingRules/business_oneWay').set({
    vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true,
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('flujo completo: reservar, pagar, confirmar, aceptar, cancelar y devolver', () => {
  it('cada paso solo es posible cuando toca, y los importes son siempre los del servidor', async () => {
    // 1. Reserva: 86 Bs (50 + 12 km × 3), aunque el cliente diga 500.
    const r = await createBooking({ db, mapsKey: 'k', fetchFn: routesOk, now: () => NOW }, 'ana', {
      origin: { name: '', address: 'Calle 1', lat: -17.7834, lng: -63.1821 },
      destination: { name: '', address: 'Av. 2', lat: -17.765, lng: -63.196 },
      scheduledAt: NOW + 2 * 3600_000, vehicleClass: 'business', serviceType: 'oneWay',
      passengerCount: 1, luggageCount: 0, requestId: randomUUID(), quotedPrice: 500, channel: 'native',
    });
    const id = r.bookingId;
    expect(r).toMatchObject({ amountDue: 8600, paymentStatus: 'awaiting_payment', paymentDeadline: NOW + 30 * 60_000 });

    // 2. Ningún chófer la puede tomar aún.
    const accept = () => (acceptBooking as unknown as Runnable).run({ auth: { uid: 'luis', token: {} }, app: {}, data: { bookingId: id } });
    expect(await accept()).toEqual({ accepted: false, reason: 'not_paid' });

    // 3. Instrucciones del pago manual; otro pasajero no puede ni verlas ni avisar.
    const deps = { db, now: () => NOW + 60_000 };
    await expect(startPayment(deps, 'ana', { bookingId: id, method: 'manual_qr' })).resolves.toMatchObject({ amountDue: 8600 });
    expect(await reason(startPayment(deps, 'beto', { bookingId: id, method: 'manual_qr' }))).toBe('not_owner');
    expect(await reason(markPaymentSent(deps, 'beto', { bookingId: id }))).toBe('not_owner');
    await markPaymentSent(deps, 'ana', { bookingId: id, operationNumber: 'OP 77' });

    // 4. Central confirma con el importe exacto; una segunda vez, no.
    const confirm = (amountReceived: number, op = 'OP 77') => adminConfirmPayment(deps, jefa,
      { bookingId: id, operationNumber: op, amountReceived, reason: 'Ingreso visto en el extracto' });
    expect(await reason(confirm(80))).toBe('amount_mismatch');
    await expect(confirm(86)).resolves.toMatchObject({ paymentStatus: 'paid', dispatched: true });
    expect(await reason(confirm(86, 'OP 78'))).toBe('already_paid');

    // 5. Ahora sí: el chófer la acepta y va en camino.
    expect(await accept()).toEqual({ accepted: true });
    await advanceBooking({ db, now: () => NOW + 5 * 60_000 }, 'luis', { bookingId: id, to: 'driver_arriving' });

    // 6. El pasajero cancela en camino: 25 % de lo pagado, hacia abajo; no puede bajarlo.
    const cdeps = { db, now: () => NOW + 10 * 60_000 };
    await expect(cancelBooking(cdeps, 'ana', { bookingId: id, dryRun: true })).resolves.toMatchObject({ retained: 2150, refund: 6450 });
    expect(await reason(cancelBooking(cdeps, 'ana', { bookingId: id, acceptedFee: 1 }))).toBe('cancellation_fee_changed');
    await cancelBooking(cdeps, 'ana', { bookingId: id, acceptedFee: 21.5 });
    expect(await doc(`bookings/${id}/payment/state`)).toMatchObject({
      paymentStatus: 'refund_pending', amountPaid: 8600, amountRetained: 2150, refundDue: 6450,
    });

    // 7. Central registra la devolución, una sola vez.
    const refund = () => adminRecordRefund(deps, jefa, { bookingId: id, externalRef: 'DEV 1', reason: 'Devuelto por transferencia' });
    await expect(refund()).resolves.toEqual({ paymentStatus: 'partially_refunded', amount: 6450 });
    expect(await reason(refund())).toBe('already_refunded');

    // Asientos: cobro, retención y devolución; nada en la reserva que lea el chófer.
    const ledger = (await db.collection('payments').where('bookingId', '==', id).get()).docs.map((d) => [d.data().type, d.data().amount]);
    expect(ledger.sort()).toEqual([['charge', 8600], ['fee_retained', 2150], ['refund', 6450]]);
    const b = (await doc(`bookings/${id}`))!;
    for (const k of ['amountPaid', 'amountRetained', 'refundDue', 'cancellationFee', 'paymentStatus']) expect(b).not.toHaveProperty(k);
  });
});
