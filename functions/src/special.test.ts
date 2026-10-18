import { describe as d, it, expect } from '@jest/globals';
import { specialNotice } from './special';

const req = { kind: 'aerotaxi' as const, status: 'new' as const, riderName: 'Ana', from: 'Santa Cruz', to: 'Uyuni' };

d('specialNotice', () => {
  it('una solicitud nueva avisa a los administradores', () => {
    expect(specialNotice(null, req)).toEqual({ to: 'admins', title: 'Nueva solicitud especial', body: 'Ana pide Aerotaxi Santa Cruz → Uyuni.' });
  });
  it('la cotización avisa al cliente con el importe', () => {
    const n = specialNotice(req, { ...req, status: 'quoted', quoteBs: 8500 });
    expect(n?.to).toBe('rider');
    expect(n?.body).toContain('8');
    expect(n?.body).toContain('500');
  });
  it('aceptar o cancelar avisa a Luxelane; sin cambio de estado no hay aviso', () => {
    expect(specialNotice({ ...req, status: 'quoted' }, { ...req, status: 'confirmed', quoteBs: 10 })?.to).toBe('admins');
    expect(specialNotice({ ...req, status: 'new' }, { ...req, status: 'cancelled' })?.title).toBe('Solicitud cancelada');
    expect(specialNotice(req, { ...req })).toBeNull();
  });
  it('describe el paseo por horas', () => {
    const tour = { kind: 'cityTour' as const, status: 'new' as const, durationHours: 4 };
    expect(specialNotice(null, tour)?.body).toContain('Paseo por la ciudad · 4 h');
  });
});
