/**
 * Entrada de quoteBooking y createBooking: solo datos del viaje. Cualquier
 * campo desconocido (precio, estado, chófer, pagos…) se rechaza.
 */
import { z } from 'zod';
import { SERVICE_TYPES, VEHICLE_CLASSES } from './fare';

// Capacidad de cada clase, igual que VehicleClass.capacity y
// luggageCapacity en lib/core/enums/enums.dart.
export const CAPACITY: Record<string, { passengers: number; luggage: number }> = {
  business: { passengers: 3, luggage: 3 },
  firstClass: { passengers: 3, luggage: 2 },
  businessVan: { passengers: 7, luggage: 2 },
  electric: { passengers: 3, luggage: 2 },
  businessSuv: { passengers: 4, luggage: 4 },
};

const place = z.strictObject({
  name: z.string().max(200).default(''),
  address: z.string().trim().min(1).max(300),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

// Igual que validGuest en firestore.rules, sin correo.
export const guestSchema = z.strictObject({
  title: z.string().max(20).optional(),
  firstName: z.string().trim().min(1).max(80),
  lastName: z.string().max(80).optional(),
  phone: z.string().max(40).optional(),
  language: z.string().max(40).optional(),
});

const trip = {
  origin: place,
  destination: place.optional(),
  /** Hora de recogida en milisegundos desde 1970 (UTC). */
  scheduledAt: z.number().int().positive(),
  vehicleClass: z.enum(VEHICLE_CLASSES),
  serviceType: z.enum(SERVICE_TYPES),
  // La tarifa valida que sean enteras (error invalid_hours).
  hours: z.number().positive().max(24).optional(),
};

const needsDestination = (d: { serviceType: string; destination?: unknown }) =>
  d.serviceType === 'byTheHour' || d.destination !== undefined;

export const quoteSchema = z.strictObject(trip)
  .refine(needsDestination, { message: 'destination required', path: ['destination'] });

export const createSchema = z.strictObject({
  ...trip,
  passengerCount: z.number().int().min(1),
  luggageCount: z.number().int().min(0),
  flightNumber: z.string().regex(/^([A-Z]{2}|[A-Z][0-9]|[0-9][A-Z]|[A-Z]{3})([0-9]{1,4})[A-Z]?$/).optional(),
  flightType: z.enum(['domestic', 'international']).optional(),
  notes: z.string().max(1000).optional(),
  guest: guestSchema.optional(),
  quotedPrice: z.number().positive().optional(),
})
  .refine(needsDestination, { message: 'destination required', path: ['destination'] })
  .refine((d) => d.passengerCount <= CAPACITY[d.vehicleClass].passengers,
    { message: 'too many passengers', path: ['passengerCount'] })
  .refine((d) => d.luggageCount <= CAPACITY[d.vehicleClass].luggage,
    { message: 'too much luggage', path: ['luggageCount'] });

export type QuoteInput = z.infer<typeof quoteSchema>;
export type CreateInput = z.infer<typeof createSchema>;
