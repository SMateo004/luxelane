import 'package:flutter/widgets.dart' show Locale;

import '../../../../core/config/legal.dart';
import '../../../../core/utils/waiting_policy.dart';

/// One titled block of a legal document.
class LegalSection {
  const LegalSection(this.title, this.paragraphs);
  final String title;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.intro, required this.sections});
  final String title;
  final String intro;
  final List<LegalSection> sections;
}

/// Date of the last revision of both documents. Shown formatted in the
/// active language (keep in sync with [LegalInfo.lastUpdated]).
final legalLastUpdated = DateTime(2026, 10, 7);

/// Privacy policy in the language of [locale]; English for unsupported
/// languages (same fallback as the app).
LegalDocument privacyPolicyFor(Locale locale) => switch (locale.languageCode) {
      'es' => _privacyEs,
      'pt' => _privacyPt,
      _ => _privacyEn,
    };

/// Terms of service in the language of [locale]; English fallback.
LegalDocument termsOfServiceFor(Locale locale) => switch (locale.languageCode) {
      'es' => _termsEs,
      'pt' => _termsPt,
      _ => _termsEn,
    };

/// [LegalInfo] values are written in Spanish. While one is still a
/// "[placeholder]", show the translated placeholder instead.
String _ph(String value, String translated) => value.startsWith('[') ? translated : value;

// These drafts describe how the product actually works (data collected,
// who can see it and when). They are NOT legal advice: have them reviewed
// by a lawyer licensed in Bolivia before launch. The Spanish version is
// the reference text; en/pt are translations and say so in their intro.

// ---------------------------------------------------------------- Español

const _privacyEs = LegalDocument(
  title: 'Política de privacidad',
  intro:
      '${LegalInfo.companyName} ("${LegalInfo.brand}"), NIT ${LegalInfo.nit}, con domicilio en ${LegalInfo.address}, '
      'es responsable de los datos personales que tratamos cuando usas la app y el sitio web de ${LegalInfo.brand}. '
      'Esta política explica qué datos recogemos, para qué los usamos, con quién los compartimos y cómo puedes ejercer tus derechos.',
  sections: [
    LegalSection('1. Datos que recogemos', [
      'Datos de cuenta: nombre, correo electrónico, teléfono y, si la agregas, foto de perfil.',
      'Datos de cada reserva: punto de recogida y destino, fecha y hora, clase de vehículo, número de pasajeros y maletas, número de vuelo (si lo indicas), notas, y el nombre y teléfono de la persona que viaja si reservas para un invitado.',
      'Ubicación: usamos tu ubicación solo cuando la autorizas, para sugerir el punto de recogida. Si eres chófer, recogemos tu ubicación mientras estás disponible y durante los viajes, también con la app en segundo plano, para asignarte viajes cercanos y mostrar tu llegada al pasajero.',
      'Datos técnicos: identificador del dispositivo para notificaciones push, y registros de errores y rendimiento de la app.',
      'Calificaciones y comentarios que dejas sobre un viaje.',
      'Si eres chófer: licencia de conducir y su vencimiento, y datos del vehículo (marca, modelo, color y placa).',
    ]),
    LegalSection('2. Para qué los usamos', [
      'Para crear y gestionar tu cuenta, calcular el precio fijo, asignar un chófer y prestar el servicio de traslado.',
      'Para mostrar al pasajero la llegada del chófer en tiempo real y enviar avisos sobre el estado del viaje.',
      'Para seguir el estado de tu vuelo y ajustar la hora de recogida si hay retrasos.',
      'Para la seguridad del servicio, la atención de reclamos y el cumplimiento de obligaciones legales y contables.',
      'No vendemos tus datos ni los usamos para publicidad de terceros.',
    ]),
    LegalSection('3. Con quién los compartimos', [
      'Con tu chófer: nombre de la persona que viaja, teléfono, punto de recogida, destino, número de vuelo y notas de la reserva.',
      'Con el pasajero: nombre abreviado del chófer, foto, calificación, vehículo, placa y, solo mientras el viaje está activo, su teléfono y su ubicación en tiempo real. Al terminar el viaje dejamos de compartir el teléfono y la ubicación.',
      'Con proveedores que nos prestan servicios: Google (Firebase para alojamiento, base de datos, autenticación y notificaciones; Google Maps para mapas y direcciones) y nuestro proveedor de información de vuelos, al que solo enviamos el número y la fecha del vuelo. Estos proveedores pueden procesar datos fuera de Bolivia.',
      'Con autoridades, cuando una norma o una orden judicial lo exija.',
    ]),
    LegalSection('4. Cuánto tiempo los conservamos', [
      'Conservamos los datos de tu cuenta mientras esté activa.',
      'Los registros de viajes se conservan ${LegalInfo.recordRetention} por obligaciones contables y tributarias. Si eliminas tu cuenta, quitamos de esos registros tu nombre, teléfono y notas.',
    ]),
    LegalSection('5. Tus derechos', [
      'Puedes acceder a tus datos, corregirlos desde tu perfil o pedirnos una copia escribiéndonos.',
      'Puedes eliminar tu cuenta en cualquier momento desde Perfil → Eliminar cuenta, o en la página "Eliminar cuenta" del sitio web. No es posible eliminarla mientras tengas un viaje en curso.',
      'Puedes retirar el permiso de ubicación o de notificaciones desde los ajustes de tu dispositivo.',
      'Para cualquier consulta sobre tus datos escríbenos a ${LegalInfo.supportEmail}.',
    ]),
    LegalSection('6. Seguridad', [
      'Protegemos tus datos con cifrado en tránsito, reglas de acceso que limitan quién puede ver cada dato y registros de auditoría. Ningún sistema es infalible; si detectamos un incidente que te afecte, te lo comunicaremos.',
    ]),
    LegalSection('7. Menores de edad', [
      'El servicio está dirigido a mayores de 18 años. Los menores solo pueden viajar en reservas hechas por un adulto responsable.',
    ]),
    LegalSection('8. Cambios a esta política', [
      'Si cambiamos esta política te lo avisaremos en la app antes de que los cambios entren en vigor.',
    ]),
  ],
);

const _termsEs = LegalDocument(
  title: 'Términos y condiciones',
  intro:
      'Estos términos regulan el uso de ${LegalInfo.brand}, servicio de traslados con chófer operado por ${LegalInfo.companyName}, '
      'NIT ${LegalInfo.nit}. Al crear una cuenta o reservar un viaje aceptas estos términos.',
  sections: [
    LegalSection('1. El servicio', [
      'Luxelane permite reservar traslados con chófer profesional: viajes de punto a punto, traslados al aeropuerto y chófer por horas.',
      'Los chóferes son verificados por nuestro equipo antes de recibir viajes.',
    ]),
    LegalSection('2. Cuenta', [
      'Debes ser mayor de 18 años y dar datos verdaderos. Eres responsable de mantener segura tu contraseña y de las reservas hechas con tu cuenta.',
    ]),
    LegalSection('3. Precio y pago', [
      'Antes de confirmar te mostramos un precio fijo en bolivianos (Bs). Ese es el precio del viaje: no cambia por tráfico ni por la ruta que elija el chófer.',
      'Salvo que se indique otra forma de pago, el precio se paga al chófer al finalizar el viaje, en efectivo o mediante QR.',
      'Cambios que tú solicites durante el viaje (paradas, otro destino, más horas) pueden modificar el precio, lo que se te informará antes de aplicarlo.',
    ]),
    LegalSection('4. Tiempo de espera', [
      'Cada reserva incluye espera gratuita: ${WaitingPolicy.airportFreeMinutes} minutos en recogidas en aeropuerto, contados desde el aterrizaje del vuelo, y ${WaitingPolicy.cityFreeMinutes} minutos en ciudad, contados desde la hora de recogida o desde la llegada del chófer si esta fue posterior.',
      'Si indicas tu número de vuelo, seguimos su estado y ajustamos la hora de recogida si se retrasa.',
      '[Definir qué ocurre al terminar la espera gratuita: tiempo adicional con costo o cancelación como no presentado.]',
    ]),
    LegalSection('5. Cancelaciones', [
      'Puedes cancelar sin costo hasta 1 hora antes de la hora de recogida, desde la app.',
      '[Definir la política para cancelaciones con menos de 1 hora y para no presentarse.]',
      'Si no podemos asignar un chófer, cancelaremos la reserva y te lo notificaremos.',
    ]),
    LegalSection('6. Conducta', [
      'Pasajeros y chóferes deben tratarse con respeto. No se permite fumar en los vehículos ni transportar objetos ilegales o peligrosos.',
      'Podemos suspender cuentas que incumplan estos términos o pongan en riesgo a otras personas.',
    ]),
    LegalSection('7. Responsabilidad', [
      '[Definir con asesoría legal los límites de responsabilidad, seguros del vehículo y del pasajero, y el procedimiento ante objetos perdidos o daños.]',
    ]),
    LegalSection('8. Ley aplicable y reclamos', [
      'Estos términos se rigen por las leyes del Estado Plurinacional de Bolivia. Puedes presentar reclamos escribiendo a ${LegalInfo.supportEmail}.',
      '[Indicar jurisdicción competente, p. ej. ${LegalInfo.city}.]',
    ]),
  ],
);

// ---------------------------------------------------------------- English

final _companyEn = _ph(LegalInfo.companyName, '[Company legal name]');
final _addressEn = _ph(LegalInfo.address, '[Business address, Santa Cruz de la Sierra, Bolivia]');
final _emailEn = _ph(LegalInfo.supportEmail, '[email@domain.bo]');
final _retentionEn = _ph(LegalInfo.recordRetention, '[N] years');

const _prevailsEn =
    'This English version is a translation provided for convenience; in case of any discrepancy, the Spanish version prevails.';

final _privacyEn = LegalDocument(
  title: 'Privacy policy',
  intro: '$_companyEn ("${LegalInfo.brand}"), NIT (Tax ID) ${LegalInfo.nit}, with registered address at $_addressEn, '
      'is responsible for the personal data we process when you use the ${LegalInfo.brand} app and website. '
      'This policy explains what data we collect, what we use it for, who we share it with and how you can exercise your rights. '
      '$_prevailsEn',
  sections: [
    const LegalSection('1. Data we collect', [
      'Account data: name, email address, phone number and, if you add one, a profile photo.',
      'Data for each booking: pickup point and destination, date and time, vehicle class, number of passengers and bags, flight number (if you provide it), notes, and the name and phone number of the person traveling if you book for a guest.',
      'Location: we use your location only when you allow it, to suggest the pickup point. If you are a chauffeur, we collect your location while you are available and during trips, including when the app is in the background, to assign you nearby trips and show your arrival to the passenger.',
      'Technical data: device identifier for push notifications, and app error and performance logs.',
      'Ratings and comments you leave about a trip.',
      "If you are a chauffeur: driver's license and its expiration date, and vehicle details (make, model, color and license plate).",
    ]),
    const LegalSection('2. What we use it for', [
      'To create and manage your account, calculate the fixed price, assign a chauffeur and provide the transfer service.',
      "To show the passenger the chauffeur's arrival in real time and send notices about the trip status.",
      'To track the status of your flight and adjust the pickup time if there are delays.',
      'For the safety of the service, handling complaints and complying with legal and accounting obligations.',
      'We do not sell your data or use it for third-party advertising.',
    ]),
    const LegalSection('3. Who we share it with', [
      'With your chauffeur: name of the person traveling, phone number, pickup point, destination, flight number and booking notes.',
      "With the passenger: the chauffeur's shortened name, photo, rating, vehicle, license plate and, only while the trip is active, their phone number and real-time location. When the trip ends, we stop sharing the phone number and location.",
      'With providers that render services to us: Google (Firebase for hosting, database, authentication and notifications; Google Maps for maps and directions) and our flight information provider, to which we only send the flight number and date. These providers may process data outside Bolivia.',
      'With authorities, when required by law or a court order.',
    ]),
    LegalSection('4. How long we keep it', [
      'We keep your account data for as long as your account is active.',
      'Trip records are kept for $_retentionEn for accounting and tax obligations. If you delete your account, we remove your name, phone number and notes from those records.',
    ]),
    LegalSection('5. Your rights', [
      'You can access your data, correct it from your profile or ask us for a copy by writing to us.',
      'You can delete your account at any time from Profile → Delete account, or on the "Delete account" page of the website. It cannot be deleted while you have a trip in progress.',
      'You can withdraw location or notification permission from your device settings.',
      'For any question about your data, write to us at $_emailEn.',
    ]),
    const LegalSection('6. Security', [
      'We protect your data with encryption in transit, access rules that limit who can see each piece of data, and audit logs. No system is infallible; if we detect an incident that affects you, we will let you know.',
    ]),
    const LegalSection('7. Minors', [
      'The service is intended for people aged 18 and over. Minors may only travel on bookings made by a responsible adult.',
    ]),
    const LegalSection('8. Changes to this policy', [
      'If we change this policy, we will notify you in the app before the changes take effect.',
    ]),
  ],
);

final _termsEn = LegalDocument(
  title: 'Terms and conditions',
  intro: 'These terms govern the use of ${LegalInfo.brand}, a chauffeured transfer service operated by $_companyEn, '
      'NIT (Tax ID) ${LegalInfo.nit}. By creating an account or booking a trip, you accept these terms. '
      '$_prevailsEn',
  sections: [
    const LegalSection('1. The service', [
      'Luxelane lets you book transfers with a professional chauffeur: point-to-point trips, airport transfers and chauffeur by the hour.',
      'Chauffeurs are vetted by our team before they receive trips.',
    ]),
    const LegalSection('2. Account', [
      'You must be at least 18 years old and provide truthful information. You are responsible for keeping your password secure and for bookings made with your account.',
    ]),
    const LegalSection('3. Price and payment', [
      'Before you confirm, we show you a fixed price in bolivianos (Bs). That is the price of the trip: it does not change due to traffic or the route the chauffeur chooses.',
      'Unless another payment method is indicated, the price is paid to the chauffeur at the end of the trip, in cash or by QR code.',
      'Changes you request during the trip (stops, a different destination, more hours) may change the price; you will be informed before they are applied.',
    ]),
    const LegalSection('4. Waiting time', [
      "Every booking includes free waiting time: ${WaitingPolicy.airportFreeMinutes} minutes for airport pickups, counted from the flight's landing, and ${WaitingPolicy.cityFreeMinutes} minutes in the city, counted from the pickup time or from the chauffeur's arrival if it was later.",
      'If you provide your flight number, we track its status and adjust the pickup time if it is delayed.',
      '[Define what happens when the free waiting time ends: additional time at a cost or cancellation as a no-show.]',
    ]),
    const LegalSection('5. Cancellations', [
      'You can cancel free of charge up to 1 hour before the pickup time, from the app.',
      "[Define the policy for cancellations with less than 1 hour's notice and for no-shows.]",
      'If we cannot assign a chauffeur, we will cancel the booking and notify you.',
    ]),
    const LegalSection('6. Conduct', [
      'Passengers and chauffeurs must treat each other with respect. Smoking in the vehicles and carrying illegal or dangerous items are not allowed.',
      'We may suspend accounts that breach these terms or put other people at risk.',
    ]),
    const LegalSection('7. Liability', [
      '[Define with legal counsel the limits of liability, vehicle and passenger insurance, and the procedure for lost items or damage.]',
    ]),
    LegalSection('8. Governing law and complaints', [
      'These terms are governed by the laws of the Plurinational State of Bolivia. You can file complaints by writing to $_emailEn.',
      '[State the competent jurisdiction, e.g. ${LegalInfo.city}.]',
    ]),
  ],
);

// ------------------------------------------------------------- Português

final _companyPt = _ph(LegalInfo.companyName, '[Razão social da empresa]');
final _addressPt = _ph(LegalInfo.address, '[Endereço comercial, Santa Cruz de la Sierra, Bolívia]');
final _emailPt = _ph(LegalInfo.supportEmail, '[email@dominio.bo]');
final _retentionPt = _ph(LegalInfo.recordRetention, '[N] anos');

const _prevailsPt =
    'Esta versão em português é uma tradução fornecida para sua conveniência; em caso de divergência, prevalece a versão em espanhol.';

final _privacyPt = LegalDocument(
  title: 'Política de privacidade',
  intro: '$_companyPt ("${LegalInfo.brand}"), NIT (identificação fiscal) ${LegalInfo.nit}, com sede em $_addressPt, '
      'é responsável pelos dados pessoais que tratamos quando você usa o app e o site da ${LegalInfo.brand}. '
      'Esta política explica quais dados coletamos, para que os usamos, com quem os compartilhamos e como você pode exercer seus direitos. '
      '$_prevailsPt',
  sections: [
    const LegalSection('1. Dados que coletamos', [
      'Dados da conta: nome, e-mail, telefone e, se você adicionar, foto de perfil.',
      'Dados de cada reserva: local de embarque e destino, data e hora, categoria do veículo, número de passageiros e malas, número do voo (se você informar), observações, e o nome e telefone da pessoa que viaja se você reservar para um convidado.',
      'Localização: usamos sua localização somente quando você autoriza, para sugerir o local de embarque. Se você for motorista, coletamos sua localização enquanto estiver disponível e durante as viagens, inclusive com o app em segundo plano, para atribuir viagens próximas a você e mostrar sua chegada ao passageiro.',
      'Dados técnicos: identificador do dispositivo para notificações push, e registros de erros e desempenho do app.',
      'Avaliações e comentários que você deixa sobre uma viagem.',
      'Se você for motorista: carteira de habilitação e sua validade, e dados do veículo (marca, modelo, cor e placa).',
    ]),
    const LegalSection('2. Para que os usamos', [
      'Para criar e gerenciar sua conta, calcular o preço fixo, atribuir um motorista e prestar o serviço de transporte.',
      'Para mostrar ao passageiro a chegada do motorista em tempo real e enviar avisos sobre o status da viagem.',
      'Para acompanhar o status do seu voo e ajustar o horário de embarque se houver atrasos.',
      'Para a segurança do serviço, o atendimento de reclamações e o cumprimento de obrigações legais e contábeis.',
      'Não vendemos seus dados nem os usamos para publicidade de terceiros.',
    ]),
    const LegalSection('3. Com quem os compartilhamos', [
      'Com seu motorista: nome da pessoa que viaja, telefone, local de embarque, destino, número do voo e observações da reserva.',
      'Com o passageiro: nome abreviado do motorista, foto, avaliação, veículo, placa e, somente enquanto a viagem estiver ativa, seu telefone e sua localização em tempo real. Ao terminar a viagem, deixamos de compartilhar o telefone e a localização.',
      'Com fornecedores que nos prestam serviços: Google (Firebase para hospedagem, banco de dados, autenticação e notificações; Google Maps para mapas e rotas) e nosso fornecedor de informações de voos, ao qual enviamos apenas o número e a data do voo. Esses fornecedores podem tratar dados fora da Bolívia.',
      'Com autoridades, quando uma norma ou uma ordem judicial o exigir.',
    ]),
    LegalSection('4. Por quanto tempo os conservamos', [
      'Conservamos os dados da sua conta enquanto ela estiver ativa.',
      'Os registros de viagens são conservados por $_retentionPt por obrigações contábeis e tributárias. Se você excluir sua conta, removemos desses registros seu nome, telefone e observações.',
    ]),
    LegalSection('5. Seus direitos', [
      'Você pode acessar seus dados, corrigi-los no seu perfil ou nos pedir uma cópia escrevendo para nós.',
      'Você pode excluir sua conta a qualquer momento em Perfil → Excluir conta, ou na página "Excluir conta" do site. Não é possível excluí-la enquanto você tiver uma viagem em andamento.',
      'Você pode retirar a permissão de localização ou de notificações nas configurações do seu dispositivo.',
      'Para qualquer dúvida sobre seus dados, escreva para $_emailPt.',
    ]),
    const LegalSection('6. Segurança', [
      'Protegemos seus dados com criptografia em trânsito, regras de acesso que limitam quem pode ver cada dado e registros de auditoria. Nenhum sistema é infalível; se detectarmos um incidente que afete você, vamos comunicá-lo.',
    ]),
    const LegalSection('7. Menores de idade', [
      'O serviço é destinado a maiores de 18 anos. Menores só podem viajar em reservas feitas por um adulto responsável.',
    ]),
    const LegalSection('8. Alterações nesta política', [
      'Se alterarmos esta política, avisaremos você no app antes que as alterações entrem em vigor.',
    ]),
  ],
);

final _termsPt = LegalDocument(
  title: 'Termos e condições',
  intro:
      'Estes termos regulam o uso da ${LegalInfo.brand}, serviço de transporte com motorista operado por $_companyPt, '
      'NIT (identificação fiscal) ${LegalInfo.nit}. Ao criar uma conta ou reservar uma viagem, você aceita estes termos. '
      '$_prevailsPt',
  sections: [
    const LegalSection('1. O serviço', [
      'A Luxelane permite reservar transportes com motorista profissional: viagens ponto a ponto, traslados ao aeroporto e motorista por hora.',
      'Os motoristas são verificados pela nossa equipe antes de receber viagens.',
    ]),
    const LegalSection('2. Conta', [
      'Você deve ser maior de 18 anos e fornecer dados verdadeiros. Você é responsável por manter sua senha segura e pelas reservas feitas com sua conta.',
    ]),
    const LegalSection('3. Preço e pagamento', [
      'Antes de confirmar, mostramos um preço fixo em bolivianos (Bs). Esse é o preço da viagem: ele não muda por causa do trânsito nem da rota escolhida pelo motorista.',
      'Salvo indicação de outra forma de pagamento, o preço é pago ao motorista ao final da viagem, em dinheiro ou por QR code.',
      'Alterações que você solicitar durante a viagem (paradas, outro destino, mais horas) podem modificar o preço, o que será informado a você antes de ser aplicado.',
    ]),
    const LegalSection('4. Tempo de espera', [
      'Cada reserva inclui espera gratuita: ${WaitingPolicy.airportFreeMinutes} minutos em embarques no aeroporto, contados a partir do pouso do voo, e ${WaitingPolicy.cityFreeMinutes} minutos na cidade, contados a partir do horário de embarque ou da chegada do motorista, se esta for posterior.',
      'Se você informar o número do seu voo, acompanhamos seu status e ajustamos o horário de embarque se ele atrasar.',
      '[Definir o que acontece ao terminar a espera gratuita: tempo adicional com custo ou cancelamento por não comparecimento.]',
    ]),
    const LegalSection('5. Cancelamentos', [
      'Você pode cancelar sem custo até 1 hora antes do horário de embarque, pelo app.',
      '[Definir a política para cancelamentos com menos de 1 hora de antecedência e para não comparecimento.]',
      'Se não conseguirmos atribuir um motorista, cancelaremos a reserva e notificaremos você.',
    ]),
    const LegalSection('6. Conduta', [
      'Passageiros e motoristas devem se tratar com respeito. Não é permitido fumar nos veículos nem transportar objetos ilegais ou perigosos.',
      'Podemos suspender contas que descumpram estes termos ou coloquem outras pessoas em risco.',
    ]),
    const LegalSection('7. Responsabilidade', [
      '[Definir com assessoria jurídica os limites de responsabilidade, seguros do veículo e do passageiro, e o procedimento em caso de objetos perdidos ou danos.]',
    ]),
    LegalSection('8. Lei aplicável e reclamações', [
      'Estes termos são regidos pelas leis do Estado Plurinacional da Bolívia. Você pode apresentar reclamações escrevendo para $_emailPt.',
      '[Indicar a jurisdição competente, p. ex. ${LegalInfo.city}.]',
    ]),
  ],
);
