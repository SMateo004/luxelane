// Firestore security rules tests. Run with: npm test (starts the emulator).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, updateDoc, writeBatch } from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

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
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
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

  it('targeted offers can only be taken by the offered driver', async () => {
    await seed('users/driver2', { role: 'driver' });
    await seed('driverProfiles/driver2', { userId: 'driver2', documentsVerified: true, rating: 0, totalRides: 0 });
    await seed('bookings/b1', booking({ dispatch: { mode: 'targeted', offeredTo: 'driver2' } }));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { driverId: 'driver', status: 'confirmed', updatedAt: 1 }));
    await assertSucceeds(updateDoc(doc(db('driver2'), 'bookings/b1'), { driverId: 'driver2', status: 'confirmed', updatedAt: 1 }));
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

describe('live tracking & driver privacy', () => {
  it('only the assigned driver writes, only rider/driver read', async () => {
    await seed('bookings/b1', booking({ driverId: 'driver', status: 'driver_arriving' }));
    const live = { lat: -17.78, lng: -63.18, heading: 90, speed: 8, updatedAt: 1 };
    await assertSucceeds(setDoc(doc(db('driver'), 'bookings/b1/tracking/live'), live));
    await assertFails(setDoc(doc(db('newdriver'), 'bookings/b1/tracking/live'), live));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1/tracking/live'), live));
    await assertFails(setDoc(doc(db('driver'), 'bookings/b1/tracking/live'), { ...live, extra: true }));
    await assertSucceeds(getDoc(doc(db('rider'), 'bookings/b1/tracking/live')));
    await assertFails(getDoc(doc(db('newdriver'), 'bookings/b1/tracking/live')));
  });

  it('no tracking writes once the trip is over', async () => {
    await seed('bookings/b2', booking({ driverId: 'driver', status: 'completed' }));
    await assertFails(setDoc(doc(db('driver'), 'bookings/b2/tracking/live'), { lat: 1, lng: 1 }));
  });

  it("riders can't read driver profiles (location, documents)", async () => {
    await assertFails(getDoc(doc(db('rider'), 'driverProfiles/driver')));
    await assertSucceeds(getDoc(doc(db('driver'), 'driverProfiles/driver')));
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

describe('companies', () => {
  beforeEach(async () => {
    await seed('companies/acme', { name: 'Acme', active: true, costCenters: [] });
    await seed('companies/acme/members/boss', { role: 'admin' });
    await seed('companies/acme/members/emp', { role: 'member' });
    await seed('users/boss', { role: 'rider', companyId: 'acme', companyRole: 'admin' });
    await seed('users/emp', { role: 'rider', companyId: 'acme', companyRole: 'member' });
    await seed('companyInvites/new@acme.bo', { companyId: 'acme', role: 'member' });
  });

  it('members read their company; outsiders and writes are refused', async () => {
    await assertSucceeds(getDoc(doc(db('emp'), 'companies/acme')));
    await assertFails(getDoc(doc(db('rider'), 'companies/acme')));
    await assertFails(updateDoc(doc(db('boss'), 'companies/acme'), { active: false }));
    await assertSucceeds(getDoc(doc(db('admin'), 'companies/acme')));
  });

  it('only company admins list members and invites', async () => {
    await assertSucceeds(getDoc(doc(db('boss'), 'companies/acme/members/emp')));
    await assertSucceeds(getDoc(doc(db('emp'), 'companies/acme/members/emp')));
    await assertFails(getDoc(doc(db('emp'), 'companies/acme/members/boss')));
    await assertSucceeds(getDoc(doc(db('boss'), 'companyInvites/new@acme.bo')));
    await assertFails(getDoc(doc(db('emp'), 'companyInvites/new@acme.bo')));
    await assertFails(setDoc(doc(db('boss'), 'companies/acme/members/rider'), { role: 'admin' }));
  });

  it('users cannot join or promote themselves', async () => {
    await assertFails(updateDoc(doc(db('rider'), 'users/rider'), { companyId: 'acme' }));
    await assertFails(updateDoc(doc(db('emp'), 'users/emp'), { companyRole: 'admin' }));
    await assertFails(setDoc(doc(db('eve'), 'users/eve'), { role: 'rider', companyId: 'acme', companyRole: 'admin' }));
  });

  it('company admins read bookings billed to their company only', async () => {
    await seed('bookings/c1', booking({ riderId: 'emp', companyId: 'acme' }));
    await seed('bookings/p1', booking({ riderId: 'emp' }));
    await assertSucceeds(getDoc(doc(db('boss'), 'bookings/c1')));
    await assertFails(getDoc(doc(db('boss'), 'bookings/p1')));
    await seed('bookings/c2', booking({ riderId: 'boss', companyId: 'acme' }));
    await assertFails(getDoc(doc(db('emp'), 'bookings/c2')));
  });
});

describe('verification documents', () => {
  const upload = (overrides = {}) => ({
    type: 'soat',
    status: 'pending',
    storagePath: 'driver_documents/driver/soat-1.pdf',
    fileName: 'soat.pdf',
    contentType: 'application/pdf',
    expiresAt: null,
    uploadedAt: null,
    ...overrides,
  });

  it('chauffeur uploads own documents as pending only', async () => {
    await assertSucceeds(setDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/soat'), upload()));
    await assertFails(setDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/soat'), upload({ status: 'approved' })));
    await assertFails(setDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/soat'), upload({ reviewedBy: 'driver' })));
    await assertFails(setDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/passport'), upload({ type: 'passport' })));
    await assertFails(
      setDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/soat'),
        upload({ storagePath: 'driver_documents/newdriver/x.pdf' })),
    );
    await assertFails(setDoc(doc(db('newdriver'), 'driverProfiles/driver/verificationDocs/soat'), upload()));
    await assertFails(setDoc(doc(db('rider'), 'driverProfiles/rider/verificationDocs/soat'), upload({ storagePath: 'driver_documents/rider/a.pdf' })));
  });

  it('only the chauffeur and admins read them', async () => {
    await seed('driverProfiles/driver/verificationDocs/license', upload({ type: 'license', status: 'approved' }));
    await assertSucceeds(getDoc(doc(db('driver'), 'driverProfiles/driver/verificationDocs/license')));
    await assertSucceeds(getDoc(doc(db('admin'), 'driverProfiles/driver/verificationDocs/license')));
    await assertFails(getDoc(doc(db('rider'), 'driverProfiles/driver/verificationDocs/license')));
    await assertFails(getDoc(doc(db('newdriver'), 'driverProfiles/driver/verificationDocs/license')));
  });

  it('storage: own folder, images or PDF under 10 MB, admins can read', async () => {
    const st = (uid) => env.authenticatedContext(uid).storage();
    const pdf = new Uint8Array([37, 80, 68, 70]);
    await assertSucceeds(uploadBytes(ref(st('driver'), 'driver_documents/driver/soat.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(st('driver'), 'driver_documents/driver/x.exe'), pdf, { contentType: 'application/octet-stream' }));
    await assertFails(uploadBytes(ref(st('rider'), 'driver_documents/driver/soat.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertSucceeds(getBytes(ref(st('admin'), 'driver_documents/driver/soat.pdf')));
    await assertFails(getBytes(ref(st('rider'), 'driver_documents/driver/soat.pdf')));
  });
});

describe('promo codes', () => {
  it('only admins read codes; nobody writes them or their uses from the client', async () => {
    await seed('promoCodes/BIENVENIDO', { code: 'BIENVENIDO', type: 'percent', value: 20, active: true, redemptions: 3 });
    await seed('promoCodes/BIENVENIDO/redemptions/rider', { count: 1 });
    await assertSucceeds(getDoc(doc(db('admin'), 'promoCodes/BIENVENIDO')));
    await assertFails(getDoc(doc(db('rider'), 'promoCodes/BIENVENIDO')));
    await assertFails(updateDoc(doc(db('admin'), 'promoCodes/BIENVENIDO'), { redemptions: 0 }));
    await assertFails(setDoc(doc(db('rider'), 'promoCodes/GRATIS'), { type: 'percent', value: 100, active: true }));
    await assertFails(updateDoc(doc(db('rider'), 'promoCodes/BIENVENIDO/redemptions/rider'), { count: 0 }));
  });
});

describe('support tickets', () => {
  const ticket = (overrides = {}) => ({
    userId: 'rider',
    userName: 'Ana',
    userRole: 'rider',
    category: 'lostItem',
    subject: 'Olvidé mi paraguas',
    bookingId: null,
    status: 'open',
    priority: 'normal',
    createdAt: null,
    updatedAt: null,
    lastMessageAt: null,
    lastMessagePreview: 'Olvidé mi paraguas',
    lastAuthorRole: 'user',
    unreadForUser: false,
    unreadForAdmin: true,
    ...overrides,
  });
  const message = (overrides = {}) => ({
    authorId: 'rider',
    authorRole: 'user',
    authorName: 'Ana',
    text: 'Hola',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  it('rider opens a ticket with its first message in one batch', async () => {
    const fs = db('rider');
    const batch = writeBatch(fs);
    batch.set(doc(fs, 'supportTickets/t1'), ticket());
    batch.set(doc(fs, 'supportTickets/t1/messages/m1'), message());
    await assertSucceeds(batch.commit());
  });

  it('rejects forged owners, roles, priorities and other people\'s trips', async () => {
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t2'), ticket({ userId: 'driver' })));
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t2'), ticket({ userRole: 'admin' })));
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t2'), ticket({ category: 'safety' })));
    await assertSucceeds(setDoc(doc(db('rider'), 'supportTickets/t3'), ticket({ category: 'safety', priority: 'urgent' })));
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t2'), ticket({ status: 'resolved' })));
    await seed('bookings/mine', booking());
    await seed('bookings/theirs', booking({ riderId: 'someone' }));
    await assertSucceeds(setDoc(doc(db('rider'), 'supportTickets/t4'), ticket({ bookingId: 'mine' })));
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t5'), ticket({ bookingId: 'theirs' })));
  });

  it('only the owner and admins read; only admins answer as the team', async () => {
    await seed('supportTickets/t1', ticket());
    await assertSucceeds(getDoc(doc(db('rider'), 'supportTickets/t1')));
    await assertSucceeds(getDoc(doc(db('admin'), 'supportTickets/t1')));
    await assertFails(getDoc(doc(db('driver'), 'supportTickets/t1')));
    await assertSucceeds(setDoc(doc(db('admin'), 'supportTickets/t1/messages/a1'),
      message({ authorId: 'admin', authorRole: 'admin', authorName: 'Luxelane' })));
    await assertFails(setDoc(doc(db('rider'), 'supportTickets/t1/messages/m2'), message({ authorRole: 'admin' })));
    await assertFails(setDoc(doc(db('driver'), 'supportTickets/t1/messages/m3'), message({ authorId: 'driver' })));
    await assertFails(updateDoc(doc(db('admin'), 'supportTickets/t1/messages/a1'), { text: 'editado' }));
  });

  it('owner can only mark read or resolve', async () => {
    await seed('supportTickets/t1', ticket({ unreadForUser: true }));
    await assertSucceeds(updateDoc(doc(db('rider'), 'supportTickets/t1'), { unreadForUser: false }));
    await assertSucceeds(updateDoc(doc(db('rider'), 'supportTickets/t1'), { status: 'resolved', updatedAt: null }));
    await assertFails(updateDoc(doc(db('rider'), 'supportTickets/t1'), { priority: 'urgent' }));
    await assertSucceeds(updateDoc(doc(db('admin'), 'supportTickets/t1'), { status: 'open' }));
  });
});

describe('observability', () => {
  it('errors and health are admin-only; clients cannot forge them', async () => {
    await seed('clientErrors/abc', { message: 'boom', count: 3, resolved: false });
    await seed('system/health', { onlineDrivers: 2 });
    await assertSucceeds(getDoc(doc(db('admin'), 'clientErrors/abc')));
    await assertSucceeds(updateDoc(doc(db('admin'), 'clientErrors/abc'), { resolved: true }));
    await assertFails(updateDoc(doc(db('admin'), 'clientErrors/abc'), { count: 0 }));
    await assertFails(getDoc(doc(db('rider'), 'clientErrors/abc')));
    await assertFails(setDoc(doc(db('rider'), 'clientErrors/x'), { message: 'spam' }));
    await assertSucceeds(getDoc(doc(db('admin'), 'system/health')));
    await assertFails(getDoc(doc(db('driver'), 'system/health')));
    await assertFails(setDoc(doc(db('admin'), 'system/health'), { onlineDrivers: 99 }));
  });
});

describe('settlements', () => {
  const record = (overrides = {}) => ({ driverId: 'driver', weekStart: null, balance: 120, paidBy: 'admin', ...overrides });

  it('only admins set a commission between 0 and 50 %', async () => {
    await assertSucceeds(setDoc(doc(db('admin'), 'config/finance'), { commissionPct: 20 }));
    await assertFails(setDoc(doc(db('admin'), 'config/finance'), { commissionPct: 80 }));
    await assertFails(setDoc(doc(db('driver'), 'config/finance'), { commissionPct: 0 }));
    await assertSucceeds(getDoc(doc(db('driver'), 'config/finance')));
  });

  it('admins record settled weeks; chauffeurs read only theirs', async () => {
    await assertSucceeds(setDoc(doc(db('admin'), 'settlements/driver_20261005'), record()));
    await assertFails(setDoc(doc(db('admin'), 'settlements/other_20261005'), record()));
    await assertFails(setDoc(doc(db('admin'), 'settlements/driver_20261012'), record({ paidBy: 'someone' })));
    await assertFails(setDoc(doc(db('driver'), 'settlements/driver_20261012'), record({ paidBy: 'driver' })));
    await assertSucceeds(getDoc(doc(db('driver'), 'settlements/driver_20261005')));
    await assertFails(getDoc(doc(db('newdriver'), 'settlements/driver_20261005')));
  });
});

describe('loyalty config', () => {
  it('only admins configure it, with at most 3 tiers', async () => {
    const tiers = [{ id: 'silver', minRides: 5, discountPct: 3 }];
    await assertSucceeds(setDoc(doc(db('admin'), 'config/loyalty'), { enabled: true, tiers }));
    await assertFails(setDoc(doc(db('admin'), 'config/loyalty'), { enabled: 'yes', tiers }));
    await assertFails(setDoc(doc(db('admin'), 'config/loyalty'), { enabled: true, tiers: [...tiers, ...tiers, ...tiers, ...tiers] }));
    await assertFails(setDoc(doc(db('rider'), 'config/loyalty'), { enabled: true, tiers }));
    await assertSucceeds(getDoc(doc(db('rider'), 'config/loyalty')));
  });
});
