// Convención de importes de Luxelane:
// - Reservas (estimatedPrice, finalPrice, settlement): bolivianos, decimales.
// - Pagos (`payments.amount`) y Stripe: centavos enteros (unidad mínima).
// Cualquier conversión entre ambos pasa por estas dos funciones.

export const toCents = (bs: number): number => Math.round(Number(bs) * 100);

export const fromCents = (cents: number): number => Math.round(Number(cents)) / 100;
