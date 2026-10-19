// Pruebas de las reglas de Firestore contra el emulador.
// Ejecutar: cd firestore-tests && npm ci && npm test   (necesita Java)
//
// Cada caso es un uso real de la app (debe funcionar) o un uso torpe o
// malicioso (debe fallar). Los nombres describen el comportamiento esperado.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  GeoPoint,
  Timestamp,
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

let env;

const now = () => Timestamp.now();
const inHours = (h) => Timestamp.fromMillis(Date.now() + h * 3600e3);
const place = (lat, lng) => ({
  name: '',
  address: 'Santa Cruz',
  coordinates: new GeoPoint(lat, lng),
});

// Reserva tal como la escribe la app (Booking.toJson).
const newBooking = (riderId, extra = {}) => ({
  id: 'b1',
  riderId,
  driverId: null,
  origin: place(-17.78, -63.18),
  destination: place(-17.7, -63.15),
  scheduledAt: inHours(2),
  class: 'business',
  vehicleClass: 'business',
  serviceType: 'oneWay',
  status: 'pending',
  estimatedPrice: 95.5,
  finalPrice: null,
  paymentId: null,
  createdAt: now(),
  updatedAt: now(),
  notes: null,
  hours: null,
  passengerCount: 1,
  luggageCount: 0,
  ...extra,
});

const user = (role, extra = {}) => ({
  role,
  email: `${role}@test.com`,
  displayName: role,
  isActive: true,
  isVerified: false,
  fcmTokens: [],
  createdAt: now(),
  ...extra,
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

/** Escribe datos de partida sin pasar por las reglas. */
async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-luxelane',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (f) => {
    await setDoc(doc(f, 'users/rider'), user('rider'));
    await setDoc(doc(f, 'users/rider2'), user('rider'));
    await setDoc(doc(f, 'users/blocked'), user('rider', { isActive: false }));
    await setDoc(doc(f, 'users/driver'), user('driver'));
    await setDoc(doc(f, 'users/driver2'), user('driver'));
    await setDoc(doc(f, 'users/newdriver'), user('driver'));
    await setDoc(doc(f, 'users/admin'), user('admin'));
    const profile = (verified) => ({
      userId: 'x',
      licenseNumber: 'LP-1',
      documentsVerified: verified,
      rating: 5,
      totalRides: 3,
      isAvailable: false,
    });
    await setDoc(doc(f, 'driverProfiles/driver'), profile(true));
    await setDoc(doc(f, 'driverProfiles/driver2'), profile(true));
    await setDoc(doc(f, 'driverProfiles/newdriver'), profile(false));
  });
});

// ---------------------------------------------------------------------------

describe('reservas: crear', () => {
  test('un pasajero crea su reserva', async () => {
    await assertSucceeds(setDoc(doc(db('rider'), 'bookings/b1'), newBooking('rider')));
  });

  test('no puede reservar a nombre de otro', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'), newBooking('rider2')));
  });

  test('no puede fijarse un precio final ni un pago', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { finalPrice: 1 })));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { paymentId: 'pago-viejo' })));
  });

  test('no puede crearla ya completada ni con chófer elegido', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { status: 'completed' })));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { status: 'confirmed', driverId: 'driver' })));
  });

  test('precio cero o negativo no se acepta', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { estimatedPrice: 0 })));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { estimatedPrice: -10 })));
  });

  test('una recogida en el pasado no se acepta', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { scheduledAt: inHours(-3) })));
  });

  test('sin coordenadas de recogida no se acepta', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { origin: { address: 'Recogida' } })));
  });

  test('pasajeros o equipaje absurdos no se aceptan', async () => {
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { passengerCount: 0 })));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { passengerCount: 40 })));
  });

  test('no puede escribir campos del servidor (reparto, revisión, chófer)', async () => {
    for (const extra of [
      { settlement: { driverPayout: 999 } },
      { pricingReview: null },
      { driverName: 'Yo' },
      { riderRating: 5 },
    ]) {
      await assertFails(setDoc(doc(db('rider'), 'bookings/b1'), newBooking('rider', extra)));
    }
  });

  test('un usuario bloqueado no puede reservar', async () => {
    await assertFails(setDoc(doc(db('blocked'), 'bookings/b1'), newBooking('blocked')));
  });

  test('en modo mantenimiento nadie reserva', async () => {
    await seed((f) => setDoc(doc(f, 'config/global'), { isMaintenanceMode: true }));
    await assertFails(setDoc(doc(db('rider'), 'bookings/b1'), newBooking('rider')));
  });

  test('sin sesión no se reserva', async () => {
    await assertFails(setDoc(doc(anon(), 'bookings/b1'), newBooking('rider')));
  });
});

describe('reservas: leer', () => {
  beforeEach(async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'bookings/p1'), newBooking('rider', { id: 'p1' }));
      await setDoc(doc(f, 'bookings/c1'), newBooking('rider2', {
        id: 'c1', status: 'confirmed', driverId: 'driver2',
      }));
    });
  });

  test('el chófer verificado ve la lista de pendientes (consulta filtrada)', async () => {
    const q = query(collection(db('driver'), 'bookings'), where('status', '==', 'pending'));
    const snap = await assertSucceeds(getDocs(q));
    if (snap.size !== 1) throw new Error(`esperaba 1 pendiente, hubo ${snap.size}`);
  });

  test('sin filtro la consulta del chófer se rechaza (por eso la app filtra)', async () => {
    await assertFails(getDocs(collection(db('driver'), 'bookings')));
  });

  test('un chófer sin verificar no ve las pendientes', async () => {
    const q = query(collection(db('newdriver'), 'bookings'), where('status', '==', 'pending'));
    await assertFails(getDocs(q));
  });

  test('un pasajero no ve reservas de otros', async () => {
    await assertFails(getDoc(doc(db('rider'), 'bookings/c1')));
    await assertSucceeds(getDoc(doc(db('rider'), 'bookings/p1')));
  });

  test('el pasajero lista sus reservas', async () => {
    const q = query(collection(db('rider'), 'bookings'), where('riderId', '==', 'rider'));
    await assertSucceeds(getDocs(q));
  });
});

describe('reservas: chófer', () => {
  beforeEach(async () => {
    await seed((f) => setDoc(doc(f, 'bookings/b1'), newBooking('rider')));
  });

  const accept = (uid) => updateDoc(doc(db(uid), 'bookings/b1'), {
    driverId: uid, status: 'confirmed', updatedAt: now(),
  });

  test('un chófer verificado acepta una pendiente', async () => {
    await assertSucceeds(accept('driver'));
  });

  test('un chófer sin verificar no puede aceptar', async () => {
    await assertFails(accept('newdriver'));
  });

  test('un pasajero no puede asignarse como chófer', async () => {
    await assertFails(accept('rider2'));
  });

  test('dos chóferes: el segundo no puede quitarle el viaje al primero', async () => {
    await assertSucceeds(accept('driver'));
    await assertFails(accept('driver2'));
  });

  test('avanza paso a paso hasta completar', async () => {
    await assertSucceeds(accept('driver'));
    for (const s of ['driver_arriving', 'driver_arrived', 'in_progress', 'completed']) {
      await assertSucceeds(updateDoc(doc(db('driver'), 'bookings/b1'),
        { status: s, updatedAt: now() }));
    }
  });

  test('no puede saltar a completado ni volver atrás', async () => {
    await assertSucceeds(accept('driver'));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { status: 'completed' }));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { status: 'pending' }));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { status: 'inventado' }));
  });

  test('no puede tocar el precio', async () => {
    await assertSucceeds(accept('driver'));
    await assertFails(updateDoc(doc(db('driver'), 'bookings/b1'), { estimatedPrice: 9999 }));
  });
});

describe('reservas: pasajero cancela y valora', () => {
  const at = (status) => seed((f) => setDoc(doc(f, 'bookings/b1'),
    newBooking('rider', { status, driverId: status === 'pending' ? null : 'driver' })));
  const cancel = (uid = 'rider') => updateDoc(doc(db(uid), 'bookings/b1'),
    { status: 'cancelled', updatedAt: now() });

  for (const s of ['pending', 'confirmed', 'driver_arriving', 'driver_arrived']) {
    test(`puede cancelar en ${s}`, async () => {
      await at(s);
      await assertSucceeds(cancel());
    });
  }

  for (const s of ['in_progress', 'completed', 'cancelled']) {
    test(`no puede cancelar en ${s} (viajes gratis)`, async () => {
      await at(s);
      await assertFails(cancel());
    });
  }

  test('otro pasajero no puede cancelar mi reserva', async () => {
    await at('pending');
    await assertFails(cancel('rider2'));
  });

  test('valora una sola vez, de 1 a 5, solo si está completado', async () => {
    await at('completed');
    const rate = (v) => updateDoc(doc(db('rider'), 'bookings/b1'),
      { riderRating: v, riderComment: 'Muy bien', updatedAt: now() });
    await assertFails(rate(6));
    await assertFails(rate(0));
    await assertSucceeds(rate(5));
    await assertFails(rate(1));
  });

  test('no puede valorar un viaje no completado', async () => {
    await at('in_progress');
    await assertFails(updateDoc(doc(db('rider'), 'bookings/b1'), { riderRating: 5 }));
  });
});

describe('usuarios', () => {
  test('el registro crea un pasajero normal', async () => {
    await assertSucceeds(setDoc(doc(db('nuevo'), 'users/nuevo'), user('rider', { id: 'nuevo' })));
  });

  test('nadie se registra como admin, chófer, verificado o bloqueado a otro', async () => {
    await assertFails(setDoc(doc(db('n1'), 'users/n1'), user('admin')));
    await assertFails(setDoc(doc(db('n2'), 'users/n2'), user('driver')));
    await assertFails(setDoc(doc(db('n3'), 'users/n3'), user('rider', { isVerified: true })));
    await assertFails(setDoc(doc(db('n4'), 'users/otro'), user('rider')));
  });

  test('edita su nombre y teléfono y registra su token', async () => {
    await assertSucceeds(updateDoc(doc(db('rider'), 'users/rider'),
      { displayName: 'Ana', phone: '+591 70000000' }));
    await assertSucceeds(updateDoc(doc(db('rider'), 'users/rider'),
      { fcmTokens: arrayUnion('tok') }));
  });

  test('no puede cambiarse rol, bloqueo, verificación, email ni fecha', async () => {
    for (const f of [
      { role: 'admin' }, { isActive: false }, { isVerified: true },
      { email: 'x@y.com' }, { createdAt: 'nada' }, { stripeCustomerId: 'cus_x' },
    ]) {
      await assertFails(updateDoc(doc(db('rider'), 'users/rider'), f));
    }
  });

  test('nombre vacío o gigante no se acepta', async () => {
    await assertFails(updateDoc(doc(db('rider'), 'users/rider'), { displayName: '' }));
    await assertFails(updateDoc(doc(db('rider'), 'users/rider'),
      { displayName: 'x'.repeat(200) }));
  });

  test('un bloqueado no puede editar su perfil', async () => {
    await assertFails(updateDoc(doc(db('blocked'), 'users/blocked'), { displayName: 'B' }));
  });

  test('no lee el perfil de otro usuario', async () => {
    await assertFails(getDoc(doc(db('rider'), 'users/driver')));
  });
});

describe('perfiles de chófer', () => {
  test('el chófer no se verifica a sí mismo ni infla sus números', async () => {
    for (const f of [{ documentsVerified: true }, { rating: 5.0001 }, { totalRides: 999 }]) {
      await assertFails(updateDoc(doc(db('newdriver'), 'driverProfiles/newdriver'), f));
    }
  });

  test('sin verificar no puede conectarse; verificado sí', async () => {
    await assertFails(updateDoc(doc(db('newdriver'), 'driverProfiles/newdriver'),
      { isAvailable: true }));
    await assertSucceeds(updateDoc(doc(db('driver'), 'driverProfiles/driver'),
      { isAvailable: true }));
  });

  test('actualiza su ubicación', async () => {
    await assertSucceeds(updateDoc(doc(db('driver'), 'driverProfiles/driver'),
      { currentLocation: new GeoPoint(-17.78, -63.18), lastSeenAt: serverTimestamp() }));
  });

  test('nadie lista todos los chóferes salvo el admin', async () => {
    await assertFails(getDocs(collection(db('rider'), 'driverProfiles')));
    await assertSucceeds(getDocs(collection(db('admin'), 'driverProfiles')));
  });

  test('el pasajero sí lee el perfil de su chófer por id', async () => {
    await assertSucceeds(getDoc(doc(db('rider'), 'driverProfiles/driver')));
  });

  test('el alta del chófer empieza sin verificar', async () => {
    await seed((f) => setDoc(doc(f, 'users/alta'), user('driver')));
    await assertFails(setDoc(doc(db('alta'), 'driverProfiles/alta'),
      { documentsVerified: true, rating: 0, totalRides: 0 }));
    await assertSucceeds(setDoc(doc(db('alta'), 'driverProfiles/alta'),
      { documentsVerified: false, rating: 0, totalRides: 0, isAvailable: false }));
  });
});

describe('vehículos', () => {
  test('el chófer registra solo su vehículo v_<uid>', async () => {
    const v = { driverId: 'newdriver', class: 'business', isActive: true };
    await assertSucceeds(setDoc(doc(db('newdriver'), 'vehicles/v_newdriver'), v));
    await assertFails(setDoc(doc(db('newdriver'), 'vehicles/otro'), v));
  });

  test('no puede reactivar un vehículo bloqueado ni subir de clase', async () => {
    await seed((f) => setDoc(doc(f, 'vehicles/v_driver'),
      { driverId: 'driver', class: 'business', isActive: false, color: 'Negro' }));
    await assertFails(updateDoc(doc(db('driver'), 'vehicles/v_driver'), { isActive: true }));
    await assertFails(updateDoc(doc(db('driver'), 'vehicles/v_driver'), { class: 'firstClass' }));
    await assertSucceeds(updateDoc(doc(db('driver'), 'vehicles/v_driver'), { color: 'Gris' }));
  });
});

describe('configuración y auditoría', () => {
  beforeEach(async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'config/global'), { isMaintenanceMode: false });
      await setDoc(doc(f, 'config/finance'), { platformCommissionPct: 20 });
    });
  });

  test('la configuración pública se lee sin sesión; la financiera no', async () => {
    await assertSucceeds(getDoc(doc(anon(), 'config/global')));
    await assertFails(getDoc(doc(anon(), 'config/finance')));
    await assertFails(getDoc(doc(db('rider'), 'config/finance')));
    await assertSucceeds(getDoc(doc(db('admin'), 'config/finance')));
  });

  test('comisión fuera de 0-100 se rechaza incluso al admin', async () => {
    await assertFails(updateDoc(doc(db('admin'), 'config/finance'), { platformCommissionPct: 250 }));
  });

  test('el admin no puede firmar auditoría como otro', async () => {
    await assertFails(setDoc(doc(db('admin'), 'admin_logs/l1'), { adminId: 'otro' }));
    await assertSucceeds(setDoc(doc(db('admin'), 'admin_logs/l2'), { adminId: 'admin' }));
  });

  test('los pagos no los crea el cliente', async () => {
    await assertFails(setDoc(doc(db('rider'), 'payments/p1'),
      { riderId: 'rider', status: 'captured', amount: 1 }));
  });
});

describe('notificaciones y datos nuevos', () => {
  test('el usuario no se fabrica notificaciones; solo las lee y marca', async () => {
    await assertFails(setDoc(doc(db('rider'), 'users/rider/notifications/n1'),
      { title: 'x', body: 'y', isRead: false }));
    await seed((f) => setDoc(doc(f, 'users/rider/notifications/n1'),
      { title: 'x', body: 'y', isRead: false }));
    await assertSucceeds(updateDoc(doc(db('rider'), 'users/rider/notifications/n1'), { isRead: true }));
    await assertFails(updateDoc(doc(db('rider'), 'users/rider/notifications/n1'), { title: 'z' }));
    await assertFails(getDoc(doc(db('rider2'), 'users/rider/notifications/n1')));
  });

  test('la reserva guarda el método de pago', async () => {
    await assertSucceeds(setDoc(doc(db('rider'), 'bookings/b1'),
      newBooking('rider', { paymentMethod: 'cash' })));
  });

  test('el pasajero lista solo sus reservas', async () => {
    await assertSucceeds(getDocs(query(collection(db('rider'), 'bookings'),
      where('riderId', '==', 'rider'))));
    await assertFails(getDocs(query(collection(db('rider'), 'bookings'),
      where('riderId', '==', 'rider2'))));
  });

  test('el chófer reporta señal pero no toca su media de valoraciones', async () => {
    await assertSucceeds(updateDoc(doc(db('driver'), 'driverProfiles/driver'),
      { lastSeenAt: serverTimestamp(), isAvailable: true }));
    await assertFails(updateDoc(doc(db('driver'), 'driverProfiles/driver'),
      { ratingSum: 500, ratingCount: 100 }));
  });

  test('el pasajero no se inventa una cancelación del sistema', async () => {
    await seed((f) => setDoc(doc(f, 'bookings/b1'), newBooking('rider')));
    await assertFails(updateDoc(doc(db('rider'), 'bookings/b1'),
      { status: 'cancelled', cancelledBy: 'pricing' }));
  });
});

describe('programa para empresas', () => {
  beforeEach(async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'users/boss'), user('rider', { companyId: 'acme', companyRole: 'admin' }));
      await setDoc(doc(f, 'users/emp'), user('rider', { companyId: 'acme', companyRole: 'employee' }));
      await setDoc(doc(f, 'companies/acme'), { name: 'Acme', status: 'active' });
      await setDoc(doc(f, 'companies/acme/members/emp'), { role: 'employee', active: true });
      await setDoc(doc(f, 'companies/other'), { name: 'Otra', status: 'active' });
      await setDoc(doc(f, 'companyStatements/acme_2026-10'), { companyId: 'acme', totalBs: 100, status: 'issued' });
      await setDoc(doc(f, 'companyStatements/acme_2026-11'), { companyId: 'acme', totalBs: 50, status: 'draft' });
      await setDoc(doc(f, 'bookings/corp1'), newBooking('emp', { paymentMethod: 'corporate', companyId: 'acme' }));
      await setDoc(doc(f, 'companyInvites/acme_x'), { companyId: 'acme', email: 'nuevo@test.com', status: 'pending' });
    });
  });

  test('nadie se registra ya dentro de una empresa', async () => {
    await assertFails(setDoc(doc(db('n'), 'users/n'), user('rider', { companyId: 'acme', companyRole: 'admin' })));
  });

  test('nadie se añade a una empresa editando su perfil', async () => {
    await assertFails(updateDoc(doc(db('rider'), 'users/rider'), { companyId: 'acme', companyRole: 'admin' }));
    await assertFails(updateDoc(doc(db('emp'), 'users/emp'), { companyRole: 'admin' }));
  });

  test('el empleado reserva con la cuenta de su empresa, no con otra', async () => {
    await assertSucceeds(setDoc(doc(db('emp'), 'bookings/c2'),
      newBooking('emp', { paymentMethod: 'corporate', companyId: 'acme', costCenter: 'Ventas' })));
    await assertFails(setDoc(doc(db('emp'), 'bookings/c3'),
      newBooking('emp', { paymentMethod: 'corporate', companyId: 'other' })));
    await assertFails(setDoc(doc(db('rider'), 'bookings/c4'),
      newBooking('rider', { paymentMethod: 'corporate', companyId: 'acme' })));
    await assertFails(setDoc(doc(db('emp'), 'bookings/c5'),
      newBooking('emp', { paymentMethod: 'cash', companyId: 'acme' })));
    await assertFails(setDoc(doc(db('emp'), 'bookings/c6'),
      newBooking('emp', { paymentMethod: 'corporate', companyId: 'acme', statementId: 'x' })));
  });

  test('el admin de la empresa ve los viajes de su empresa; un empleado no ve los ajenos', async () => {
    await assertSucceeds(getDocs(query(collection(db('boss'), 'bookings'), where('companyId', '==', 'acme'))));
    await assertFails(getDocs(query(collection(db('emp'), 'bookings'), where('companyId', '==', 'acme'))));
    await assertFails(getDocs(query(collection(db('rider'), 'bookings'), where('companyId', '==', 'acme'))));
  });

  test('extractos y equipo: solo el admin de la empresa', async () => {
    await assertSucceeds(getDoc(doc(db('boss'), 'companyStatements/acme_2026-10')));
    await assertFails(getDoc(doc(db('emp'), 'companyStatements/acme_2026-10')));
    await assertFails(getDoc(doc(db('boss'), 'companyStatements/acme_2026-11')));
    await assertSucceeds(getDocs(query(collection(db('boss'), 'companyStatements'),
      where('companyId', '==', 'acme'), where('status', 'in', ['issued', 'paid']))));
    await assertSucceeds(getDocs(collection(db('boss'), 'companies/acme/members')));
    await assertSucceeds(getDoc(doc(db('emp'), 'companies/acme/members/emp')));
    await assertFails(getDocs(collection(db('emp'), 'companies/acme/members')));
    await assertSucceeds(getDoc(doc(db('emp'), 'companies/acme')));
    await assertFails(getDoc(doc(db('emp'), 'companies/other')));
  });

  test('nada de la empresa se escribe desde la app', async () => {
    await assertFails(updateDoc(doc(db('boss'), 'companies/acme'), { discountPct: 50 }));
    await assertFails(setDoc(doc(db('boss'), 'companies/acme/members/rider'), { role: 'admin' }));
    await assertFails(updateDoc(doc(db('boss'), 'companyStatements/acme_2026-10'), { totalBs: 0 }));
  });

  test('las invitaciones las ve el invitado (por su correo) y su empresa', async () => {
    const invited = env.authenticatedContext('nuevo', { email: 'Nuevo@Test.com' }).firestore();
    await assertSucceeds(getDoc(doc(invited, 'companyInvites/acme_x')));
    await assertSucceeds(getDoc(doc(db('boss'), 'companyInvites/acme_x')));
    await assertFails(getDoc(doc(db('rider'), 'companyInvites/acme_x')));
  });
});

describe('servicios especiales', () => {
  const inDays = (d) => Timestamp.fromMillis(Date.now() + d * 86400e3);
  const aerotaxi = (extra = {}) => ({
    riderId: 'rider', riderName: 'Ana', riderEmail: 'a@b.bo', riderPhone: '+591 7',
    kind: 'aerotaxi', date: inDays(3), passengers: 2,
    from: 'Santa Cruz', to: 'Uyuni', notes: '', status: 'new',
    createdAt: now(), updatedAt: now(), ...extra,
  });
  const tour = (extra = {}) => ({
    riderId: 'rider', riderName: 'Ana', kind: 'cityTour', date: inDays(1), passengers: 3,
    pickup: 'Hotel Los Tajibos', durationHours: 4, language: 'en', notes: 'Mercados',
    status: 'new', createdAt: now(), updatedAt: now(), ...extra,
  });

  test('el pasajero pide un aerotaxi o un paseo', async () => {
    await assertSucceeds(setDoc(doc(db('rider'), 'specialRequests/s1'), aerotaxi()));
    await assertSucceeds(setDoc(doc(db('rider'), 'specialRequests/s2'), tour()));
  });

  test('no se fabrican cotizaciones, fechas pasadas ni datos raros', async () => {
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x1'), aerotaxi({ status: 'quoted', quoteBs: 1 })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x2'), aerotaxi({ date: inDays(-1) })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x3'), aerotaxi({ to: 'Santa Cruz' })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x4'), aerotaxi({ passengers: 40 })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x5'), tour({ durationHours: 9 })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x6'), aerotaxi({ kind: 'submarino' })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x7'), aerotaxi({ riderId: 'rider2' })));
    await assertFails(setDoc(doc(db('blocked'), 'specialRequests/x8'), aerotaxi({ riderId: 'blocked' })));
    await assertFails(setDoc(doc(db('rider'), 'specialRequests/x9'), aerotaxi({ notes: 'x'.repeat(600) })));
  });

  test('el cliente acepta o cancela; no se pone precio ni ve las ajenas', async () => {
    await seed((f) => setDoc(doc(f, 'specialRequests/q1'), { ...aerotaxi(), status: 'quoted', quoteBs: 9000 }));
    await assertFails(updateDoc(doc(db('rider'), 'specialRequests/q1'), { quoteBs: 1 }));
    await assertFails(updateDoc(doc(db('rider'), 'specialRequests/q1'), { status: 'completed' }));
    await assertFails(getDoc(doc(db('rider2'), 'specialRequests/q1')));
    await assertSucceeds(updateDoc(doc(db('rider'), 'specialRequests/q1'), { status: 'confirmed', updatedAt: now() }));
    await assertFails(updateDoc(doc(db('rider'), 'specialRequests/q1'), { status: 'cancelled' }));
    await assertSucceeds(getDocs(query(collection(db('rider'), 'specialRequests'), where('riderId', '==', 'rider'))));
  });

  test('el admin cotiza', async () => {
    await seed((f) => setDoc(doc(f, 'specialRequests/n1'), aerotaxi()));
    await assertSucceeds(updateDoc(doc(db('admin'), 'specialRequests/n1'), { status: 'quoted', quoteBs: 8500, adminNote: 'Avioneta 5 plazas' }));
  });
});
