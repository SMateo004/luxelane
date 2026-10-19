import { describe, it, expect } from '@jest/globals';
import { describePlan, parseLegacyNotes, planBookingMigration } from './booking_pii';

describe('parseLegacyNotes', () => {
  it('separa el invitado de la nota libre', () => {
    expect(parseLegacyNotes(
      'Pasajero: Sra. Carla María Tercero · carla@example.com · +59170000001\nLlevar agua\nGracias',
    )).toEqual({
      guest: {
        title: 'Sra.',
        firstName: 'Carla',
        lastName: 'María Tercero',
        email: 'carla@example.com',
        phone: '+59170000001',
      },
      notes: 'Llevar agua\nGracias',
    });
  });

  it('sin nota libre deja notes vacía; sin contactos, solo el nombre', () => {
    expect(parseLegacyNotes('Pasajero: Sr. Luis  ')).toEqual({
      guest: { title: 'Sr.', firstName: 'Luis' },
      notes: null,
    });
  });

  it('no toca notas que no son del formato antiguo', () => {
    expect(parseLegacyNotes('Toque el timbre')).toBeNull();
    expect(parseLegacyNotes(undefined)).toBeNull();
    expect(parseLegacyNotes('Pasajero: ')).toBeNull();
  });
});

describe('planBookingMigration', () => {
  const legacy = {
    status: 'pending',
    riderId: 'ana',
    notes: 'Pasajero: Sra. Carla Tercero · +59170000001\nLlevar agua',
    origin: { address: 'Calle Exacta 1', coordinates: { latitude: -17.78, longitude: -63.18 } },
  };

  it('planifica mover el invitado y crear la solicitud abierta', () => {
    const plan = planBookingMigration(legacy, false);
    expect(plan.guest?.guest.firstName).toBe('Carla');
    expect(plan.guest?.notes).toBe('Llevar agua');
    expect(plan.openRequest?.pickupApprox).toEqual({ lat: -17.78, lng: -63.18 });
  });

  it('no repite lo ya migrado', () => {
    const plan = planBookingMigration({ ...legacy, guest: { firstName: 'Carla' } }, true);
    expect(plan).toEqual({});
  });

  it('el informe no incluye datos personales', () => {
    const text = describePlan(planBookingMigration(legacy, false)).join(' ');
    expect(text).toContain('mover invitado');
    for (const secret of ['Carla', 'Tercero', '+5917', 'agua', 'Exacta']) {
      expect(text).not.toContain(secret);
    }
  });
});
