// B2 (decisión 4): las reglas usan el claim `role`; sin claim, el rol de
// Firestore (transición). isActive sigue saliendo de Firestore.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const as = (uid: string, claims?: Record<string, unknown>) =>
  env.authenticatedContext(uid, claims).firestore();
const readAlerts = (uid: string, claims?: Record<string, unknown>) => getDocs(collection(as(uid, claims), 'adminAlerts'));

describe('rol por custom claim', () => {
  test('con claim admin, admin aunque Firestore diga pasajero', async () => {
    await assertSucceeds(readAlerts('ana', { role: 'admin' }));
  });

  test('con claim rider, no admin aunque Firestore diga admin', async () => {
    await assertFails(readAlerts('admin', { role: 'rider' }));
  });

  test('sin claim (transición): el rol de Firestore', async () => {
    await assertSucceeds(readAlerts('admin'));
    await assertFails(readAlerts('ana'));
  });

  test('claim driver: chófer verificado y activo ve solicitudes', async () => {
    await assertSucceeds(getDoc(doc(as('libre', { role: 'driver' }), 'openRequests', 'pend')));
  });

  test('el claim no salta el bloqueo: isActive sale de Firestore', async () => {
    await assertFails(getDoc(doc(as('bloq', { role: 'driver' }), 'openRequests', 'pend')));
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users', 'admin2'), { id: 'admin2', role: 'admin', isActive: false }));
    // Un admin bloqueado con claim no puede tocar config.
    await assertFails(updateDoc(doc(as('admin2', { role: 'admin' }), 'config', 'global'), { x: 1 }));
  });
});
