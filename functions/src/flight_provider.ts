/**
 * Fuente de datos de vuelos (prompt de vuelos, A6).
 *
 * - FlightProvider: la consulta a una fuente. Implementaciones aquí: la
 *   manual (lo que fija un admin con adminSetFlightInfo vive en la reserva:
 *   esta fuente no aporta datos nuevos al planificador) y la de pruebas. La
 *   de la ATT NO está implementada.
 * - Caché por aeropuerto y fecha local: flightBoard/{AEROPUERTO_AAAA-MM-DD},
 *   solo la escribe el servidor (el planificador, Parte B). La app y las
 *   callables de reserva NUNCA consultan la fuente externa: solo leen esta
 *   caché.
 */
import * as admin from 'firebase-admin';
import { FlightStatus, FLIGHT_STATUSES } from './flight_time';

export interface FlightQuery {
  airportCode: string;
  /** Normalizado (normalizeFlightNumber). */
  flightNumber: string;
  /** Fecha local del vuelo, AAAA-MM-DD. */
  flightDate: string;
}

/** Lo que una fuente sabe de una llegada; horas en ms UTC (null si no las da). */
export interface ArrivalObservation {
  kind: 'found';
  status: FlightStatus;
  scheduled: number | null;
  estimated: number | null;
  actual: number | null;
  /** Cuándo la fuente dio este dato. */
  observedAt: number;
  /** Nombre corto de la fuente (para el panel y la auditoría). */
  sourceLabel: string;
}

export type ArrivalResult = ArrivalObservation | { kind: 'notFound' } | { kind: 'unavailable' };

export interface FlightProvider {
  readonly label: string;
  getArrival(q: FlightQuery): Promise<ArrivalResult>;
}

/**
 * Fuente manual: los datos los fija un admin en la reserva (A5), con su
 * bloqueo. Para el planificador no hay nada nuevo que leer.
 */
export class ManualFlightProvider implements FlightProvider {
  readonly label = 'manual';
  async getArrival(): Promise<ArrivalResult> {
    return { kind: 'notFound' };
  }
}

/** Solo pruebas: respuestas fijadas por vuelo. */
export class FakeFlightProvider implements FlightProvider {
  readonly label = 'fake';
  constructor(private readonly data: Map<string, ArrivalResult> = new Map(), public calls: FlightQuery[] = []) {}
  static key(q: FlightQuery): string {
    return `${q.airportCode}_${q.flightDate}_${q.flightNumber}`;
  }
  set(q: FlightQuery, r: ArrivalResult): void {
    this.data.set(FakeFlightProvider.key(q), r);
  }
  async getArrival(q: FlightQuery): Promise<ArrivalResult> {
    this.calls.push(q);
    return this.data.get(FakeFlightProvider.key(q)) ?? { kind: 'notFound' };
  }
}

// ---------------------------------------------------------------------------
// Caché flightBoard/{AEROPUERTO_AAAA-MM-DD}
// ---------------------------------------------------------------------------

/** Una llegada en la caché (horas como Timestamp). */
export interface BoardEntry {
  status: FlightStatus;
  scheduled: admin.firestore.Timestamp | null;
  estimated: admin.firestore.Timestamp | null;
  actual: admin.firestore.Timestamp | null;
  observedAt: admin.firestore.Timestamp;
  sourceLabel: string;
}

/** Documento: { airportCode, flightDate, flights: { [número]: BoardEntry }, updatedAt }. */
export const boardId = (airportCode: string, flightDate: string) => `${airportCode}_${flightDate}`;

const tsOrNull = (ms: number | null) => (ms === null ? null : admin.firestore.Timestamp.fromMillis(ms));
const msOrNull = (t: unknown) => (t instanceof admin.firestore.Timestamp ? t.toMillis() : null);

/** Lo que dice la caché de un vuelo; null si no está. */
export async function readBoard(db: admin.firestore.Firestore, q: FlightQuery): Promise<ArrivalObservation | null> {
  const snap = await db.collection('flightBoard').doc(boardId(q.airportCode, q.flightDate)).get();
  const e = (snap.data()?.flights as Record<string, Record<string, unknown>> | undefined)?.[q.flightNumber];
  if (!e || !FLIGHT_STATUSES.includes(e.status as FlightStatus)) return null;
  const observed = msOrNull(e.observedAt);
  if (observed === null) return null;
  return {
    kind: 'found', status: e.status as FlightStatus, scheduled: msOrNull(e.scheduled), estimated: msOrNull(e.estimated),
    actual: msOrNull(e.actual), observedAt: observed, sourceLabel: typeof e.sourceLabel === 'string' ? e.sourceLabel : 'auto',
  };
}

/** Guarda una observación en la caché (solo el servidor). */
export async function writeBoard(db: admin.firestore.Firestore, q: FlightQuery, o: ArrivalObservation): Promise<void> {
  const entry: BoardEntry = {
    status: o.status, scheduled: tsOrNull(o.scheduled), estimated: tsOrNull(o.estimated), actual: tsOrNull(o.actual),
    observedAt: admin.firestore.Timestamp.fromMillis(o.observedAt), sourceLabel: o.sourceLabel,
  };
  await db.collection('flightBoard').doc(boardId(q.airportCode, q.flightDate)).set({
    airportCode: q.airportCode, flightDate: q.flightDate, flights: { [q.flightNumber]: entry },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}
