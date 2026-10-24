/**
 * Eventos de reserva escritos antes de eventDetails (A8.7): el motivo del
 * admin y el control de llegada estaban en el propio evento, que leen el
 * pasajero y el chófer. Este plan los pasa a eventDetails/{mismo id} y los
 * quita del evento. Solo planifica; el script de scripts/ decide si escribe.
 */
export const ADMIN_ONLY_EVENT_FIELDS = ['reason', 'farFromPickup', 'arrivalCheck'] as const;

export interface EventDetailPlan {
  detail: Record<string, unknown>;
  remove: string[];
}

export function planEventDetail(event: Record<string, unknown>): EventDetailPlan | null {
  const remove = ADMIN_ONLY_EVENT_FIELDS.filter((k) => k in event);
  if (remove.length === 0) return null;
  return { detail: Object.fromEntries(remove.map((k) => [k, event[k]])), remove: [...remove] };
}
