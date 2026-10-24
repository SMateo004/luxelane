import { describe, it, expect } from '@jest/globals';
import { planEventDetail } from './event_details';

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
