// Push-notification copy in the user's language (users/{uid}.locale is kept
// in sync with the device language by the app). Falls back to Spanish.

export type Lang = 'es' | 'en' | 'pt';

export function langOf(locale: unknown): Lang {
  const code = String(locale ?? '').toLowerCase().slice(0, 2);
  return code === 'en' || code === 'pt' ? code : 'es';
}

const TZ = 'America/La_Paz';
const intlTag: Record<Lang, string> = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };

/** "Bs 1.250" (es/pt) · "Bs 1,250" (en) */
export function money(amount: number, lang: Lang): string {
  const n = new Intl.NumberFormat(intlTag[lang], { maximumFractionDigits: 0 }).format(Math.round(amount));
  return `Bs ${n}`;
}

/** Local Bolivian time, e.g. "14:35" / "2:35 PM". */
export function clock(date: Date, lang: Lang): string {
  // 24-hour clock in Spanish and Portuguese, 12-hour in English.
  return date.toLocaleTimeString(intlTag[lang], { hour: '2-digit', minute: '2-digit', hour12: lang === 'en', timeZone: TZ });
}

type Template = Record<Lang, string>;

const M = {
  offerTitle: { es: 'Nueva solicitud para ti', en: 'New request for you', pt: 'Nova solicitação para você' },
  offerBody: {
    es: '{price}{distance}. Tienes 1 minuto para aceptarla.',
    en: '{price}{distance}. You have 1 minute to accept it.',
    pt: '{price}{distance}. Você tem 1 minuto para aceitar.',
  },
  offerDistance: { es: ' · a {km} km', en: ' · {km} km away', pt: ' · a {km} km' },
  broadcastTitle: { es: 'Nueva reserva disponible', en: 'New booking available', pt: 'Nova reserva disponível' },
  broadcastBody: { es: '{vehicle} · {price}', en: '{vehicle} · {price}', pt: '{vehicle} · {price}' },
  statusTitle: { es: 'Luxelane', en: 'Luxelane', pt: 'Luxelane' },
  statusConfirmed: { es: 'Tu chófer ha sido asignado', en: 'Your chauffeur has been assigned', pt: 'Seu motorista foi designado' },
  statusArriving: { es: 'Tu chófer está en camino', en: 'Your chauffeur is on the way', pt: 'Seu motorista está a caminho' },
  statusArrived: {
    es: 'Tu chófer ha llegado. Espera gratuita hasta las {time}.',
    en: 'Your chauffeur has arrived. Free waiting until {time}.',
    pt: 'Seu motorista chegou. Espera grátis até as {time}.',
  },
  statusInProgress: { es: 'Tu viaje ha comenzado', en: 'Your ride has started', pt: 'Sua viagem começou' },
  statusCompleted: {
    es: 'Has llegado. ¡Gracias por viajar con Luxelane!',
    en: 'You have arrived. Thank you for riding with Luxelane!',
    pt: 'Você chegou. Obrigado por viajar com a Luxelane!',
  },
  companyAddedTitle: { es: 'Cuenta corporativa', en: 'Corporate account', pt: 'Conta corporativa' },
  companyAddedBody: {
    es: 'Ahora puedes facturar tus viajes a {company}.',
    en: 'You can now bill your rides to {company}.',
    pt: 'Agora você pode faturar suas viagens para {company}.',
  },
  docApprovedTitle: { es: 'Documento aprobado', en: 'Document approved', pt: 'Documento aprovado' },
  docApprovedBody: {
    es: 'Aprobamos tu {doc}.',
    en: 'Your {doc} was approved.',
    pt: 'Aprovamos seu {doc}.',
  },
  docRejectedTitle: { es: 'Revisa tu documento', en: 'Check your document', pt: 'Revise seu documento' },
  docRejectedBody: {
    es: 'No pudimos aprobar tu {doc}: {reason}. Súbelo de nuevo desde Documentos.',
    en: "We couldn't approve your {doc}: {reason}. Upload it again from Documents.",
    pt: 'Não conseguimos aprovar seu {doc}: {reason}. Envie novamente em Documentos.',
  },
  docExpiringTitle: { es: 'Documento por vencer', en: 'Document expiring soon', pt: 'Documento a vencer' },
  docExpiringBody: {
    es: 'Tu {doc} vence en {days} días. Sube la versión renovada para seguir recibiendo viajes.',
    en: 'Your {doc} expires in {days} days. Upload the renewed one to keep receiving rides.',
    pt: 'Seu {doc} vence em {days} dias. Envie a versão renovada para continuar recebendo viagens.',
  },
  docExpiredTitle: { es: 'Documento vencido', en: 'Document expired', pt: 'Documento vencido' },
  docExpiredBody: {
    es: 'Tu {doc} venció. No recibirás viajes hasta que subas uno vigente y lo aprobemos.',
    en: "Your {doc} has expired. You won't get rides until you upload a current one and we approve it.",
    pt: 'Seu {doc} venceu. Você não receberá viagens até enviar um válido e aprovarmos.',
  },
  supportReplyTitle: { es: 'Respuesta de soporte', en: 'Support replied', pt: 'Resposta do suporte' },
  supportReplyBody: { es: '{preview}', en: '{preview}', pt: '{preview}' },
  supportNewTitle: { es: 'Nueva solicitud de soporte', en: 'New support request', pt: 'Nova solicitação de suporte' },
  supportUrgentTitle: { es: 'URGENTE: reporte de seguridad', en: 'URGENT: safety report', pt: 'URGENTE: relato de segurança' },
  supportNewBody: { es: '{name}: {preview}', en: '{name}: {preview}', pt: '{name}: {preview}' },
  opsNoDriverTitle: { es: 'Reserva sin chófer', en: 'Booking without a chauffeur', pt: 'Reserva sem motorista' },
  opsNoDriverBody: {
    es: 'Recogida a las {time} en {place}. Nadie la ha tomado todavía.',
    en: 'Pickup at {time} at {place}. Nobody has taken it yet.',
    pt: 'Embarque às {time} em {place}. Ninguém aceitou ainda.',
  },
  opsNoDriversOnlineTitle: { es: 'Ningún chófer en línea', en: 'No chauffeurs online', pt: 'Nenhum motorista on-line' },
  opsNoDriversOnlineBody: {
    es: 'Hay {count} reservas en las próximas 2 horas y ningún chófer verificado conectado.',
    en: 'There are {count} bookings in the next 2 hours and no verified chauffeur online.',
    pt: 'Há {count} reservas nas próximas 2 horas e nenhum motorista verificado on-line.',
  },
  statusCancelled: { es: 'Tu reserva ha sido cancelada', en: 'Your booking has been cancelled', pt: 'Sua reserva foi cancelada' },
  assignedTitle: { es: 'Nueva reserva', en: 'New booking', pt: 'Nova reserva' },
  assignedBody: { es: 'Se te ha asignado un nuevo viaje', en: 'A new ride has been assigned to you', pt: 'Uma nova viagem foi atribuída a você' },
  acceptedTitle: { es: 'Chófer asignado', en: 'Chauffeur assigned', pt: 'Motorista designado' },
  acceptedBody: { es: 'Tu chófer ha confirmado la reserva', en: 'Your chauffeur has confirmed the booking', pt: 'Seu motorista confirmou a reserva' },
  flightTitle: { es: 'Actualización de vuelo', en: 'Flight update', pt: 'Atualização de voo' },
  flightDelayed: {
    es: 'Tu vuelo {flight} llega con {minutes} min de retraso. Tu chófer te esperará a las {time}.',
    en: 'Your flight {flight} is {minutes} min late. Your chauffeur will meet you at {time}.',
    pt: 'Seu voo {flight} está {minutes} min atrasado. Seu motorista vai esperar você às {time}.',
  },
  flightCancelled: {
    es: 'Tu vuelo {flight} figura como cancelado. Revisa tu reserva.',
    en: 'Your flight {flight} shows as cancelled. Please check your booking.',
    pt: 'Seu voo {flight} consta como cancelado. Verifique sua reserva.',
  },
  pickupMovedTitle: { es: 'Recogida reprogramada', en: 'Pickup rescheduled', pt: 'Embarque reagendado' },
  pickupMovedBody: {
    es: 'Vuelo {flight}: nueva hora de recogida {time}.',
    en: 'Flight {flight}: new pickup time {time}.',
    pt: 'Voo {flight}: novo horário de embarque {time}.',
  },
  riderCancelledTitle: { es: 'Viaje cancelado', en: 'Ride cancelled', pt: 'Viagem cancelada' },
  riderCancelledBody: {
    es: 'El pasajero canceló el viaje de las {time}. Ya estás libre para otras solicitudes.',
    en: 'The passenger cancelled the {time} ride. You are free for other requests.',
    pt: 'O passageiro cancelou a viagem das {time}. Você está livre para outras solicitações.',
  },
  paymentTitle: { es: 'Pago confirmado', en: 'Payment confirmed', pt: 'Pagamento confirmado' },
  paymentBody: {
    es: 'Se cobró {price} por tu viaje',
    en: '{price} was charged for your ride',
    pt: 'Foram cobrados {price} pela sua viagem',
  },
} satisfies Record<string, Template>;

export type MessageKey = keyof typeof M;

export function t(lang: Lang, key: MessageKey, params: Record<string, string | number> = {}): string {
  return M[key][lang].replace(/\{(\w+)\}/g, (_, name: string) => String(params[name] ?? ''));
}

/** Vehicle class names as shown to drivers. */
export function vehicleName(cls: string, lang: Lang): string {
  const names: Record<string, Template> = {
    business: { es: 'Business Class', en: 'Business Class', pt: 'Business Class' },
    firstClass: { es: 'First Class', en: 'First Class', pt: 'First Class' },
    businessVan: { es: 'Business Van', en: 'Business Van', pt: 'Business Van' },
    electric: { es: 'Eléctrico', en: 'Electric', pt: 'Elétrico' },
  };
  return names[cls]?.[lang] ?? cls;
}

const DOC_NAMES: Record<string, Template> = {
  license: { es: 'licencia de conducir', en: "driver's license", pt: 'carteira de motorista' },
  idCard: { es: 'cédula de identidad', en: 'ID card', pt: 'documento de identidade' },
  criminalRecord: { es: 'certificado de antecedentes', en: 'criminal record certificate', pt: 'certidão de antecedentes' },
  soat: { es: 'SOAT', en: 'SOAT insurance', pt: 'seguro SOAT' },
  vehicleRegistration: { es: 'registro del vehículo (RUAT)', en: 'vehicle registration (RUAT)', pt: 'registro do veículo (RUAT)' },
};

export function docName(type: string, lang: Lang): string {
  return DOC_NAMES[type]?.[lang] ?? type;
}
