// Entorno común de los tests de reglas: emulador de Firestore con el
// proyecto ficticio demo-luxelane (nunca un proyecto real).
// RULES_PATH permite apuntar a otro archivo de reglas (prueba negativa).
import { readFileSync } from 'fs';
import { resolve } from 'path';
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

const RULES_PATH =
  process.env.RULES_PATH ?? resolve(__dirname, '../../../firestore.rules');

export function startEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: 'demo-luxelane',
    firestore: { rules: readFileSync(RULES_PATH, 'utf8') },
  });
}

/**
 * Personas de las pruebas:
 * ana (pasajera dueña), beto (pasajero ajeno), nover (chófer sin
 * verificar), libre (chófer verificado sin asignar), asig (chófer
 * verificado y asignado), bloq (chófer verificado pero bloqueado) y admin.
 */
export const PERSONAS: Record<string, { role: string; isActive: boolean }> = {
  ana: { role: 'rider', isActive: true },
  beto: { role: 'rider', isActive: true },
  nover: { role: 'driver', isActive: true },
  libre: { role: 'driver', isActive: true },
  asig: { role: 'driver', isActive: true },
  bloq: { role: 'driver', isActive: false },
  admin: { role: 'admin', isActive: true },
};

const VERIFIED: Record<string, boolean> = {
  nover: false,
  libre: true,
  asig: true,
  bloq: true,
};

const place = (address: string) => ({
  name: '',
  address,
  coordinates: { latitude: -17.78, longitude: -63.18 },
});

/** Reserva de Ana con todos los datos sensibles posibles. */
export function bookingDoc(extra: Record<string, unknown> = {}) {
  return {
    riderId: 'ana',
    status: 'pending',
    estimatedPrice: 100,
    scheduledAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
    origin: place('Calle Exacta 123'),
    destination: place('Avenida Exacta 456'),
    notes: 'Toque el timbre dos veces',
    riderPreferences: { music: 'jazz' },
    guest: {
      title: 'Sra.',
      firstName: 'Carla',
      lastName: 'Tercero',
      phone: '+59170000001',
      email: 'carla@example.com',
      language: 'Español',
    },
    ...extra,
  };
}

export async function seed(env: RulesTestEnvironment): Promise<void> {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, p] of Object.entries(PERSONAS)) {
      await setDoc(doc(db, 'users', uid), { id: uid, ...p });
    }
    for (const [uid, verified] of Object.entries(VERIFIED)) {
      await setDoc(doc(db, 'driverProfiles', uid), {
        userId: uid,
        licenseNumber: `LIC-${uid}`,
        documentsVerified: verified,
        isAvailable: true,
      });
    }
    // Pendiente, en camino (asig), confirmada (asig), terminada (asig) y en
    // camino con el chófer bloqueado.
    await setDoc(doc(db, 'bookings', 'pend'), bookingDoc());
    await setDoc(doc(db, 'bookings', 'activa'),
      bookingDoc({ status: 'driver_arriving', driverId: 'asig' }));
    await setDoc(doc(db, 'bookings', 'conf'),
      bookingDoc({ status: 'confirmed', driverId: 'asig' }));
    await setDoc(doc(db, 'bookings', 'fin'),
      bookingDoc({ status: 'completed', driverId: 'asig' }));
    await setDoc(doc(db, 'bookings', 'activaBloq'),
      bookingDoc({ status: 'driver_arriving', driverId: 'bloq' }));
    for (const id of ['activa', 'conf', 'fin']) {
      await setDoc(doc(db, 'bookings', id, 'tracking', 'driver'), {
        lat: -17.7,
        lng: -63.1,
        updatedAt: Timestamp.now(),
      });
    }
    await setDoc(doc(db, 'openRequests', 'pend'), {
      vehicleClass: 'business',
      serviceType: 'oneWay',
      estimatedPrice: 100,
      scheduledAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
      pickupArea: 'Santa Cruz de la Sierra',
      pickupApprox: { lat: -17.78, lng: -63.18 },
    });
  });
}
