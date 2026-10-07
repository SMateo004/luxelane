// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Chófer';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonCall => 'Llamar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonConnectionError => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCouldNotOpenApp => 'No se pudo abrir la aplicación';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonGenericError => 'Algo no salió bien';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonRequired => 'Requerido';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get flightCancelled => 'Cancelado';

  @override
  String flightDelayed(int minutes) {
    return 'Retrasado $minutes min';
  }

  @override
  String get flightLanded => 'Aterrizó';

  @override
  String get flightOnTime => 'A tiempo';

  @override
  String legalCompanyDetails(String nit, String address) {
    return 'NIT $nit · $address';
  }

  @override
  String get legalContactComingSoon => 'Los canales de contacto se publicarán pronto.';

  @override
  String get legalContactEmail => 'Correo';

  @override
  String get legalContactHeadline => 'Estamos para ayudarte';

  @override
  String get legalContactIntro => 'Escríbenos por cualquier consulta sobre una reserva, tu cuenta o tus datos. Si tienes un viaje en curso, usa los botones de contacto con tu chófer en la pantalla del viaje.';

  @override
  String get legalContactTitle => 'Contacto';

  @override
  String get legalDeleteActiveTrip => 'Tienes un viaje en curso. Podrás eliminar tu cuenta cuando termine.';

  @override
  String get legalDeleteButton => 'Eliminar mi cuenta';

  @override
  String legalDeleteConfirmPrompt(String keyword) {
    return 'Escribe $keyword para confirmar.';
  }

  @override
  String get legalDeleteConnectionError => 'No pudimos eliminar tu cuenta. Revisa tu conexión.';

  @override
  String get legalDeleteEffectBookings => 'Cancelamos tus reservas pendientes.';

  @override
  String get legalDeleteEffectDriver => 'Si eres chófer, también borramos tu perfil de chófer y desactivamos tu vehículo.';

  @override
  String get legalDeleteEffectPermanent => 'Esta acción no se puede deshacer.';

  @override
  String get legalDeleteEffectProfile => 'Borramos tu perfil, tus notificaciones y tu acceso.';

  @override
  String get legalDeleteEffectTrips => 'Quitamos tu nombre, teléfono y notas de tus viajes anteriores. Los registros de esos viajes se conservan sin datos de contacto por obligaciones contables.';

  @override
  String get legalDeleteFailed => 'No pudimos eliminar tu cuenta. Inténtalo de nuevo o contáctanos.';

  @override
  String get legalDeleteHeadline => 'Eliminar tu cuenta';

  @override
  String get legalDeleteIntro => 'Al eliminar tu cuenta:';

  @override
  String get legalDeleteKeyword => 'ELIMINAR';

  @override
  String get legalDeleteSignIn => 'Iniciar sesión';

  @override
  String get legalDeleteSignInPrompt => 'Inicia sesión con la cuenta que quieres eliminar.';

  @override
  String get legalDeleteSuccess => 'Tu cuenta fue eliminada.';

  @override
  String get legalDeleteTitle => 'Eliminar cuenta';

  @override
  String get legalDraftBanner => 'Borrador: este documento contiene datos pendientes entre corchetes y debe ser revisado por un abogado antes de publicarse.';

  @override
  String legalLastUpdated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Última actualización: $dateString';
  }

  @override
  String get serviceByTheHour => 'Por horas';

  @override
  String get serviceByTheHourDesc => 'Chófer a tu disposición por un tiempo determinado';

  @override
  String get serviceOneWay => 'Solo ida';

  @override
  String get serviceOneWayDesc => 'Traslado a precio fijo a tu destino';

  @override
  String get servicesAirportArriveBody => 'Un servicio de chófer de Luxelane busca alcanzar los estándares más altos posibles para todos sus pasajeros. Nuestros conductores profesionales pueden hacer un seguimiento de su vuelo y ajustar la hora de recogida si hay retrasos fuera de su control.';

  @override
  String get servicesAirportArriveTitle => 'Llegue o salga del aeropuerto';

  @override
  String get servicesAirportClassesTitle => 'Descubre nuestras clases de servicio';

  @override
  String get servicesAirportConnectionsBody => 'Reservar un servicio de Luxelane es fácil. Simplemente proporcione los datos de recogida y destino y seleccione la clase del vehículo. El precio que ve es el precio que paga, sin cargos ocultos.';

  @override
  String get servicesAirportConnectionsTitle => 'Reservas de conexiones entre aeropuertos';

  @override
  String get servicesAirportFaq1A => 'Un traslado al aeropuerto es un servicio de coche privado que lleva a los pasajeros de avión hacia y desde el aeropuerto. Los conductores profesionales pueden recoger a los pasajeros en la terminal después de recoger su equipaje.';

  @override
  String get servicesAirportFaq1Q => '¿Qué hace un traslado al aeropuerto?';

  @override
  String get servicesAirportFaq2A => 'Los traslados al aeropuerto son una forma estupenda de evitar el estrés tanto al inicio como al final de un vuelo. Luxelane ofrece una amplia gama de opciones de traslado que se adaptan a tus necesidades.';

  @override
  String get servicesAirportFaq2Q => '¿Merece la pena reservar un traslado desde el aeropuerto?';

  @override
  String get servicesAirportFaq3A => 'Un traslado al aeropuerto de pago es un servicio de transporte con un conductor profesional reservado con antelación, con un precio fijo en bolivianos que se confirma antes de reservar.';

  @override
  String get servicesAirportFaq3Q => '¿Qué es un traslado al aeropuerto de pago?';

  @override
  String get servicesAirportFeatureFlexBody => 'Manténgase flexible: cancele sin costo hasta 1 hora antes de la recogida, desde la app.';

  @override
  String get servicesAirportFeatureFlexTitle => 'Flexibilidad de viaje';

  @override
  String get servicesAirportFeatureFlightBody => 'Relájese con la hora gratuita de espera y el seguimiento de vuelos.';

  @override
  String get servicesAirportFeatureFlightTitle => 'Viaje al aeropuerto sin problemas';

  @override
  String get servicesAirportFeaturePriceBody => 'Acceda a un servicio de primera calidad a precios basados en la distancia.';

  @override
  String servicesAirportFreeWait(int minutes) {
    return 'El chófer esperará $minutes minutos sin coste adicional.';
  }

  @override
  String get servicesAirportHeroEyebrow => 'SERVICIO DE TRASLADOS';

  @override
  String get servicesAirportHeroTitle => 'Al aeropuerto sin\nestrés ni esperas';

  @override
  String get servicesAirportPanelSubtitle => 'Ida o Por horas · Sin esperas';

  @override
  String get servicesAirportPanelTitle => 'Traslados al aeropuerto';

  @override
  String get servicesBackHome => '← Volver al inicio';

  @override
  String get servicesBookNow => 'RESERVAR AHORA';

  @override
  String get servicesBookRide => 'RESERVAR UN VIAJE';

  @override
  String get servicesFaqTitle => 'Preguntas frecuentes';

  @override
  String get servicesFeaturePriceTitle => 'Precios competitivos';

  @override
  String servicesFooterRights(String year) {
    return '© $year Luxelane · Todos los derechos reservados';
  }

  @override
  String get servicesFromHint => 'De - Dirección, aeropuerto, hotel...';

  @override
  String get servicesHourlyBullet1 => 'Define tu itinerario: Tú decides dónde y cuándo ir';

  @override
  String get servicesHourlyBullet2 => 'Ahorra tiempo: Te dejaremos y recogeremos en la puerta de cada parada';

  @override
  String get servicesHourlyBullet3 => 'Disfruta con tranquilidad: Viaja en un vehículo premium';

  @override
  String get servicesHourlyBullet4 => 'Tarifa fija por hora: conoces el precio antes de reservar';

  @override
  String get servicesHourlyBullet5 => 'Fiabilidad: Chóferes formados en los más altos estándares';

  @override
  String get servicesHourlyBullet6 => 'Chóferes verificados por nuestro equipo';

  @override
  String get servicesHourlyBullet7 => 'Seguimiento en vivo de tu chófer desde la app';

  @override
  String get servicesHourlyBullet8 => 'Diseñado para la ciudad: Comienza y termina en la misma ciudad';

  @override
  String servicesHourlyDurationField(String duration) {
    return 'Duración - $duration';
  }

  @override
  String get servicesHourlyFaq1A => 'Selecciona el lugar de recogida, elige la duración, el día y la hora, elige una clase de vehículo y completa tu reserva.';

  @override
  String get servicesHourlyFaq1Q => '¿Cómo reservo un chófer por horas?';

  @override
  String get servicesHourlyFaq2A => 'Sí. El conductor y el vehículo están a tu disposición en todo momento durante las horas de la reserva.';

  @override
  String get servicesHourlyFaq2Q => '¿Puedo modificar mi itinerario durante el viaje?';

  @override
  String get servicesHourlyFaq3A => 'Cuando se asigna tu chófer recibirás una notificación y verás en la app su nombre, vehículo, placa y teléfono.';

  @override
  String get servicesHourlyFaq3Q => '¿Cuándo recibiré los datos del chófer?';

  @override
  String get servicesHourlyFaq4A => 'Sí, la reserva puede empezar o terminar en un aeropuerto. El lugar de inicio y finalización deben estar en la misma ciudad.';

  @override
  String get servicesHourlyFaq4Q => '¿La reserva puede empezar en un aeropuerto?';

  @override
  String servicesHourlyFaq5A(int min, int max) {
    return 'Sí, puedes editar la reserva antes de la hora de inicio. La duración mínima es $min horas, máximo $max horas.';
  }

  @override
  String get servicesHourlyFaq5Q => '¿Puedo aumentar el número de horas?';

  @override
  String get servicesHourlyHeroEyebrow => 'CONTRATACIÓN POR HORAS';

  @override
  String get servicesHourlyHeroTitle => 'Alquiler de chófer\npor horas y días';

  @override
  String get servicesHourlyPanelSubtitle => 'Tu itinerario · Tu ritmo';

  @override
  String get servicesHourlyPanelTitle => 'Chófer por horas';

  @override
  String get servicesHourlyReachBanner => 'Disponible en Santa Cruz de la Sierra · Reserva desde la app o la web';

  @override
  String get servicesHourlyServiceBody => 'Olvídate de cambiar de medio de transporte cuando tengas que hacer viajes con múltiples paradas. Con Luxelane, defines tu itinerario: tú decides dónde y cuándo ir.';

  @override
  String get servicesHourlyServiceTitle => 'Servicio de chófer por horas';

  @override
  String get servicesHourlyUseBusinessBody => 'Concéntrate en lo importante. Desplázate fácilmente entre reuniones sin preocuparte por la logística.';

  @override
  String get servicesHourlyUseBusinessTitle => 'Viajes de negocios';

  @override
  String get servicesHourlyUseCasesTitle => 'Diseñado para cada ocasión';

  @override
  String get servicesHourlyUseEventsBody => 'Disfruta de una llegada triunfal y una salida sin contratiempos de cualquier evento.';

  @override
  String get servicesHourlyUseEventsTitle => 'Conciertos y eventos';

  @override
  String get servicesHourlyUseLeisureBody => 'Ya sea un almuerzo, compras o tu lista de tareas, tu chófer estará listo cuando lo necesites.';

  @override
  String get servicesHourlyUseLeisureTitle => 'Actividades de ocio';

  @override
  String get servicesHourlyUseSightseeingBody => 'Descubre la ciudad a tu manera, a tu ritmo, con un chófer local siempre a tu disposición.';

  @override
  String get servicesHourlyUseSightseeingTitle => 'Visitas turísticas';

  @override
  String get servicesNavBusiness => 'PARA EMPRESAS';

  @override
  String get servicesNavFleet => 'FLOTA';

  @override
  String get servicesNavHome => 'INICIO';

  @override
  String get servicesNavServices => 'SERVICIOS';

  @override
  String get servicesPickupChauffeursBody => 'Viaje con confianza gracias a los chóferes expertos que le ofrecen la mejor calidad y discreción.';

  @override
  String get servicesPickupChauffeursTitle => 'Chóferes profesionales';

  @override
  String get servicesPickupComfortBody => 'Un viaje privado en un vehículo de alta gama hace que cada viaje sea un placer.';

  @override
  String get servicesPickupComfortTitle => 'Comodidad';

  @override
  String get servicesPickupConvenienceBody => 'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques.';

  @override
  String get servicesPickupConvenienceTitle => 'Conveniencia';

  @override
  String get servicesPickupHeroSubtitle => 'Chóferes profesionales a su alcance';

  @override
  String get servicesPickupHeroTitle => '¡Servicio de\nRecogida Inmediata!';

  @override
  String get servicesPickupIntroBody => 'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques en la aplicación Luxelane.';

  @override
  String get servicesPickupIntroEyebrow => 'RECOGIDA INMEDIATA';

  @override
  String get servicesPickupIntroTitle => 'Descubre el servicio de recogida inmediata';

  @override
  String get servicesPickupPriceBody => 'Acceda a un servicio de primera calidad a precios basados en la distancia, justos para todos.';

  @override
  String get servicesPickupQualityBody => 'Hacer que su experiencia sea excelente es nuestra máxima prioridad en todos sus viajes.';

  @override
  String get servicesPickupQualityTitle => 'Calidad';

  @override
  String get servicesPickupReliabilityBody => 'Reserve con seguridad y manténgase informado con actualizaciones del estado del viaje en tiempo real.';

  @override
  String get servicesPickupReliabilityTitle => 'Fiabilidad';

  @override
  String get servicesPickupSplitBody => 'Cuando necesite una forma segura de desplazarse por la ciudad, piense en el servicio de recogida inmediata de Luxelane. La combinación perfecta entre el servicio tradicional de traslados y el transporte privado.';

  @override
  String get servicesPickupSplitEyebrow => 'CÓMODO · SEGURO · INMEDIATO';

  @override
  String get servicesPickupSplitTitle => 'Cómodos viajes a la carta en cuestión de minutos';

  @override
  String servicesQuote(String quote) {
    return '“$quote”';
  }

  @override
  String get servicesSelect => 'SELECCIONAR';

  @override
  String get servicesToHint => 'A - Dirección, aeropuerto, hotel...';

  @override
  String get servicesToggleOneWay => 'Ida';

  @override
  String servicesUpToLargeBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hasta $count maletas grandes',
      one: 'Hasta 1 maleta grande',
    );
    return '$_temp0';
  }

  @override
  String servicesUpToPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hasta $count personas',
      one: 'Hasta 1 persona',
    );
    return '$_temp0';
  }

  @override
  String get servicesVehicleBusinessModels => 'Mercedes Clase E, BMW Serie 5 o similar';

  @override
  String get servicesVehicleFirstModels => 'Mercedes Clase S, BMW Serie 7 o similar';

  @override
  String get servicesVehicleGroups => 'Ideal para grupos y familias';

  @override
  String get servicesVehicleMostCities => 'Disponible en Santa Cruz de la Sierra';

  @override
  String get servicesVehiclePremiumLuxury => 'Servicio de lujo premium';

  @override
  String get servicesVehicleVanModels => 'Mercedes Clase V, Toyota Alphard o similar';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusDriverArrived => 'Chófer llegó';

  @override
  String get statusDriverArriving => 'En camino';

  @override
  String get statusInProgress => 'En progreso';

  @override
  String get statusPending => 'Pendiente';

  @override
  String unitBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maletas',
      one: '1 maleta',
    );
    return '$_temp0';
  }

  @override
  String unitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String unitHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String unitMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String unitPassengers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasajeros',
      one: '1 pasajero',
    );
    return '$_temp0';
  }

  @override
  String unitTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
    );
    return '$_temp0';
  }

  @override
  String get vehicleBusiness => 'Business Class';

  @override
  String get vehicleBusinessDesc => 'Mercedes E-Class o similar';

  @override
  String get vehicleBusinessVan => 'Business Van';

  @override
  String get vehicleBusinessVanDesc => 'Mercedes V-Class · Hasta 7';

  @override
  String get vehicleElectric => 'Eléctrico';

  @override
  String get vehicleElectricDesc => 'Tesla Model S o similar';

  @override
  String get vehicleFirstClass => 'First Class';

  @override
  String get vehicleFirstClassDesc => 'Mercedes S-Class o similar';

  @override
  String waitAirportSummary(int minutes) {
    return '$minutes min de espera gratuita desde el aterrizaje';
  }

  @override
  String waitCitySummary(int minutes) {
    return '$minutes min de espera gratuita';
  }
}
