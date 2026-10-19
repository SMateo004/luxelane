/**
 * Reconciliación de solicitudes abiertas (D5): cada reserva pendiente debe
 * tener su openRequests y ninguna solicitud debe quedar sin reserva
 * pendiente. Cada arreglo se revalida en una transacción, y si hubo alguno
 * se escribe una alerta para el admin. Correr dos veces seguidas no cambia
 * nada la segunda vez.
 */
import * as admin from 'firebase-admin';
import { buildOpenRequest, BookingForRequest } from './open_requests';

export interface ReconcileResult {
  created: string[];
  deleted: string[];
}

export async function reconcileOpenRequests(
  db: admin.firestore.Firestore,
  now: () => admin.firestore.Timestamp = admin.firestore.Timestamp.now,
): Promise<ReconcileResult> {
  const [pending, requests] = await Promise.all([
    db.collection('bookings').where('status', '==', 'pending').get(),
    db.collection('openRequests').select().get(),
  ]);
  const pendingIds = new Set(pending.docs.map((d) => d.id));
  const requestIds = new Set(requests.docs.map((d) => d.id));

  const created: string[] = [];
  for (const id of pendingIds) {
    if (requestIds.has(id)) continue;
    const fixed = await db.runTransaction(async (tx) => {
      const bookingRef = db.collection('bookings').doc(id);
      const requestRef = db.collection('openRequests').doc(id);
      const [booking, request] = await Promise.all([tx.get(bookingRef), tx.get(requestRef)]);
      if (booking.data()?.status !== 'pending' || request.exists) return false;
      tx.set(requestRef, buildOpenRequest(booking.data() as BookingForRequest));
      return true;
    });
    if (fixed) created.push(id);
  }

  const deleted: string[] = [];
  for (const id of requestIds) {
    if (pendingIds.has(id)) continue;
    const fixed = await db.runTransaction(async (tx) => {
      const bookingRef = db.collection('bookings').doc(id);
      const requestRef = db.collection('openRequests').doc(id);
      const [booking, request] = await Promise.all([tx.get(bookingRef), tx.get(requestRef)]);
      if (!request.exists || booking.data()?.status === 'pending') return false;
      tx.delete(requestRef);
      return true;
    });
    if (fixed) deleted.push(id);
  }

  if (created.length || deleted.length) {
    await db.collection('adminAlerts').add({
      type: 'open_requests_reconciled',
      message: 'Solicitudes abiertas corregidas: faltaban para reservas pendientes ' +
        'o seguían visibles sin reserva pendiente.',
      created,
      deleted,
      createdAt: now(),
      resolved: false,
    });
  }
  return { created, deleted };
}
