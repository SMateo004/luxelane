import { describe, it, expect } from '@jest/globals';
import { planEventDetail, planIncidentCleanup } from './event_details';

describe('planEventDetail', () => {
  it('pasa el motivo del admin a eventDetails y lo quita del evento', () => {
    expect(planEventDetail({ to: 'verified', method: 'admin_override', reason: 'Sin batería' }))
      .toEqual({ detail: { reason: 'Sin batería' }, remove: ['reason'] });
  });

  it('pasa el control de llegada', () => {
    expect(planEventDetail({ to: 'driver_arrived', arrivalCheck: 'compared', farFromPickup: true }))
      .toEqual({ detail: { farFromPickup: true, arrivalCheck: 'compared' }, remove: ['farFromPickup', 'arrivalCheck'] });
  });

  it('un evento sin esos campos no se toca', () => {
    expect(planEventDetail({ to: 'in_progress', hasLocation: false })).toBeNull();
  });
});

describe('0.2: el uid del admin sale de los eventos y de los incidentes', () => {
  it('evento con actor admin: el uid pasa a eventDetails y queda solo el rol', () => {
    expect(planEventDetail({ to: 'verified', actor: { uid: 'jefa', role: 'admin' } }))
      .toEqual({ detail: { actorUid: 'jefa' }, remove: [], actor: { role: 'admin' } });
  });

  it('con motivo y actor admin a la vez', () => {
    expect(planEventDetail({ reason: 'Sin batería', actor: { uid: 'jefa', role: 'admin' } }))
      .toEqual({ detail: { reason: 'Sin batería', actorUid: 'jefa' }, remove: ['reason'], actor: { role: 'admin' } });
  });

  it('el chófer como actor no se toca; un evento ya migrado tampoco', () => {
    expect(planEventDetail({ to: 'in_progress', actor: { uid: 'chofer', role: 'driver' } })).toBeNull();
    expect(planEventDetail({ to: 'verified', actor: { role: 'admin' } })).toBeNull();
  });

  it('incidente: quita acknowledgedBy y closedBy', () => {
    expect(planIncidentCleanup({ status: 'closed', acknowledgedBy: 'jefa', closedBy: 'jefa' }))
      .toEqual(['acknowledgedBy', 'closedBy']);
    expect(planIncidentCleanup({ status: 'open' })).toEqual([]);
  });
});
