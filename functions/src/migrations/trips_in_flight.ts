/**
 * Viajes en curso al desplegar las reglas de la verificación en recogida
 * (D1). Con las reglas nuevas, la app antigua del chófer ya no puede
 * escribir status: un viaje que avanzó con ella se queda en su paso. Los
 * que avanzan por advanceBooking dejan eventos; los de la app antigua no.
 * Solo clasifica; el script no escribe nada.
 */

/** Estados en que un chófer está en medio del viaje. */
export const IN_FLIGHT = ['confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress'] as const;

export interface InFlightTrip {
  id: string;
  status: string;
  /** Tiene eventos: avanza por advanceBooking (app nueva). */
  serverFlow: boolean;
}

export interface InFlightReport {
  total: number;
  byStatus: Record<string, number>;
  /** Viajes que dependen de la app antigua: bloquean el despliegue de reglas. */
  blocking: InFlightTrip[];
}

/** Qué hacer si uno de estos viajes queda bloqueado tras las reglas. */
export function remedyFor(status: string): string {
  switch (status) {
    case 'confirmed':
    case 'driver_arriving':
      return 'el chófer actualiza la app y sigue desde el mismo paso';
    case 'driver_arrived':
      return 'el chófer actualiza la app y pide el código; si el pasajero no lo tiene, «Forzar verificación»';
    case 'in_progress':
      return 'el chófer actualiza la app para completar, o el admin lo marca «Completado» desde el panel';
    default:
      return 'revisar en el panel';
  }
}

export function classifyInFlight(trips: InFlightTrip[]): InFlightReport {
  const active = trips.filter((t) => (IN_FLIGHT as readonly string[]).includes(t.status));
  const byStatus: Record<string, number> = {};
  for (const t of active) byStatus[t.status] = (byStatus[t.status] ?? 0) + 1;
  // Confirmada sin eventos es normal: el chófer aún no salió. Solo bloquea
  // si ya dio pasos con la app antigua (driver_arriving en adelante).
  const blocking = active.filter((t) => !t.serverFlow && t.status !== 'confirmed' && t.status !== 'verified');
  return { total: active.length, byStatus, blocking };
}

/** Proyectos en los que el script no se ejecuta nunca. */
export const FORBIDDEN_PROJECTS = ['luxelane-4e7ae'];

export function assertTarget(project: string, emulatorHost: string | undefined): void {
  if (FORBIDDEN_PROJECTS.includes(project)) {
    throw new Error(`Este script no se ejecuta contra ${project}. En producción, revisa los viajes activos en el panel (Operaciones, filtro por estado).`);
  }
  if (project.startsWith('demo-') && !emulatorHost) {
    throw new Error('Un proyecto demo-* solo existe en el emulador: define FIRESTORE_EMULATOR_HOST.');
  }
}
