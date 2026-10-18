// Servicios especiales bajo cotización (aerotaxi, paseo por la ciudad):
// qué aviso corresponde a cada cambio de estado. Funciones puras.

export type SpecialKind = 'aerotaxi' | 'cityTour';
export type SpecialStatus = 'new' | 'quoted' | 'confirmed' | 'declined' | 'cancelled' | 'completed';

export interface SpecialRequest {
  kind: SpecialKind;
  status: SpecialStatus;
  riderName?: string;
  from?: string;
  to?: string;
  pickup?: string;
  durationHours?: number;
  quoteBs?: number | null;
  adminNote?: string | null;
}

export interface Notice {
  to: 'rider' | 'admins';
  title: string;
  body: string;
}

export function describe(r: SpecialRequest): string {
  return r.kind === 'aerotaxi'
    ? `Aerotaxi ${r.from ?? ''} → ${r.to ?? ''}`.trim()
    : `Paseo por la ciudad · ${r.durationHours ?? ''} h`;
}

const money = (n?: number | null) => `Bs ${Number(n ?? 0).toLocaleString('es-BO', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;

/** Aviso a enviar cuando una solicitud se crea (before = null) o cambia. */
export function specialNotice(before: SpecialRequest | null, after: SpecialRequest | null): Notice | null {
  if (!after) return null;
  const what = describe(after);
  if (!before) {
    return { to: 'admins', title: 'Nueva solicitud especial', body: `${after.riderName || 'Un cliente'} pide ${what}.` };
  }
  if (before.status === after.status) return null;
  switch (after.status) {
    case 'quoted':
      return { to: 'rider', title: 'Tu cotización está lista', body: `${what}: ${money(after.quoteBs)}. Revísala en Servicios especiales.` };
    case 'declined':
      return { to: 'rider', title: 'No podemos atender tu solicitud', body: `${what}.${after.adminNote ? ` ${after.adminNote}` : ''}` };
    case 'confirmed':
      return { to: 'admins', title: 'Cotización aceptada', body: `${after.riderName || 'El cliente'} confirmó ${what} por ${money(after.quoteBs)}.` };
    case 'cancelled':
      return { to: 'admins', title: 'Solicitud cancelada', body: `${after.riderName || 'El cliente'} canceló ${what}.` };
    case 'completed':
      return { to: 'rider', title: 'Gracias por viajar con Luxelane', body: `${what} completado.` };
    default:
      return null;
  }
}
