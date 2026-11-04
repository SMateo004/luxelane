// Verificación en servidor de las tarifas que configura el panel admin.
//
// El precio de una reserva lo calcula la app con /pricingRules; aquí se
// comprueba que la reserva respeta la tarifa vigente (servicio activo y no por
// debajo del mínimo). Los valores de fábrica replican DefaultPricing
// (lib/core/models/models.dart) para cuando el admin no ha guardado tarifa.

export interface FareRule {
  basePriceUsd: number;
  pricePerKmUsd: number;
  pricePerHourUsd: number;
  minimumPriceUsd: number;
  isActive?: boolean;
}

const fare = (base: number, perKm: number, perHour: number, min: number): FareRule => ({
  basePriceUsd: base,
  pricePerKmUsd: perKm,
  pricePerHourUsd: perHour,
  minimumPriceUsd: min,
  isActive: true,
});

export const DEFAULT_FARES: Record<string, FareRule> = {
  business_oneWay: fare(50, 3, 0, 50),
  business_byTheHour: fare(0, 0, 80, 160),
  businessSuv_oneWay: fare(70, 4, 0, 70),
  businessSuv_byTheHour: fare(0, 0, 115, 230),
  firstClass_oneWay: fare(80, 4, 0, 80),
  firstClass_byTheHour: fare(0, 0, 120, 240),
  businessVan_oneWay: fare(90, 5, 0, 90),
  businessVan_byTheHour: fare(0, 0, 150, 300),
  electric_oneWay: fare(60, 3.5, 0, 60),
  electric_byTheHour: fare(0, 0, 90, 180),
};

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
  /**
   * Distancia en línea recta entre recogida y destino. La ruta por calles
   * nunca es más corta, así que base + km en línea recta × tarifa es un
   * mínimo seguro: atrapa precios manipulados sin rechazar los legítimos.
   */
  straightKm = 0,
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
  } else if (booking.serviceType !== 'byTheHour' && straightKm > 0) {
    expectedMinimum = Math.max(
      expectedMinimum,
      rule.basePriceUsd + straightKm * rule.pricePerKmUsd,
    );
  }
  // Tolerancia de céntimos por redondeo en el cliente.
  if (!(price + 0.01 >= expectedMinimum)) {
    return { ok: false, reason: 'below_fare', expectedMinimum };
  }
  return { ok: true };
}
