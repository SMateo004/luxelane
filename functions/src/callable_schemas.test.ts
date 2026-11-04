/**
 * Cada callable tiene un esquema estricto. Por callable: una entrada válida
 * pasa; un campo extra, un tipo incorrecto y un valor extremo se rechazan.
 */
import { describe, it, expect } from '@jest/globals';
import { z } from 'zod';
import * as index from './index';
import { quoteSchema, createSchema } from './booking_schema';
import { advanceSchema, pickupCodeSchema, verifySchema, overrideSchema } from './trip_flow';
import { raiseSchema, incidentIdSchema, closeSchema } from './incidents';
import { resolveSchema } from './alerts';
import { leadSchema } from './business_leads';
import { deviceSchema } from './driver_devices';
import { cancelSchema, releaseSchema } from './cancellation';
import {
  bookingSchema as adminBookingSchema, configSchema as adminConfigSchema, paymentSchema as adminPaymentSchema,
  pricingSchema as adminPricingSchema, verifyDriverSchema, driverSensitiveSchema, vehicleActiveSchema,
  leadHandledSchema,
} from './admin_ops';
import { callableSchemas as c } from './schemas';
import { confirmSchema as confirmPaymentSchema, rejectSchema as rejectPaymentSchema, sentSchema } from './payment_manual';
import { startSchema as startPaymentSchema } from './payment_card';
import { refundSchema } from './payment_refund';
import { inboxSchema } from './payment_inbox';
import { collectBalanceSchema } from './payment_balance';
import { updatePreferencesSchema } from './preferences';
import {
  decideSchema, docUrlSchema, expiriesSchema, overrideSchema as allowOnlineSchema, purgeSchema, reviewSchema, stepSchema, uploadSchema,
} from './driver_application';
import { clearLockSchema, forceNoShowSchema, setFlightSchema, upsertAirportSchema } from './flight';
import { adminRevokeSchema, bookingSchema as shareBookingSchema } from './trip_share';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Exported = Record<string, any>;

const ID = 'abcDEF123_-xyz';
const LONG_ID = 'a'.repeat(129);
const place = { name: 'Hotel', address: 'Calle 1', lat: 40.4, lng: -3.7 };
const trip = {
  origin: place, destination: { ...place, lat: 40.5 },
  scheduledAt: 1_900_000_000_000, vehicleClass: 'business', serviceType: 'oneWay',
};

interface Case {
  schema: z.ZodType;
  valid: unknown;
  /** Campo con el tipo equivocado. */
  wrongType: unknown;
  /** Longitud, rango o formato fuera de lo admitido. */
  extreme: unknown[];
}

const lead = {
  company: 'Empresa SA', contactName: 'Laura', email: 'laura@example.com',
  phone: '+59170000000', travellers: '11–50', message: 'Hola',
};

const CASES: Record<string, Case> = {
  submitBusinessLead: {
    schema: leadSchema, valid: lead,
    wrongType: { ...lead, travellers: 20 },
    extreme: [{ ...lead, company: 'x'.repeat(121) }, { ...lead, message: 'x'.repeat(2001) },
      { ...lead, email: 'no-es-correo' }, { ...lead, travellers: '1-10000' }, { ...lead, website: 'x'.repeat(201) }],
  },
  quoteBooking: {
    schema: quoteSchema, valid: trip,
    wrongType: { ...trip, scheduledAt: '2030-01-01' },
    extreme: [{ ...trip, scheduledAt: 9e15 }, { ...trip, hours: 1e9 },
      { ...trip, origin: { ...place, lat: 91 } }, { ...trip, origin: { ...place, address: 'x'.repeat(301) } }],
  },
  createBooking: {
    schema: createSchema,
    valid: { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
    wrongType: { ...trip, passengerCount: '2', luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
    extreme: [
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f', quotedPrice: 1e12 },
      { ...trip, passengerCount: 1e9, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: 'no-es-uuid' },
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f', notes: 'x'.repeat(1001) },
    ],
  },
  advanceBooking: {
    schema: advanceSchema, valid: { bookingId: ID, to: 'driver_arriving' },
    wrongType: { bookingId: 42, to: 'driver_arriving' },
    extreme: [{ bookingId: LONG_ID, to: 'driver_arriving' }, { bookingId: ID, to: 'cancelled' },
      { bookingId: ID, to: 'completed', location: { lat: 0, lng: 181 } }],
  },
  getPickupCode: {
    schema: pickupCodeSchema, valid: { bookingId: ID },
    wrongType: { bookingId: [ID] }, extreme: [{ bookingId: LONG_ID }, { bookingId: '../users/x' }],
  },
  verifyPickup: {
    schema: verifySchema, valid: { bookingId: ID, code: '0427' },
    wrongType: { bookingId: ID, code: 427 },
    extreme: [{ bookingId: ID, code: '04270' }, { bookingId: ID, code: '0'.repeat(10000) }],
  },
  adminOverrideVerify: {
    schema: overrideSchema, valid: { bookingId: ID, reason: 'Código ilegible' },
    wrongType: { bookingId: ID, reason: true },
    extreme: [{ bookingId: ID, reason: 'x'.repeat(501) }, { bookingId: LONG_ID, reason: 'Código ilegible' }],
  },
  raiseIncident: {
    schema: raiseSchema, valid: { bookingId: ID, location: { lat: 40.4, lng: -3.7 } },
    wrongType: { bookingId: ID, location: '40.4,-3.7' },
    extreme: [{ bookingId: ID, location: { lat: Infinity, lng: 0 } }, { bookingId: ID, appVersion: '1'.repeat(41) }],
  },
  cancelIncident: {
    schema: incidentIdSchema, valid: { incidentId: ID },
    wrongType: { incidentId: null }, extreme: [{ incidentId: LONG_ID }, { incidentId: '' }],
  },
  acknowledgeIncident: {
    schema: incidentIdSchema, valid: { incidentId: ID },
    wrongType: { incidentId: 1 }, extreme: [{ incidentId: 'a/b' }],
  },
  closeIncident: {
    schema: closeSchema, valid: { incidentId: ID, note: 'Llamada hecha, todo bien' },
    wrongType: { incidentId: ID, note: 10 },
    extreme: [{ incidentId: ID, note: 'x'.repeat(1001) }, { incidentId: ID, note: 'corta' }],
  },
  adminUpdateBooking: {
    schema: adminBookingSchema, valid: { action: 'cancel', bookingId: ID, reason: 'Pedido por el pasajero', cause: 'rider' },
    wrongType: { action: 'adjust_price', bookingId: ID, finalPrice: '100', reason: 'Pedido por el pasajero' },
    extreme: [{ action: 'cancel', bookingId: ID, reason: 'corto', cause: 'rider' },
      { action: 'cancel', bookingId: ID, reason: 'Pedido por el pasajero', cause: 'otro' },
      { action: 'cancel', bookingId: ID, reason: 'Pedido por el pasajero', cause: 'rider', cancellationFee: 1 },
      { action: 'status', bookingId: ID, to: 'verified', reason: 'Pedido por el pasajero' },
      { action: 'adjust_price', bookingId: ID, finalPrice: -1, reason: 'Pedido por el pasajero' },
      { action: 'borrar', bookingId: ID, reason: 'Pedido por el pasajero' }],
  },
  adminRecordPayment: {
    schema: adminPaymentSchema, valid: { action: 'record', bookingId: ID, method: 'cash', reason: 'Cobrado en efectivo al llegar' },
    wrongType: { action: 'correct', paymentId: ID, amountBs: '10', reason: 'Importe mal anotado' },
    extreme: [{ action: 'record', bookingId: ID, method: 'card', reason: 'Cobrado en efectivo al llegar' },
      { action: 'correct', paymentId: ID, amountBs: -5, reason: 'Importe mal anotado' },
      { action: 'record', bookingId: ID, method: 'cash', reason: 'x' }],
  },
  adminUpdateConfig: {
    schema: adminConfigSchema, valid: { doc: 'finance', changes: { platformCommissionPct: 15 }, reason: 'Acuerdo nuevo con los chóferes' },
    wrongType: { doc: 'global', changes: { isMaintenanceMode: 'sí' }, reason: 'Mantenimiento programado' },
    extreme: [{ doc: 'security', changes: { mfaEnforced: false }, reason: 'Quitar el segundo factor' },
      { doc: 'global', changes: { minAppVersion: '9.9.9' }, reason: 'Subir la versión mínima' },
      { doc: 'finance', changes: { platformCommissionPct: 101 }, reason: 'Acuerdo nuevo con los chóferes' },
      { doc: 'ops', changes: {}, reason: 'Ajuste de operación del SOS' }],
  },
  adminUpdatePricingRule: {
    schema: adminPricingSchema,
    valid: { action: 'upsert', vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 1, pricePerKmUsd: 1,
      pricePerHourUsd: 0, minimumPriceUsd: 1, isActive: true, reason: 'Tarifa nueva del piloto' },
    wrongType: { action: 'deactivate', vehicleClass: 'business', serviceType: 1, reason: 'Fuera de servicio' },
    extreme: [{ action: 'deactivate', vehicleClass: 'limo', serviceType: 'oneWay', reason: 'Fuera de servicio' },
      { action: 'upsert', vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: -1, pricePerKmUsd: 1,
        pricePerHourUsd: 0, minimumPriceUsd: 1, isActive: true, reason: 'Tarifa nueva del piloto' },
      { action: 'delete', vehicleClass: 'business', serviceType: 'oneWay', reason: 'Fuera de servicio' }],
  },
  adminVerifyDriver: {
    schema: verifyDriverSchema, valid: { driverId: ID, vehicleReviewed: true, reason: 'Documentos revisados en persona' },
    wrongType: { driverId: ID, vehicleReviewed: 'sí', reason: 'Documentos revisados en persona' },
    extreme: [{ driverId: ID, vehicleReviewed: true, vehicleNote: 'x'.repeat(501), reason: 'Documentos revisados en persona' },
      { driverId: LONG_ID, vehicleReviewed: false, reason: 'Documentos revisados en persona' }],
  },
  adminUpdateDriverSensitive: {
    schema: driverSensitiveSchema, valid: { driverId: ID, profile: { licenseNumber: 'A-1' }, reason: 'Renovó la licencia' },
    wrongType: { driverId: ID, profile: { licenseExpiry: '2030' }, reason: 'Renovó la licencia' },
    extreme: [{ driverId: ID, vehicle: { vehicleId: ID, year: 1800 }, reason: 'Cambio de vehículo' },
      { driverId: ID, vehicle: { vehicleId: ID, vehicleClass: 'limo' }, reason: 'Cambio de vehículo' },
      { driverId: ID, profile: { rating: 5 }, reason: 'Renovó la licencia' }],
  },
  adminSetVehicleActive: {
    schema: vehicleActiveSchema, valid: { vehicleId: ID, active: false, reason: 'Vehículo en el taller' },
    wrongType: { vehicleId: ID, active: 'no', reason: 'Vehículo en el taller' },
    extreme: [{ vehicleId: ID, active: true, reason: 'ok' }],
  },
  adminSetLeadHandled: {
    schema: leadHandledSchema, valid: { leadId: ID, handled: true },
    wrongType: { leadId: ID, handled: 'sí' }, extreme: [{ leadId: ID, handled: true, reason: 'x'.repeat(501) }],
  },
  cancelBooking: {
    schema: cancelSchema, valid: { bookingId: ID, reason: 'changed_plans' },
    wrongType: { bookingId: ID, dryRun: 'sí' },
    extreme: [{ bookingId: ID, reason: 'me_aburri' }, { bookingId: ID, acceptedFee: -1 }, { bookingId: ID, status: 'cancelled' }],
  },
  releaseBooking: {
    schema: releaseSchema, valid: { bookingId: ID, reason: 'vehicle_issue', location: { lat: -17.6, lng: -63.1 } },
    wrongType: { bookingId: ID, reason: 1 },
    extreme: [{ bookingId: ID }, { bookingId: ID, reason: 'me_aburri' }, { bookingId: ID, reason: 'other', status: 'pending' },
      { bookingId: ID, reason: 'other', location: { lat: 91, lng: 0 } }],
  },
  registerDriverDevice: {
    schema: deviceSchema, valid: { installationId: 'a'.repeat(8) + '-' + 'b'.repeat(27), platform: 'android', appVersion: '1.0.0' },
    wrongType: { installationId: 1, platform: 'android', appVersion: '1' },
    extreme: [{ installationId: 'corto', platform: 'android', appVersion: '1' },
      { installationId: 'x'.repeat(65), platform: 'android', appVersion: '1' },
      { installationId: 'a'.repeat(36), platform: 'windows', appVersion: '1' }],
  },
  resolveAlert: {
    schema: resolveSchema, valid: { alertId: ID },
    wrongType: { alertId: ID, note: {} }, extreme: [{ alertId: ID, note: 'x'.repeat(501) }, { alertId: LONG_ID }],
  },
  createPaymentIntent: {
    schema: c.createPaymentIntent, valid: { bookingId: ID, paymentMethodId: 'pm_123' },
    wrongType: { bookingId: ID, paymentMethodId: 123 },
    extreme: [{ bookingId: ID, paymentMethodId: 'tok_123' }, { bookingId: LONG_ID }],
  },
  capturePayment: {
    schema: c.capturePayment, valid: { bookingId: ID, stripePaymentIntentId: 'pi_123' },
    wrongType: { bookingId: ID, stripePaymentIntentId: { id: 'pi_123' } },
    extreme: [{ bookingId: ID, stripePaymentIntentId: 'pi_' + 'a'.repeat(256) }, { bookingId: ID, stripePaymentIntentId: 'ch_123' }],
  },
  refundPayment: {
    schema: c.refundPayment, valid: { paymentId: ID, reason: 'Cliente no se presentó' },
    wrongType: { paymentId: ID, reason: 5 }, extreme: [{ paymentId: ID, reason: 'x'.repeat(501) }],
  },
  listPaymentMethods: {
    schema: c.listPaymentMethods, valid: { customerId: 'cus_123' },
    wrongType: { customerId: 123 }, extreme: [{ customerId: 'cus_' + 'a'.repeat(256) }, { customerId: 'acct_1' }],
  },
  setDefaultPaymentMethod: {
    schema: c.setDefaultPaymentMethod, valid: { paymentMethodId: 'pm_1' },
    wrongType: { paymentMethodId: false }, extreme: [{ paymentMethodId: 'pm_' }, { paymentMethodId: 'pm_a b' }],
  },
  attachPaymentMethod: {
    schema: c.attachPaymentMethod, valid: { customerId: 'cus_1', paymentMethodId: 'pm_1' },
    wrongType: { customerId: 'cus_1', paymentMethodId: ['pm_1'] },
    extreme: [{ customerId: 'cus_1', paymentMethodId: 'pm_' + 'a'.repeat(256) }],
  },
  detachPaymentMethod: {
    schema: c.detachPaymentMethod, valid: { paymentMethodId: 'pm_1' },
    wrongType: { paymentMethodId: 1 }, extreme: [{ paymentMethodId: 'card_1' }],
  },
  deleteAccount: { schema: c.deleteAccount, valid: null, wrongType: 'borrar', extreme: [[]] },
  syncEmailVerification: { schema: c.syncEmailVerification, valid: null, wrongType: 'sí', extreme: [[]] },
  getPreferenceOptions: { schema: c.getPreferenceOptions, valid: null, wrongType: 'sí', extreme: [[]] },
  getDriverApplication: { schema: c.getDriverApplication, valid: null, wrongType: 'sí', extreme: [[]] },
  submitApplication: { schema: c.submitApplication, valid: null, wrongType: 'sí', extreme: [[]] },
  startDriverApplication: { schema: c.startDriverApplication, valid: null, wrongType: 'sí', extreme: [[]] },
  saveDriverStep: {
    schema: stepSchema,
    valid: { step: 'vehicle', make: 'Marca', model: 'Modelo', year: 2022, color: 'black', plate: 'abc-1234',
      bodyType: 'sedan', passengers: 3, vehicleClass: 'business' },
    wrongType: { step: 'vehicle', make: 'Marca', model: 'Modelo', year: '2022', color: 'black', plate: 'ABC1234',
      bodyType: 'sedan', passengers: 3, vehicleClass: 'business' },
    extreme: [
      { step: 'personal', fullName: 'A', nationalIdNumber: '123', licenseNumber: 'L-1', licenseExpiry: 1 },
      { step: 'vehicle', make: 'M', model: 'M', year: 2022, color: 'other', plate: 'ABC1234', bodyType: 'sedan',
        passengers: 3, vehicleClass: 'business' },
      { step: 'vehicle', make: 'M', model: 'M', year: 2022, color: 'black', plate: 'AB', bodyType: 'sedan',
        passengers: 3, vehicleClass: 'business' },
      { step: 'vehicle', make: 'M', model: 'M', year: 2022, color: 'black', plate: 'ABC1234', bodyType: 'bus',
        passengers: 30, vehicleClass: 'business' },
    ],
  },
  registerDocumentUpload: {
    schema: uploadSchema, valid: { type: 'license_front', version: 1, expiresAt: 1_900_000_000_000 },
    wrongType: { type: 'license_front', version: '1' },
    extreme: [{ type: 'selfie', version: 1 }, { type: 'license_front', version: 0 }, { type: 'license_front', version: 1_000_000 },
      { type: 'license_front', version: 21 }],
  },
  adminSetFlightInfo: {
    schema: setFlightSchema,
    valid: { bookingId: ID, status: 'landed', actualArrival: 1_900_000_000_000, reason: 'Llamé a la aerolínea (prueba)' },
    wrongType: { bookingId: ID, status: 'landed', actualArrival: '1900000000000', reason: 'Llamé a la aerolínea (prueba)' },
    extreme: [
      { bookingId: ID, status: 'landed', reason: 'Sin hora real no se marca aterrizado' },
      { bookingId: ID, status: 'otro', reason: 'Estado fuera de la lista cerrada' },
      { bookingId: ID, status: 'delayed', reason: 'corto' },
    ],
  },
  adminClearFlightLock: {
    schema: clearLockSchema, valid: { bookingId: ID, reason: 'La fuente ya da datos (prueba)' },
    wrongType: { bookingId: 5, reason: 'La fuente ya da datos (prueba)' }, extreme: [{ bookingId: ID, reason: 'x' }],
  },
  adminForceNoShow: {
    schema: forceNoShowSchema, valid: { bookingId: ID, reason: 'Esperó 40 min y llamó dos veces (prueba)' },
    wrongType: { bookingId: ID, reason: 12 }, extreme: [{ bookingId: LONG_ID, reason: 'Esperó 40 min y llamó dos veces' }],
  },
  createTripShare: {
    schema: shareBookingSchema, valid: { bookingId: ID }, wrongType: { bookingId: 12 },
    extreme: [{ bookingId: LONG_ID }, { bookingId: ID, extra: 1 }],
  },
  revokeTripShare: {
    schema: shareBookingSchema, valid: { bookingId: ID }, wrongType: { bookingId: 12 },
    extreme: [{ bookingId: LONG_ID }, { bookingId: ID, extra: 1 }],
  },
  getTripShare: {
    schema: shareBookingSchema, valid: { bookingId: ID }, wrongType: { bookingId: 12 },
    extreme: [{ bookingId: LONG_ID }],
  },
  adminRevokeTripShare: {
    schema: adminRevokeSchema, valid: { bookingId: ID, reason: 'Pedido por el pasajero por teléfono (prueba)' },
    wrongType: { bookingId: ID, reason: 12 }, extreme: [{ bookingId: ID, reason: 'corto' }],
  },
  adminUpsertAirport: {
    schema: upsertAirportSchema,
    valid: { code: 'ZZZ', name: 'Aeropuerto de prueba', city: 'Ciudad', pickupPoints: {
      domestic: { name: 'Salida nacional', instructions: 'Frente a la puerta 1 (ficticio)', lat: -17.6, lng: -63.1 } },
    reason: 'Alta del aeropuerto (prueba)' },
    wrongType: { code: 'ZZZ', name: 'Aeropuerto', city: 'Ciudad', pickupPoints: { domestic: { name: 'x', instructions: '',
      lat: '-17', lng: -63 } }, reason: 'Alta del aeropuerto (prueba)' },
    extreme: [
      { code: 'zz', name: 'Aeropuerto', city: 'Ciudad', pickupPoints: {}, reason: 'Alta del aeropuerto (prueba)' },
      { code: 'ZZZ', name: 'Aeropuerto', city: 'Ciudad', timeZone: 'America/Lima', pickupPoints: {}, reason: 'Alta del aeropuerto (prueba)' },
      { code: 'ZZZ', name: 'Aeropuerto', city: 'Ciudad', pickupPoints: { domestic: { name: 'P', instructions: '', lat: 91, lng: 0 } },
        reason: 'Alta del aeropuerto (prueba)' },
      { code: 'ZZZ', name: 'Aeropuerto', city: 'Ciudad', pickupPoints: { domestic: { name: 'P', instructions: '', lat: 0, lng: 0 } },
        reason: 'Alta del aeropuerto (prueba)' },
    ],
  },
  adminListDocExpiries: {
    schema: expiriesSchema, valid: { days: 30 }, wrongType: { days: '30' }, extreme: [{ days: 0 }, { days: 366 }, { days: 30, x: 1 }],
  },
  adminGetDocumentUrl: {
    schema: docUrlSchema, valid: { driverId: ID, type: 'national_id_front' },
    wrongType: { driverId: ID, type: 5 }, extreme: [{ driverId: LONG_ID, type: 'national_id_front' }],
  },
  adminReviewDocument: {
    schema: reviewSchema, valid: { driverId: ID, type: 'license_front', version: 1, decision: 'reject', rejectReason: 'illegible' },
    wrongType: { driverId: ID, type: 'license_front', version: 1, decision: true },
    extreme: [{ driverId: ID, type: 'license_front', version: 1, decision: 'reject' },
      { driverId: ID, type: 'license_front', version: 1, decision: 'reject', rejectReason: 'feo' }],
  },
  adminDecideApplication: {
    schema: decideSchema, valid: { driverId: ID, decision: 'approve', reason: 'Documentos revisados uno a uno' },
    wrongType: { driverId: ID, decision: 1, reason: 'Documentos revisados uno a uno' },
    extreme: [{ driverId: ID, decision: 'approve', reason: 'corto' }, { driverId: ID, decision: 'maybe', reason: 'Documentos revisados' }],
  },
  adminAllowDriverOnline: {
    schema: allowOnlineSchema, valid: { driverId: ID, reason: 'Renovación en trámite, comprobante visto' },
    wrongType: { driverId: 5, reason: 'Renovación en trámite' }, extreme: [{ driverId: ID, reason: 'x' }],
  },
  adminPurgeDriverDocuments: {
    schema: purgeSchema, valid: { driverId: ID, reason: 'Orden del responsable legal' },
    wrongType: { driverId: ID, reason: 7 }, extreme: [{ driverId: LONG_ID, reason: 'Orden del responsable legal' }],
  },
  updatePreferences: {
    schema: updatePreferencesSchema,
    valid: { preferredDriverLanguages: ['es', 'pt'], conversation: 'quiet', note: 'Hola', locale: 'pt', localeSource: 'user' },
    wrongType: { preferredDriverLanguages: 'es' },
    extreme: [{ note: 'x'.repeat(201) }, { preferredDriverLanguages: ['fr'] }, { musicStyle: 'reggaeton' },
      { needs: ['child_seat', 'child_seat'] }, { playlistUrl: `https://x.example/${'a'.repeat(300)}` },
      { locale: 'fr', localeSource: 'user' }, { locale: 'system', localeSource: 'system' }, { locale: 'es' },
      { localeSource: 'user' }],
  },
  acceptTerms: {
    schema: c.acceptTerms, valid: { version: '2026-10', appVersion: '1.0.0' },
    wrongType: { appVersion: 1 }, extreme: [{ appVersion: 'x'.repeat(41) }, { version: '', appVersion: '1.0.0' }],
  },
  setUserBlocked: {
    schema: c.setUserBlocked, valid: { uid: ID, blocked: true, reason: 'Reclamo grave' },
    wrongType: { uid: ID, blocked: 'sí' }, extreme: [{ uid: ID, blocked: true, reason: 'x'.repeat(501) }, { uid: LONG_ID, blocked: false }],
  },
  setUserRole: {
    schema: c.setUserRole, valid: { uid: ID, role: 'driver' },
    wrongType: { uid: ID, role: 1 }, extreme: [{ uid: ID, role: 'superadmin' }, { uid: LONG_ID, role: 'rider' }],
  },
  ensureStripeCustomer: { schema: c.ensureStripeCustomer, valid: {}, wrongType: 1, extreme: [[]] },
  backfillSettlements: { schema: c.backfillSettlements, valid: undefined, wrongType: true, extreme: [[]] },
  assignNearestDriver: {
    schema: c.assignNearestDriver, valid: { bookingId: ID },
    wrongType: { bookingId: 1 }, extreme: [{ bookingId: LONG_ID }],
  },
  acceptBooking: {
    schema: c.acceptBooking, valid: { bookingId: ID },
    wrongType: { bookingId: true }, extreme: [{ bookingId: 'x'.repeat(10000) }],
  },
  markPaymentSent: {
    schema: sentSchema, valid: { bookingId: ID, operationNumber: 'OP 123/45' },
    wrongType: { bookingId: ID, operationNumber: 123 },
    extreme: [{ bookingId: ID, operationNumber: 'x'.repeat(41) }, { bookingId: ID, operationNumber: 'OP<1>' },
      { bookingId: LONG_ID }],
  },
  adminConfirmPayment: {
    schema: confirmPaymentSchema,
    valid: { bookingId: ID, operationNumber: 'OP 1', amountReceived: 52.5, reason: 'Ingreso visto en el banco' },
    wrongType: { bookingId: ID, operationNumber: 'OP 1', amountReceived: '52.50', reason: 'Ingreso visto en el banco' },
    extreme: [
      { bookingId: ID, operationNumber: 'OP 1', amountReceived: -1, reason: 'Ingreso visto en el banco' },
      { bookingId: ID, operationNumber: 'OP 1', amountReceived: 1e9, reason: 'Ingreso visto en el banco' },
      { bookingId: ID, operationNumber: 'OP 1', amountReceived: 52.5, reason: 'corto' },
    ],
  },
  startPayment: {
    schema: startPaymentSchema, valid: { bookingId: ID, method: 'card' },
    wrongType: { bookingId: ID, method: 1 },
    extreme: [{ bookingId: ID, method: 'wallet' }, { bookingId: ID, method: 'card', amount: 1 }, { bookingId: LONG_ID, method: 'card' }],
  },
  adminRecordRefund: {
    schema: refundSchema, valid: { bookingId: ID, externalRef: 'DEV 123', reason: 'Devuelto por transferencia hoy' },
    wrongType: { bookingId: ID, externalRef: 123, reason: 'Devuelto por transferencia hoy' },
    extreme: [{ bookingId: ID, externalRef: 'x'.repeat(61), reason: 'Devuelto por transferencia hoy' },
      { bookingId: ID, externalRef: 'DEV 1', reason: 'Devuelto por transferencia hoy', amount: 1 },
      { bookingId: ID, externalRef: 'DEV<1>', reason: 'Devuelto por transferencia hoy' }],
  },
  adminCollectBalance: {
    schema: collectBalanceSchema,
    valid: { bookingId: ID, amount: 12.5, operationNumber: 'OP 2', method: 'manual_qr', reason: 'Saldo visto en el banco' },
    wrongType: { bookingId: ID, amount: '12.50', operationNumber: 'OP 2', method: 'manual_qr', reason: 'Saldo visto en el banco' },
    extreme: [
      { bookingId: ID, amount: -1, operationNumber: 'OP 2', method: 'manual_qr', reason: 'Saldo visto en el banco' },
      { bookingId: ID, amount: 12.5, operationNumber: 'OP 2', method: 'efectivo', reason: 'Saldo visto en el banco' },
      { bookingId: ID, amount: 12.5, operationNumber: 'OP<2>', method: 'manual_qr', reason: 'Saldo visto en el banco' },
      { bookingId: ID, amount: 12.5, operationNumber: 'OP 2', method: 'manual_qr', reason: 'corto' },
    ],
  },
  adminPaymentInbox: {
    schema: inboxSchema, valid: { kind: 'reported' },
    wrongType: { kind: 1 }, extreme: [{ kind: 'todo' }, { kind: 'refunds', limit: 1000 }, { kind: 'refunds', limit: 0 }],
  },
  adminRejectPayment: {
    schema: rejectPaymentSchema, valid: { bookingId: ID, reason: 'No hay ingreso en el extracto' },
    wrongType: { bookingId: ID, reason: 5 }, extreme: [{ bookingId: ID, reason: 'x'.repeat(501) }],
  },
};

/** Añade un campo desconocido; en las callables sin datos, un objeto con uno. */
const withExtra = (v: unknown) =>
  (v && typeof v === 'object' ? { ...(v as object), extra: 1 } : { extra: 1 });

const callables = Object.entries(index as Exported)
  .filter(([, fn]) => fn?.__endpoint?.callableTrigger !== undefined)
  .map(([name]) => name);

describe('esquemas de entrada de las callables', () => {
  it('toda callable exportada tiene su caso aquí', () => {
    expect(callables.length).toBeGreaterThanOrEqual(23);
    expect(callables.filter((n) => !CASES[n])).toEqual([]);
  });

  describe.each(Object.entries(CASES))('%s', (_name, k) => {
    it('acepta una entrada válida', () => {
      expect(k.schema.safeParse(k.valid).success).toBe(true);
    });
    it('rechaza un campo extra', () => {
      expect(k.schema.safeParse(withExtra(k.valid)).success).toBe(false);
    });
    it('rechaza un tipo incorrecto', () => {
      expect(k.schema.safeParse(k.wrongType).success).toBe(false);
    });
    it('rechaza valores extremos', () => {
      for (const v of k.extreme) expect(k.schema.safeParse(v).success).toBe(false);
    });
  });
});
