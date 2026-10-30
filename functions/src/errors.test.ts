/**
 * Al cliente solo llegan siete códigos y un motivo corto; el log del
 * servidor no guarda claves, correos, teléfonos, tarjetas, códigos de
 * recogida ni coordenadas. Los valores son falsos, hechos para el test.
 */
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { FunctionsErrorCode, HttpsError } from 'firebase-functions/v2/https';
import { CLIENT_CODES, toClientError } from './errors';
import { logger, redact } from './logger';
import { secureCallable } from './callable';

const FAKE_SK = 'sk_test_51FalsaClaveDePrueba000';
const EMAIL = 'pasajera.prueba@example.com';
const COORDS = '-17.7834, -63.1821';
const SECRETS = [FAKE_SK, EMAIL, COORDS, '-17.7834', '-63.1821'];
const LEAKY = `Stripe: Invalid API Key provided: ${FAKE_SK} for ${EMAIL} at ${COORDS}`;

/** Todo lo que se escribió en la consola durante `fn`. */
async function captureLogs(fn: () => Promise<unknown> | unknown): Promise<string> {
  const lines: string[] = [];
  const grab = (...a: unknown[]) => { lines.push(a.map(String).join(' ')); };
  jest.spyOn(console, 'log').mockImplementation(grab);
  jest.spyOn(console, 'warn').mockImplementation(grab);
  jest.spyOn(console, 'error').mockImplementation(grab);
  try {
    await fn();
  } catch {
    // el error lo revisa cada test
  }
  return lines.join('\n');
}

const expectClean = (text: string) => {
  for (const s of SECRETS) expect(text).not.toContain(s);
};

const asClient = (e: HttpsError) => JSON.stringify({ code: e.code, message: e.message, details: e.details });

afterEach(() => { jest.restoreAllMocks(); });

describe('toClientError', () => {
  it('un error inesperado llega como internal, sin texto, y el log va tachado', async () => {
    let out!: HttpsError;
    const logs = await captureLogs(() => { out = toClientError('prueba', new Error(LEAKY)); });
    expect(out.code).toBe('internal');
    expect(out.message).toBe('internal');
    expect(out.details).toEqual({ code: 'internal', reason: 'internal' });
    expectClean(asClient(out));
    expect(logs).toContain('[stripe-key]');
    expectClean(logs);
  });

  it('un HttpsError con texto libre pierde el texto', async () => {
    let out!: HttpsError;
    await captureLogs(() => { out = toClientError('prueba', new HttpsError('invalid-argument', LEAKY)); });
    expect(out.message).toBe('invalid_request');
    expect(out.details).toEqual({ code: 'invalid_request', reason: 'invalid_request' });
  });

  it('conserva el motivo corto y solo los datos extra permitidos', () => {
    const out = toClientError('prueba', new HttpsError('failed-precondition', 'price_changed', {
      reason: 'price_changed', price: 86, email: EMAIL, stack: LEAKY, attemptsLeft: Infinity,
    }));
    expect(out.details).toEqual({ code: 'failed_precondition', reason: 'price_changed', price: 86 });
  });

  it('un motivo que no es un código corto se sustituye por el código', () => {
    const out = toClientError('prueba', new HttpsError('not-found', 'Booking not found', { reason: `No existe ${EMAIL}` }));
    expect(out.details).toEqual({ code: 'not_found', reason: 'not_found' });
  });

  it.each([
    ['already-exists', 'failed-precondition'],
    ['aborted', 'failed-precondition'],
    ['out-of-range', 'invalid-argument'],
    ['unavailable', 'internal'],
    ['data-loss', 'internal'],
    ['unknown', 'internal'],
  ] as [FunctionsErrorCode, FunctionsErrorCode][])('%s se pliega a %s', async (from, to) => {
    let out!: HttpsError;
    await captureLogs(() => { out = toClientError('prueba', new HttpsError(from, 'detalle interno')); });
    expect(out.code).toBe(to);
    expect(Object.values(CLIENT_CODES)).toContain(out.message);
  });

  it('el pago fallido se distingue sin el mensaje de Stripe', () => {
    const out = toClientError('prueba', new HttpsError('internal', 'payment_failed', { reason: 'payment_failed' }));
    expect(out.details).toEqual({ code: 'internal', reason: 'payment_failed' });
  });
});

describe('secureCallable traduce los errores del handler', () => {
  // Nombre sin límite de tasa: no toca Firestore.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const run = (fn: unknown, data: unknown) => (fn as { run: (r: any) => Promise<unknown> }).run({ app: {}, data });

  it('respuesta y log sin la clave, el correo ni las coordenadas', async () => {
    const fn = secureCallable('pruebaErrores', {}, () => { throw new Error(LEAKY); });
    let caught: unknown;
    const logs = await captureLogs(async () => {
      try { await run(fn, {}); } catch (e) { caught = e; throw e; }
    });
    expect(caught).toBeInstanceOf(HttpsError);
    expect((caught as HttpsError).code).toBe('internal');
    expectClean(asClient(caught as HttpsError));
    expectClean(logs);
  });

  it('los errores de negocio siguen llegando con su motivo', async () => {
    const fn = secureCallable('pruebaErrores', {}, () => {
      throw new HttpsError('failed-precondition', 'wrong_code', { reason: 'wrong_code', attemptsLeft: 2 });
    });
    await expect(run(fn, {})).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'failed_precondition',
      details: { code: 'failed_precondition', reason: 'wrong_code', attemptsLeft: 2 },
    });
  });
});

describe('logger: redacción', () => {
  it('tacha por nombre de campo y por patrón, y deja lo demás', async () => {
    const logs = await captureLogs(() => logger.error('prueba', `fallo con ${EMAIL}`, {
      bookingId: 'b123',
      email: EMAIL,
      phone: '+591 70000001',
      code: '0427',
      location: { lat: -17.7834, lng: -63.1821 },
      lat: -17.7834,
      fcmToken: 'token-falso-de-dispositivo',
      error: `${LEAKY}; tarjeta 4242 4242 4242 4242; maps AIzaSyFalsaClaveDePrueba0000000000000; ` +
        'tel +59170000001; pk_test_FalsaPublica; pi_123_secret_abc; eyJhbGciOi.eyJzdWIiOi.firmaFalsa',
    }));
    expectClean(logs);
    for (const s of ['4242 4242 4242 4242', 'AIzaSyFalsa', '+59170000001', 'pk_test_Falsa',
      'pi_123_secret_abc', 'eyJhbGciOi', 'token-falso', '0427', '+591 70000001']) {
      expect(logs).not.toContain(s);
    }
    expect(logs).toContain('b123');
  });

  it('A5: ni la nota ni la URL de la lista salen en el log', async () => {
    const NOTE = 'Llevo un carrito de bebé';
    const URL = 'https://music.example.com/lista/abc';
    const logs = await captureLogs(() => logger.warn('prueba', `fallo al guardar ${URL}`, {
      bookingId: 'b123',
      note: NOTE,
      notes: NOTE,
      playlistUrl: URL,
      preferences: { note: NOTE, playlistUrl: URL },
      tripPreferences: { note: NOTE },
      input: { preferences: { conversation: 'quiet', note: NOTE, playlistUrl: URL } },
      error: `rechazada ${URL}`,
    }));
    expect(logs).not.toContain(NOTE);
    expect(logs).not.toContain('music.example.com');
    expect(logs).toContain('b123');
  });

  it('no confunde un número largo cualquiera con una tarjeta', () => {
    expect(redact('timestamp 1700000000000')).toBe('timestamp 1700000000000');
  });
});
