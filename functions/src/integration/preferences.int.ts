/**
 * Preferencias del pasajero (A1, A2, A7) contra el emulador: updatePreferences
 * guarda las del perfil y createBooking deja una copia saneada por reserva
 * en bookings/{id}/driverView/preferences, en la misma transacción.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import { randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
// Inicializa Firebase como los demás tests de integración.
import '../index';
import { BookingDeps, createBooking } from '../booking_service';
import { preferenceOptions, updatePreferences } from '../preferences';

const db = admin.firestore();
const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 12000 }] }) })) as unknown as typeof fetch;
const deps = (): BookingDeps => ({ db, mapsKey: 'clave-de-prueba', fetchFn: routesOk });

const SCZ = { name: '', address: 'Calle Exacta 123', lat: -17.7834, lng: -63.1821 };
const EQUIPETROL = { name: 'Equipetrol', address: 'Av. Exacta 456', lat: -17.765, lng: -63.196 };
const HOST = 'music.example.com';
const URL_OK = `https://${HOST}/lista/1`;

const trip = (over: Record<string, unknown> = {}) => ({
  origin: SCZ, destination: EQUIPETROL, scheduledAt: Date.now() + 2 * 60 * 60 * 1000,
  vehicleClass: 'business', serviceType: 'oneWay', passengerCount: 1, luggageCount: 1,
  requestId: randomUUID(), channel: 'native', ...over,
});

const TRIP_PREFS = {
  preferredDriverLanguages: ['en', 'es'], cabinTemperature: 'cool', conversation: 'quiet',
  musicStyle: 'jazz', playlistUrl: URL_OK, needs: ['child_seat'], note: 'Llevo\nun carrito',
};

async function reason(p: Promise<unknown>): Promise<{ code: string; reason: string; fields?: string[] }> {
  try {
    await p;
  } catch (e) {
    const err = e as HttpsError;
    const d = err.details as { reason: string; fields?: string[] };
    return { code: err.code, reason: d?.reason, fields: d?.fields };
  }
  throw new Error('se esperaba un error');
}

const view = async (id: string) => (await db.doc(`bookings/${id}/driverView/preferences`).get()).data();

async function clear(): Promise<void> {
  for (const col of ['openRequests', 'adminAlerts', 'users', 'pricingRules', 'config', 'paymentRefs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/ina').set({ role: 'rider', isActive: false });
  await db.doc('users/carlos').set({ role: 'driver', isActive: true });
  await db.doc('pricingRules/business_oneWay').set({
    vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3,
    pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true,
  });
  // Datos de PRUEBA, ficticios. playlistHosts: un host de ejemplo, no real.
  await db.doc('config/ops').set({
    paymentMethods: { manual_qr: true },
    paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
    playlistHosts: [HOST],
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('updatePreferences (perfil)', () => {
  it('guarda la copia saneada en users/{uid}.tripPreferences', async () => {
    const { preferences } = await updatePreferences({ db }, 'ana', TRIP_PREFS);
    expect(preferences).toMatchObject({ preferredDriverLanguages: ['es', 'en'], note: 'Llevo un carrito' });
    const saved = (await db.doc('users/ana').get()).data()!.tripPreferences;
    expect(saved).toMatchObject({ ...preferences });
    expect(saved.updatedAt).toBeInstanceOf(admin.firestore.Timestamp);
  });

  it('sin sesión, inactivo o chófer: rechazado y no escribe nada', async () => {
    expect((await reason(updatePreferences({ db }, undefined, {}))).reason).toBe('unauthenticated');
    expect((await reason(updatePreferences({ db }, 'ina', {}))).reason).toBe('inactive_user');
    expect((await reason(updatePreferences({ db }, 'carlos', {}))).reason).toBe('inactive_user');
    expect((await db.doc('users/ina').get()).data()!.tripPreferences).toBeUndefined();
  });

  it('campo extra o host fuera de la lista: rechazado', async () => {
    expect(await reason(updatePreferences({ db }, 'ana', { ...TRIP_PREFS, phone: '+59170000000' })))
      .toMatchObject({ reason: 'invalid_request', fields: ['(raíz)'] });
    expect(await reason(updatePreferences({ db }, 'ana', { playlistUrl: 'https://otro.example.com/l' })))
      .toMatchObject({ reason: 'playlist_not_allowed', fields: ['playlistUrl'] });
    expect((await db.doc('users/ana').get()).data()!.tripPreferences).toBeUndefined();
  });

  it('sin config/ops.playlistHosts: el campo no se ofrece y la URL se rechaza', async () => {
    expect(await preferenceOptions({ db }, 'ana')).toEqual({ playlistEnabled: true, noteMax: 200 });
    await db.doc('config/ops').update({ playlistHosts: admin.firestore.FieldValue.delete() });
    expect(await preferenceOptions({ db }, 'ana')).toEqual({ playlistEnabled: false, noteMax: 200 });
    expect((await reason(updatePreferences({ db }, 'ana', { playlistUrl: URL_OK }))).reason).toBe('playlist_not_allowed');
    await db.doc('config/ops').update({ playlistHosts: [] });
    expect((await reason(updatePreferences({ db }, 'ana', { playlistUrl: URL_OK }))).reason).toBe('playlist_not_allowed');
  });
});

describe('updatePreferences: idioma de la cuenta (idiomas, A2)', () => {
  it('solo el idioma: lo guarda sin tocar las preferencias', async () => {
    await updatePreferences({ db }, 'ana', { conversation: 'quiet' });
    expect(await updatePreferences({ db }, 'ana', { locale: 'pt', localeSource: 'system' }))
      .toEqual({ locale: 'pt', localeSource: 'system' });
    const u = (await db.doc('users/ana').get()).data()!;
    expect(u).toMatchObject({ locale: 'pt', localeSource: 'system', tripPreferences: { conversation: 'quiet' } });
    expect(u.localeUpdatedAt).toBeInstanceOf(admin.firestore.Timestamp);
  });

  it('el chófer guarda su idioma, pero no preferencias', async () => {
    await updatePreferences({ db }, 'carlos', { locale: 'en', localeSource: 'user' });
    expect((await db.doc('users/carlos').get()).data()).toMatchObject({ locale: 'en', localeSource: 'user' });
    expect((await reason(updatePreferences({ db }, 'carlos', { conversation: 'quiet' }))).reason).toBe('inactive_user');
  });

  it('idioma fuera de la lista, «system» como idioma o sin su origen: rechazado', async () => {
    for (const d of [{ locale: 'fr', localeSource: 'user' }, { locale: 'system', localeSource: 'system' },
      { locale: 'es' }, { localeSource: 'user' }]) {
      expect((await reason(updatePreferences({ db }, 'ana', d))).reason).toBe('invalid_request');
    }
    expect((await db.doc('users/ana').get()).data()!.locale).toBeUndefined();
  });

  it('cuenta inactiva: rechazado', async () => {
    expect((await reason(updatePreferences({ db }, 'ina', { locale: 'en', localeSource: 'user' }))).reason)
      .toBe('inactive_user');
  });
});

describe('createBooking: copia por reserva en driverView/preferences', () => {
  it('con preferencias del viaje: copia saneada; en la reserva solo los idiomas', async () => {
    const { bookingId } = await createBooking(deps(), 'ana', trip({ preferences: TRIP_PREFS }));
    expect(await view(bookingId)).toMatchObject({
      bookingId, riderId: 'ana', source: 'trip',
      preferredDriverLanguages: ['es', 'en'], cabinTemperature: 'cool', conversation: 'quiet',
      musicStyle: 'jazz', playlistUrl: URL_OK, needs: ['child_seat'], note: 'Llevo un carrito',
    });
    const booking = (await db.doc(`bookings/${bookingId}`).get()).data()!;
    expect(booking.preferredDriverLanguages).toEqual(['es', 'en']);
    for (const k of ['riderPreferences', 'cabinTemperature', 'conversation', 'musicStyle', 'playlistUrl', 'needs', 'note']) {
      expect(booking[k]).toBeUndefined();
    }
  });

  it('sin preferencias del viaje: copia las del perfil', async () => {
    await updatePreferences({ db }, 'ana', { conversation: 'chatty', preferredDriverLanguages: ['pt'] });
    const { bookingId } = await createBooking(deps(), 'ana', trip());
    expect(await view(bookingId)).toMatchObject({ source: 'profile', conversation: 'chatty', preferredDriverLanguages: ['pt'] });
  });

  it('cambiar el perfil después no cambia la reserva ya hecha', async () => {
    await updatePreferences({ db }, 'ana', { conversation: 'quiet', note: 'Primera' });
    const { bookingId } = await createBooking(deps(), 'ana', trip());
    await updatePreferences({ db }, 'ana', { conversation: 'chatty', note: 'Segunda' });
    expect(await view(bookingId)).toMatchObject({ conversation: 'quiet', note: 'Primera' });
  });

  it('app anterior (sin el campo preferences, sin tripPreferences): reserva normal', async () => {
    await db.doc('users/ana').update({ ridePreferences: { quiet: true, music: false, openDoor: true } });
    const { bookingId, price } = await createBooking(deps(), 'ana', trip());
    expect(price).toBe(86);
    expect(await view(bookingId)).toMatchObject({
      source: 'profile', conversation: 'quiet', musicStyle: 'none', needs: [], note: null, playlistUrl: null,
    });
  });

  it('preferencias inválidas: invalid_request y no crea nada', async () => {
    for (const p of [{ note: 'x'.repeat(201) }, { musicStyle: 'tango_de_marca' }, { conversation: 'quiet', email: 'a@b.c' },
      { note: 'mira www.algo.test' }]) {
      expect((await reason(createBooking(deps(), 'ana', trip({ preferences: p })))).reason).toBe('invalid_request');
    }
    expect(await reason(createBooking(deps(), 'ana', trip({ preferences: { playlistUrl: 'http://music.example.com/l' } }))))
      .toMatchObject({ reason: 'playlist_not_allowed' });
    expect((await db.collection('bookings').get()).size).toBe(0);
  });

  it('perfil con una URL de un host que se quitó después: la reserva se crea sin la URL', async () => {
    await updatePreferences({ db }, 'ana', { playlistUrl: URL_OK, conversation: 'quiet' });
    await db.doc('config/ops').update({ playlistHosts: [] });
    const { bookingId } = await createBooking(deps(), 'ana', trip());
    expect(await view(bookingId)).toMatchObject({ playlistUrl: null, conversation: 'quiet' });
  });

  it('reintento con el mismo requestId y otras preferencias: misma reserva, copia sin tocar', async () => {
    const requestId = randomUUID();
    const first = await createBooking(deps(), 'ana', trip({ requestId, preferences: { note: 'Primera' } }));
    const again = await createBooking(deps(), 'ana', trip({ requestId, preferences: { note: 'Otra' } }));
    expect(again.bookingId).toBe(first.bookingId);
    expect((await view(first.bookingId))!.note).toBe('Primera');
    expect((await db.collection('bookings').get()).size).toBe(1);
  });

});
