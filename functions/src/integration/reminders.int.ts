/**
 * Prompt 18, Parte A: recordatorios programados (A2–A4) contra el emulador,
 * con reloj simulado. Desfases, minutos y datos de PRUEBA, ficticios: los
 * de negocio los pone el responsable en config/ops.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { adminUpdateBooking } from '../admin_ops';
import { cancelBooking, releaseBooking } from '../cancellation';
import { adminForceNoShow, adminSetFlightInfo } from '../flight';
import { rescheduleRemindersOnBooking, rescheduleRemindersOnPayment, scheduledCleanup } from '../index';
import { applyWebhookEvent } from '../payment_card';
import { expirePayments } from '../payment_expiry';
import { adminConfirmPayment } from '../payment_manual';
import { readState, rescheduleReminders, runReminders } from '../reminders';
import { advanceBooking } from '../trip_flow';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const MIN = 60_000;
const ANCHOR = Date.UTC(2026, 10, 20, 18); // 14:00 en La Paz
let clock = ANCHOR - 5 * 60 * MIN;
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Motivo de prueba suficientemente largo';
const HERE = { lat: -17.6448, lng: -63.1353 };
// Desfases y minutos FICTICIOS.
const OPS = {
  reminderOffsetsMinutes: { rider: [120, 30], driver: [60, 15] },
  unassignedAlertMinutes: 90,
  paymentMethods: { manual_qr: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
};

let pushes: Array<{ tokens: string[]; title: string; body: string; data: Record<string, string> }> = [];
let failToken: string | null = null;
const push = async (tokens: string[], title: string, body: string, data: Record<string, string>) => {
  if (failToken && tokens.includes(failToken)) throw new Error('registration-token-not-registered');
  pushes.push({ tokens, title, body, data });
};
const rdeps = () => ({ db, now: () => clock, push });
const deps = () => ({ db, now: () => clock });

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'adminAlerts', 'admin_logs', 'payments', 'paymentOperations',
    'openRequests', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

/** Reserva FICTICIA de ana; pagada salvo que se diga lo contrario. */
async function booking(id: string, extra: Record<string, unknown> = {}, paid = true) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', driverId: null, status: 'pending', class: 'business', vehicleClass: 'business',
    serviceType: 'oneWay', estimatedPrice: 100, scheduledAt: ts(ANCHOR), createdAt: ts(clock), updatedAt: ts(clock),
    origin: { address: 'Origen (prueba)', coordinates: new admin.firestore.GeoPoint(HERE.lat, HERE.lng) },
    ...extra,
  });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: paid ? 'paid' : 'awaiting_payment', paymentMethod: paid ? 'manual_qr' : null,
    amountDue: 10000, amountPaid: paid ? 10000 : 0, paymentRef: `REF${id}`.toUpperCase().slice(0, 8),
    paidAt: paid ? ts(clock) : null, paymentDeadline: null, createdAt: ts(clock), updatedAt: ts(clock),
  });
  await sync(id);
}
/** Lo que hacen los disparadores tras cada escritura. */
const sync = (id: string) => rescheduleReminders(rdeps(), id);
const at = async (ms: number) => { clock = ms; return runReminders(rdeps()); };
const state = async (id: string) => readState((await db.doc(`bookings/${id}`).get()).data());
const inbox = async (uid: string) => (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) => d.data());
const alerts = async () => (await db.collection('adminAlerts').where('type', '==', 'booking_unassigned').get()).docs;
const keysTo = (uid: string) => pushes.filter((p) => p.tokens.includes(`tok-${uid}`)).map((p) => p.data.type);

beforeEach(async () => {
  await clear();
  clock = ANCHOR - 5 * 60 * MIN;
  pushes = [];
  failToken = null;
  for (const [uid, role, locale] of [['ana', 'rider', 'es'], ['luis', 'driver', 'es'], ['raul', 'driver', 'es']]) {
    await db.doc(`users/${uid}`).set({ role, isActive: true, locale, fcmTokens: [`tok-${uid}`] });
  }
  for (const uid of ['luis', 'raul']) {
    await db.doc(`driverProfiles/${uid}`).set({ userId: uid, documentsVerified: true, isAvailable: true, online: true });
  }
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('config/ops').set(OPS);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('A4: envíos', () => {
  it('sin configuración: no se envía nada y no hay nextAt', async () => {
    await db.doc('config/ops').set({});
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    expect((await state('b1')).nextAt).toBeNull();
    await at(ANCHOR - 10 * MIN);
    expect(pushes).toEqual([]);
    expect(await inbox('ana')).toEqual([]);
  });

  it('un recordatorio por desfase y persona, a su hora; nextAt avanza', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    expect((await state('b1')).nextAt).toBe(ANCHOR - 120 * MIN);
    await at(ANCHOR - 121 * MIN);
    expect(pushes).toEqual([]);
    await at(ANCHOR - 120 * MIN);
    expect(keysTo('ana')).toEqual(['reminder_rider']);
    expect((await state('b1')).nextAt).toBe(ANCHOR - 60 * MIN);
    await at(ANCHOR - 60 * MIN);
    await at(ANCHOR - 30 * MIN);
    await at(ANCHOR - 15 * MIN);
    expect(keysTo('ana')).toEqual(['reminder_rider', 'reminder_rider']);
    expect(keysTo('luis')).toEqual(['reminder_driver', 'reminder_driver']);
    expect((await state('b1')).sent.sort()).toEqual(['driver:15', 'driver:60', 'rider:120', 'rider:30']);
    expect((await state('b1')).nextAt).toBeNull();
    // Sin datos personales en la pantalla bloqueada: solo la hora.
    for (const p of pushes) expect(`${p.title} ${p.body}`).not.toMatch(/Origen|ana|luis|REF/i);
  });

  it('reintento: dos pasadas a la misma hora no duplican push ni bandeja', async () => {
    await booking('b1');
    await at(ANCHOR - 120 * MIN);
    await at(ANCHOR - 120 * MIN);
    await sync('b1');
    await at(ANCHOR - 119 * MIN);
    expect(keysTo('ana')).toEqual(['reminder_rider']);
    expect(await inbox('ana')).toHaveLength(1);
  });

  it('cambio de scheduledAt tras enviar el primero: no se repite; los vencidos por el cambio no salen de golpe', async () => {
    await booking('b1');
    await at(ANCHOR - 120 * MIN);
    // La recogida se adelanta 100 min: el de 30 min antes ya «pasó» (no sale).
    await db.doc('bookings/b1').update({ scheduledAt: ts(ANCHOR - 100 * MIN) });
    await sync('b1');
    expect((await state('b1')).skipped).toContain('rider:30');
    await at(ANCHOR - 100 * MIN);
    expect(keysTo('ana')).toEqual(['reminder_rider']);
  });

  it('cambio de scheduledAt más tarde: el pendiente sigue la hora nueva', async () => {
    await booking('b1');
    await at(ANCHOR - 120 * MIN);
    await db.doc('bookings/b1').update({ scheduledAt: ts(ANCHOR + 60 * MIN) });
    await sync('b1');
    // Lo primero pendiente es la alerta de «sin chófer» (90 min antes de la
    // hora nueva); el de 30 min antes del pasajero, a ANCHOR + 30.
    expect((await state('b1')).nextAt).toBe(ANCHOR - 30 * MIN);
    await at(ANCHOR - 30 * MIN);
    expect(keysTo('ana')).toHaveLength(1);
    await at(ANCHOR + 30 * MIN);
    expect(keysTo('ana')).toHaveLength(2);
  });

  it('cancelada entre dos recordatorios: el segundo no sale', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await at(ANCHOR - 120 * MIN);
    await cancelBooking(deps(), 'ana', { bookingId: 'b1', reason: 'changed_plans' });
    await sync('b1');
    expect((await state('b1')).nextAt).toBeNull();
    await at(ANCHOR - 15 * MIN);
    expect(keysTo('ana')).toEqual(['reminder_rider']);
    expect(keysTo('luis')).toEqual([]);
  });

  it('chófer liberado: el nuevo chófer solo recibe los pendientes', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await at(ANCHOR - 60 * MIN);
    expect(keysTo('luis')).toEqual(['reminder_driver']);
    await releaseBooking(deps(), 'luis', { bookingId: 'b1', reason: 'vehicle_issue', location: HERE });
    await sync('b1');
    clock = ANCHOR - 40 * MIN;
    await adminUpdateBooking(deps(), JEFA, { action: 'assign', bookingId: 'b1', driverId: 'raul', reason: REASON });
    await sync('b1');
    expect((await state('b1')).skipped).toContain('driver:60');
    await at(ANCHOR - 15 * MIN);
    expect(keysTo('raul')).toEqual(['reminder_driver']);
    expect(keysTo('luis')).toEqual(['reminder_driver']);
  });

  it('reserva pagada sin chófer: una alerta alta a central, una sola vez', async () => {
    await booking('b1');
    await at(ANCHOR - 91 * MIN);
    expect(await alerts()).toHaveLength(0);
    await at(ANCHOR - 90 * MIN);
    await at(ANCHOR - 80 * MIN);
    const a = await alerts();
    expect(a).toHaveLength(1);
    expect(a[0].data()).toMatchObject({ severity: 'high', bookingId: 'b1', resolved: false });
  });

  it('sin la clave unassignedAlertMinutes: no hay alerta', async () => {
    await db.doc('config/ops').set({ reminderOffsetsMinutes: OPS.reminderOffsetsMinutes });
    await booking('b1');
    await at(ANCHOR - 10 * MIN);
    expect(await alerts()).toHaveLength(0);
  });

  it('una reserva sin pagar no recuerda ni alerta', async () => {
    await booking('b1', {}, false);
    await at(ANCHOR - 10 * MIN);
    expect(pushes).toEqual([]);
    expect(await alerts()).toHaveLength(0);
  });

  it('idioma por usuario', async () => {
    await db.doc('users/ana').update({ locale: 'en' });
    await db.doc('users/luis').update({ locale: 'pt' });
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await at(ANCHOR - 120 * MIN);
    await at(ANCHOR - 60 * MIN);
    expect(pushes.find((p) => p.tokens.includes('tok-ana'))!.title).toBe('Your trip is coming up');
    expect(pushes.find((p) => p.tokens.includes('tok-luis'))!.title).toBe('Você tem uma viagem em breve');
    expect((await inbox('ana'))[0].locale).toBe('en');
  });

  it('token inválido: no corta el resto; la bandeja se escribe igual', async () => {
    failToken = 'tok-ana';
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await booking('b2', { riderId: 'ana', driverId: 'raul', status: 'confirmed' });
    await at(ANCHOR - 60 * MIN);
    expect(await inbox('ana')).toHaveLength(2);
    expect(keysTo('luis')).toEqual(['reminder_driver']);
    expect(keysTo('raul')).toEqual(['reminder_driver']);
  });

  it('interruptor global apagado: sin push, la bandeja sí', async () => {
    await db.doc('config/global').set({ pushNotificationsEnabled: false });
    await booking('b1');
    await at(ANCHOR - 120 * MIN);
    expect(pushes).toEqual([]);
    expect(await inbox('ana')).toHaveLength(1);
    expect((await state('b1')).sent).toEqual(['rider:120']);
  });
});

describe('A3: caminos que recalculan nextAt', () => {
  it('1. createBooking (reserva nueva, sin pagar): el disparador la registra sin envíos', async () => {
    await db.doc('bookings/n1').set({ riderId: 'ana', status: 'pending', driverId: null, scheduledAt: ts(ANCHOR) });
    const snap = await db.doc('bookings/n1').get();
    await (rescheduleRemindersOnBooking as unknown as Runnable).run({ data: { before: snap, after: snap }, params: { bookingId: 'n1' } });
    const s = await state('n1');
    expect(s.anchor).toBe(ANCHOR);
    expect(s.nextAt).toBeNull();
  });

  it('2. adminConfirmPayment (pago confirmado): el disparador del pago activa los del pasajero', async () => {
    await booking('b1', {}, false);
    await db.doc('bookings/b1/payment/state').update({ paymentStatus: 'awaiting_payment', paymentMethod: 'manual_qr',
      riderReportedAt: ts(clock) });
    await adminConfirmPayment(deps(), JEFA, { bookingId: 'b1', operationNumber: 'OP 1', amountReceived: 100, reason: REASON });
    await (rescheduleRemindersOnPayment as unknown as Runnable).run({ data: {}, params: { bookingId: 'b1' } });
    expect((await state('b1')).nextAt).toBe(ANCHOR - 120 * MIN);
  });

  it('3. el chófer acepta (escritura de la app, permitida por las reglas)', async () => {
    await booking('b1');
    await db.doc('bookings/b1').update({ driverId: 'luis', status: 'confirmed', updatedAt: ts(clock) });
    await sync('b1');
    expect((await state('b1')).driverFor).toBe('luis');
  });

  it('4. adminUpdateBooking assign', async () => {
    await booking('b1');
    await adminUpdateBooking(deps(), JEFA, { action: 'assign', bookingId: 'b1', driverId: 'luis', reason: REASON });
    await sync('b1');
    expect((await state('b1')).driverFor).toBe('luis');
  });

  it('5. adminUpdateBooking reasignación: claves del chófer de cero para el nuevo', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await at(ANCHOR - 60 * MIN);
    clock = ANCHOR - 50 * MIN;
    await adminUpdateBooking(deps(), JEFA, { action: 'assign', bookingId: 'b1', driverId: 'raul', reason: REASON });
    await sync('b1');
    const s = await state('b1');
    expect(s.driverFor).toBe('raul');
    expect(s.sent).not.toContain('driver:60');
    expect(s.skipped).toContain('driver:60');
  });

  it('6. releaseBooking: sin chófer, sin recordatorios de chófer', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await releaseBooking(deps(), 'luis', { bookingId: 'b1', reason: 'vehicle_issue', location: HERE });
    await sync('b1');
    expect((await state('b1')).driverFor).toBeNull();
  });

  it('7. cancelBooking: nada pendiente', async () => {
    await booking('b1');
    await cancelBooking(deps(), 'ana', { bookingId: 'b1', reason: 'changed_plans' });
    await sync('b1');
    expect((await state('b1')).nextAt).toBeNull();
  });

  it('8. adminUpdateBooking cancel: nada pendiente', async () => {
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    await adminUpdateBooking(deps(), JEFA, { action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'platform' });
    await sync('b1');
    expect((await state('b1')).nextAt).toBeNull();
  });

  it('9. cambio de readyAt (adminSetFlightInfo): scheduledAt y nextAt siguen al vuelo', async () => {
    await db.doc('config/ops').set({ ...OPS,
      flightExitMinutes: { domestic: { noCheckedBag: 10, checkedBag: 25 }, international: { noCheckedBag: 30, checkedBag: 50 } } });
    await booking('b1', { readyAt: ts(ANCHOR), flightActive: true,
      flight: { airportCode: 'VVI', flightType: 'domestic', airline: null, flightNumber: 'ZZ1', flightDate: '2026-11-20',
        scheduledArrival: ts(ANCHOR - 25 * MIN), hasCheckedBag: true, estimatedArrival: null, actualArrival: null,
        status: 'scheduled', source: 'passenger', lastObservedAt: null, lastChangeAt: ts(clock), dataQuality: 'none',
        manualLock: false } });
    await adminSetFlightInfo(deps(), JEFA, { bookingId: 'b1', status: 'delayed',
      estimatedArrival: ANCHOR + 35 * MIN, reason: 'Confirmado con la aerolínea (prueba)' });
    await sync('b1');
    expect((await state('b1')).nextAt).toBe(ANCHOR + 60 * MIN - 120 * MIN);
  });

  it('10. advanceBooking a driver_arrived: se acaban los recordatorios', async () => {
    await booking('b1', { driverId: 'luis', status: 'driver_arriving' });
    expect((await state('b1')).nextAt).not.toBeNull();
    await advanceBooking({ db, pickupSecret: 'secreto', now: () => clock }, 'luis',
      { bookingId: 'b1', to: 'driver_arrived', location: HERE });
    await sync('b1');
    expect((await state('b1')).nextAt).toBeNull();
  });
});

describe('A3: caminos que antes solo cubría el disparador', () => {
  it('11. adminForceNoShow: tras «no se presentó», nada pendiente', async () => {
    await db.doc('config/ops').set({ ...OPS, cancellationPolicy: { stages: [{ fromStatus: 'no_show', percent: 0 }],
      noShowWaitMinutes: 15 } });
    await booking('b1', { driverId: 'luis', status: 'confirmed' });
    expect((await state('b1')).nextAt).not.toBeNull();
    await db.doc('bookings/b1').update({ status: 'driver_arrived', arrivedAt: ts(clock) });
    await adminForceNoShow(deps(), JEFA, { bookingId: 'b1', reason: REASON });
    await sync('b1');
    expect((await db.doc('bookings/b1').get()).data()!.status).toBe('no_show');
    expect((await state('b1')).nextAt).toBeNull();
    await at(ANCHOR - 10 * MIN);
    expect(pushes).toEqual([]);
  });

  it('12. scheduledCleanup: la pagada sin chófer que vence se cancela y su alerta pendiente desaparece', async () => {
    const past = Date.now() - 2 * 60 * MIN;
    clock = past - 5 * 60 * MIN;
    await booking('b1', { scheduledAt: ts(past) });
    expect((await state('b1')).nextAt).not.toBeNull();
    await (scheduledCleanup as unknown as Runnable).run({});
    clock = Date.now();
    await sync('b1');
    expect((await db.doc('bookings/b1').get()).data()!.status).toBe('cancelled');
    expect((await state('b1')).nextAt).toBeNull();
  });

  it('13. expirePayments: la reserva sin pagar que vence queda cancelada y sin nada pendiente', async () => {
    await db.doc('config/ops').set({ ...OPS, paymentWindowMinutes: 30 });
    await booking('b1', {}, false);
    await db.doc('bookings/b1/payment/state').update({ paymentDeadline: ts(clock - MIN) });
    expect((await expirePayments(deps())).expired).toEqual(['b1']);
    await (rescheduleRemindersOnPayment as unknown as Runnable).run({ data: {}, params: { bookingId: 'b1' } });
    await sync('b1');
    expect((await db.doc('bookings/b1').get()).data()!.status).toBe('cancelled');
    expect((await state('b1')).nextAt).toBeNull();
  });

  it('14. pago con tarjeta (webhook del proveedor): se programan los del pasajero', async () => {
    await db.doc('config/ops').set({ ...OPS, paymentMethods: { card: true },
      paymentInstructions: { card: { provider: 'stripe' } } });
    await booking('b1', {}, false);
    await db.doc('bookings/b1/payment/state').update({ paymentMethod: 'card', providerChargeRef: 'ch_ficticio' });
    expect((await state('b1')).nextAt).toBeNull();
    const r = await applyWebhookEvent(deps(), { type: 'charge.succeeded', bookingId: 'b1', amount: 10000,
      externalRef: 'ch_ficticio' });
    expect(r).toMatchObject({ applied: true, paymentStatus: 'paid' });
    await (rescheduleRemindersOnPayment as unknown as Runnable).run({ data: {}, params: { bookingId: 'b1' } });
    expect((await state('b1')).nextAt).toBe(ANCHOR - 120 * MIN);
  });
});

