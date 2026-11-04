/**
 * Vuelo que manda la app en quoteBooking y createBooking (prompt de vuelos,
 * A1). Sin dependencias pesadas: lo importa booking_schema.
 */
import { z } from 'zod';
import { localToUtcMs, normalizeFlightNumber } from './flight_time';

const CONTROL = /[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g;
const clean = (s: string) => s.replace(CONTROL, ' ').replace(/\s+/g, ' ').trim();
/** Nada que parezca un enlace o un correo en un texto libre. */
const LINKISH = /(https?:|www\.|:\/\/|@|\.[a-z]{2,}\/)/i;

export const flightInputSchema = z.strictObject({
  airportCode: z.string().regex(/^[A-Z]{3}$/),
  flightType: z.enum(['domestic', 'international']),
  /** Aerolínea: opcional, texto saneado de hasta 40 caracteres, sin enlaces. */
  airline: z.string().max(80).transform(clean)
    .refine((s) => s.length >= 1 && s.length <= 40 && !LINKISH.test(s), { message: 'airline' }).optional(),
  /** Número normalizado (normalizeFlightNumber); inválido, rechazado. */
  flightNumber: z.string().max(20).transform((s, ctx) => {
    const n = normalizeFlightNumber(s);
    if (!n) ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'flightNumber' });
    return n ?? '';
  }),
  /** Fecha local del vuelo (La Paz), AAAA-MM-DD. */
  flightDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  /** Hora programada de llegada según el billete, HH:MM local. */
  scheduledArrival: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  /** Obligatorio con vuelo (la app propone «con equipaje», el caso más largo). */
  hasCheckedBag: z.boolean(),
}).refine((f) => localToUtcMs(f.flightDate, f.scheduledArrival) !== null,
  { message: 'flightDate', path: ['flightDate'] });

export type FlightInput = z.infer<typeof flightInputSchema>;
