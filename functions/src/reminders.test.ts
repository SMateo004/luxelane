/**
 * Prompt 18, A1: plan de recordatorios (puro). Minutos y desfases de PRUEBA,
 * ficticios.
 */
import { describe, it, expect } from '@jest/globals';
import * as admin from 'firebase-admin';
import { planReminders, readReminderConfig, readState } from './reminders';

const MIN = 60_000;
const ANCHOR = Date.UTC(2026, 10, 20, 18);
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const cfg = readReminderConfig({ reminderOffsetsMinutes: { rider: [30, 120], driver: [15] }, unassignedAlertMinutes: 90 });
const empty = readState(undefined);
const b = (extra: Record<string, unknown> = {}) => ({ riderId: 'ana', status: 'pending', driverId: null,
  scheduledAt: ts(ANCHOR), ...extra });

describe('readReminderConfig', () => {
  it('ordena, quita repetidos y descarta lo que no son minutos enteros positivos', () => {
    expect(readReminderConfig({ reminderOffsetsMinutes: { rider: [30, 120, 30, -5, 0, 1.5, 'x', 99999999] } }))
      .toEqual({ rider: [120, 30], driver: [], unassigned: null });
  });
  it('sin las claves: nada', () => {
    expect(readReminderConfig({})).toEqual({ rider: [], driver: [], unassigned: null });
  });
});

describe('planReminders', () => {
  it('pagada y pendiente: los del pasajero y la alerta; sin pagar: nada', () => {
    const now = ANCHOR - 5 * 60 * MIN;
    expect(planReminders(b(), true, cfg, now, empty).state.nextAt).toBe(ANCHOR - 120 * MIN);
    expect(planReminders(b(), false, cfg, now, empty).state.nextAt).toBeNull();
  });

  it('el pasajero empieza a recibirlos al pagar: lo que ya pasó, no sale', () => {
    const now = ANCHOR - 60 * MIN;
    const { state, due } = planReminders(b({ driverId: 'luis', status: 'confirmed' }), true, cfg, now, empty);
    expect(state.skipped).toEqual(['rider:120']);
    expect(due).toEqual([]);
    expect(state.nextAt).toBe(ANCHOR - 30 * MIN);
  });

  it('la alerta sale aunque su hora ya pasara (es para central)', () => {
    const now = ANCHOR - 60 * MIN;
    const { due } = planReminders(b(), true, cfg, now, empty);
    expect(due.map((d) => d.key)).toEqual(['unassigned']);
  });

  it.each(['driver_arrived', 'verified', 'in_progress', 'completed', 'cancelled', 'no_show'])(
    'en %s no hay nada pendiente', (status) => {
      expect(planReminders(b({ status, driverId: 'luis' }), true, cfg, ANCHOR - 300 * MIN, empty).state.nextAt).toBeNull();
    });

  it('las claves no llevan identificadores de personas', () => {
    const { state } = planReminders(b({ driverId: 'luis', status: 'confirmed' }), true, cfg, ANCHOR - 60 * MIN, empty);
    expect(JSON.stringify(state.sent.concat(state.skipped))).not.toContain('luis');
  });
});
