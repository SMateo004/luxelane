import { describe, it, expect } from '@jest/globals';
import { clock, langOf, money, t, vehicleName } from './messages';

describe('push messages', () => {
  it('maps device locales to supported languages, defaulting to Spanish', () => {
    expect(langOf('en')).toBe('en');
    expect(langOf('pt-BR')).toBe('pt');
    expect(langOf('de')).toBe('es');
    expect(langOf(undefined)).toBe('es');
  });

  it('formats money per language', () => {
    expect(money(1250, 'es')).toBe('Bs 1.250');
    expect(money(1250, 'en')).toBe('Bs 1,250');
  });

  it('formats Bolivian local time', () => {
    const d = new Date('2026-10-07T18:35:00Z'); // 14:35 in La Paz
    expect(clock(d, 'es')).toBe('14:35');
    expect(clock(d, 'en')).toMatch(/02:35\s?PM/);
  });

  it('fills placeholders in every language', () => {
    for (const lang of ['es', 'en', 'pt'] as const) {
      const msg = t(lang, 'flightDelayed', { flight: 'OB760', minutes: 45, time: '15:05' });
      expect(msg).toContain('OB760');
      expect(msg).toContain('45');
      expect(msg).not.toMatch(/\{\w+\}/);
    }
    expect(t('en', 'statusArrived', { time: '2:35 PM' })).toBe('Your chauffeur has arrived. Free waiting until 2:35 PM.');
    expect(vehicleName('electric', 'pt')).toBe('Elétrico');
  });
});
