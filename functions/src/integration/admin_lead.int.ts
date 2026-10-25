/** Solicitudes de empresas: marcar atendida por el servidor (emulador). */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminSetLeadHandled } from '../admin_ops';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const jefa = { adminId: 'jefa', adminEmail: null };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['businessLeads', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}
beforeEach(async () => { await clear(); await db.doc('businessLeads/l1').set({ company: 'Empresa', handled: false }); });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminSetLeadHandled', () => {
  it('marca atendida con auditoría; repetir no escribe', async () => {
    await adminSetLeadHandled({ db }, jefa, { leadId: 'l1', handled: true });
    expect((await db.doc('businessLeads/l1').get()).data()?.handled).toBe(true);
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ operation: 'lead_handled', reason: null,
      changes: { handled: { before: false, after: true } } })]);
    expect(await reason(adminSetLeadHandled({ db }, jefa, { leadId: 'l1', handled: true }))).toBe('no_change');
  });

  it('no toca otros campos', async () => {
    expect(await reason(adminSetLeadHandled({ db }, jefa, { leadId: 'l1', handled: true, company: 'Otra' }))).toBe('invalid_request');
  });
});
