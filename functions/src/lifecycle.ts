// Reglas del ciclo de vida de una reserva que aplica el servidor.
// Funciones puras: index.ts las usa en los triggers y se prueban aparte.

export type BookingStatus =
  | 'pending'
  | 'confirmed'
  | 'driver_arriving'
  | 'driver_arrived'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export interface DriverBookkeeping {
  driverId: string;
  /** El chófer vuelve a estar libre para recibir viajes. */
  release: boolean;
  /** Suma un viaje completado a su historial. */
  countRide: boolean;
}

/**
 * Qué hacer con el perfil del chófer cuando cambia el estado de su reserva:
 * al completar se libera y suma un viaje; al cancelar solo se libera.
 */
export function driverBookkeeping(
  before: { status: BookingStatus; driverId?: string | null },
  after: { status: BookingStatus; driverId?: string | null },
): DriverBookkeeping | null {
  if (before.status === after.status) return null;
  const driverId = after.driverId ?? before.driverId;
  if (!driverId) return null;
  if (after.status === 'completed') return { driverId, release: true, countRide: true };
  if (after.status === 'cancelled') return { driverId, release: true, countRide: false };
  return null;
}

/** Aviso al pasajero por cada cambio de estado (push y bandeja de la app). */
export const RIDER_MESSAGES: Partial<Record<BookingStatus, { title: string; body: string; type: string }>> = {
  confirmed: {
    title: 'Chófer asignado',
    body: 'Ya tienes chófer para tu reserva.',
    type: 'booking_confirmed',
  },
  driver_arriving: {
    title: 'Tu chófer va en camino',
    body: 'Tu chófer se dirige al punto de recogida.',
    type: 'driver_arriving',
  },
  driver_arrived: {
    title: 'Tu chófer ha llegado',
    body: 'Tu chófer te espera en el punto de recogida.',
    type: 'driver_arrived',
  },
  in_progress: {
    title: 'Trayecto iniciado',
    body: 'Disfruta del viaje.',
    type: 'ride_started',
  },
  completed: {
    title: 'Has llegado',
    body: 'Gracias por viajar con Luxelane. Valora tu trayecto.',
    type: 'ride_completed',
  },
  cancelled: {
    title: 'Reserva cancelada',
    body: 'Tu reserva ha sido cancelada.',
    type: 'booking_cancelled',
  },
};

export function riderMessage(
  status: BookingStatus,
  cancelledBy?: string | null,
): { title: string; body: string; type: string } | null {
  const m = RIDER_MESSAGES[status];
  if (!m) return null;
  if (status === 'cancelled' && cancelledBy === 'rider') {
    return { ...m, body: 'Cancelaste tu reserva.' };
  }
  if (status === 'cancelled' && cancelledBy === 'corporate') {
    return {
      ...m,
      body: 'No pudimos cargar el viaje a la cuenta de tu empresa. Reserva con otro método de pago.',
    };
  }
  if (status === 'cancelled' && cancelledBy === 'pricing') {
    return {
      ...m,
      body: 'Las tarifas cambiaron mientras reservabas. Vuelve a reservar para ver el precio actual. No se te cobrará.',
    };
  }
  if (status === 'cancelled' && cancelledBy === 'system') {
    return {
      ...m,
      body: 'No encontramos chófer a tiempo y cancelamos tu reserva. No se te cobrará.',
    };
  }
  return m;
}

/** Datos del chófer y su vehículo que el pasajero ve en su reserva. */
export function driverSnapshot(
  user: { displayName?: string; phone?: string; photoUrl?: string | null } | undefined,
  vehicle: { make?: string; model?: string; color?: string; plate?: string } | undefined,
): Record<string, string | null> {
  const label = [vehicle?.make, vehicle?.model, vehicle?.color]
    .filter((s) => typeof s === 'string' && s.trim().length > 0)
    .join(' ');
  return {
    driverName: user?.displayName?.trim() || 'Tu chófer',
    driverPhone: user?.phone?.trim() || null,
    driverPhotoUrl: user?.photoUrl ?? null,
    vehicleLabel: label || null,
    vehiclePlate: vehicle?.plate?.trim() || null,
  };
}

/**
 * Una reserva pendiente que nadie aceptó caduca cuando su hora de recogida
 * pasó hace más de [graceMinutes]. Las reservas programadas para el futuro no
 * se tocan, aunque se hayan creado hace días.
 */
export function isExpiredPending(
  booking: { status: BookingStatus; scheduledAtMs?: number | null },
  nowMs: number,
  graceMinutes = 30,
): boolean {
  if (booking.status !== 'pending') return false;
  if (booking.scheduledAtMs == null) return false;
  return booking.scheduledAtMs < nowMs - graceMinutes * 60_000;
}

/**
 * Un chófer solo recibe viajes automáticos si su app reportó señal hace poco
 * (la app escribe `lastSeenAt` cada pocos segundos mientras está conectado).
 * Evita asignar a quien cerró la app o perdió cobertura sin desconectarse.
 */
export function isRecentlySeen(
  lastSeenMs: number | null | undefined,
  nowMs: number,
  maxMinutes = 10,
): boolean {
  if (lastSeenMs == null) return false;
  return nowMs - lastSeenMs <= maxMinutes * 60_000;
}

/**
 * Media de valoraciones del chófer tras una nueva (1 a 5). Perfiles antiguos
 * sin contador empiezan de cero, para que el 5.0 por defecto no cuente como
 * una valoración real.
 */
export function nextRating(
  prev: { ratingSum?: number | null; ratingCount?: number | null },
  stars: number,
): { rating: number; ratingSum: number; ratingCount: number } {
  const s = Math.min(5, Math.max(1, Math.round(stars)));
  const count = Math.max(0, prev.ratingCount ?? 0) + 1;
  const sum = Math.max(0, prev.ratingSum ?? 0) + s;
  return { rating: Math.round((sum / count) * 100) / 100, ratingSum: sum, ratingCount: count };
}
