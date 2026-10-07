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
  String get bookingAllFeesIncluded => 'Todos los cargos incluidos';

  @override
  String get bookingApplyOffer => 'Aplicar oferta';

  @override
  String get bookingAssuranceFixedPrice => 'Precio fijo, sin sorpresas';

  @override
  String get bookingAssuranceVerified => 'Chóferes verificados';

  @override
  String get bookingAuthCreateAccountCta => 'Crear cuenta';

  @override
  String get bookingAuthEmail => 'Correo electrónico';

  @override
  String get bookingAuthEmailHint => 'tu@ejemplo.com';

  @override
  String get bookingAuthFullName => 'Nombre completo';

  @override
  String get bookingAuthFullNameHint => 'Tu nombre';

  @override
  String get bookingAuthHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get bookingAuthHidePassword => 'Ocultar contraseña';

  @override
  String get bookingAuthNoAccount => '¿No tienes cuenta? Crear una';

  @override
  String get bookingAuthPassword => 'Contraseña';

  @override
  String get bookingAuthShowPassword => 'Mostrar contraseña';

  @override
  String get bookingAuthSignInCta => 'Iniciar sesión';

  @override
  String get bookingAuthSubtitleLogin => 'Inicia sesión para confirmar tu reserva.';

  @override
  String get bookingAuthSubtitleRegister => 'Crea tu cuenta de Luxelane para completar la reserva.';

  @override
  String get bookingAuthTitleLogin => 'Inicia sesión para continuar';

  @override
  String get bookingAuthTitleRegister => 'Crear una cuenta';

  @override
  String get bookingBackHome => 'Volver al inicio';

  @override
  String get bookingBaseFare => 'Tarifa base';

  @override
  String get bookingBreakdownHeading => 'DESGLOSE';

  @override
  String get bookingCapacityLuggageInfo => 'Basado en tamaños estándar de equipaje, que pueden diferir de los tuyos. Puedes especificar los detalles de tu equipaje en las \"Notas de recogida\" en el siguiente paso.';

  @override
  String get bookingCapacityTitle => 'Capacidad';

  @override
  String get bookingCardFallback => 'Tarjeta';

  @override
  String bookingChauffeurAtDisposal(int hours) {
    return 'Chófer a disposición · $hours h';
  }

  @override
  String get bookingChooseExperience => 'Elige tu experiencia';

  @override
  String get bookingChooseService => 'Elegir servicio';

  @override
  String get bookingConfirmCta => 'Confirmar reserva';

  @override
  String get bookingConfirmedEyebrow => 'RESERVA CONFIRMADA';

  @override
  String get bookingConfirmedHeadline => 'Tu chófer te esperará.';

  @override
  String get bookingConfirmedSemantics => 'Reserva confirmada';

  @override
  String get bookingCountdownOnTheWay => 'Tu chófer está en camino.';

  @override
  String bookingDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get bookingDescriptiveText => 'Premium hecho práctico. Asientos espaciosos, un viaje suave y recogidas puntuales que mantienen tu día en ritmo.';

  @override
  String get bookingDestinationLabel => 'Destino';

  @override
  String bookingDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get bookingErrorCreateFailed => 'No se pudo crear la reserva';

  @override
  String get bookingErrorInvalidFlight => 'Revisa el número de vuelo (ej. LA 8810).';

  @override
  String get bookingErrorPaymentNotAuthorised => 'No pudimos autorizar tu tarjeta. Inténtalo de nuevo o elige otra.';

  @override
  String get bookingErrorQuoteExpired => 'La cotización venció. Vuelve a confirmar para ver el precio actualizado.';

  @override
  String get bookingErrorQuoteFailed => 'No se pudo cotizar el viaje';

  @override
  String get bookingErrorQuoteMissing => 'Falta la cotización del viaje';

  @override
  String get bookingErrorRateFailed => 'No se pudo enviar tu calificación';

  @override
  String get bookingErrorTooManyPassengers => 'El número de pasajeros supera la capacidad del vehículo.';

  @override
  String get bookingEstimatedTax => 'Impuesto estimado';

  @override
  String get bookingEstimatedTotal => 'TOTAL ESTIMADO';

  @override
  String get bookingFixedPriceLabel => 'PRECIO FIJO';

  @override
  String get bookingFixedPricePaidByCard => 'Precio fijo · tarjeta autorizada';

  @override
  String get bookingFixedPricePayDriver => 'Precio fijo · pago al chófer';

  @override
  String bookingFlight(String flight) {
    return 'Vuelo $flight';
  }

  @override
  String get bookingFlightNumber => 'Número de vuelo';

  @override
  String get bookingFlightNumberHint => 'ej. LA 8810 (opcional)';

  @override
  String get bookingForGuest => 'Reservar para un invitado';

  @override
  String get bookingForGuestSubtitle => 'Seleccionar o añadir un invitado';

  @override
  String get bookingForMyself => 'Reservar para mí';

  @override
  String get bookingForMyselfSubtitle => 'Reserva con la información de tu cuenta';

  @override
  String get bookingFreeCancellationShort => 'Cancelación gratuita hasta 1 h antes';

  @override
  String get bookingGuestDialogBody => 'Ingresa la información de tu invitado y bríndale un servicio premium. Lo mantendremos informado sobre su trayecto durante todo el proceso. No te preocupes, no compartiremos ninguna información de pago o facturación con él.';

  @override
  String get bookingGuestDialogTitle => 'Añadir nuevo invitado';

  @override
  String bookingGuestDisplayName(String title, String firstName, String lastName) {
    return '$title $firstName $lastName';
  }

  @override
  String get bookingGuestEmailHint => 'Correo del invitado';

  @override
  String get bookingGuestFirstName => 'Nombre';

  @override
  String get bookingGuestFirstNameHint => 'Nombre del invitado';

  @override
  String get bookingGuestLastName => 'Apellido';

  @override
  String get bookingGuestLastNameHint => 'Apellido del invitado';

  @override
  String get bookingGuestPhone => 'Número de móvil del invitado';

  @override
  String get bookingGuestPhoneHelp => 'Tu invitado recibirá las notificaciones del trayecto en este número';

  @override
  String get bookingGuestTitleDr => 'Dr.';

  @override
  String get bookingGuestTitleLabel => 'Tratamiento';

  @override
  String get bookingGuestTitleMr => 'Sr.';

  @override
  String get bookingGuestTitleMrs => 'Sra.';

  @override
  String get bookingGuestTitleMs => 'Srta.';

  @override
  String get bookingGuestTitleProf => 'Prof.';

  @override
  String get bookingHeroTagline => 'Precio fijo · Sin sorpresas · Disponible en todo el mundo';

  @override
  String get bookingHeroTitle => 'Elige tu\nexperiencia';

  @override
  String bookingHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get bookingIncludedChargers => 'Cargadores para iOS y Android a bordo';

  @override
  String get bookingIncludedFreeCancellation => 'Cancelación gratuita hasta 1 hora antes de la recogida';

  @override
  String get bookingIncludedMeetGreet => 'Recibimiento personalizado';

  @override
  String get bookingIncludedTissues => 'Pañuelos y toallitas desinfectantes de cortesía';

  @override
  String get bookingIncludedTitle => 'Qué incluye';

  @override
  String bookingIncludedWaiting(int minutes) {
    return 'Hasta $minutes minutos de espera gratuita';
  }

  @override
  String get bookingIncludedWater => 'Agua fría de cortesía incluida';

  @override
  String get bookingLoadErrorTitle => 'No pudimos cargar tu reserva';

  @override
  String get bookingLuggage => 'Equipaje';

  @override
  String bookingLuggageCarryOn(int count) {
    return '$count x De mano';
  }

  @override
  String bookingLuggageChecked(int count) {
    return '$count x Facturada estándar';
  }

  @override
  String bookingLuggageExtraLarge(int count) {
    return '$count x Extra grande';
  }

  @override
  String get bookingNotFound => 'Esta reserva ya no está disponible.';

  @override
  String get bookingNoteCapacity => 'Los límites de capacidad de pasajeros y equipaje deben respetarse por razones de seguridad. Si se exceden, el chófer podrá rechazar el servicio.';

  @override
  String get bookingNoteExtras => 'Las necesidades adicionales (silla de ruedas, asiento infantil, artículos extra) pueden añadirse en \"Notas de recogida\". Elige Business Van para grupos más grandes o equipaje adicional.';

  @override
  String get bookingNoteImages => 'Las imágenes del vehículo son solo de referencia. El vehículo real puede variar manteniendo una calidad equivalente o superior.';

  @override
  String get bookingPassengers => 'Pasajeros';

  @override
  String bookingPassengersAndBags(String passengers, String bags) {
    return '$passengers · $bags';
  }

  @override
  String get bookingPayOnTripBody => 'Pagas el precio fijo a tu chófer en efectivo o con QR. Nada se cobra al reservar.';

  @override
  String get bookingPayOnTripTitle => 'Pago al finalizar el viaje';

  @override
  String get bookingPaymentFailed => 'El pago falló';

  @override
  String get bookingPaymentMethodHeading => 'MÉTODO DE PAGO';

  @override
  String bookingPickupInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Recogida en $days días',
      one: 'Recogida en 1 día',
    );
    return '$_temp0';
  }

  @override
  String bookingPickupInHours(int hours) {
    return 'Recogida en $hours h';
  }

  @override
  String bookingPickupInHoursMinutes(int hours, int minutes) {
    return 'Recogida en $hours h $minutes min';
  }

  @override
  String bookingPickupInMinutes(int minutes) {
    return 'Recogida en $minutes min';
  }

  @override
  String get bookingPickupLabel => 'Recogida';

  @override
  String get bookingPleaseNote => 'Nota importante:';

  @override
  String get bookingPriceBreakdownTitle => 'Desglose de precio';

  @override
  String bookingPriceConfirmedBody(String price) {
    return 'El precio fijo de tu viaje es $price. No cambiará aunque haya tráfico.';
  }

  @override
  String get bookingPriceConfirmedTitle => 'Precio confirmado';

  @override
  String bookingReference(String code) {
    return 'Código de reserva: $code';
  }

  @override
  String bookingReserveCta(String vehicle) {
    return 'RESERVAR $vehicle';
  }

  @override
  String get bookingRoutePreview => 'Vista previa de ruta';

  @override
  String get bookingSeating => 'Asientos';

  @override
  String get bookingSeatingFive => 'Cinco pasajeros';

  @override
  String get bookingSeatingInfantSeat => 'Asiento de bebé';

  @override
  String get bookingSeatingInfo => 'Elige la configuración de asientos que mejor se adapte a tus necesidades. Los asientos especiales (infantil / bebé) deben solicitarse con anticipación y están sujetos a disponibilidad.';

  @override
  String get bookingSeatingThree => 'Tres pasajeros';

  @override
  String get bookingSeatingTwo => 'Dos pasajeros';

  @override
  String bookingSeatsUpTo(int count) {
    return 'Hasta $count pax';
  }

  @override
  String get bookingSelectRouteError => 'Selecciona el punto de recogida y el destino';

  @override
  String get bookingSelectedBadge => 'SELECCIONADO';

  @override
  String get bookingSlideBusiness1 => 'Confort ejecutivo en cada trayecto';

  @override
  String get bookingSlideBusiness2 => 'Puntual, profesional y perfectamente refinado';

  @override
  String get bookingSlideBusiness3 => 'Llega con confianza, en cada ocasión';

  @override
  String get bookingSlideBusiness4 => 'Premium hecho práctico para el ejecutivo moderno';

  @override
  String get bookingSlideElectric1 => 'Totalmente eléctrico, silencioso y de nivel ejecutivo';

  @override
  String get bookingSlideElectric2 => 'Cero emisiones, máxima experiencia de lujo';

  @override
  String get bookingSlideFirst1 => 'Un nivel extraordinario de lujo te espera';

  @override
  String get bookingSlideFirst2 => 'Diseñado para quienes exigen lo mejor';

  @override
  String get bookingSlideFirst3 => 'Privacidad y elegancia en cada traslado';

  @override
  String get bookingSlideFirst4 => 'Primera clase, de puerta a puerta';

  @override
  String get bookingSlideVan1 => 'Espacio y confort para todo tu equipo';

  @override
  String get bookingSlideVan2 => 'Traslados grupales sin estrés y con puntualidad';

  @override
  String get bookingSlideVan3 => 'El viaje perfecto para familias y grupos';

  @override
  String get bookingSlideVan4 => 'Capacidad premium, sin compromiso en el confort';

  @override
  String get bookingSpecialRequests => 'Solicitudes especiales';

  @override
  String get bookingSpecialRequestsHint => 'Asiento infantil, letrero de bienvenida…';

  @override
  String get bookingStepDetails => 'Detalles';

  @override
  String bookingStepOf(int step, int total) {
    return 'PASO $step DE $total';
  }

  @override
  String get bookingStepVehicle => 'Vehículo';

  @override
  String get bookingSummaryDistance => 'Distancia';

  @override
  String get bookingSummaryDuration => 'Duración';

  @override
  String get bookingSummaryEstDuration => 'Duración est.';

  @override
  String get bookingSummaryFlight => 'Vuelo';

  @override
  String get bookingSummaryFrom => 'Desde';

  @override
  String get bookingSummaryHeading => 'RESUMEN DE RESERVA';

  @override
  String get bookingSummaryNotes => 'Notas';

  @override
  String get bookingSummaryService => 'Servicio';

  @override
  String get bookingSummaryTo => 'Hasta';

  @override
  String get bookingTripDetailsHeading => 'DETALLES DEL VIAJE';

  @override
  String get bookingViewMyBooking => 'VER MI RESERVA';

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
  String get driverAcceptRide => 'Aceptar viaje';

  @override
  String get driverActionArrived => 'He llegado';

  @override
  String get driverActionCompleteTrip => 'Completar viaje';

  @override
  String get driverActionGoToPickup => 'Ir al punto de recogida';

  @override
  String get driverActionGoToPickupShort => 'Ir a la recogida';

  @override
  String get driverActionStartTrip => 'Iniciar viaje';

  @override
  String get driverActiveRide => 'Viaje activo';

  @override
  String driverCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes completados',
      one: '1 viaje completado',
    );
    return '$_temp0';
  }

  @override
  String get driverCompletedTrips => 'Viajes completados';

  @override
  String get driverConnectionErrorTitle => 'Error de conexión';

  @override
  String get driverDecline => 'Rechazar';

  @override
  String get driverErrorUnauthorized => 'Esta cuenta no tiene acceso de chófer.';

  @override
  String get driverEstimatedFare => 'Tarifa estimada';

  @override
  String get driverGoOnline => 'Conectarse';

  @override
  String get driverMapsOpenError => 'No se pudieron abrir los mapas';

  @override
  String get driverMsgHeadToPickup => 'Dirígete al punto de recogida';

  @override
  String get driverMsgInProgress => 'Viaje en curso · ve al destino';

  @override
  String get driverMsgOnTheWay => 'En camino a la recogida · llegando pronto';

  @override
  String get driverMsgWaitingPassenger => 'Esperando al pasajero';

  @override
  String driverNavigateTo(String address) {
    return 'Navegar hacia $address';
  }

  @override
  String get driverNavigateToDestination => 'Navegar hacia el destino';

  @override
  String get driverNavigateToPickup => 'Navegar hacia la recogida';

  @override
  String get driverNoCompletedTrips => 'Aún no hay viajes completados';

  @override
  String get driverNoMapsApps => 'No hay aplicaciones de mapas disponibles';

  @override
  String get driverOfferExpiring => 'Oferta por expirar';

  @override
  String get driverOfflineSubtitle => 'Activa el interruptor para conectarte';

  @override
  String get driverOfflineTitle => 'Estás desconectado';

  @override
  String get driverOnbBack => 'Atrás';

  @override
  String get driverOnbColor => 'Color';

  @override
  String get driverOnbDefaultColor => 'Negro';

  @override
  String get driverOnbExpiryFormat => 'Usa MM/AAAA';

  @override
  String get driverOnbInvalid => 'Inválido';

  @override
  String get driverOnbInvalidMonth => 'Mes inválido';

  @override
  String get driverOnbLicenseExpired => 'Licencia vencida';

  @override
  String get driverOnbLicenseExpiry => 'Fecha de vencimiento (MM/AAAA)';

  @override
  String get driverOnbLicenseNumber => 'Número de licencia';

  @override
  String get driverOnbLicenseSubtitle => 'Tus documentos serán revisados antes de que puedas aceptar viajes.';

  @override
  String get driverOnbLicenseTitle => 'Licencia de conducir';

  @override
  String get driverOnbLogout => 'Cerrar sesión';

  @override
  String get driverOnbMake => 'Marca';

  @override
  String get driverOnbModel => 'Modelo';

  @override
  String get driverOnbPlate => 'Placa';

  @override
  String get driverOnbReviewNotice => 'Un administrador verificará tus documentos antes de que puedas conectarte.';

  @override
  String get driverOnbSaveError => 'No pudimos guardar tus datos. Inténtalo de nuevo.';

  @override
  String get driverOnbVehicleClass => 'Categoría del vehículo';

  @override
  String get driverOnbVehicleSubtitle => 'Registra el vehículo que vas a conducir.';

  @override
  String get driverOnbVehicleTitle => 'Tu vehículo';

  @override
  String get driverOnbYear => 'Año';

  @override
  String get driverOnlineSubtitle => 'Esperando nuevas solicitudes de viaje';

  @override
  String get driverOnlineTitle => 'Estás conectado';

  @override
  String get driverPaid => 'PAGADO';

  @override
  String get driverQueueAvailable => 'SOLICITUDES DISPONIBLES';

  @override
  String get driverQueueEmptyBody => 'Las nuevas reservas aparecerán aquí';

  @override
  String get driverQueueEmptyTitle => 'Sin trabajos aún';

  @override
  String get driverQueueMyActive => 'MIS TRABAJOS ACTIVOS';

  @override
  String get driverQueueOfflineBody => 'Activa tu disponibilidad en la pestaña Inicio';

  @override
  String get driverQueueOfflineTitle => 'Conéctate para recibir trabajos';

  @override
  String get driverQueueTitle => 'Cola de trabajos';

  @override
  String get driverRequestExclusive => 'SOLICITUD EXCLUSIVA PARA TI';

  @override
  String get driverRequestNew => 'NUEVA SOLICITUD DE VIAJE';

  @override
  String driverRespondIn(int seconds) {
    return 'Responde en ${seconds}s';
  }

  @override
  String get driverStatCompleted => 'Completados';

  @override
  String get driverStatEarnings => 'Ganancias';

  @override
  String get driverTabHome => 'Inicio';

  @override
  String get driverTabJobs => 'Trabajos';

  @override
  String get driverTabProfile => 'Perfil';

  @override
  String get driverTodaySummary => 'Resumen de hoy';

  @override
  String get driverTotalEarnings => 'Ganancias totales';

  @override
  String get driverTripNotFound => 'Viaje no encontrado';

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
  String get homeBarDateTime => 'Fecha y hora';

  @override
  String get homeBarDestination => 'Destino';

  @override
  String get homeBarDestinationHint => '¿A dónde vas?';

  @override
  String get homeBarDuration => 'Duración';

  @override
  String get homeBarPickup => 'Recogida';

  @override
  String get homeBarPickupHint => '¿Dónde estás?';

  @override
  String get homeBarSeeOptions => 'Ver opciones';

  @override
  String get homeBookBulletAdvance => 'Reserva con anticipación';

  @override
  String get homeBookBulletCentralBilling => 'Facturación centralizada';

  @override
  String get homeBookBulletChampagne => 'Servicio de champán disponible';

  @override
  String get homeBookBulletClimate => 'Control de clima ambiental';

  @override
  String get homeBookBulletFixedPrice => 'Precio fijo, siempre';

  @override
  String get homeBookBulletLeather => 'Interiores de cuero premium';

  @override
  String get homeBookBulletPolicy => 'Cumplimiento de política de viajes';

  @override
  String get homeBookBulletTracking => 'Seguimiento en tiempo real';

  @override
  String get homeBookBulletWifiCharging => 'Wi-Fi y carga inalámbrica';

  @override
  String get homeBookBusinessSub => 'Viajes corporativos redefinidos';

  @override
  String get homeBookCoverSubtitle => 'Servicio de chófer premium';

  @override
  String get homeBookExperienceBody => 'Desde agua fría y listas de reproducción seleccionadas hasta privacidad con cancelación de ruido — tus preferencias recordadas, siempre.';

  @override
  String get homeBookExperienceHeadline => 'Cada detalle,\ncuidado.';

  @override
  String get homeBookExperienceLabel => 'La experiencia';

  @override
  String get homeBookExperienceSub => 'Cada detalle considerado';

  @override
  String get homeBookEyebrow => 'Nuestra experiencia distintiva';

  @override
  String get homeBookRide => 'Reservar un viaje';

  @override
  String get homeBookScrollCue => 'Desliza';

  @override
  String get homeBookStandardBody => 'Cada chófer es verificado por nuestro equipo: revisamos su licencia, sus documentos y su vehículo antes de su primer viaje.';

  @override
  String get homeBookStandardHeadline => 'El estándar que\notros siguen.';

  @override
  String get homeBookStandardLabel => 'El estándar';

  @override
  String get homeBookStandardSub => 'La promesa que cumplimos';

  @override
  String get homeBookStandardTag => 'El estándar Luxelane';

  @override
  String get homeBusinessBody => 'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.';

  @override
  String get homeBusinessEyebrow => 'Para empresas';

  @override
  String get homeBusinessLearnMore => 'Más información';

  @override
  String get homeBusinessPerkAccountManager => 'Gerente de cuenta dedicado';

  @override
  String get homeBusinessPerkBilling => 'Facturación y cobros centralizados';

  @override
  String get homeBusinessPerkGuests => 'Reservas para invitados y equipos';

  @override
  String get homeBusinessPerkMonitoring => 'Monitoreo de viajes en tiempo real';

  @override
  String get homeBusinessPerkPolicy => 'Herramientas de cumplimiento de política de viajes';

  @override
  String get homeBusinessPerkPriority => 'Reservas prioritarias para ejecutivos';

  @override
  String get homeBusinessTitle => 'Viajes corporativos,\nredefinidos.';

  @override
  String get homeCtaEyebrow => 'Cuando quieras. Donde quieras.';

  @override
  String get homeCtaHighlights => 'Precio fijo  ·  Chóferes verificados  ·  Reserva anticipada';

  @override
  String get homeCtaTitle => 'Tu próximo viaje,\n<i>en tus términos.</i>';

  @override
  String get homeCtaViewFleet => 'Ver flota';

  @override
  String homeDateTimeShort(String date, String time) {
    return '$date, $time';
  }

  @override
  String get homeErrorDestinationRequired => 'Ingresa un destino';

  @override
  String get homeErrorPickupRequired => 'Ingresa un lugar de recogida';

  @override
  String get homeFleetEyebrow => 'Nuestra flota';

  @override
  String get homeFleetModelVan => 'Mercedes V-Class o similar';

  @override
  String homeFleetSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count asientos',
      one: '1 asiento',
    );
    return '$_temp0';
  }

  @override
  String get homeFleetSwipeHint => 'Desliza para explorar →';

  @override
  String get homeFleetTagChampagne => 'Champán';

  @override
  String get homeFleetTagExtraLuggage => 'Equipaje extra';

  @override
  String get homeFleetTagLeather => 'Interior de cuero';

  @override
  String get homeFleetTagPremium => 'Premium';

  @override
  String get homeFleetTagPremiumAudio => 'Audio premium';

  @override
  String get homeFleetTagWifi => 'Wi-Fi';

  @override
  String get homeFleetTagZeroEmissions => 'Cero emisiones';

  @override
  String get homeFleetTitle => 'Vehículos premium,\nsin excepciones.';

  @override
  String get homeFooterContact => 'Contacto';

  @override
  String homeFooterCopyright(String year) {
    return '© $year Luxelane. Todos los derechos reservados.';
  }

  @override
  String get homeFooterPrivacy => 'Privacidad';

  @override
  String get homeFooterTerms => 'Términos';

  @override
  String get homeFormPickupHint => 'Calle, barrio, aeropuerto…';

  @override
  String get homeFormPickupLabel => 'Lugar de recogida';

  @override
  String get homeHeroTitle => 'Tu chófer <i>te espera.</i>';

  @override
  String homeHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get homeHowItWorksEyebrow => 'Cómo funciona';

  @override
  String get homeLocateMe => 'Usar mi ubicación';

  @override
  String get homeMapChangeLocation => 'Cambiar ubicación';

  @override
  String get homeMarqueeAirportTransfers => 'Traslados aeroportuarios';

  @override
  String get homeMarqueeBookInMinutes => 'Reserva en minutos';

  @override
  String get homeMarqueeCorporateTravel => 'Viajes corporativos';

  @override
  String get homeMarqueeFixedPrices => 'Precios fijos en Bs';

  @override
  String get homeMarqueeHourly => 'Chófer por horas';

  @override
  String get homeMarqueePremiumFleet => 'Flota premium';

  @override
  String get homeMarqueePrivacy => 'Privacidad y discreción';

  @override
  String get homeNavBusiness => 'Para empresas';

  @override
  String get homeNavFleet => 'Flota';

  @override
  String get homeNavServices => 'Servicios';

  @override
  String get homePickDestinationTitle => 'Seleccionar destino';

  @override
  String get homePickPickupTitle => 'Seleccionar lugar de recogida';

  @override
  String get homePromiseCancelBody => 'Cancela sin costo hasta 1 hora antes de la recogida, desde la app.';

  @override
  String get homePromiseCancelTitle => 'Cancelación gratuita';

  @override
  String homePromiseFixedPriceBody(int airportMinutes, int cityMinutes) {
    return 'Ves el precio final antes de reservar, sin recargos por tráfico. Incluye $airportMinutes min de espera en aeropuerto y $cityMinutes en ciudad.';
  }

  @override
  String get homePromiseFixedPriceTitle => 'Precio fijo en Bs';

  @override
  String get homePromiseTrackingBody => 'Sigue a tu chófer en el mapa y recibe avisos cuando está en camino y cuando llega.';

  @override
  String get homePromiseTrackingTitle => 'Seguimiento en vivo';

  @override
  String get homePromiseVerifiedBody => 'Licencia y documentos revisados por nuestro equipo antes de su primer viaje.';

  @override
  String get homePromiseVerifiedTitle => 'Chóferes verificados';

  @override
  String homeRouteSummary(String distance, String duration) {
    return '$distance km · $duration';
  }

  @override
  String get homeSearchVehicles => 'Buscar vehículos';

  @override
  String get homeServiceAirportTransfer => 'Traslado al aeropuerto';

  @override
  String get homeServiceHourly => 'Contratación por horas';

  @override
  String get homeServiceImmediatePickup => 'Recogida inmediata';

  @override
  String get homeShellMyTrips => 'Mis viajes';

  @override
  String get homeShellSignIn => 'Iniciar sesión';

  @override
  String get homeShellSignOut => 'Cerrar sesión';

  @override
  String get homeShellTabHome => 'Inicio';

  @override
  String get homeShellTabProfile => 'Perfil';

  @override
  String get homeShellTabTrips => 'Viajes';

  @override
  String get homeStepBookBody => 'Elige origen, destino, fecha y clase de vehículo.';

  @override
  String get homeStepBookTitle => 'Reserva en un minuto';

  @override
  String get homeStepChauffeurBody => 'Recibe los datos de tu chófer y síguelo en tiempo real.';

  @override
  String get homeStepChauffeurTitle => 'Tu chófer te espera';

  @override
  String get homeStepPriceBody => 'Te mostramos el precio final en bolivianos. Ese es el que pagas.';

  @override
  String get homeStepPriceTitle => 'Confirma tu precio fijo';

  @override
  String get homeTrustEyebrow => 'La promesa Luxelane';

  @override
  String get homeTrustTitle => 'Viajar con confianza,\nde principio a fin.';

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
  String notifBellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones sin leer',
      one: '1 notificación sin leer',
    );
    return '$_temp0';
  }

  @override
  String get notifEmpty => 'Aún no hay notificaciones';

  @override
  String notifHoursAgo(int hours) {
    return 'Hace $hours h';
  }

  @override
  String get notifJustNow => 'Ahora';

  @override
  String get notifMarkAllRead => 'Marcar todo como leído';

  @override
  String notifMinutesAgo(int minutes) {
    return 'Hace $minutes min';
  }

  @override
  String get notifTitle => 'Notificaciones';

  @override
  String get rideArrived => '¡Has llegado!';

  @override
  String rideArrivesIn(String eta) {
    return 'Llega en $eta';
  }

  @override
  String get rideAssigning => 'Asignando a tu chófer';

  @override
  String get rideAssigningBody => 'Estamos confirmando a tu chófer. Te avisaremos apenas esté asignado.';

  @override
  String get rideBackHome => 'Volver al inicio';

  @override
  String get rideCancelled => 'Reserva cancelada';

  @override
  String rideChauffeurArrivesIn(String eta) {
    return 'Tu chófer llega en $eta';
  }

  @override
  String get rideChauffeurConfirmed => 'Chófer confirmado';

  @override
  String get rideChauffeurOnTheWay => 'Tu chófer está en camino';

  @override
  String get rideChauffeurWaiting => 'Tu chófer te espera';

  @override
  String rideFlightArrivesAt(String time) {
    return 'Llega $time';
  }

  @override
  String rideFlightLandedAt(String time) {
    return 'Aterrizó $time';
  }

  @override
  String rideFlightTitle(String number) {
    return 'Vuelo $number';
  }

  @override
  String rideFlightTitleTerminal(String number, String terminal) {
    return 'Vuelo $number · Terminal $terminal';
  }

  @override
  String get rideHeadingToDestination => 'En camino a tu destino';

  @override
  String get rideLive => 'EN VIVO';

  @override
  String get rideLoading => 'Cargando tu reserva…';

  @override
  String get rideNotifArrivedBody => 'Tu chófer te espera en el punto de recogida.';

  @override
  String get rideNotifArrivedTitle => 'El chófer ha llegado';

  @override
  String get rideNotifArrivingBody => 'Tu chófer se dirige a tu punto de recogida.';

  @override
  String get rideNotifArrivingTitle => 'El chófer está en camino';

  @override
  String get rideNotifAssignedBody => 'Tu chófer confirmó la reserva.';

  @override
  String get rideNotifAssignedTitle => 'Chófer asignado';

  @override
  String get rideNotifCompletedBody => '¡Has llegado! Gracias por viajar con Luxelane.';

  @override
  String get rideNotifCompletedTitle => 'Viaje completado';

  @override
  String get rideNotifStartedBody => 'Ya estás en camino hacia tu destino.';

  @override
  String get rideNotifStartedTitle => 'Viaje iniciado';

  @override
  String ridePickupAt(String time) {
    return 'Recogida $time';
  }

  @override
  String get rideRateTrip => 'Calificar viaje';

  @override
  String get rideRatingCommentHint => 'Comentario (opcional)';

  @override
  String get rideRatingExcellent => 'Excelente';

  @override
  String get rideRatingFair => 'Regular';

  @override
  String get rideRatingGood => 'Bueno';

  @override
  String get rideRatingPoor => 'Malo';

  @override
  String rideRatingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get rideRatingThanks => '¡Gracias por tu calificación!';

  @override
  String get rideRatingTitle => 'Califica tu viaje';

  @override
  String get rideRatingVeryPoor => 'Muy malo';

  @override
  String get rideThanks => 'Gracias por viajar con Luxelane';

  @override
  String get rideThanksForRating => 'Gracias por calificar';

  @override
  String get rideVerifiedChauffeur => 'Chófer verificado';

  @override
  String rideVerifiedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verificado · $count viajes',
      one: 'Verificado · 1 viaje',
    );
    return '$_temp0';
  }

  @override
  String get rideViewReceipt => 'Ver recibo';

  @override
  String rideYouArriveIn(String eta) {
    return 'Llegas en $eta';
  }

  @override
  String get rideYourChauffeur => 'Tu chófer';

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
  String get tripDestination => 'Destino';

  @override
  String tripFlightNumber(String number) {
    return 'Vuelo $number';
  }

  @override
  String tripFreeWaitLeft(int minutes) {
    return 'Espera gratuita: $minutes min';
  }

  @override
  String tripFreeWaitOver(String time) {
    return 'Espera gratuita terminada a las $time';
  }

  @override
  String get tripFreeWaitOverDriver => 'Contacta al pasajero antes de retirarte.';

  @override
  String get tripFreeWaitOverRider => 'Tu chófer sigue esperándote. Avísale si necesitas más tiempo.';

  @override
  String tripFreeWaitUntil(String time, String summary) {
    return 'Hasta las $time · $summary';
  }

  @override
  String get tripMeetGreetBody => 'Tu chófer te esperará en la salida de llegadas con un cartel con tu nombre.';

  @override
  String tripMeetGreetBodyNamed(String name) {
    return 'Tu chófer te esperará en la salida de llegadas con un cartel con el nombre «$name».';
  }

  @override
  String get tripMeetGreetTitle => 'Meet & greet en llegadas';

  @override
  String tripMeetGreetWait(int minutes) {
    return '$minutes min de espera gratuita desde que aterriza tu vuelo.';
  }

  @override
  String tripNameSignSemantics(String name) {
    return 'Cartel con el nombre $name. Toca para cerrar.';
  }

  @override
  String get tripNameSignTapToClose => 'Toca la pantalla para cerrar';

  @override
  String get tripPassenger => 'Pasajero';

  @override
  String get tripPickup => 'Recogida';

  @override
  String get tripPriceBaseFare => 'Tarifa base';

  @override
  String get tripPriceBreakdown => 'Desglose del precio';

  @override
  String tripPriceDistanceLine(String km, String rate) {
    return '$km km × $rate';
  }

  @override
  String get tripPriceEstimatedTotal => 'Total estimado';

  @override
  String get tripPriceFinalNote => 'El precio fijo final se confirma antes de reservar.';

  @override
  String tripPriceHoursLine(int hours, String rate) {
    return '$hours h × $rate';
  }

  @override
  String get tripPriceMinimumAdjustment => 'Ajuste a tarifa mínima';

  @override
  String get tripReceiptAdjustment => 'Ajuste';

  @override
  String get tripReceiptCancelled => 'RESERVA CANCELADA';

  @override
  String get tripReceiptCard => 'Tarjeta';

  @override
  String get tripReceiptCompleted => 'VIAJE COMPLETADO';

  @override
  String get tripReceiptCopied => 'Recibo copiado al portapapeles';

  @override
  String get tripReceiptCopy => 'Copiar recibo';

  @override
  String get tripReceiptCurrencyNote => 'Montos en bolivianos (BOB).';

  @override
  String get tripReceiptDuration => 'Duración';

  @override
  String get tripReceiptFixedPrice => 'Precio fijo';

  @override
  String get tripReceiptFlight => 'Vuelo';

  @override
  String get tripReceiptNoCharge => 'Sin cargo';

  @override
  String tripReceiptNumber(String code) {
    return 'Nº $code';
  }

  @override
  String get tripReceiptPassengers => 'Pasajeros';

  @override
  String get tripReceiptPayChauffeur => 'Pago al chófer';

  @override
  String get tripReceiptPaymentMethod => 'Forma de pago';

  @override
  String tripReceiptPlainFrom(String place) {
    return 'Desde: $place';
  }

  @override
  String tripReceiptPlainHeader(String code) {
    return 'Luxelane — Recibo $code';
  }

  @override
  String tripReceiptPlainTo(String place) {
    return 'Hasta: $place';
  }

  @override
  String tripReceiptPlainTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get tripReceiptService => 'Servicio';

  @override
  String get tripReceiptTitle => 'Recibo';

  @override
  String get tripReceiptTotal => 'Total';

  @override
  String get tripReceiptVehicle => 'Vehículo';

  @override
  String get tripShowSign => 'Mostrar cartel';

  @override
  String get tripsBookNow => 'Reservar ahora';

  @override
  String get tripsEmpty => 'Aún no tienes viajes.\nReserva tu primera experiencia.';

  @override
  String get tripsLoadError => 'No pudimos cargar tus viajes. Revisa tu conexión.';

  @override
  String get tripsPast => 'ANTERIORES';

  @override
  String tripsRouteByHour(String origin, int hours) {
    return '$origin · $hours h';
  }

  @override
  String get tripsTitle => 'Mis viajes';

  @override
  String get tripsUpcoming => 'PRÓXIMOS';

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
