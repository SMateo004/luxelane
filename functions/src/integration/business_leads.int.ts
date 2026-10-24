/**
 * submitBusinessLead contra el emulador de Firestore: alta válida sin
 * sesión, campo trampa, límites por IP y por correo, la IP nunca se guarda
 * en claro y el contador caído rechaza (falla cerrado).
 */
import { describe, it, expect, beforeEach, afterEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { LEAD_LIMITS, LeadRequest, pseudonym, submitBusinessLead } from '../business_leads';
import { rateLimiter } from '../rate_limit';
import { submitBusinessLead as submitBusinessLeadFn } from '../index';

const db = admin.firestore();
const SALT = 'sal-de-prueba';
const IP = '203.0.113.7';
const realCheck = rateLimiter.check;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

const lead = (over: Record<string, unknown> = {}) => ({
  company: 'Empresa SA', contactName: 'Laura Prueba', email: 'Laura@Example.com',
  phone: '+59170000000', travellers: '11–50', message: 'Queremos cotizar', ...over,
});
const req = (data: unknown, ip = IP): LeadRequest => ({
  data, rawRequest: { ip: '10.0.0.1', headers: { 'x-forwarded-for': `${ip}, 10.0.0.1` } },
});
const send = (data: unknown, ip?: string, salt = SALT) => submitBusinessLead({ db, salt }, req(data, ip));

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
  for (const col of ['businessLeads', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

/** Todo lo guardado en las dos colecciones, como texto. */
async function stored(): Promise<string> {
  const out: unknown[] = [];
  for (const col of ['businessLeads', 'rateLimits']) {
    for (const d of (await db.collection(col).get()).docs) out.push({ id: d.id, ...d.data() });
  }
  return JSON.stringify(out);
}

beforeEach(clear);
afterEach(() => { rateLimiter.check = realCheck; delete process.env.RATE_LIMIT_SALT; });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('submitBusinessLead', () => {
  it('guarda la solicitud con el correo normalizado y sin la IP en claro', async () => {
    await expect(send(lead())).resolves.toEqual({ ok: true });
    const docs = (await db.collection('businessLeads').get()).docs.map((d) => d.data());
    expect(docs).toHaveLength(1);
    expect(docs[0]).toMatchObject({ company: 'Empresa SA', email: 'laura@example.com', handled: false });
    const all = await stored();
    expect(all).not.toContain(IP);
    expect(all).toContain(pseudonym(SALT, 'ip', IP));
  });

  it('sin sesión, por la callable exportada (App Check y traducción de errores)', async () => {
    process.env.RATE_LIMIT_SALT = SALT;
    await expect((submitBusinessLeadFn as unknown as Runnable).run({ app: {}, ...req(lead()) }))
      .resolves.toEqual({ ok: true });
    expect((await db.collection('businessLeads').get()).size).toBe(1);
  });

  it('campo trampa relleno: responde igual y no guarda nada', async () => {
    await expect(send(lead({ website: 'https://spam.example' }))).resolves.toEqual({ ok: true });
    expect((await db.collection('businessLeads').get()).size).toBe(0);
  });

  it('rechaza campos desconocidos', async () => {
    expect((await failure(send(lead({ handled: true })))).reason).toBe('invalid_request');
    expect((await db.collection('businessLeads').get()).size).toBe(0);
  });

  it(`límite por IP: ${LEAD_LIMITS.perIp.limit} por hora, aunque cambie el correo`, async () => {
    for (let i = 0; i < LEAD_LIMITS.perIp.limit; i++) await send(lead({ email: `p${i}@example.com` }));
    expect(await failure(send(lead({ email: 'otra@example.com' }))))
      .toEqual({ code: 'resource-exhausted', reason: 'rate_limited' });
    // Otra IP sigue pudiendo.
    await expect(send(lead({ email: 'otra@example.com' }), '198.51.100.9')).resolves.toEqual({ ok: true });
  });

  it(`límite por correo: ${LEAD_LIMITS.perEmail.limit} por día, aunque cambie la IP`, async () => {
    for (let i = 0; i < LEAD_LIMITS.perEmail.limit; i++) await send(lead(), `198.51.100.${i}`);
    expect((await failure(send(lead({ email: 'LAURA@example.com' }), '198.51.100.99'))).reason)
      .toBe('rate_limited');
    // El contador guarda el hash del correo, nunca el correo.
    const counters = JSON.stringify((await db.collection('rateLimits').get()).docs
      .map((d) => ({ id: d.id, ...d.data() })));
    expect(counters.toLowerCase()).not.toContain('laura');
  });

  it('si el contador falla, rechaza (falla cerrado)', async () => {
    rateLimiter.check = async () => { throw new Error('Firestore caído'); };
    expect((await failure(send(lead()))).reason).toBe('rate_limited');
    expect((await db.collection('businessLeads').get()).size).toBe(0);
  });

  it('sin la sal configurada, no acepta nada', async () => {
    expect((await failure(send(lead(), IP, ''))).code).toBe('internal');
    expect((await db.collection('businessLeads').get()).size).toBe(0);
  });
});
