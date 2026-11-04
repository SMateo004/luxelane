/**
 * Ventana del chófer, decisión 2: historial del chófer sin datos del
 * pasajero. Cuando una reserva con chófer llega a un estado final
 * (completed, cancelled, no_show), el servidor escribe
 * driverHistory/{driverId}/trips/{bookingId} con una lista cerrada de
 * campos. El chófer ya no lee la reserva fuera de su ventana (reglas).
 *
 * Lo escribe un disparador sobre bookings (writeDriverHistory, index.ts) y
 * no cada camino que cierra la reserva: así cubre todos los caminos de hoy
 * (advanceBooking, cancelBooking, adminUpdateBooking, adminForceNoShow, …),
 * los que se añadan, y los datos que llegan después del cierre (valoración
 * del pasajero, reparto, reembolso, ajuste del importe). La escritura es
 * idempotente: si el resumen ya es igual, no se escribe nada.
 */
import * as admin from 'firebase-admin';
import { approx, ApproxPoint, distanceKm } from './open_requests';

export const FINAL_STATUSES = ['completed', 'cancelled', 'no_show'] as const;
export type FinalStatus = (typeof FINAL_STATUSES)[number];

/**
 * Los únicos campos del resumen (el test de privacidad los compara uno a
 * uno). Nada de nombres, teléfonos, notas, direcciones exactas, vuelo,
 * preferencias ni comentario de la valoración. Los importes (estimatedPrice,
 * finalPrice, settlement, refunded) son los mismos campos que la pantalla de
 * ganancias del chófer ya leía de la reserva.
 */
export const SUMMARY_FIELDS = [
  'bookingId', 'status', 'endedAt', 'serviceType', 'vehicleClass',
  'pickupArea', 'dropoffArea', 'pickupApprox', 'dropoffApprox',
  'distanceKm', 'durationMinutes', 'riderRating',
  'estimatedPrice', 'finalPrice', 'settlement', 'refunded',
] as const;

export interface DriverTripSummary {
  bookingId: string;
  status: FinalStatus;
  endedAt: admin.firestore.Timestamp | null;
  serviceType: string | null;
  vehicleClass: string | null;
  pickupArea: string | null;
  dropoffArea: string | null;
  pickupApprox: ApproxPoint | null;
  dropoffApprox: ApproxPoint | null;
  distanceKm: number | null;
  durationMinutes: number | null;
  riderRating: number | null;
  estimatedPrice: number | null;
  finalPrice: number | null;
  settlement: { amount: number; commissionPct: number; platformCommission: number; driverPayout: number } | null;
  refunded: boolean;
}

type Data = admin.firestore.DocumentData;

const isTs = (v: unknown): v is admin.firestore.Timestamp => v instanceof admin.firestore.Timestamp;
const num = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const str = (v: unknown, max = 80): string | null =>
  (typeof v === 'string' && v.trim() && v.length <= max ? v.trim() : null);

export const isFinal = (s: unknown): s is FinalStatus => (FINAL_STATUSES as readonly unknown[]).includes(s);

/** Chófer al que pertenece el resumen: el asignado al cerrar. */
export const summaryDriver = (b: Data | undefined): string | null =>
  (b && isFinal(b.status) && typeof b.driverId === 'string' && b.driverId ? b.driverId : null);

function endedAt(b: Data): admin.firestore.Timestamp | null {
  const at = b.status === 'completed' ? b.completedAt : b.status === 'no_show' ? b.noShowAt : b.cancelledAt;
  if (isTs(at)) return at;
  return isTs(b.updatedAt) ? b.updatedAt : null;
}

function settlementOf(v: unknown): DriverTripSummary['settlement'] {
  if (!v || typeof v !== 'object') return null;
  const s = v as Record<string, unknown>;
  const amount = num(s.amount), pct = num(s.commissionPct), fee = num(s.platformCommission), pay = num(s.driverPayout);
  return amount === null || pct === null || fee === null || pay === null
    ? null : { amount, commissionPct: pct, platformCommission: fee, driverPayout: pay };
}

/** Resumen de una reserva en estado final con chófer, o null si no corresponde. */
export function buildDriverSummary(bookingId: string, b: Data | undefined): DriverTripSummary | null {
  if (!b || !summaryDriver(b)) return null;
  const hourly = b.serviceType === 'byTheHour';
  const from = b.origin?.coordinates;
  const to = b.destination?.coordinates;
  const routeKm = num(b.pricing?.breakdown?.km);
  const approxKm = !hourly && approx(from) && approx(to) ? Math.round(distanceKm(from, to) * 10) / 10 : null;
  const started = isTs(b.startedAt) ? b.startedAt.toMillis() : null;
  const completed = b.status === 'completed' && isTs(b.completedAt) ? b.completedAt.toMillis() : null;
  const rating = num(b.riderRating);
  return {
    bookingId,
    status: b.status,
    endedAt: endedAt(b),
    serviceType: str(b.serviceType, 20),
    vehicleClass: str(b.vehicleClass ?? b.class, 40),
    pickupArea: str(b.pickupArea),
    dropoffArea: hourly ? null : str(b.dropoffArea),
    pickupApprox: approx(from),
    dropoffApprox: hourly ? null : approx(to),
    // Kilómetros de la ruta con la que se cotizó; si no hay, la distancia en
    // línea recta entre zonas, como en openRequests.
    distanceKm: hourly ? null : routeKm ?? approxKm,
    // Duración real del trayecto (inicio a fin); sin ella, null.
    durationMinutes: started !== null && completed !== null && completed >= started
      ? Math.round((completed - started) / 60_000) : null,
    riderRating: rating !== null && Number.isInteger(rating) && rating >= 1 && rating <= 5 ? rating : null,
    estimatedPrice: num(b.estimatedPrice),
    finalPrice: num(b.finalPrice),
    settlement: settlementOf(b.settlement),
    refunded: b.refunded === true,
  };
}

export const driverTripRef = (db: admin.firestore.Firestore, driverId: string, bookingId: string) =>
  db.collection('driverHistory').doc(driverId).collection('trips').doc(bookingId);

/** Comparación estable (Timestamp por milisegundos). */
function same(a: Data | undefined, b: Data): boolean {
  const norm = (v: unknown): unknown => {
    if (isTs(v)) return { __ts: v.toMillis() };
    if (Array.isArray(v)) return v.map(norm);
    if (v && typeof v === 'object') {
      return Object.fromEntries(Object.keys(v as object).sort().map((k) => [k, norm((v as Data)[k])]));
    }
    return v;
  };
  return a !== undefined && JSON.stringify(norm(a)) === JSON.stringify(norm(b));
}

export type HistoryWrite = 'skipped' | 'unchanged' | 'written';

/**
 * Escribe (o deja igual) el resumen de la reserva. Lee la reserva en la
 * transacción: el dato es el de ahora, no el del evento que despertó al
 * disparador (un reintento tardío no pisa un dato más nuevo).
 */
export async function writeDriverHistory(db: admin.firestore.Firestore, bookingId: string): Promise<HistoryWrite> {
  return db.runTransaction(async (tx) => {
    const booking = await tx.get(db.collection('bookings').doc(bookingId));
    const b = booking.data();
    const driverId = summaryDriver(b);
    const summary = buildDriverSummary(bookingId, b);
    if (!driverId || !summary) return 'skipped';
    const ref = driverTripRef(db, driverId, bookingId);
    const current = await tx.get(ref);
    if (same(current.data(), summary as unknown as Data)) return 'unchanged';
    tx.set(ref, summary);
    return 'written';
  });
}
