/**
 * SOS e incidentes contra el emulador de Firestore, con los handlers reales
 * (el emulador de Functions no corre en el contenedor). Push simulado y
 * reloj controlado.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { HttpsError } from 'firebase-functions/v2/https';
import {
  acknowledgeIncident,
  cancelIncident,
  closeIncident,
  escalateIncidents,
  IncidentDeps,
  purgeIncidentLocations,
  raiseIncident,
  RATE_LIMIT,
} from '../incidents';
import {
  acknowledgeIncident as acknowledgeIncidentFn,
  closeIncident as closeIncidentFn,
  raiseIncident as raiseIncidentFn,
} from '../index';

const db = admin.firestore();
let clock = Date.UTC(2026, 9, 23, 15, 0, 0);
const push = jest.fn(async (..._args: unknown[]) => undefined);
const deps = (): IncidentDeps => ({ db, now: () => clock, push: push as unknown as IncidentDeps['push'] });
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function failure(p: Promise<unknown>): Promise<{ code: string; reason?: string }> {
  try {
    await p;
  } catch (e) {
    const err = e as HttpsError;
    return { code: err.code, reason: (err.details as { reason?: string } | undefined)?.reason };
  }
  throw new Error('se esperaba un error');
}

async function clear(): Promise<void> {
  for (const col of ['bookings', 'incidents', 'incidentRateLimits', 'adminAlerts', 'admin_logs', 'users', 'config']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

async function booking(id: string, status: string) {
  await db.doc(`bookings/${id}`).set({ riderId: 'ana', driverId: 'chofer', status, estimatedPrice: 100 });
}

const incident = async (id: string) => (await db.doc(`incidents/${id}`).get()).data()!;
const incidentEvents = async (id: string) =>
  (await db.collection(`incidents/${id}/events`).get()).docs.map((d) => d.data().type).sort();
const alertTypes = async () => (await db.collection('adminAlerts').get()).docs.map((d) => d.data().type).sort();
const state = async (bookingId: string) => (await db.doc(`bookings/${bookingId}/adminOnly/incident`).get()).data();

beforeEach(async () => {
  clock = Date.UTC(2026, 9, 23, 15, 0, 0);
  push.mockClear();
  sendEachForMulticast.mockClear();
  await clear();
  await db.doc('users/ana').set({ role: 'rider' });
  await db.doc('users/chofer').set({ role: 'driver', isActive: true });
  await db.doc('users/beto').set({ role: 'rider' });
  await db.doc('users/jefa').set({ role: 'admin', fcmTokens: ['tok-jefa'] });
  await db.doc('users/otra').set({ role: 'admin', fcmTokens: ['tok-otra'] });
  await booking('b1', 'in_progress');
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('raiseIncident', () => {
  it('disparo: incidente abierto, alerta alta, push a todos los admin y bandera solo para el admin', async () => {
    const res = await raiseIncident(deps(), 'ana', { bookingId: 'b1', location: { lat: -17.78, lng: -63.18 } });
    expect(res).toMatchObject({ status: 'open', count: 1, alreadyOpen: false, rateLimited: false });
    const inc = await incident(res.incidentId);
    expect(inc).toMatchObject({ bookingId: 'b1', reporterId: 'ana', reporterRole: 'rider', status: 'open', count: 1 });
    expect((await db.collection(`incidents/${res.incidentId}/locations`).get()).size).toBe(1);
    const alerts = (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({ type: 'incident', severity: 'high', incidentId: res.incidentId })]);
    expect(push).toHaveBeenCalledTimes(1);
    expect(push.mock.calls[0][0]).toEqual(['tok-jefa', 'tok-otra']);
    // La reserva no cambia: el flujo sigue.
    expect((await db.doc('bookings/b1').get()).data()).toEqual({ riderId: 'ana', driverId: 'chofer', status: 'in_progress', estimatedPrice: 100 });
    expect(await state('b1')).toMatchObject({ incidentOpen: true, activeIncidentId: res.incidentId });
  });

  it('el chófer también puede; el pasajero no recibe nada ni hay push a la contraparte', async () => {
    await db.doc('users/ana').set({ role: 'rider', fcmTokens: ['tok-ana'] });
    const res = await raiseIncident(deps(), 'chofer', { bookingId: 'b1' });
    expect((await incident(res.incidentId)).reporterRole).toBe('driver');
    expect(push.mock.calls.flatMap((c) => c[0] as string[])).not.toContain('tok-ana');
  });

  it('repetición: mismo incidente, contador, sin otro push', async () => {
    const a = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    const b = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    expect(b).toMatchObject({ incidentId: a.incidentId, alreadyOpen: true, count: 2 });
    expect((await db.collection('incidents').get()).size).toBe(1);
    expect(push).toHaveBeenCalledTimes(1);
    expect(await incidentEvents(a.incidentId)).toEqual(['raised', 'repeated']);
  });

  it('límite de 5 por hora: con uno abierto devuelve ese; sin abierto, rate_limited', async () => {
    const first = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    for (let i = 1; i < RATE_LIMIT; i++) await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    const over = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    expect(over).toMatchObject({ incidentId: first.incidentId, rateLimited: true, count: RATE_LIMIT });
    await cancelIncident(deps(), 'ana', { incidentId: first.incidentId });
    expect(await failure(raiseIncident(deps(), 'ana', { bookingId: 'b1' })))
      .toEqual({ code: 'resource-exhausted', reason: 'rate_limited' });
    clock += 60 * 60 * 1000 + 1;
    expect((await raiseIncident(deps(), 'ana', { bookingId: 'b1' })).alreadyOpen).toBe(false);
  });

  it('fuera de la ventana (confirmada o completada) no se crea', async () => {
    for (const s of ['confirmed', 'completed', 'cancelled', 'pending']) {
      await booking('b2', s);
      expect(await failure(raiseIncident(deps(), 'ana', { bookingId: 'b2' })))
        .toEqual({ code: 'failed-precondition', reason: 'outside_window' });
    }
    for (const s of ['driver_arriving', 'driver_arrived', 'verified']) {
      await booking(`ok-${s}`, s);
      expect((await raiseIncident(deps(), 'ana', { bookingId: `ok-${s}` })).status).toBe('open');
    }
  });

  it('usuario ajeno, reserva inexistente, sin sesión o datos inválidos', async () => {
    expect(await failure(raiseIncident(deps(), 'beto', { bookingId: 'b1' }))).toEqual({ code: 'permission-denied', reason: 'not_in_booking' });
    expect(await failure(raiseIncident(deps(), 'ana', { bookingId: 'nada' }))).toEqual({ code: 'not-found', reason: 'booking_not_found' });
    expect((await failure(raiseIncident(deps(), undefined, { bookingId: 'b1' }))).code).toBe('unauthenticated');
    expect((await failure(raiseIncident(deps(), 'ana', { bookingId: 'b1', status: 'closed' }))).reason).toBe('invalid_request');
    expect((await failure(raiseIncident(deps(), 'ana', { bookingId: 'b1', location: { lat: 300, lng: 0 } }))).reason).toBe('invalid_request');
    expect((await db.collection('incidents').get()).size).toBe(0);
  });

  it('sin tokens de admin el incidente se crea igual', async () => {
    await db.doc('users/jefa').set({ role: 'admin' });
    await db.doc('users/otra').set({ role: 'admin' });
    const res = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    expect(res.status).toBe('open');
    expect(push).not.toHaveBeenCalled();
  });

  it('un fallo del push no hace fallar el SOS', async () => {
    push.mockRejectedValueOnce(new Error('fcm caído'));
    expect((await raiseIncident(deps(), 'ana', { bookingId: 'b1' })).status).toBe('open');
  });

  it('la callable desplegada usa FCM sin depender del interruptor de push', async () => {
    await db.doc('config/global').set({ pushNotificationsEnabled: false });
    await (raiseIncidentFn as unknown as Runnable).run({ auth: { uid: 'ana' }, data: { bookingId: 'b1' } });
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
  });
});

describe('cancelIncident (falsa alarma)', () => {
  it('quien lo disparó lo cancela; queda registrado y el admin recibe el aviso', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    expect(await cancelIncident(deps(), 'ana', { incidentId })).toEqual({ status: 'cancelled_by_reporter', alreadyCancelled: false });
    const inc = await incident(incidentId);
    expect(inc).toMatchObject({ status: 'cancelled_by_reporter', cancelledByReporter: true, locationRetention: 'not_configured' });
    expect(await alertTypes()).toEqual(['incident', 'incident_cancelled']);
    expect(push).toHaveBeenCalledTimes(2);
    expect(await state('b1')).toMatchObject({ incidentOpen: false, activeIncidentId: null });
    // Repetirlo no duplica nada.
    expect((await cancelIncident(deps(), 'ana', { incidentId })).alreadyCancelled).toBe(true);
    expect(push).toHaveBeenCalledTimes(2);
  });

  it('ni la contraparte ni un tercero lo cancelan', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    for (const uid of ['chofer', 'beto']) {
      expect(await failure(cancelIncident(deps(), uid, { incidentId }))).toEqual({ code: 'permission-denied', reason: 'not_reporter' });
    }
    expect((await incident(incidentId)).status).toBe('open');
  });
});

describe('acknowledgeIncident y closeIncident (admin)', () => {
  it('reconocer y cerrar con nota: auditoría en el servidor', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    clock += 45 * 1000;
    expect(await acknowledgeIncident(deps(), jefa, { incidentId })).toEqual({ status: 'acknowledged', alreadyAcknowledged: false });
    expect(await acknowledgeIncident(deps(), jefa, { incidentId })).toEqual({ status: 'acknowledged', alreadyAcknowledged: true });
    await closeIncident(deps(), jefa, { incidentId, note: 'Llamé al pasajero: todo en orden.' });
    expect(await incident(incidentId)).toMatchObject({ status: 'closed', closedBy: 'jefa', closeNote: 'Llamé al pasajero: todo en orden.' });
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data().action).sort();
    expect(logs).toEqual(['acknowledge_incident', 'close_incident']);
    expect(await incidentEvents(incidentId)).toEqual(['acknowledged', 'closed', 'raised']);
    expect(await state('b1')).toMatchObject({ incidentOpen: false });
  });

  it('cerrar sin nota (o con menos de 10 caracteres) no hace nada', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    for (const data of [{ incidentId }, { incidentId, note: '' }, { incidentId, note: '   corta   ' }]) {
      expect((await failure(closeIncident(deps(), jefa, data))).reason).toBe('invalid_request');
    }
    expect((await incident(incidentId)).status).toBe('open');
  });

  it('un incidente cancelado por quien lo disparó también se cierra con nota', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    await cancelIncident(deps(), 'ana', { incidentId });
    expect((await failure(acknowledgeIncident(deps(), jefa, { incidentId }))).reason).toBe('not_open');
    await closeIncident(deps(), jefa, { incidentId, note: 'Confirmado por teléfono: falsa alarma.' });
    expect(await incident(incidentId)).toMatchObject({ status: 'closed', cancelledByReporter: true });
  });

  it('solo un admin: las callables desplegadas rechazan a pasajero y chófer', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    for (const uid of ['ana', 'chofer']) {
      expect((await failure((acknowledgeIncidentFn as unknown as Runnable).run({ auth: { uid, token: {} }, data: { incidentId } }))).code)
        .toBe('permission-denied');
      expect((await failure((closeIncidentFn as unknown as Runnable)
        .run({ auth: { uid, token: {} }, data: { incidentId, note: 'Nota suficientemente larga' } }))).code).toBe('permission-denied');
    }
    expect((await incident(incidentId)).status).toBe('open');
  });

  it('incidente inexistente', async () => {
    expect((await failure(acknowledgeIncident(deps(), jefa, { incidentId: 'nada' }))).code).toBe('not-found');
  });

  it('cerrado: deja de admitir ubicaciones y se anota la retención configurada', async () => {
    await db.doc('config/global').set({ incidentLocationRetentionDays: 30 });
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1', location: { lat: -17.7, lng: -63.1 } });
    await closeIncident(deps(), jefa, { incidentId, note: 'Resuelto con el pasajero.' });
    const inc = await incident(incidentId);
    expect(inc.locationRetentionDays).toBe(30);
    expect((inc.deleteLocationsAfter as admin.firestore.Timestamp).toMillis()).toBe(clock + 30 * 86400000);
    // Antes del plazo no se borra; después, sí.
    expect(await purgeIncidentLocations(deps())).toEqual([]);
    clock += 30 * 86400000 + 1;
    expect(await purgeIncidentLocations(deps())).toEqual([incidentId]);
    expect((await db.collection(`incidents/${incidentId}/locations`).get()).size).toBe(0);
    expect((await incident(incidentId)).locationsPurged).toBe(true);
  });
});

describe('escalada (reloj simulado)', () => {
  it('sin reconocer a los 120 s: reenvía alerta y push; repite cada 120 s', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    push.mockClear();
    clock += 119 * 1000;
    expect(await escalateIncidents(deps())).toEqual([]);
    clock += 1000;
    expect(await escalateIncidents(deps())).toEqual([incidentId]);
    expect((await incident(incidentId)).escalation.count).toBe(1);
    expect(push).toHaveBeenCalledTimes(1);
    clock += 60 * 1000;
    expect(await escalateIncidents(deps())).toEqual([]);
    clock += 60 * 1000;
    expect(await escalateIncidents(deps())).toEqual([incidentId]);
    expect((await incident(incidentId)).escalation.count).toBe(2);
    expect((await alertTypes()).filter((t) => t === 'incident_escalated')).toHaveLength(2);
  });

  it('con los tiempos de config/global', async () => {
    await db.doc('config/global').set({ incidentAckSeconds: 30, incidentEscalateEverySeconds: 10 });
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    clock += 30 * 1000;
    expect(await escalateIncidents(deps())).toEqual([incidentId]);
    clock += 10 * 1000;
    expect(await escalateIncidents(deps())).toEqual([incidentId]);
  });

  it('reconocido: ya no escala', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    await acknowledgeIncident(deps(), jefa, { incidentId });
    clock += 10 * 60 * 1000;
    expect(await escalateIncidents(deps())).toEqual([]);
    expect((await incident(incidentId)).escalation.count).toBe(0);
  });

  it('cancelado por quien lo disparó: no escala', async () => {
    const { incidentId } = await raiseIncident(deps(), 'ana', { bookingId: 'b1' });
    await cancelIncident(deps(), 'ana', { incidentId });
    clock += 10 * 60 * 1000;
    expect(await escalateIncidents(deps())).toEqual([]);
  });
});
