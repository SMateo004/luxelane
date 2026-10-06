// Firestore security rules tests. Run with: npm test (starts the emulator).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let env;

const booking = (overrides = {}) => ({
  riderId: 'rider',
  driverId: null,
  status: 'pending',
  estimatedPrice: 120,
  finalPrice: null,
  paymentId: null,
  class: 'business',
  ...overrides,
});

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-luxelane',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed('users/rider', { role: 'rider', email: 'r@x.com' });
  await seed('users/driver', { role: 'driver', email: 'd@x.com' });
  await seed('users/newdriver', { role: 'driver', email: 'n@x.com' });
  await seed('users/admin', { role: 'admin', email: 'a@x.com' });
  await seed('driverProfiles/driver', { userId: 'driver', documentsVerified: true, rating: 4.9, totalRides: 10 });
  await seed('driverProfiles/newdriver', { userId: 'newdriver', documentsVerified: false, rating: 0, totalRides: 0 });
});

describe('users', () => {
  it('cannot self-register as admin', async () => {
    await assertFails(setDoc(doc(db('mallory'), 'users/mallory'), { role: 'admin' }));
  });

  it('can self-register as rider (shape written by the app)', async () => {
    await assertSucceeds(
      setDoc(doc(db('alice'), 'users/alice'), {
        role: 'rider',
        email: 'a@a.com',
        isVerified: false,
        stripeCustomerId: null,
        fcmTokens: [],
      }),
    );
  });

  it('cannot self-register pre-verified or with a Stripe customer', async () => {
    await assertFails(setDoc(doc(db('bob'), 'users/bob'), { role: 'rider', isVerified: true }));
    await assertFails(setDoc(doc(db('bob'), 'users/bob'), { role: 'rider', stripeCustomerId: 'cus_x' }));
  });

  it('cannot escalate own role', async () => {
    await assertFails(updateDoc(doc(db('rider'), 'users/rider'), { role: 'admin' }));
  });

  it('can edit own non-privileged fields', async () => {
    await assertSucceeds(updateDoc(doc(db('rider'), 'users/rider'), { displayName: 'Ana' }));
  });

  it('admin can change roles', async () => {
    await assertSucceeds(updateDoc(doc(db('admin'), 'users/rider'), { role: 'driver' }));
  });

  it('cannot read other users', async () => {
    await assertFails(getDoc(doc(db('rider'), 'users/driver')));
  });
});

describe('driverProfiles', () => {
  it('driver cannot self-verify or inflate rating', async () => {
    await assertFails(updateDoc(doc(db('newdriver'), 'driverProfiles/newdriver'), { documentsVerified: true }));
    await assertFails(updateDoc(doc(db('driver'), 'driverProfiles/driver'), { rating: 5 }));
  });

  it('driver can toggle availability', async () => {
    await assertSucceeds(updateDoc(doc(db('driver'), 'driverProfiles/driver'), { isAvailable: true }));
  });
});

describe('bookings', () => {
  it('clients cannot create bookings directly (server-only, quoted price)', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'), booking()));
    await assertFails(setDoc(doc(db('admin'), 'bookings/b1'), booking()));
  });

  it('only verified drivers can self-assign', async () => {
    await seed('bookings/b1', booking());
    const accept = { driverId: 'newdriver', status: 'confirmed', updatedAt: 1 };
    await assertFails(updateDoc(doc(db('newdriver'), 'bookings/b1'), accept));
    await assertFails(updateDoc(doc(db('rider'), 'bookings/b1'), { ...accept, driverId: 'rider' }));
    await assertSucceeds(updateDoc(doc(db('driver'), 'bookings/b1'), { ...accept, driverId: 'driver' }));
  });

  it('assigned driver follows the state machine', async () => {
    await seed('bookings/b1', booking({ driverId: 'driver', status: 'confirmed' }));
    const ref = doc(db('driver'), 'bookings/b1');
    await assertFails(updateDoc(ref, { status: 'completed' }));
    await assertSucceeds(updateDoc(ref, { status: 'driver_arriving' }));
    await assertFails(updateDoc(ref, { status: 'pending' }));
    await assertSucceeds(updateDoc(ref, { status: 'driver_arrived' }));
    await assertSucceeds(updateDoc(ref, { status: 'in_progress' }));
    await assertSucceeds(updateDoc(ref, { status: 'completed' }));
  });

  it('driver cannot change the price', async () => {
    await seed('bookings/b1', booking({ driverId: 'driver', status: 'confirmed' }));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { estimatedPrice: 9999 }));
  });

  it('rider can cancel before the ride starts, not during', async () => {
    await seed('bookings/b1', booking({ driverId: 'driver', status: 'confirmed' }));
    await seed('bookings/b2', booking({ driverId: 'driver', status: 'in_progress' }));
    await assertSucceeds(updateDoc(doc(db('rider'), 'bookings/b1'), { status: 'cancelled' }));
    await assertFails(updateDoc(doc(db('rider'), 'bookings/b2'), { status: 'cancelled' }));
  });
});

describe('payments & admin collections', () => {
  it('clients cannot write payments', async () => {
    await assertFails(setDoc(doc(db('rider'), 'payments/p1'), { riderId: 'rider', status: 'captured' }));
  });

  it('admin logs are admin-only and append-only', async () => {
    await assertFails(setDoc(doc(db('rider'), 'admin_logs/l1'), { action: 'x' }));
    await assertSucceeds(setDoc(doc(db('admin'), 'admin_logs/l1'), { action: 'x' }));
    await assertFails(updateDoc(doc(db('admin'), 'admin_logs/l1'), { action: 'y' }));
  });
});

describe('quotes', () => {
  it('rider reads own quotes only and nobody writes them', async () => {
    await seed('quotes/q1', { riderId: 'rider', amount: 120 });
    await assertSucceeds(getDoc(doc(db('rider'), 'quotes/q1')));
    await assertFails(getDoc(doc(db('driver'), 'quotes/q1')));
    await assertFails(updateDoc(doc(db('rider'), 'quotes/q1'), { amount: 1 }));
    await assertFails(setDoc(doc(db('rider'), 'quotes/q2'), { riderId: 'rider', amount: 1 }));
  });
});

describe('notifications', () => {
  it('owner reads and marks own notifications as read only', async () => {
    await seed('users/rider/notifications/n1', { userId: 'rider', isRead: false, title: 'Hola' });
    await assertSucceeds(updateDoc(doc(db('rider'), 'users/rider/notifications/n1'), { isRead: true }));
    await assertFails(updateDoc(doc(db('rider'), 'users/rider/notifications/n1'), { title: 'x' }));
    await assertFails(getDoc(doc(db('driver'), 'users/rider/notifications/n1')));
  });
});
