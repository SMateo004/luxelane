/**
 * Eventos de reserva escritos antes de eventDetails (A8.7): el motivo del
 * admin y el control de llegada estaban en el propio evento, que leen el
 * pasajero y el chófer. Este plan los pasa a eventDetails/{mismo id} y los
 * quita del evento. Desde 0.2 también el uid del admin que actuó: en el
 * evento queda solo actor.role = 'admin'. Solo planifica; el script de
 * scripts/ decide si escribe.
 */
export const ADMIN_ONLY_EVENT_FIELDS = ['reason', 'farFromPickup', 'arrivalCheck'] as const;

export interface EventDetailPlan {
  detail: Record<string, unknown>;
  remove: string[];
  /** Actor nuevo del evento, si había que quitar el uid del admin. */
  actor?: { role: 'admin' };
}

export function planEventDetail(event: Record<string, unknown>): EventDetailPlan | null {
  const remove = ADMIN_ONLY_EVENT_FIELDS.filter((k) => k in event);
  const actor = event.actor as { uid?: unknown; role?: unknown } | undefined;
  const adminUid = actor?.role === 'admin' && typeof actor.uid === 'string' ? actor.uid : null;
  if (remove.length === 0 && adminUid === null) return null;
  const detail: Record<string, unknown> = Object.fromEntries(remove.map((k) => [k, event[k]]));
  if (adminUid !== null) detail.actorUid = adminUid;
  return { detail, remove: [...remove], ...(adminUid !== null ? { actor: { role: 'admin' as const } } : {}) };
}

/**
 * Incidentes (0.2): acknowledgedBy y closedBy eran el uid del admin en un
 * documento que lee quien disparó el SOS. Se quitan; el uid ya está en los
 * eventos del incidente y en admin_logs (solo admin).
 */
export const ADMIN_UID_INCIDENT_FIELDS = ['acknowledgedBy', 'closedBy'] as const;

export function planIncidentCleanup(incident: Record<string, unknown>): string[] {
  return ADMIN_UID_INCIDENT_FIELDS.filter((k) => k in incident);
}
