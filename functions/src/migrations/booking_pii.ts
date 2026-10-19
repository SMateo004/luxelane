/**
 * Migración de reservas existentes (D5/F4/D16):
 * - Los datos del invitado que la app antigua concatenaba en `notes`
 *   ("Pasajero: Sra. Nombre Apellido · correo · teléfono\nnota") pasan al
 *   campo `guest`, y `notes` conserva solo la nota libre.
 * - Las reservas pendientes sin solicitud abierta reciben su `openRequests`.
 * - El teléfono del chófer sale de `driverInfo` y, en reservas que aún
 *   llegarán o están en la ventana activa, pasa a driverContact/phone.
 * Solo planifica; el script de scripts/ decide si escribe.
 */
import { buildOpenRequest, BookingForRequest, OpenRequest } from '../open_requests';

const PREFIX = 'Pasajero: ';
const TITLES = ['Sr.', 'Sra.', 'Srta.', 'Dr.', 'Prof.'];

export interface Guest {
  title?: string;
  firstName: string;
  lastName?: string;
  phone?: string;
  email?: string;
}

/** Datos del invitado y nota libre a partir del texto antiguo, o null. */
export function parseLegacyNotes(notes: unknown): { guest: Guest; notes: string | null } | null {
  if (typeof notes !== 'string' || !notes.startsWith(PREFIX)) return null;
  const [first, ...rest] = notes.split('\n');
  const [names, ...contacts] = first.slice(PREFIX.length).split(' · ');
  const words = names.trim().split(/\s+/).filter(Boolean);
  const title = TITLES.includes(words[0]) ? words.shift() : undefined;
  if (!words.length) return null;
  const guest: Guest = { firstName: words[0] };
  if (title) guest.title = title;
  if (words.length > 1) guest.lastName = words.slice(1).join(' ');
  for (const c of contacts.map((c) => c.trim()).filter(Boolean)) {
    if (c.includes('@')) guest.email = c;
    else guest.phone = c;
  }
  const free = rest.join('\n').trim();
  return { guest, notes: free || null };
}

/**
 * Estados en que el teléfono sigue haciendo falta: la ventana activa y la
 * reserva confirmada que entrará en ella (las reglas no dejan leerlo antes
 * de driver_arriving). En el historial se borra sin copiarlo.
 */
const CONTACT_STATUSES = ['confirmed', 'driver_arriving', 'driver_arrived', 'in_progress'];

export interface BookingPlan {
  /** Nuevo `guest` y nueva `notes` (null = borrar el campo). */
  guest?: { guest: Guest; notes: string | null };
  /** Solicitud abierta a crear (reserva pendiente sin ella). */
  openRequest?: OpenRequest;
  /** Quitar driverInfo.phone; `contact` = teléfono a copiar en driverContact. */
  driverPhone?: { contact: string | null };
}

export function planBookingMigration(
  booking: Record<string, unknown>,
  hasOpenRequest: boolean,
  hasDriverContact = false,
): BookingPlan {
  const plan: BookingPlan = {};
  if (!booking.guest) {
    const parsed = parseLegacyNotes(booking.notes);
    if (parsed) plan.guest = parsed;
  }
  if (booking.status === 'pending' && !hasOpenRequest) {
    plan.openRequest = buildOpenRequest(booking as BookingForRequest);
  }
  const info = booking.driverInfo as Record<string, unknown> | undefined;
  if (info && typeof info === 'object' && 'phone' in info) {
    const phone = typeof info.phone === 'string' ? info.phone.trim() : '';
    const keep = phone !== '' && !hasDriverContact &&
      CONTACT_STATUSES.includes(booking.status as string);
    plan.driverPhone = { contact: keep ? phone : null };
  }
  return plan;
}

/** Descripción de la acción sin datos personales (para el informe). */
export function describePlan(plan: BookingPlan): string[] {
  const out: string[] = [];
  if (plan.guest) {
    const fields = Object.keys(plan.guest.guest).join(', ');
    out.push(`mover invitado de notes a guest (${fields}); notes ` +
      (plan.guest.notes === null ? 'se borra' : `queda con ${plan.guest.notes.length} caracteres`));
  }
  if (plan.openRequest) out.push('crear openRequests (reserva pendiente)');
  if (plan.driverPhone) {
    out.push(plan.driverPhone.contact
      ? 'quitar teléfono del chófer de driverInfo y copiarlo a driverContact'
      : 'quitar teléfono del chófer de driverInfo (sin copiarlo)');
  }
  return out;
}
