/**
 * Catálogo de los textos que el servidor muestra a una persona (idiomas,
 * A4): avisos push y de la bandeja, y el nombre del destino en el servicio
 * por horas. Cada clave tiene español, inglés y portugués de Brasil con los
 * mismos marcadores {así}; t() falla si falta o sobra un valor.
 *
 * Inglés y portugués: redactados por nosotros, PENDIENTES DE REVISIÓN POR UN
 * HABLANTE NATIVO (docs/GLOSARIO_IDIOMAS.md). Las alertas del panel
 * (adminAlerts) siguen en español y no pasan por aquí.
 */
import * as admin from 'firebase-admin';
import { APP_LOCALES, AppLocale } from './preferences';

export { APP_LOCALES };
export type { AppLocale };

export const DEFAULT_LOCALE: AppLocale = 'es';

type Texts = Record<AppLocale, string>;

export const MESSAGES = {
  // --- Pasajero: pasos de la reserva (bandeja y push) -----------------------
  'booking_confirmed.title': { es: 'Chófer asignado', en: 'Chauffeur assigned', pt: 'Motorista designado' },
  'booking_confirmed.body': {
    es: 'Tu chófer ha sido asignado.',
    en: 'Your chauffeur has been assigned.',
    pt: 'Seu motorista foi designado.',
  },
  'driver_arriving.title': { es: 'El chófer está en camino', en: 'Your chauffeur is on the way', pt: 'Seu motorista está a caminho' },
  'driver_arriving.body': {
    es: 'Tu chófer va hacia el punto de recogida.',
    en: 'Your chauffeur is heading to the pickup point.',
    pt: 'Seu motorista está indo até o ponto de embarque.',
  },
  'driver_arrived.title': { es: 'El chófer ha llegado', en: 'Your chauffeur has arrived', pt: 'Seu motorista chegou' },
  'driver_arrived.body': {
    es: 'Tu chófer te espera. Abre la app y dale tu código de recogida.',
    en: 'Your chauffeur is waiting. Open the app and give them your pickup code.',
    pt: 'Seu motorista está aguardando. Abra o app e informe seu código de embarque.',
  },
  'ride_started.title': { es: 'Viaje iniciado', en: 'Trip started', pt: 'Viagem iniciada' },
  'ride_started.body': { es: 'Tu trayecto ha comenzado.', en: 'Your journey has begun.', pt: 'Seu trajeto começou.' },
  'ride_completed.title': { es: 'Viaje completado', en: 'Trip completed', pt: 'Viagem concluída' },
  'ride_completed.body': {
    es: 'Has llegado. Gracias por viajar con Luxelane.',
    en: 'You have arrived. Thank you for travelling with Luxelane.',
    pt: 'Você chegou. Obrigado por viajar com a Luxelane.',
  },
  'booking_cancelled.title': { es: 'Reserva cancelada', en: 'Booking cancelled', pt: 'Reserva cancelada' },
  'booking_cancelled.body': {
    es: 'Tu reserva ha sido cancelada.',
    en: 'Your booking has been cancelled.',
    pt: 'Sua reserva foi cancelada.',
  },
  'booking_driver_released.title': { es: 'Buscamos otro chófer', en: 'Finding another chauffeur', pt: 'Buscando outro motorista' },
  'booking_driver_released.body': {
    es: 'Tu chófer tuvo un imprevisto. Estamos buscando otro chófer para tu reserva.',
    en: 'Your chauffeur had an unforeseen issue. We are looking for another chauffeur for your booking.',
    pt: 'Seu motorista teve um imprevisto. Estamos buscando outro motorista para sua reserva.',
  },
  'rider_no_show.title': { es: 'No te encontramos', en: 'We could not find you', pt: 'Não encontramos você' },
  'rider_no_show.body': {
    es: 'Tu chófer no te encontró en el punto de recogida. Central revisará tu reserva.',
    en: 'Your chauffeur could not find you at the pickup point. Our operations team will review your booking.',
    pt: 'Seu motorista não encontrou você no ponto de embarque. A central vai analisar sua reserva.',
  },

  // --- Pasajero: pagos -------------------------------------------------------
  'payment_receipt.title': { es: 'Pago confirmado', en: 'Payment confirmed', pt: 'Pagamento confirmado' },
  'payment_receipt.body': {
    es: 'Se cobraron {amount} por tu trayecto.',
    en: '{amount} was charged for your journey.',
    pt: 'Foram cobrados {amount} pela sua viagem.',
  },
  'payment_confirmed.title': { es: 'Pago confirmado', en: 'Payment confirmed', pt: 'Pagamento confirmado' },
  'payment_confirmed.body': {
    es: 'Confirmamos tu pago. Estamos buscando a tu chófer.',
    en: 'We have confirmed your payment. We are looking for your chauffeur.',
    pt: 'Confirmamos seu pagamento. Estamos buscando seu motorista.',
  },
  'payment_confirmed_cancelled.title': { es: 'Pago confirmado', en: 'Payment confirmed', pt: 'Pagamento confirmado' },
  'payment_confirmed_cancelled.body': {
    es: 'Confirmamos tu pago, pero la reserva ya estaba cancelada. Central gestionará la devolución.',
    en: 'We have confirmed your payment, but the booking had already been cancelled. Our operations team will handle the refund.',
    pt: 'Confirmamos seu pagamento, mas a reserva já estava cancelada. A central vai cuidar do reembolso.',
  },
  'payment_rejected.title': { es: 'Pago no confirmado', en: 'Payment not confirmed', pt: 'Pagamento não confirmado' },
  'payment_rejected.body': {
    es: 'No pudimos confirmar tu pago. Revisa los datos del pago en la app o contacta con central.',
    en: 'We could not confirm your payment. Please check the payment details in the app or contact our operations team.',
    pt: 'Não conseguimos confirmar seu pagamento. Confira os dados do pagamento no app ou fale com a central.',
  },
  'payment_expired.title': { es: 'Reserva cancelada', en: 'Booking cancelled', pt: 'Reserva cancelada' },
  'payment_expired.body': {
    es: 'El plazo para pagar terminó y la reserva se canceló. No se te cobró nada.',
    en: 'The payment window ended and the booking was cancelled. You have not been charged.',
    pt: 'O prazo para pagar terminou e a reserva foi cancelada. Nada foi cobrado.',
  },
  'refund_recorded.title': { es: 'Devolución registrada', en: 'Refund recorded', pt: 'Reembolso registrado' },
  'refund_recorded.body': {
    es: 'Te devolvemos el dinero al método con el que pagaste.',
    en: 'We are refunding the money to the method you paid with.',
    pt: 'Vamos devolver o valor ao método que você usou para pagar.',
  },

  // --- Chófer ----------------------------------------------------------------
  'new_trip_available.title': { es: 'Nuevo viaje disponible', en: 'New trip available', pt: 'Nova viagem disponível' },
  'new_trip_available.body': { es: '{vehicleClass} · {amount}', en: '{vehicleClass} · {amount}', pt: '{vehicleClass} · {amount}' },
  'driver_assigned.title': { es: 'Nueva reserva', en: 'New booking', pt: 'Nova reserva' },
  'driver_assigned.body': {
    es: 'Se te ha asignado un nuevo viaje.',
    en: 'A new trip has been assigned to you.',
    pt: 'Uma nova viagem foi designada para você.',
  },
  'trip_cancelled_by_rider.title': { es: 'Viaje cancelado', en: 'Trip cancelled', pt: 'Viagem cancelada' },
  'booking_cancelled_by_rider.title': { es: 'Reserva cancelada', en: 'Booking cancelled', pt: 'Reserva cancelada' },
  'cancelled_by_rider.body': {
    es: 'El pasajero canceló la reserva. Ya estás disponible.',
    en: 'The passenger cancelled the booking. You are available again.',
    pt: 'O passageiro cancelou a reserva. Você já está disponível.',
  },

  // --- Admin (push del SOS) --------------------------------------------------
  'incident_raised.title': { es: 'SOS en un viaje', en: 'SOS during a trip', pt: 'SOS em uma viagem' },
  'incident_raised.body': {
    es: 'Reserva #{ref}: abre el panel y reconoce el incidente.',
    en: 'Booking #{ref}: open the dashboard and acknowledge the incident.',
    pt: 'Reserva #{ref}: abra o painel e reconheça o incidente.',
  },
  'incident_cancel_requested.title': {
    es: 'SOS cancelado: verificar por llamada',
    en: 'SOS cancelled: verify by phone',
    pt: 'SOS cancelado: verificar por telefone',
  },
  'incident_cancel_requested.body': {
    es: 'Reserva #{ref}: el usuario canceló el aviso. Llama para verificar que está bien.',
    en: 'Booking #{ref}: the user cancelled the alert. Call to verify that they are safe.',
    pt: 'Reserva #{ref}: o usuário cancelou o alerta. Ligue para confirmar que está bem.',
  },
  'incident_unacknowledged.title': { es: 'SOS sin reconocer', en: 'Unacknowledged SOS', pt: 'SOS não reconhecido' },
  'incident_unacknowledged.body': {
    es: 'Reserva #{ref}: nadie ha reconocido el incidente.',
    en: 'Booking #{ref}: nobody has acknowledged the incident.',
    pt: 'Reserva #{ref}: ninguém reconheceu o incidente.',
  },

  // --- Datos que se guardan y se muestran ------------------------------------
  'hourly_destination.name': { es: 'Servicio por horas', en: 'Hourly service', pt: 'Serviço por hora' },
  // Nombres de las clases: Business, First y SUV son nombres de producto.
  'vehicle_class.business': { es: 'Business Class', en: 'Business Class', pt: 'Business Class' },
  'vehicle_class.businessSuv': { es: 'Business SUV', en: 'Business SUV', pt: 'Business SUV' },
  'vehicle_class.businessVan': { es: 'Business Van', en: 'Business Van', pt: 'Business Van' },
  'vehicle_class.firstClass': { es: 'First Class', en: 'First Class', pt: 'First Class' },
  'vehicle_class.electric': { es: 'Eléctrico', en: 'Electric', pt: 'Elétrico' },
  'vehicle_class.unknown': { es: 'Luxelane', en: 'Luxelane', pt: 'Luxelane' },
} as const satisfies Record<string, Texts>;

export type MessageKey = keyof typeof MESSAGES;

/** Tipos de aviso (los de users/{uid}/notifications.type y del push). */
export const NOTICES = {
  booking_confirmed: ['booking_confirmed.title', 'booking_confirmed.body'],
  driver_arriving: ['driver_arriving.title', 'driver_arriving.body'],
  driver_arrived: ['driver_arrived.title', 'driver_arrived.body'],
  ride_started: ['ride_started.title', 'ride_started.body'],
  ride_completed: ['ride_completed.title', 'ride_completed.body'],
  booking_cancelled: ['booking_cancelled.title', 'booking_cancelled.body'],
  booking_driver_released: ['booking_driver_released.title', 'booking_driver_released.body'],
  rider_no_show: ['rider_no_show.title', 'rider_no_show.body'],
  payment_receipt: ['payment_receipt.title', 'payment_receipt.body'],
  payment_confirmed: ['payment_confirmed.title', 'payment_confirmed.body'],
  payment_confirmed_cancelled: ['payment_confirmed_cancelled.title', 'payment_confirmed_cancelled.body'],
  payment_rejected: ['payment_rejected.title', 'payment_rejected.body'],
  payment_expired: ['payment_expired.title', 'payment_expired.body'],
  refund_recorded: ['refund_recorded.title', 'refund_recorded.body'],
  new_trip_available: ['new_trip_available.title', 'new_trip_available.body'],
  driver_assigned: ['driver_assigned.title', 'driver_assigned.body'],
  trip_cancelled_by_rider: ['trip_cancelled_by_rider.title', 'cancelled_by_rider.body'],
  booking_cancelled_by_rider: ['booking_cancelled_by_rider.title', 'cancelled_by_rider.body'],
  incident_raised: ['incident_raised.title', 'incident_raised.body'],
  incident_cancel_requested: ['incident_cancel_requested.title', 'incident_cancel_requested.body'],
  incident_unacknowledged: ['incident_unacknowledged.title', 'incident_unacknowledged.body'],
} as const satisfies Record<string, readonly [MessageKey, MessageKey]>;

export type NoticeType = keyof typeof NOTICES;

const PLACEHOLDER = /\{([A-Za-z][A-Za-z0-9_]*)\}/g;

/** Marcadores {así} de un texto, ordenados y sin repetir. */
export function placeholdersOf(text: string): string[] {
  return [...new Set([...text.matchAll(PLACEHOLDER)].map((m) => m[1]))].sort();
}

export const isAppLocale = (v: unknown): v is AppLocale =>
  typeof v === 'string' && (APP_LOCALES as readonly string[]).includes(v);

/** Idioma de una persona: users/{uid}.locale, o español. */
export function localeOf(user: Record<string, unknown> | undefined | null): AppLocale {
  return isAppLocale(user?.locale) ? user!.locale as AppLocale : DEFAULT_LOCALE;
}

export async function userLocale(db: admin.firestore.Firestore, uid: string): Promise<AppLocale> {
  return localeOf((await db.collection('users').doc(uid).get()).data());
}

/**
 * Texto de una clave en un idioma. Los valores tienen que ser exactamente
 * los marcadores del texto: si falta o sobra uno, es un error de código.
 */
export function t(key: MessageKey, locale: AppLocale, params: Record<string, string> = {}): string {
  const text: string = MESSAGES[key][locale] ?? MESSAGES[key][DEFAULT_LOCALE];
  const want = placeholdersOf(text);
  const got = Object.keys(params).filter((k) => params[k] !== undefined).sort();
  if (want.length !== got.length || want.some((p, i) => p !== got[i])) {
    throw new Error(`i18n: ${key} espera {${want.join(', ')}} y recibió {${got.join(', ')}}`);
  }
  return text.replace(PLACEHOLDER, (_, name: string) => params[name]);
}

/** Título y cuerpo de un aviso en el idioma de quien lo recibe. */
export function notice(type: NoticeType, locale: AppLocale, params: Record<string, string> = {}) {
  const [titleKey, bodyKey] = NOTICES[type];
  const pick = (key: MessageKey) => Object.fromEntries(
    placeholdersOf(MESSAGES[key][DEFAULT_LOCALE]).map((p) => [p, params[p]]));
  return { title: t(titleKey, locale, pick(titleKey)), body: t(bodyKey, locale, pick(bodyKey)), type, locale };
}

/**
 * Importe en bolivianos, siempre «Bs» delante de la cifra (decisión 5). En
 * español y portugués «Bs 1.234,50»; en inglés «Bs 1,234.50», para que la
 * cifra no se lea distinta. Sin céntimos, sin decimales.
 */
export function formatMoney(amount: number, locale: AppLocale): string {
  const cents = Math.round(amount * 100);
  const abs = Math.abs(cents);
  const [thousands, decimal] = locale === 'en' ? [',', '.'] : ['.', ','];
  const whole = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, thousands);
  const rest = abs % 100;
  const sign = cents < 0 ? '-' : '';
  return `${sign}Bs ${whole}${rest ? `${decimal}${String(rest).padStart(2, '0')}` : ''}`;
}

export function vehicleClassName(vehicleClass: string | undefined, locale: AppLocale): string {
  const key = `vehicle_class.${vehicleClass}` as MessageKey;
  return t(key in MESSAGES ? key : 'vehicle_class.unknown', locale);
}
