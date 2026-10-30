/**
 * Preferencias del pasajero (A1, A7) contra el emulador: updatePreferences
 * guarda las del perfil.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
// Inicializa Firebase como los demás tests de integración.
import '../index';
import { preferenceOptions, updatePreferences } from '../preferences';

const db = admin.firestore();

const HOST = 'music.example.com';
const URL_OK = `https://${HOST}/lista/1`;


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
