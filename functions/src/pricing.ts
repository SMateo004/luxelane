// Red de seguridad de onBookingCreated: comprueba que una reserva respeta la
// tarifa vigente (servicio activo y no por debajo del mínimo).
//
// El precio lo calcula createBooking con fare.ts y /pricingRules. No hay
// tarifas en el código (D20): sin tarifa en Firestore, createBooking no
// reserva y este control marca la reserva para revisión (unknown_fare).
// Los importes están en bolivianos aunque los campos se llamen *Usd.

export interface FareRule {
  basePriceUsd: number;
  pricePerKmUsd: number;
  pricePerHourUsd: number;
  minimumPriceUsd: number;
  isActive?: boolean;
}

export const fareId = (vehicleClass: string, serviceType: string): string =>
  `${vehicleClass}_${serviceType}`;

export interface PriceCheck {
  ok: boolean;
  reason?: string;
  expectedMinimum?: number;
}

/** Comprueba una reserva contra la tarifa vigente (o la de fábrica). */
export function checkBookingPrice(
  booking: { estimatedPrice?: number; hours?: number | null; serviceType?: string },
  rule: FareRule | undefined,
): PriceCheck {
  if (!rule) return { ok: false, reason: 'unknown_fare' };
  if (rule.isActive === false) return { ok: false, reason: 'fare_disabled' };

  const price = Number(booking.estimatedPrice ?? 0);
  let expectedMinimum = rule.minimumPriceUsd;
  if (booking.serviceType === 'byTheHour' && booking.hours) {
    expectedMinimum = Math.max(
      expectedMinimum,
      rule.basePriceUsd + booking.hours * rule.pricePerHourUsd,
    );
  }
  // Tolerancia de céntimos por redondeo en el cliente.
  if (!(price + 0.01 >= expectedMinimum)) {
    return { ok: false, reason: 'below_fare', expectedMinimum };
  }
  return { ok: true };
}
