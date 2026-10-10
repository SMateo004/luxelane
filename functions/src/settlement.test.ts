import { describe, it, expect } from '@jest/globals';
import { computeSettlement } from './settlement';

describe('computeSettlement', () => {
  it('reparte un viaje completado con la comisión vigente', () => {
    expect(computeSettlement({ status: 'completed', estimatedPrice: 125.5 }, 20)).toEqual({
      amount: 125.5,
      commissionPct: 20,
      platformCommission: 25.1,
      driverPayout: 100.4,
    });
  });

  it('usa el precio final si existe', () => {
    expect(computeSettlement({ status: 'completed', estimatedPrice: 100, finalPrice: 150 }, 10)?.driverPayout).toBe(135);
  });

  it('no hace nada si no está completado o ya está repartido', () => {
    expect(computeSettlement({ status: 'in_progress', estimatedPrice: 100 }, 20)).toBeNull();
    const settlement = { amount: 100, commissionPct: 20, platformCommission: 20, driverPayout: 80 };
    expect(computeSettlement({ status: 'completed', estimatedPrice: 100, settlement }, 30)).toBeNull();
  });

  it('al ajustar el precio conserva el porcentaje fijado al completar', () => {
    const settlement = { amount: 100, commissionPct: 20, platformCommission: 20, driverPayout: 80 };
    expect(computeSettlement({ status: 'completed', estimatedPrice: 100, finalPrice: 120, settlement }, 30)).toEqual({
      amount: 120,
      commissionPct: 20,
      platformCommission: 24,
      driverPayout: 96,
    });
  });

  it('acota porcentajes fuera de rango', () => {
    expect(computeSettlement({ status: 'completed', estimatedPrice: 100 }, 150)?.driverPayout).toBe(0);
    expect(computeSettlement({ status: 'completed', estimatedPrice: 100 }, NaN)?.commissionPct).toBe(20);
  });
});
