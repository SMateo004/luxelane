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

// These drafts describe how the product actually works (data collected,
// who can see it and when). They are NOT legal advice: have them reviewed
// by a lawyer licensed in Bolivia before launch.

final privacyPolicy = LegalDocument(
  title: 'Política de privacidad',
  intro:
      '${LegalInfo.companyName} ("${LegalInfo.brand}"), NIT ${LegalInfo.nit}, con domicilio en ${LegalInfo.address}, '
      'es responsable de los datos personales que tratamos cuando usas la app y el sitio web de ${LegalInfo.brand}. '
      'Esta política explica qué datos recogemos, para qué los usamos, con quién los compartimos y cómo puedes ejercer tus derechos.',
  sections: [
    const LegalSection('1. Datos que recogemos', [
      'Datos de cuenta: nombre, correo electrónico, teléfono y, si la agregas, foto de perfil.',
      'Datos de cada reserva: punto de recogida y destino, fecha y hora, clase de vehículo, número de pasajeros y maletas, número de vuelo (si lo indicas), notas, y el nombre y teléfono de la persona que viaja si reservas para un invitado.',
      'Ubicación: usamos tu ubicación solo cuando la autorizas, para sugerir el punto de recogida. Si eres chófer, recogemos tu ubicación mientras estás disponible y durante los viajes, también con la app en segundo plano, para asignarte viajes cercanos y mostrar tu llegada al pasajero.',
      'Datos técnicos: identificador del dispositivo para notificaciones push, y registros de errores y rendimiento de la app.',
      'Calificaciones y comentarios que dejas sobre un viaje.',
      'Si eres chófer: licencia de conducir y su vencimiento, y datos del vehículo (marca, modelo, color y placa).',
    ]),
    const LegalSection('2. Para qué los usamos', [
      'Para crear y gestionar tu cuenta, calcular el precio fijo, asignar un chófer y prestar el servicio de traslado.',
      'Para mostrar al pasajero la llegada del chófer en tiempo real y enviar avisos sobre el estado del viaje.',
      'Para seguir el estado de tu vuelo y ajustar la hora de recogida si hay retrasos.',
      'Para la seguridad del servicio, la atención de reclamos y el cumplimiento de obligaciones legales y contables.',
      'No vendemos tus datos ni los usamos para publicidad de terceros.',
    ]),
    const LegalSection('3. Con quién los compartimos', [
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
    const LegalSection('6. Seguridad', [
      'Protegemos tus datos con cifrado en tránsito, reglas de acceso que limitan quién puede ver cada dato y registros de auditoría. Ningún sistema es infalible; si detectamos un incidente que te afecte, te lo comunicaremos.',
    ]),
    const LegalSection('7. Menores de edad', [
      'El servicio está dirigido a mayores de 18 años. Los menores solo pueden viajar en reservas hechas por un adulto responsable.',
    ]),
    const LegalSection('8. Cambios a esta política', [
      'Si cambiamos esta política te lo avisaremos en la app antes de que los cambios entren en vigor.',
    ]),
  ],
);

final termsOfService = LegalDocument(
  title: 'Términos y condiciones',
  intro:
      'Estos términos regulan el uso de ${LegalInfo.brand}, servicio de traslados con chófer operado por ${LegalInfo.companyName}, '
      'NIT ${LegalInfo.nit}. Al crear una cuenta o reservar un viaje aceptas estos términos.',
  sections: [
    const LegalSection('1. El servicio', [
      'Luxelane permite reservar traslados con chófer profesional: viajes de punto a punto, traslados al aeropuerto y chófer por horas.',
      'Los chóferes son verificados por nuestro equipo antes de recibir viajes.',
    ]),
    const LegalSection('2. Cuenta', [
      'Debes ser mayor de 18 años y dar datos verdaderos. Eres responsable de mantener segura tu contraseña y de las reservas hechas con tu cuenta.',
    ]),
    const LegalSection('3. Precio y pago', [
      'Antes de confirmar te mostramos un precio fijo en bolivianos (Bs). Ese es el precio del viaje: no cambia por tráfico ni por la ruta que elija el chófer.',
      'Salvo que se indique otra forma de pago, el precio se paga al chófer al finalizar el viaje, en efectivo o mediante QR.',
      'Cambios que tú solicites durante el viaje (paradas, otro destino, más horas) pueden modificar el precio, lo que se te informará antes de aplicarlo.',
    ]),
    LegalSection('4. Tiempo de espera', [
      'Cada reserva incluye espera gratuita: ${WaitingPolicy.airportFreeMinutes} minutos en recogidas en aeropuerto, contados desde el aterrizaje del vuelo, y ${WaitingPolicy.cityFreeMinutes} minutos en ciudad, contados desde la hora de recogida o desde la llegada del chófer si esta fue posterior.',
      'Si indicas tu número de vuelo, seguimos su estado y ajustamos la hora de recogida si se retrasa.',
      '[Definir qué ocurre al terminar la espera gratuita: tiempo adicional con costo o cancelación como no presentado.]',
    ]),
    const LegalSection('5. Cancelaciones', [
      'Puedes cancelar sin costo hasta 1 hora antes de la hora de recogida, desde la app.',
      '[Definir la política para cancelaciones con menos de 1 hora y para no presentarse.]',
      'Si no podemos asignar un chófer, cancelaremos la reserva y te lo notificaremos.',
    ]),
    const LegalSection('6. Conducta', [
      'Pasajeros y chóferes deben tratarse con respeto. No se permite fumar en los vehículos ni transportar objetos ilegales o peligrosos.',
      'Podemos suspender cuentas que incumplan estos términos o pongan en riesgo a otras personas.',
    ]),
    const LegalSection('7. Responsabilidad', [
      '[Definir con asesoría legal los límites de responsabilidad, seguros del vehículo y del pasajero, y el procedimiento ante objetos perdidos o daños.]',
    ]),
    LegalSection('8. Ley aplicable y reclamos', [
      'Estos términos se rigen por las leyes del Estado Plurinacional de Bolivia. Puedes presentar reclamos escribiendo a ${LegalInfo.supportEmail}.',
      '[Indicar jurisdicción competente, p. ej. ${LegalInfo.city}.]',
    ]),
  ],
);
