/**
 * El pago antes de pedir chófer (A3). createBooking deja la reserva en
 * awaiting_payment; nada la ofrece a un chófer (openRequests, aviso,
 * assignNearestDriver, acceptBooking, asignación del admin, regla de
 * auto-aceptación) hasta que su pago está en paid.
 */
import * as admin from 'firebase-admin';
import { buildOpenRequest, BookingForRequest } from './open_requests';
import {
  cents, newPaymentRef, PaymentMethod, PaymentState, paymentRefDoc, paymentStateRef,
} from './payment_model';

/** Intentos de referencia nueva antes de rendirse (colisión casi imposible). */
const REF_ATTEMPTS = 5;

/**
 * Elige una referencia libre. Solo lee: va antes de cualquier escritura de
 * la transacción.
 */
export async function reservePaymentRef(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  generate: () => string = () => newPaymentRef()): Promise<string> {
  for (let i = 0; i < REF_ATTEMPTS; i++) {
    const ref = generate();
    if (!(await tx.get(paymentRefDoc(db, ref))).exists) return ref;
  }
  throw new Error('payment_ref_exhausted');
}

export interface InitialPayment {
  bookingId: string;
  riderId: string;
  /** Precio del servidor en bolivianos (estimatedPrice). */
  price: number;
  paymentRef: string;
  now: admin.firestore.Timestamp;
  /** config/ops.paymentWindowMinutes; null: sin vencimiento automático. */
  windowMinutes: number | null;
  /** Métodos activos al crear la reserva (la app los ofrece; startPayment revalida). */
  methodsOffered: PaymentMethod[];
}

/** Escribe el estado inicial del pago y reserva la referencia. */
export function writeInitialPayment(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  p: InitialPayment): PaymentState {
  const state: PaymentState = {
    bookingId: p.bookingId,
    riderId: p.riderId,
    paymentStatus: 'awaiting_payment',
    paymentMethod: null,
    amountDue: cents(p.price),
    amountPaid: 0,
    paymentRef: p.paymentRef,
    paidAt: null,
    paymentDeadline: p.windowMinutes === null
      ? null
      : admin.firestore.Timestamp.fromMillis(p.now.toMillis() + p.windowMinutes * 60_000),
    createdAt: p.now,
    updatedAt: p.now,
    methodsOffered: p.methodsOffered,
  };
  tx.set(paymentStateRef(db, p.bookingId), state);
  tx.create(paymentRefDoc(db, p.paymentRef), { bookingId: p.bookingId, createdAt: p.now });
  return state;
}

/** Respuesta de createBooking sobre el pago (lo que la app necesita para pagar). */
export function paymentSummary(s: Partial<PaymentState> | undefined) {
  return {
    paymentStatus: s?.paymentStatus ?? null,
    paymentRef: s?.paymentRef ?? null,
    amountDue: s?.amountDue ?? null,
    paymentDeadline: s?.paymentDeadline ? s.paymentDeadline.toMillis() : null,
    methodsOffered: s?.methodsOffered ?? [],
  };
}

/** El pago de la reserva está confirmado. Sin estado (reservas antiguas): no. */
export const isPaid = (s: admin.firestore.DocumentSnapshot | undefined): boolean =>
  s?.data()?.paymentStatus === 'paid';

/** Lee el estado dentro de una transacción (o fuera, sin tx). */
export async function readPaymentState(db: admin.firestore.Firestore, bookingId: string,
  tx?: admin.firestore.Transaction): Promise<admin.firestore.DocumentSnapshot> {
  const ref = paymentStateRef(db, bookingId);
  return tx ? tx.get(ref) : ref.get();
}

/**
 * Abre la solicitud para los chóferes si la reserva sigue esperando chófer.
 * Solo se llama con el pago confirmado.
 */
export function openForDrivers(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  bookingId: string, booking: admin.firestore.DocumentData): boolean {
  if (booking.status !== 'pending' || booking.driverId) return false;
  tx.set(db.collection('openRequests').doc(bookingId), buildOpenRequest(booking as BookingForRequest));
  return true;
}
