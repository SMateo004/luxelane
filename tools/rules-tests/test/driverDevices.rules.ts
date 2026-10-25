// B7 (decisión 5): dispositivos y eventos del chófer: los escribe solo el
// servidor; los lee solo el admin (ni el propio chófer).
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'driverDevices/asig/devices/dev-1'), { platform: 'android' });
    await setDoc(doc(ctx.firestore(), 'driverDevices/asig/events/ev-1'), { type: 'first_device' });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('driverDevices (B7)', () => {
  test('el admin lee dispositivos y eventos', async () => {
    await assertSucceeds(getDoc(doc(db('admin'), 'driverDevices/asig/devices/dev-1')));
    await assertSucceeds(getDoc(doc(db('admin'), 'driverDevices/asig/events/ev-1')));
  });

  test('el chófer no los lee ni los escribe', async () => {
    await assertFails(getDoc(doc(db('asig'), 'driverDevices/asig/devices/dev-1')));
    await assertFails(setDoc(doc(db('asig'), 'driverDevices/asig/devices/dev-2'), { platform: 'ios' }));
    await assertFails(setDoc(doc(db('asig'), 'driverDevices/asig/events/ev-2'), { type: 'first_device' }));
  });

  test('nadie escribe desde el cliente, tampoco el admin', async () => {
    await assertFails(setDoc(doc(db('admin'), 'driverDevices/asig/devices/dev-3'), { platform: 'ios' }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'driverDevices/asig/devices/dev-1')));
  });
});
