// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get adminActionFailed => 'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get adminActive => 'Activo';

  @override
  String get adminAppVersion => 'Versión de la app';

  @override
  String get adminAssignNearest => 'Asignar chófer más cercano';

  @override
  String adminAttentionBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas sin chófer con recogida en menos de 2 horas',
      one: '1 reserva sin chófer con recogida en menos de 2 horas',
    );
    return '$_temp0';
  }

  @override
  String get adminAttentionView => 'Ver';

  @override
  String adminAuditBy(String id) {
    return 'Admin: $id';
  }

  @override
  String get adminBackend => 'Backend';

  @override
  String get adminBookingActions => 'Acciones';

  @override
  String adminBookingDriver(String name) {
    return 'Chófer: $name';
  }

  @override
  String adminBookingRider(String name) {
    return 'Pasajero: $name';
  }

  @override
  String get adminBusinessPerformance => 'Rendimiento del negocio';

  @override
  String get adminCancelBooking => 'Cancelar reserva';

  @override
  String get adminCancelBookingBody => 'El pasajero y el chófer asignado recibirán un aviso.';

  @override
  String adminCancelBookingTitle(String code) {
    return '¿Cancelar la reserva $code?';
  }

  @override
  String adminChangeRoleTitle(String name) {
    return 'Cambiar rol de $name';
  }

  @override
  String get adminCurrency => 'Moneda';

  @override
  String get adminCurrencyValue => 'Bolivianos (Bs)';

  @override
  String adminDeleteBookingBody(String id) {
    return 'Se eliminará permanentemente la reserva #$id. Esta acción no se puede deshacer.';
  }

  @override
  String get adminDeleteBookingTitle => '¿Eliminar reserva?';

  @override
  String get adminDeleteBookingTooltip => 'Eliminar reserva';

  @override
  String get adminDisable => 'Deshabilitar';

  @override
  String get adminDocumentsVerified => 'Documentos verificados';

  @override
  String get adminFieldBase => 'Base (Bs)';

  @override
  String get adminFieldMinimum => 'Mínimo (Bs)';

  @override
  String get adminFieldPerHour => 'Por hora (Bs)';

  @override
  String get adminFieldPerKm => 'Por km (Bs)';

  @override
  String get adminFilterAll => 'Todos';

  @override
  String get adminFilterUnassigned => 'Sin chófer';

  @override
  String get adminFirestoreRules => 'Reglas de precios de Firestore';

  @override
  String get adminGlobalSettings => 'Configuración global de la app';

  @override
  String get adminInactive => 'Inactivo';

  @override
  String get adminKpiAwaitingDriver => 'Esperando chófer';

  @override
  String get adminKpiCompleted => 'Viajes completados';

  @override
  String adminKpiDriversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chóferes',
      one: '1 chófer',
    );
    return '$_temp0';
  }

  @override
  String adminKpiInProgress(int count) {
    return '$count en progreso';
  }

  @override
  String get adminKpiPending => 'Reservas pendientes';

  @override
  String adminKpiToday(String amount) {
    return 'Hoy: $amount';
  }

  @override
  String get adminKpiTotalRevenue => 'Ingresos totales';

  @override
  String get adminKpiUsers => 'Usuarios registrados';

  @override
  String adminLicense(String number) {
    return 'Licencia: $number';
  }

  @override
  String get adminLiveStats => 'Estadísticas en vivo';

  @override
  String get adminMaintenanceBanner => 'MODO MANTENIMIENTO ACTIVO — Los pasajeros no pueden reservar nuevos viajes.';

  @override
  String get adminMaintenanceMode => 'Modo mantenimiento';

  @override
  String get adminMaintenanceModeDesc => 'Deshabilita todas las reservas y muestra la pantalla de mantenimiento a los usuarios.';

  @override
  String adminMemberSince(String date) {
    return 'Miembro desde $date';
  }

  @override
  String get adminNoAuditLogs => 'Aún no hay registros de auditoría';

  @override
  String get adminNoAuditLogsHint => 'Las acciones administrativas aparecerán aquí en tiempo real';

  @override
  String get adminNoBookings => 'No se encontraron reservas';

  @override
  String get adminNoDrivers => 'No se encontraron chóferes';

  @override
  String get adminNoUsersMatch => 'Ningún usuario coincide con la búsqueda';

  @override
  String get adminNoVehicles => 'Aún no hay vehículos registrados';

  @override
  String get adminNoVehiclesHint => 'Los vehículos vinculados a chóferes aparecen aquí';

  @override
  String get adminNoticeBookingCancelled => 'Reserva cancelada';

  @override
  String get adminNoticeBookingDeleted => 'Reserva eliminada';

  @override
  String get adminNoticeDriverAssigned => 'Chófer asignado';

  @override
  String get adminNoticeDriverVerified => 'Chófer verificado';

  @override
  String get adminNoticeMaintenanceOff => 'Modo mantenimiento desactivado';

  @override
  String get adminNoticeMaintenanceOn => 'Modo mantenimiento activado';

  @override
  String get adminNoticeNoDriver => 'No hay chóferes disponibles cerca para esta clase de vehículo';

  @override
  String get adminNoticePricingUpdated => 'Regla de precios actualizada';

  @override
  String get adminNoticeRoleUpdated => 'Rol actualizado';

  @override
  String get adminNoticeSettingsSaved => 'Configuración guardada';

  @override
  String get adminOffline => 'Fuera de línea';

  @override
  String get adminOnline => 'En línea';

  @override
  String get adminOverview => 'Resumen';

  @override
  String get adminPanelBadge => 'Panel admin';

  @override
  String get adminPlatform => 'Plataforma';

  @override
  String get adminPlatformValue => 'Flutter Web + móvil';

  @override
  String adminPriceBaseAndKm(String base, String perKm) {
    return '$base base + $perKm/km';
  }

  @override
  String adminPriceBasePlusKm(String base, String perKm) {
    return '$base + $perKm/km';
  }

  @override
  String adminPriceMinimum(String amount) {
    return 'Mín.: $amount';
  }

  @override
  String adminPricePerHour(String amount) {
    return '$amount/h';
  }

  @override
  String get adminPricingNote => 'Los precios reflejan el modelo DefaultPricing. Si la colección pricingRules está vacía, los precios se calculan localmente.';

  @override
  String get adminPricingRules => 'Reglas de precios (Bs)';

  @override
  String get adminPushNotifications => 'Notificaciones push';

  @override
  String get adminPushNotificationsDesc => 'Habilita notificaciones a nivel del sistema para nuevas reservas.';

  @override
  String get adminRecentActivity => 'Actividad reciente';

  @override
  String get adminRegisteredDrivers => 'Chóferes registrados';

  @override
  String get adminRegisteredVehicles => 'Vehículos registrados';

  @override
  String get adminReportsAvgRating => 'Calificación promedio';

  @override
  String get adminReportsAvgTicket => 'Ticket promedio';

  @override
  String get adminReportsByAdmin => 'Operaciones';

  @override
  String get adminReportsByRider => 'Pasajero';

  @override
  String get adminReportsBySystem => 'Automática';

  @override
  String get adminReportsByUnknown => 'Sin registro';

  @override
  String get adminReportsCancellationRate => 'Tasa de cancelación';

  @override
  String get adminReportsCancellations => 'Cancelaciones por origen';

  @override
  String adminReportsCancelledOf(int cancelled, int total) {
    return '$cancelled de $total reservas';
  }

  @override
  String get adminReportsColDate => 'Fecha';

  @override
  String get adminReportsColDriver => 'Chófer';

  @override
  String get adminReportsColRating => 'Calificación';

  @override
  String get adminReportsColRevenue => 'Ingresos (Bs)';

  @override
  String get adminReportsColTrips => 'Viajes';

  @override
  String get adminReportsCopied => 'CSV copiado al portapapeles';

  @override
  String get adminReportsDailyTable => 'Ver datos por día';

  @override
  String adminReportsDays(int days) {
    return '$days días';
  }

  @override
  String get adminReportsDownloaded => 'CSV descargado';

  @override
  String get adminReportsDrivers => 'Rendimiento de chóferes';

  @override
  String get adminReportsEmpty => 'No hay reservas con recogida en este período.';

  @override
  String get adminReportsExportDaily => 'Exportar días (CSV)';

  @override
  String get adminReportsExportDrivers => 'Exportar chóferes (CSV)';

  @override
  String get adminReportsLateCancellations => 'Cancelaciones tardías';

  @override
  String get adminReportsLateHint => 'Del pasajero, dentro de la ventana con cargo';

  @override
  String get adminReportsNoCancellations => 'Sin cancelaciones en este período.';

  @override
  String get adminReportsNoDrivers => 'Ningún chófer completó viajes en este período.';

  @override
  String get adminReportsNoPrevious => 'Sin datos del período anterior';

  @override
  String adminReportsPeakHour(String hour) {
    return 'Hora pico: $hour';
  }

  @override
  String get adminReportsPeakHours => 'Demanda por hora de recogida';

  @override
  String get adminReportsPeakHoursHint => 'Todas las reservas del período, incluidas las canceladas.';

  @override
  String get adminReportsPerTrip => 'Por viaje completado';

  @override
  String adminReportsRange(String from, String to) {
    return 'Recogidas del $from al $to (hora local)';
  }

  @override
  String adminReportsRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calificaciones',
      one: '1 calificación',
      zero: 'Sin calificaciones',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsRevenue => 'Ingresos';

  @override
  String get adminReportsRevenuePerDay => 'Ingresos por día (Bs)';

  @override
  String get adminReportsServiceMix => 'Viajes por tipo de servicio';

  @override
  String get adminReportsTitle => 'Reportes de operaciones';

  @override
  String adminReportsTooltipBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas',
      one: '1 reserva',
    );
    return '$_temp0';
  }

  @override
  String adminReportsTooltipTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsTrips => 'Viajes completados';

  @override
  String get adminReportsTripsPerDay => 'Viajes completados por día';

  @override
  String get adminReportsUnknownDriver => 'Chófer sin nombre';

  @override
  String get adminReportsUnserved => 'Sin chófer asignado';

  @override
  String get adminReportsUnservedHint => 'Canceladas automáticamente';

  @override
  String get adminReportsVehicleMix => 'Viajes por categoría';

  @override
  String adminReportsVsPrevious(String delta) {
    return '$delta vs. período anterior';
  }

  @override
  String get adminRevenueTrend => 'Tendencia de ingresos 7 días (Bs)';

  @override
  String get adminSearchUsers => 'Buscar usuarios…';

  @override
  String get adminSectionAudit => 'Auditoría';

  @override
  String get adminSectionBookings => 'Reservas';

  @override
  String get adminSectionCompanies => 'Empresas';

  @override
  String get adminSectionDashboard => 'Panel';

  @override
  String get adminSectionDrivers => 'Chóferes';

  @override
  String get adminSectionHealth => 'Salud';

  @override
  String get adminSectionHotels => 'Hoteles';

  @override
  String get adminSectionLoyalty => 'Fidelidad';

  @override
  String get adminSectionPricing => 'Precios';

  @override
  String get adminSectionPromos => 'Promociones';

  @override
  String get adminSectionReports => 'Reportes';

  @override
  String get adminSectionSettings => 'Configuración';

  @override
  String get adminSectionSettlements => 'Liquidaciones';

  @override
  String get adminSectionSupport => 'Soporte';

  @override
  String get adminSectionUsers => 'Usuarios';

  @override
  String get adminSectionVehicles => 'Vehículos';

  @override
  String get adminSignOutConfirm => '¿Seguro que quieres cerrar sesión del panel de administración?';

  @override
  String get adminSystemInfo => 'Información del sistema';

  @override
  String get adminTitle => 'Administrador';

  @override
  String get adminTotalBookings => 'Total de reservas';

  @override
  String get adminTwoFactor => 'Autenticación admin de dos factores';

  @override
  String get adminTwoFactorDesc => 'Requiere 2FA para todas las acciones administrativas.';

  @override
  String adminVehicleDetails(String plate, String vehicleClass) {
    return 'Placa: $plate · Clase: $vehicleClass';
  }

  @override
  String get adminVerifiedDrivers => 'Chóferes verificados';

  @override
  String get adminVerify => 'Verificar';

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Chófer';

  @override
  String get authAlreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authBrandHeadline => 'Servicio de chófer\npremium.';

  @override
  String get authBrandTagline => 'Precio fijo. Chóferes verificados.';

  @override
  String get authConsentPrivacyLink => 'Política de privacidad';

  @override
  String get authConsentRequired => 'Debes aceptar los términos y la política de privacidad';

  @override
  String get authConsentTermsLink => 'Términos y condiciones';

  @override
  String authConsentText(String terms, String privacy) {
    return 'Acepto los $terms y la $privacy';
  }

  @override
  String get authCreateOne => 'Crear una';

  @override
  String get authEmailInvalid => 'Ingresa un correo válido';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authErrorEmailInUse => 'Ya existe una cuenta con este correo';

  @override
  String get authErrorGeneric => 'No pudimos completar la solicitud. Inténtalo de nuevo.';

  @override
  String get authErrorInvalidEmail => 'El correo electrónico no es válido';

  @override
  String get authErrorTooManyRequests => 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get authErrorUserDisabled => 'Esta cuenta está desactivada. Contáctanos para más información.';

  @override
  String get authErrorUserNotFound => 'No existe una cuenta con este correo';

  @override
  String get authErrorWeakPassword => 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';

  @override
  String get authErrorWrongCredentials => 'Correo o contraseña incorrectos';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get authLoginHeadline => 'Bienvenido\nde nuevo.';

  @override
  String get authLoginSubtitle => 'Inicia sesión en tu cuenta';

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authLoginWelcomeBack => 'Bienvenido de nuevo a Luxelane.';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String authPasswordTooShort(int count) {
    return 'Mínimo $count caracteres';
  }

  @override
  String get authPhoneLabel => 'Teléfono';

  @override
  String get authRegisterHeadline => 'Crear cuenta.';

  @override
  String get authRegisterSubtitle => 'Únete a Luxelane hoy';

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authResetEmailSent => 'Correo de restablecimiento enviado';

  @override
  String get authResetNeedsEmail => 'Ingresa tu correo para restablecer la contraseña';

  @override
  String get authSignInLink => 'Inicia sesión';

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
  String bookingChauffeurAtDisposalDays(int days, int hours) {
    return 'Chófer a disposición · $days días, $hours h por día';
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
  String get bookingDaysLabel => 'Días';

  @override
  String bookingDaysSummary(int days, int hours) {
    return '$days días · $hours h por día';
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
  String get bookingHeroTagline => 'Precio fijo · Sin sorpresas · Chóferes verificados';

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
  String get bookingIncludedWater => 'Espera gratuita incluida: 60 min en aeropuerto, 15 en ciudad';

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
  String get bookingReturnTooEarly => 'El regreso debe ser después de la recogida de ida.';

  @override
  String get bookingReturnTrip => 'Reservar el regreso';

  @override
  String get bookingReturnWhen => '¿Cuándo te recogemos para volver?';

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
  String get coreClearField => 'Borrar';

  @override
  String get coreConfirmBooking => 'Confirmar reserva';

  @override
  String get coreDriverLocationNotification => 'Compartiendo tu ubicación mientras estás disponible';

  @override
  String get coreErrorBody => 'Hemos sido notificados y estamos trabajando en una solución.';

  @override
  String get coreErrorTitle => 'Algo salió mal';

  @override
  String get coreFixedPrice => 'Precio fijo';

  @override
  String coreHoursTotal(int hours) {
    return '$hours h en total';
  }

  @override
  String get coreMapKeyMissing => 'Agrega GOOGLE_MAPS_KEY para habilitar el mapa';

  @override
  String get coreMapPickerHint => 'Mueve el mapa para seleccionar una ubicación';

  @override
  String get coreMapPickerSelected => 'Ubicación seleccionada';

  @override
  String get coreMapPickerTitle => 'Seleccionar ubicación';

  @override
  String get coreMapView => 'Vista del mapa';

  @override
  String get coreRoleAdmin => 'Admin';

  @override
  String get coreRoleDriver => 'Chófer';

  @override
  String get coreRoleRider => 'Pasajero';

  @override
  String coreVehicleCapacity(int count) {
    return 'Hasta $count';
  }

  @override
  String get corpAddCostCenter => 'Agregar centro de costo';

  @override
  String get corpAddMember => 'Agregar miembro';

  @override
  String get corpAddMemberAction => 'Agregar';

  @override
  String get corpAddMemberHint => 'Podrá facturar sus viajes a la empresa. Si aún no tiene cuenta, se unirá al registrarse con este correo.';

  @override
  String get corpAdminEmail => 'Correo del administrador';

  @override
  String get corpAdminEmailHint => 'Si aún no tiene cuenta, se unirá al registrarse con este correo.';

  @override
  String get corpAdminEmpty => 'Todavía no hay empresas.';

  @override
  String get corpAdminIntro => 'Las empresas reciben una factura mensual por los viajes de sus miembros. El administrador de cada empresa gestiona miembros y centros de costo desde su portal.';

  @override
  String get corpAdminTitle => 'Cuentas corporativas';

  @override
  String get corpBillCompanyHint => 'Factura mensual a la empresa';

  @override
  String corpBillCompanyNotice(String company) {
    return 'Este viaje se incluye en la factura mensual de $company. No pagas nada al chófer.';
  }

  @override
  String get corpBillPersonal => 'Personal';

  @override
  String get corpBillPersonalHint => 'Lo pagas tú';

  @override
  String get corpBillTo => 'Facturar a';

  @override
  String corpBilledTo(String company) {
    return 'Facturado a $company';
  }

  @override
  String get corpBillingDetails => 'Datos de facturación';

  @override
  String get corpBillingEmail => 'Correo de facturación';

  @override
  String get corpByCostCenter => 'Por centro de costo';

  @override
  String get corpByTraveler => 'Por persona';

  @override
  String get corpCancelInvite => 'Cancelar invitación';

  @override
  String get corpColAmount => 'Monto (Bs)';

  @override
  String get corpColBookedBy => 'Reservado por';

  @override
  String get corpColDate => 'Fecha';

  @override
  String get corpColFrom => 'Origen';

  @override
  String get corpColPassenger => 'Pasajero';

  @override
  String get corpColTo => 'Destino';

  @override
  String get corpColVehicle => 'Vehículo';

  @override
  String get corpCompanyCreated => 'Empresa creada';

  @override
  String get corpCompanyName => 'Razón social';

  @override
  String get corpCostCenter => 'Centro de costo';

  @override
  String get corpCostCenterNone => 'Ninguno';

  @override
  String get corpCostCenterOptional => 'Centro de costo (opcional)';

  @override
  String get corpCostCenterRequired => 'Centro de costo (obligatorio)';

  @override
  String get corpCostCenters => 'Centros de costo';

  @override
  String get corpCostCentersHint => 'Aparecen al reservar para que cada viaje quede asignado a un área o proyecto.';

  @override
  String get corpCreate => 'Crear';

  @override
  String get corpCreateCompany => 'Nueva empresa';

  @override
  String corpDriverNoCollect(String company) {
    return 'Cuenta corporativa ($company): no cobres al pasajero.';
  }

  @override
  String get corpEmail => 'Correo electrónico';

  @override
  String get corpErrorCompanyInactive => 'La cuenta corporativa está suspendida.';

  @override
  String get corpErrorCostCenterRequired => 'Elige un centro de costo para facturar a la empresa.';

  @override
  String get corpErrorCostCentersEmpty => 'Agrega al menos un centro de costo antes de exigirlo.';

  @override
  String get corpErrorInvalidEmail => 'Revisa el correo electrónico.';

  @override
  String get corpErrorInvalidName => 'Escribe la razón social.';

  @override
  String get corpErrorInvalidTaxId => 'El NIT debe tener solo números (5 a 15).';

  @override
  String get corpErrorLastAdmin => 'La empresa necesita al menos un administrador.';

  @override
  String get corpErrorNotARider => 'Esa cuenta es de chófer o de administración; solo pasajeros pueden ser miembros.';

  @override
  String get corpErrorNotAllowed => 'No puedes facturar este viaje a la empresa. Elige pago personal.';

  @override
  String get corpErrorOtherCompany => 'Esa persona ya pertenece a otra empresa.';

  @override
  String get corpExportCsv => 'Exportar detalle (CSV)';

  @override
  String get corpFormerMember => 'Exmiembro';

  @override
  String get corpInviteCancelled => 'Invitación cancelada';

  @override
  String corpKpiCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelaciones en total',
      one: '1 cancelación en total',
      zero: 'Sin cancelaciones',
    );
    return '$_temp0';
  }

  @override
  String get corpKpiCompleted => 'Viajes completados';

  @override
  String get corpKpiLateCancellations => 'Cancelaciones tardías';

  @override
  String get corpKpiToInvoice => 'A facturar';

  @override
  String get corpKpiToInvoiceHint => 'Viajes completados del mes';

  @override
  String get corpKpiUpcoming => 'Próximos o en curso';

  @override
  String get corpMakeAdmin => 'Hacer administrador';

  @override
  String get corpMakeMember => 'Quitar permisos de administrador';

  @override
  String get corpMemberActions => 'Opciones del miembro';

  @override
  String get corpMemberAdded => 'Listo. Si la persona ya tenía cuenta, se agregó; si no, se unirá al registrarse.';

  @override
  String get corpMemberRemoved => 'Miembro quitado';

  @override
  String get corpMemberUpdated => 'Permisos actualizados';

  @override
  String get corpMembers => 'Miembros';

  @override
  String get corpNewCostCenter => 'Nuevo centro de costo';

  @override
  String get corpNextMonth => 'Mes siguiente';

  @override
  String get corpNoAccess => 'Solo los administradores de la empresa pueden ver este portal.';

  @override
  String get corpNoCostCenter => 'Sin centro de costo';

  @override
  String get corpNoMembers => 'Aún no hay miembros.';

  @override
  String get corpNoRidesMonth => 'No hay viajes facturados a la empresa en este mes.';

  @override
  String get corpOpenPortal => 'Abrir portal';

  @override
  String get corpPendingInvites => 'Invitaciones pendientes';

  @override
  String get corpPendingInvitesHint => 'Se unirán al crear su cuenta con estos correos.';

  @override
  String get corpPortalTitle => 'Cuenta corporativa';

  @override
  String get corpPrevMonth => 'Mes anterior';

  @override
  String get corpProfileAdminHint => 'Administras esta cuenta: estado de cuenta, miembros y ajustes';

  @override
  String get corpProfileMemberHint => 'Puedes facturar tus viajes a la empresa';

  @override
  String get corpProfileSection => 'Cuenta corporativa';

  @override
  String get corpReactivate => 'Reactivar cuenta';

  @override
  String get corpReactivated => 'Cuenta reactivada';

  @override
  String get corpReference => 'Referencia';

  @override
  String get corpReferenceHint => 'Proyecto, orden de compra, cliente…';

  @override
  String get corpRemoveCostCenter => 'Quitar';

  @override
  String get corpRemoveMember => 'Quitar de la empresa';

  @override
  String corpRemoveMemberBody(String name) {
    return '$name ya no podrá facturar viajes a la empresa. Sus viajes anteriores siguen en el estado de cuenta.';
  }

  @override
  String get corpRequireCostCenter => 'Exigir centro de costo';

  @override
  String get corpRequireCostCenterHint => 'No se podrá reservar a cuenta de la empresa sin elegir uno.';

  @override
  String get corpRidesOfMonth => 'Viajes del mes';

  @override
  String get corpRoleAdmin => 'Administrador';

  @override
  String get corpRoleMember => 'Miembro';

  @override
  String corpRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get corpSave => 'Guardar cambios';

  @override
  String get corpSettingsSaved => 'Cambios guardados';

  @override
  String get corpSuspend => 'Suspender cuenta';

  @override
  String get corpSuspended => 'Cuenta suspendida';

  @override
  String get corpSuspendedBanner => 'La cuenta está suspendida: sus miembros no pueden facturar viajes a la empresa. Escríbenos para reactivarla.';

  @override
  String get corpSuspendedShort => 'Cuenta suspendida';

  @override
  String get corpTabMembers => 'Miembros';

  @override
  String get corpTabSettings => 'Ajustes';

  @override
  String get corpTabStatement => 'Estado de cuenta';

  @override
  String get corpTaxId => 'NIT';

  @override
  String corpTaxIdShort(String taxId) {
    return 'NIT $taxId';
  }

  @override
  String docApprovedCount(int approved, int total) {
    return '$approved de $total aprobados';
  }

  @override
  String docBannerExpiring(String doc) {
    return 'Tu $doc vence pronto. Sube la versión renovada.';
  }

  @override
  String get docBannerInReview => 'Estamos revisando tus documentos. Te avisaremos al aprobarlos.';

  @override
  String docBannerToUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count documentos para que puedas recibir viajes.',
      one: 'Falta 1 documento para que puedas recibir viajes.',
    );
    return '$_temp0';
  }

  @override
  String get docCriminalRecord => 'Certificado de antecedentes';

  @override
  String get docCriminalRecordHint => 'REJAP o FELCC, emitido en los últimos 3 meses';

  @override
  String get docErrorAlreadyExpired => 'Ese documento ya está vencido.';

  @override
  String get docErrorExpiryRequired => 'Indica la fecha de vencimiento.';

  @override
  String get docErrorFailed => 'No se pudo completar. Inténtalo de nuevo.';

  @override
  String get docErrorReasonRequired => 'Escribe el motivo del rechazo.';

  @override
  String get docErrorTooLarge => 'El archivo pesa más de 10 MB.';

  @override
  String docExpiredOn(String date) {
    return 'Venció el $date';
  }

  @override
  String docExpiresOn(String date) {
    return 'Vence el $date';
  }

  @override
  String docExpiryPickerTitle(String doc) {
    return '¿Cuándo vence tu $doc?';
  }

  @override
  String get docIdCard => 'Cédula de identidad';

  @override
  String get docIdCardHint => 'Ambos lados, legible';

  @override
  String get docLicense => 'Licencia de conducir';

  @override
  String get docLicenseHint => 'Categoría profesional, ambos lados';

  @override
  String docPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en revisión',
      one: '1 en revisión',
    );
    return '$_temp0';
  }

  @override
  String get docPendingHint => 'Lo revisamos normalmente en menos de 24 horas.';

  @override
  String get docPrivacyNote => 'Tus documentos solo los ve el equipo de Luxelane para verificarte. Se borran si eliminas tu cuenta.';

  @override
  String get docProfileLink => 'Mis documentos y verificación';

  @override
  String docRejectedReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get docReplace => 'Reemplazar';

  @override
  String get docReviewAction => 'Revisar documentos';

  @override
  String get docReviewAllApproved => 'Todos los documentos están aprobados y vigentes.';

  @override
  String get docReviewApprove => 'Aprobar';

  @override
  String get docReviewApproved => 'Documento aprobado';

  @override
  String get docReviewConfirmExpiry => 'Confirma la fecha de vencimiento';

  @override
  String get docReviewOpen => 'Ver archivo';

  @override
  String get docReviewReject => 'Rechazar';

  @override
  String get docReviewRejectReason => 'Motivo';

  @override
  String get docReviewRejectReasonHint => 'Ej.: la foto está borrosa';

  @override
  String get docReviewRejectTitle => 'Rechazar documento';

  @override
  String get docReviewRejected => 'Documento rechazado; avisamos al chófer';

  @override
  String docReviewTitle(String name) {
    return 'Documentos de $name';
  }

  @override
  String get docSoat => 'SOAT';

  @override
  String get docSoatHint => 'Seguro obligatorio vigente del vehículo';

  @override
  String get docStatusApproved => 'Aprobado';

  @override
  String get docStatusExpired => 'Vencido';

  @override
  String get docStatusExpiring => 'Por vencer';

  @override
  String get docStatusMissing => 'Falta';

  @override
  String get docStatusPending => 'En revisión';

  @override
  String get docStatusRejected => 'Rechazado';

  @override
  String get docSummaryBody => 'Para recibir viajes revisamos y aprobamos estos documentos. Sube fotos nítidas o PDF; te avisamos cuando estén revisados.';

  @override
  String get docSummaryTitle => 'Verificación pendiente';

  @override
  String get docSummaryVerified => 'Chófer verificado';

  @override
  String get docSummaryVerifiedBody => 'Todos tus documentos están aprobados. Te avisaremos 30 y 7 días antes de que venza alguno.';

  @override
  String get docTitle => 'Documentos';

  @override
  String docToUploadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por subir',
      one: '1 por subir',
    );
    return '$_temp0';
  }

  @override
  String get docUpload => 'Subir';

  @override
  String get docUploaded => 'Documento enviado a revisión';

  @override
  String docUploadedOn(String date) {
    return 'Subido el $date';
  }

  @override
  String get docVehicleRegistration => 'Registro del vehículo (RUAT)';

  @override
  String get docVehicleRegistrationHint => 'Certificado de propiedad o RUAT a tu nombre o autorizado';

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
  String get healthAlertsNote => 'Los admins reciben un aviso cuando una reserva queda sin chófer a 30 minutos de la recogida y cuando no hay chóferes en línea con reservas próximas (como máximo una vez por hora).';

  @override
  String healthBuildInfo(String env, String version) {
    return 'Entorno: $env · versión $version';
  }

  @override
  String get healthEnvDev => 'desarrollo';

  @override
  String get healthEnvProd => 'producción';

  @override
  String get healthErrors24h => 'Errores distintos en 24 h';

  @override
  String get healthErrorsNote => 'Agrupados: el mismo error de muchos usuarios aparece una vez con su conteo. Los de Android e iOS están en Firebase Crashlytics.';

  @override
  String get healthErrorsTitle => 'Errores de la app web';

  @override
  String get healthHideResolved => 'Ocultar resueltos';

  @override
  String healthLastSeen(String date) {
    return 'último: $date';
  }

  @override
  String get healthMarkResolved => 'Marcar resuelto';

  @override
  String healthMonitorOk(String time) {
    return 'Monitor activo · última revisión a las $time';
  }

  @override
  String get healthMonitorStale => 'El monitor no informa hace más de 15 minutos. Revisa que las Cloud Functions estén desplegadas.';

  @override
  String get healthNeedsAttention => 'Requiere atención';

  @override
  String get healthNoErrors => 'Sin errores pendientes.';

  @override
  String healthOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String get healthOnlineDrivers => 'Chóferes verificados en línea';

  @override
  String get healthPendingNext2h => 'Reservas en las próximas 2 h';

  @override
  String get healthReopen => 'Reabrir';

  @override
  String get healthShowResolved => 'Ver resueltos';

  @override
  String get healthTitle => 'Salud del sistema';

  @override
  String get healthUnassignedSoon => 'Sin chófer, recogida en < 30 min';

  @override
  String get healthUrgentTickets => 'Reportes de seguridad abiertos';

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
  String get homeBookBulletDirectContact => 'Contacto directo con tu chófer';

  @override
  String get homeBookBulletFixedPrice => 'Precio fijo, siempre';

  @override
  String get homeBookBulletFlightTracking => 'Seguimiento de vuelos';

  @override
  String get homeBookBulletFreeWait => 'Espera gratuita incluida';

  @override
  String get homeBookBulletGuests => 'Reservas para invitados';

  @override
  String get homeBookBulletMeetGreet => 'Meet & greet con cartel';

  @override
  String get homeBookBulletReceipts => 'Recibo de cada viaje';

  @override
  String get homeBookBulletTracking => 'Seguimiento en tiempo real';

  @override
  String get homeBookBusinessSub => 'Viajes corporativos redefinidos';

  @override
  String get homeBookCoverSubtitle => 'Servicio de chófer premium';

  @override
  String get homeBookExperienceBody => 'Del aeropuerto a tu destino: seguimos tu vuelo, tu chófer te espera con un cartel con tu nombre y la espera está incluida — 60 min en aeropuerto, 15 en ciudad.';

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
  String get homeBusinessBody => 'Reserva para tu equipo y tus invitados con precio fijo en bolivianos, seguimiento en vivo y un recibo de cada viaje.';

  @override
  String get homeBusinessEyebrow => 'Para empresas';

  @override
  String get homeBusinessLearnMore => 'Más información';

  @override
  String get homeBusinessPerkFixedPrice => 'Precio fijo confirmado antes de reservar';

  @override
  String get homeBusinessPerkFlights => 'Seguimiento de vuelos y recogida ajustada';

  @override
  String get homeBusinessPerkGuests => 'Reservas para invitados y equipos';

  @override
  String get homeBusinessPerkMeetGreet => 'Meet & greet con cartel en el aeropuerto';

  @override
  String get homeBusinessPerkMonitoring => 'Seguimiento en vivo de cada viaje';

  @override
  String get homeBusinessPerkReceipts => 'Recibo de cada viaje en la app';

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
  String get homeFleetSwipeHint => 'Desliza para explorar →';

  @override
  String get homeFleetTagExtraLuggage => 'Equipaje extra';

  @override
  String get homeFleetTagFixedPrice => 'Precio fijo';

  @override
  String get homeFleetTagGroups => 'Ideal para grupos';

  @override
  String get homeFleetTagTracking => 'Seguimiento en vivo';

  @override
  String get homeFleetTagVerified => 'Chófer verificado';

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
  String get homeMarqueeFreeWait => 'Espera gratuita';

  @override
  String get homeMarqueeHourly => 'Chófer por horas';

  @override
  String get homeMarqueePremiumFleet => 'Flota premium';

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
  String get homeServiceHotels => 'Traslados de hotel';

  @override
  String get homeServiceHourly => 'Contratación por horas';

  @override
  String get homeServiceImmediatePickup => 'Recogida inmediata';

  @override
  String get homeServiceIntercity => 'Ciudad a ciudad';

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
  String get hotelAdminAdd => 'Agregar hotel';

  @override
  String get hotelAdminAddress => 'Dirección';

  @override
  String get hotelAdminAddressHint => 'Busca el hotel';

  @override
  String get hotelAdminCopyLink => 'Copiar enlace';

  @override
  String get hotelAdminEdit => 'Editar';

  @override
  String hotelAdminEditTitle(String name) {
    return 'Editar $name';
  }

  @override
  String get hotelAdminEmpty => 'Aún no hay hoteles aliados. La página pública dice que pronto los anunciarán.';

  @override
  String get hotelAdminHidden => 'Oculto';

  @override
  String get hotelAdminHide => 'Ocultar de la página';

  @override
  String get hotelAdminIntro => 'Los hoteles visibles aparecen en la página de traslados de hotel. Cada uno tiene un enlace para poner en un QR en recepción: abre la página con ese hotel ya elegido. Para facturar los traslados al hotel, créale una cuenta de empresa.';

  @override
  String get hotelAdminLinkCopied => 'Enlace copiado. Puedes convertirlo en un código QR.';

  @override
  String get hotelAdminMeetingPoint => 'Punto de encuentro (opcional)';

  @override
  String get hotelAdminMeetingPointHint => 'Ej.: Lobby principal';

  @override
  String get hotelAdminName => 'Nombre del hotel';

  @override
  String get hotelAdminSave => 'Guardar';

  @override
  String get hotelAdminSaved => 'Hotel guardado';

  @override
  String get hotelAdminShow => 'Mostrar en la página';

  @override
  String get hotelAdminTitle => 'Hoteles aliados';

  @override
  String get hotelAdminVisible => 'Visible';

  @override
  String get hotelErrorMeetingPoint => 'El punto de encuentro admite hasta 120 caracteres.';

  @override
  String get hotelErrorName => 'Ingresa el nombre del hotel (hasta 80 caracteres).';

  @override
  String get hotelErrorPlace => 'Elige la dirección del hotel de la lista.';

  @override
  String get hotelEyebrow => 'Traslados de hotel';

  @override
  String get hotelFromAirport => 'Desde el aeropuerto';

  @override
  String hotelFromAirportHint(int minutes) {
    return 'Indica la hora de llegada de tu vuelo y, en el siguiente paso, el número de vuelo: lo seguimos y la espera es gratis hasta $minutes min después del aterrizaje.';
  }

  @override
  String get hotelHomeLink => 'Traslados de hotel';

  @override
  String hotelIncFlightBody(int minutes) {
    return 'Si llegas al aeropuerto, seguimos tu vuelo: espera gratis hasta $minutes min tras el aterrizaje.';
  }

  @override
  String get hotelIncFlightTitle => 'Seguimiento de vuelo';

  @override
  String get hotelIncLobbyBody => 'Tu chófer te espera en el punto de encuentro acordado con el hotel.';

  @override
  String get hotelIncLobbyTitle => 'Recogida en el hotel';

  @override
  String get hotelIntro => 'Traslados privados entre nuestros hoteles aliados y el Aeropuerto Internacional Viru Viru. Elige tu hotel, la dirección y la hora; el precio queda fijo antes de confirmar.';

  @override
  String hotelLandingAt(String when) {
    return 'Llegada del vuelo: $when';
  }

  @override
  String hotelMeetingPoint(String place) {
    return 'Punto de encuentro: $place';
  }

  @override
  String get hotelMeetingPointLabel => 'Punto de encuentro';

  @override
  String get hotelNoneBody => 'Mientras tanto, puedes reservar un traslado desde o hacia cualquier hotel con la reserva normal.';

  @override
  String get hotelNoneTitle => 'Pronto anunciaremos nuestros hoteles aliados';

  @override
  String get hotelOtherHotel => 'Otro hotel o dirección';

  @override
  String get hotelPartnerCta => '¿Tienes un hotel? Escríbenos';

  @override
  String hotelPickupAt(String when) {
    return 'Recogida: $when';
  }

  @override
  String get hotelTitle => 'Del hotel al aeropuerto, sin pensarlo';

  @override
  String get hotelToAirport => 'Al aeropuerto';

  @override
  String get hotelToAirportHint => 'Tu chófer te recoge en el hotel a la hora que elijas. Para vuelos nacionales, sal unas 2 h antes; para internacionales, unas 3 h.';

  @override
  String get intercityBuenaVista => 'Puerta de entrada al Parque Amboró';

  @override
  String intercityCardMeta(String km, String price) {
    return '≈ $km km · desde $price';
  }

  @override
  String get intercityCochabamba => 'La ciudad del valle';

  @override
  String get intercityConcepcion => 'Misiones jesuíticas de Chiquitos';

  @override
  String get intercityContinue => 'Ver vehículos y precio';

  @override
  String get intercityEstimateNote => 'Distancia y precio estimados desde el centro en Business. El precio final se calcula con tu dirección real y queda fijo al reservar.';

  @override
  String get intercityEyebrow => 'Ciudad a ciudad';

  @override
  String get intercityFormEyebrow => 'Viaje privado';

  @override
  String intercityFormTitle(String city) {
    return 'A $city';
  }

  @override
  String get intercityHomeLink => 'Viajes a otras ciudades';

  @override
  String get intercityIncChauffeurBody => 'Con licencia, antecedentes y SOAT revisados y vigentes.';

  @override
  String get intercityIncChauffeurTitle => 'Chófer verificado';

  @override
  String get intercityIncFixedBody => 'Lo ves y lo confirmas antes de reservar; no cambia en el camino.';

  @override
  String get intercityIncFixedTitle => 'Precio fijo';

  @override
  String get intercityIncTrackingBody => 'Ves dónde está tu chófer y cuánto falta para llegar.';

  @override
  String get intercityIncTrackingTitle => 'Seguimiento en vivo';

  @override
  String get intercityIncludedTitle => 'En cada viaje';

  @override
  String get intercityIntro => 'Te recogemos donde estés y te llevamos puerta a puerta, con el precio fijado antes de salir. Elige un destino para empezar.';

  @override
  String get intercityMontero => 'Norte integrado de Santa Cruz';

  @override
  String get intercityOtherDestination => '¿Otro destino? Escríbelo en el inicio';

  @override
  String get intercityPickupRequired => 'Indica dónde te recogemos.';

  @override
  String get intercitySamaipata => 'Valles y El Fuerte, Patrimonio de la Humanidad';

  @override
  String get intercitySanJose => 'Misiones jesuíticas de Chiquitos';

  @override
  String get intercityTimeInPast => 'Elige una fecha y hora futuras.';

  @override
  String get intercityTitle => 'Viajes privados desde Santa Cruz';

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
  String get loyaltyAdminIntro => 'Programa de fidelidad por niveles según los viajes completados en los últimos 12 meses. Cada nivel da un descuento sobre la tarifa. Tú decides los umbrales y los porcentajes.';

  @override
  String get loyaltyAdminTitle => 'Luxelane Circle';

  @override
  String loyaltyBenefit(String pct) {
    return 'Tienes $pct % de descuento en cada viaje.';
  }

  @override
  String get loyaltyDisabledHint => 'Apagado: nadie ve el programa ni recibe descuentos.';

  @override
  String loyaltyDiscountLine(String tier) {
    return 'Descuento Circle $tier';
  }

  @override
  String get loyaltyDiscountPct => 'Descuento %';

  @override
  String get loyaltyEnable => 'Programa activo';

  @override
  String get loyaltyEnabledHint => 'Los clientes ven su nivel en el perfil y el descuento se aplica al cotizar.';

  @override
  String get loyaltyErrorDiscounts => 'Cada nivel debe dar al menos el mismo descuento que el anterior.';

  @override
  String get loyaltyErrorMinRides => 'Ingresa al menos 1 viaje para cada nivel.';

  @override
  String get loyaltyErrorRange => 'El descuento debe estar entre 0 y 20 %.';

  @override
  String get loyaltyErrorThresholds => 'Cada nivel debe pedir más viajes que el anterior.';

  @override
  String get loyaltyGold => 'Gold';

  @override
  String get loyaltyHowItWorks => 'Cuentan los viajes completados en los últimos 12 meses. No se suma a códigos promocionales.';

  @override
  String get loyaltyMember => 'Miembro';

  @override
  String get loyaltyMinRides => 'Viajes en 12 meses';

  @override
  String get loyaltyNoBenefitYet => 'Completa viajes para subir de nivel y obtener descuentos.';

  @override
  String get loyaltyPlatinum => 'Platinum';

  @override
  String get loyaltyProgramName => 'Luxelane Circle';

  @override
  String get loyaltyRulesNote => 'El descuento no se suma a un código promocional: se aplica el mayor de los dos. Solo cuentan los viajes completados.';

  @override
  String get loyaltySave => 'Guardar';

  @override
  String get loyaltySaved => 'Programa de fidelidad guardado';

  @override
  String loyaltySavedLine(String amount, String tier) {
    return 'Ahorras $amount por ser Circle $tier';
  }

  @override
  String get loyaltySilver => 'Silver';

  @override
  String loyaltyToNext(int count, String tier, String pct) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes más para $tier ($pct %)',
      one: '1 viaje más para $tier ($pct %)',
    );
    return '$_temp0';
  }

  @override
  String loyaltyTopTier(int rides) {
    String _temp0 = intl.Intl.pluralLogic(
      rides,
      locale: localeName,
      other: 'Nivel máximo · $rides viajes en 12 meses',
      one: 'Nivel máximo · 1 viaje en 12 meses',
    );
    return '$_temp0';
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
  String get paymentsAccountNotSetUp => 'La cuenta no está configurada para pagos';

  @override
  String get paymentsAdd => 'Agregar';

  @override
  String get paymentsAddCard => 'Agregar tarjeta';

  @override
  String get paymentsAddMethodTitle => 'Agregar método de pago';

  @override
  String get paymentsAddNewCard => 'Agregar nueva tarjeta';

  @override
  String get paymentsCardAdded => 'Tarjeta agregada exitosamente';

  @override
  String get paymentsCardDetails => 'Datos de la tarjeta';

  @override
  String paymentsCardExpires(String month, String year) {
    return 'Vence $month/$year';
  }

  @override
  String get paymentsCardFallback => 'Tarjeta';

  @override
  String get paymentsCardIncomplete => 'Ingresa los datos completos de la tarjeta';

  @override
  String get paymentsDefault => 'Predeterminada';

  @override
  String get paymentsEmptyBody => 'Agrega una tarjeta para reservar viajes';

  @override
  String get paymentsEmptyTitle => 'Sin métodos de pago';

  @override
  String get paymentsError => 'No pudimos completar la operación con tu tarjeta. Inténtalo de nuevo.';

  @override
  String get paymentsMethodsTitle => 'Métodos de pago';

  @override
  String get paymentsRemoveCard => 'Eliminar tarjeta';

  @override
  String get paymentsSavedCards => 'Tarjetas guardadas';

  @override
  String get paymentsSecured => 'Protegido por Stripe';

  @override
  String get paymentsSecuredPci => 'Protegido por Stripe · Cumplimiento PCI DSS';

  @override
  String get paymentsSetDefault => 'Predeterminar';

  @override
  String get profileContactHelp => 'Contacto y ayuda';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileLoadError => 'No pudimos cargar tu perfil';

  @override
  String get profileNameLabel => 'Nombre';

  @override
  String get profileSaveChanges => 'Guardar cambios';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileSectionHelp => 'Ayuda y legal';

  @override
  String get profileSectionStats => 'Estadísticas';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileStatRating => 'Calificación';

  @override
  String get profileStatTrips => 'Viajes';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String profileVersion(String version) {
    return 'Luxelane v$version';
  }

  @override
  String get promoAdminActive => 'Activo';

  @override
  String get promoAdminCap => 'Tope (Bs, opcional)';

  @override
  String get promoAdminClasses => 'Categorías (ninguna marcada = todas)';

  @override
  String get promoAdminCode => 'Código';

  @override
  String get promoAdminCodeHint => 'Ej.: BIENVENIDO';

  @override
  String get promoAdminCreate => 'Nuevo código';

  @override
  String get promoAdminDescription => 'Descripción interna';

  @override
  String get promoAdminDescriptionHint => 'Ej.: campaña de lanzamiento';

  @override
  String get promoAdminEdit => 'Editar';

  @override
  String promoAdminEditTitle(String code) {
    return 'Editar $code';
  }

  @override
  String get promoAdminEmpty => 'Todavía no hay códigos.';

  @override
  String get promoAdminErrorCode => 'El código debe tener de 3 a 20 letras, números, guion o guion bajo.';

  @override
  String get promoAdminErrorDates => 'La fecha de fin debe ser posterior a la de inicio.';

  @override
  String get promoAdminErrorExists => 'Ya existe un código con ese nombre.';

  @override
  String get promoAdminErrorValue => 'Revisa el descuento: un porcentaje va de 1 a 100 y un monto debe ser mayor a 0.';

  @override
  String get promoAdminExhausted => 'Agotado';

  @override
  String get promoAdminExpired => 'Vencido';

  @override
  String get promoAdminFirstRide => 'Solo primer viaje';

  @override
  String get promoAdminFirstRideSwitch => 'Solo para el primer viaje del pasajero';

  @override
  String get promoAdminFixed => 'Monto fijo';

  @override
  String promoAdminFrom(String date) {
    return 'Desde el $date';
  }

  @override
  String get promoAdminFromAny => 'Desde: hoy';

  @override
  String get promoAdminIntro => 'El descuento se valida en el servidor y queda fijado en el precio de la reserva. Si la reserva se cancela, el uso se libera.';

  @override
  String get promoAdminMaxUses => 'Usos totales (vacío = sin límite)';

  @override
  String promoAdminMinFare(String amount) {
    return 'Mínimo $amount';
  }

  @override
  String get promoAdminMinFareLabel => 'Monto mínimo del viaje (Bs, opcional)';

  @override
  String get promoAdminPause => 'Pausar';

  @override
  String get promoAdminPaused => 'Pausado';

  @override
  String get promoAdminPerUser => 'Usos por pasajero';

  @override
  String get promoAdminPercent => 'Porcentaje';

  @override
  String get promoAdminResume => 'Reactivar';

  @override
  String get promoAdminSave => 'Guardar';

  @override
  String get promoAdminSaved => 'Código guardado';

  @override
  String get promoAdminTitle => 'Códigos promocionales';

  @override
  String promoAdminUntil(String date) {
    return 'Hasta el $date';
  }

  @override
  String get promoAdminUntilAny => 'Hasta: sin fecha';

  @override
  String promoAdminUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usos',
      one: '1 uso',
      zero: 'Sin usos',
    );
    return '$_temp0';
  }

  @override
  String promoAdminUsageOf(int used, int max) {
    return '$used de $max usos';
  }

  @override
  String promoAdminValueCapped(String value, String cap) {
    return '$value (máx. $cap)';
  }

  @override
  String get promoAdminValueFixed => 'Descuento (Bs)';

  @override
  String get promoAdminValuePercent => 'Descuento (%)';

  @override
  String promoApplied(String code) {
    return 'Código $code aplicado';
  }

  @override
  String promoAppliedWithDiscount(String code, String amount) {
    return '$code: −$amount';
  }

  @override
  String get promoApply => 'Aplicar';

  @override
  String promoDiscountLine(String code) {
    return 'Descuento $code';
  }

  @override
  String get promoErrorAlreadyUsed => 'Ya usaste este código.';

  @override
  String get promoErrorExhausted => 'Ese código ya alcanzó su límite de usos.';

  @override
  String get promoErrorExpired => 'Ese código ya venció.';

  @override
  String get promoErrorFailed => 'No pudimos verificar el código. Inténtalo de nuevo.';

  @override
  String get promoErrorFirstRideOnly => 'Este código es solo para tu primer viaje.';

  @override
  String get promoErrorInvalid => 'Ese código no existe o no está activo.';

  @override
  String get promoErrorMinFare => 'El viaje no alcanza el monto mínimo de este código.';

  @override
  String get promoErrorNoLongerValid => 'El código dejó de ser válido. Revisa el precio e inténtalo de nuevo.';

  @override
  String get promoErrorNotStarted => 'Ese código todavía no está vigente.';

  @override
  String get promoErrorVehicleClass => 'Este código no aplica a esta categoría de vehículo.';

  @override
  String get promoFieldLabel => 'Código promocional';

  @override
  String get promoLoyaltyBetter => 'Tu descuento Circle es mayor que el del código, así que aplicamos el Circle.';

  @override
  String get promoRemove => 'Quitar código';

  @override
  String promoSavedLine(String amount, String code) {
    return 'Ahorras $amount con $code';
  }

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
  String get rideCancelBooking => 'Cancelar reserva';

  @override
  String get rideCancelChauffeurNotified => 'Avisaremos a tu chófer.';

  @override
  String get rideCancelConfirm => 'Sí, cancelar';

  @override
  String get rideCancelDone => 'Tu reserva fue cancelada.';

  @override
  String get rideCancelFailed => 'No pudimos cancelar la reserva. Inténtalo de nuevo.';

  @override
  String get rideCancelFree => 'La cancelación es gratuita: faltan más de 1 hora para la recogida.';

  @override
  String get rideCancelKeep => 'Mantener reserva';

  @override
  String get rideCancelLate => 'Faltan menos de 1 hora para la recogida. Revisa nuestros términos sobre cancelaciones tardías.';

  @override
  String get rideCancelNotAllowed => 'Esta reserva ya no se puede cancelar desde la app.';

  @override
  String get rideCancelTitle => '¿Cancelar esta reserva?';

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
  String get routerGoHome => 'Ir al inicio';

  @override
  String get routerNotFoundBody => 'La página que buscas no existe o se ha movido.';

  @override
  String get routerNotFoundTitle => 'Página no encontrada';

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
  String settleChangedSincePaid(String amount) {
    return 'Cambió desde que se liquidó (entonces: $amount)';
  }

  @override
  String get settleColBalance => 'Saldo (+ Luxelane paga)';

  @override
  String get settleColByDriver => 'Cobrado por el chófer';

  @override
  String get settleColByLuxelane => 'Cobrado por Luxelane';

  @override
  String get settleColCommission => 'Comisión';

  @override
  String get settleColGross => 'Total de viajes';

  @override
  String get settleCommissionEdit => 'Cambiar';

  @override
  String get settleCommissionHelp => 'Porcentaje que Luxelane retiene de cada viaje completado. Se aplica a las semanas que liquides desde ahora; las ya liquidadas guardan el porcentaje de ese momento.';

  @override
  String settleCommissionIs(String pct) {
    return 'Comisión de Luxelane: $pct % por viaje';
  }

  @override
  String get settleCommissionLabel => 'Comisión (%)';

  @override
  String get settleCommissionMissing => 'Aún no definiste la comisión de Luxelane. Defínela para calcular las liquidaciones.';

  @override
  String get settleCommissionRange => 'Ingresa un porcentaje entre 0 y 50.';

  @override
  String get settleCommissionSaved => 'Comisión guardada';

  @override
  String get settleCommissionSet => 'Definir';

  @override
  String get settleCommissionTitle => 'Comisión de Luxelane';

  @override
  String settleDriverBreakdown(String gross, String pct, String commission) {
    return '$gross en viajes − $pct % de comisión ($commission)';
  }

  @override
  String settleDriverEarnings(String amount) {
    return 'Tus ganancias: $amount';
  }

  @override
  String settleDriverGrossOnly(String amount) {
    return 'Total de tus viajes: $amount';
  }

  @override
  String get settleDriverHow => 'Lo que cobraste en efectivo o QR ya es tuyo: de esos viajes debes la comisión. De los viajes de empresas o tarjeta, Luxelane te paga el monto menos la comisión.';

  @override
  String get settleDriverNoCommission => 'La comisión todavía no está configurada; verás tu saldo cuando lo esté.';

  @override
  String get settleDriverNoTrips => 'Sin viajes completados.';

  @override
  String settleDriverOwes(String amount) {
    return 'El chófer debe $amount';
  }

  @override
  String settleDriverPays(String amount) {
    return 'Debes a Luxelane $amount';
  }

  @override
  String settleDriverReceives(String amount) {
    return 'Luxelane te paga $amount';
  }

  @override
  String get settleDriverTitle => 'Liquidación semanal';

  @override
  String get settleEven => 'Saldo en cero';

  @override
  String get settleExport => 'Exportar semana (CSV)';

  @override
  String get settleIntro => 'Por semana (lunes a domingo). En los viajes que cobra el chófer (efectivo o QR), el chófer le debe la comisión a Luxelane. En los que cobra Luxelane (empresas o tarjeta), Luxelane le paga al chófer el monto menos la comisión. El saldo dice quién paga a quién.';

  @override
  String get settleLastWeek => 'Semana pasada';

  @override
  String settleLuxelanePays(String amount) {
    return 'Luxelane paga $amount';
  }

  @override
  String get settleMarkPaid => 'Marcar liquidado';

  @override
  String get settleNeedsCommission => 'Define la comisión para ver las liquidaciones.';

  @override
  String get settleNextWeek => 'Semana siguiente';

  @override
  String get settleNoTrips => 'No hay viajes completados esta semana.';

  @override
  String get settlePaid => 'Liquidado';

  @override
  String settlePaidOn(String date) {
    return 'Liquidado el $date';
  }

  @override
  String get settlePrevWeek => 'Semana anterior';

  @override
  String get settleSave => 'Guardar';

  @override
  String get settleStatCommission => 'Comisión de Luxelane';

  @override
  String get settleStatToCollect => 'Los chóferes deben';

  @override
  String get settleStatToPay => 'Luxelane debe pagar';

  @override
  String get settleThisWeek => 'Esta semana';

  @override
  String get settleTitle => 'Liquidaciones a chóferes';

  @override
  String get settleUndo => 'Deshacer';

  @override
  String settleWeekRange(String from, String to) {
    return '$from – $to';
  }

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
  String get supportAdminEmpty => 'No hay solicitudes en esta vista.';

  @override
  String get supportAdminTitle => 'Solicitudes de soporte';

  @override
  String get supportCatApp => 'La app';

  @override
  String get supportCatBilling => 'Pagos y facturación';

  @override
  String get supportCatChauffeur => 'El chófer';

  @override
  String get supportCatLostItem => 'Objeto olvidado';

  @override
  String get supportCatOther => 'Otro';

  @override
  String get supportCatSafety => 'Seguridad';

  @override
  String get supportCatTrip => 'Un viaje';

  @override
  String get supportCategoryQuestion => '¿Sobre qué es?';

  @override
  String get supportContactBody => 'Escríbenos y te responde una persona del equipo de Luxelane. Te avisamos cuando haya respuesta.';

  @override
  String get supportContactTitle => '¿Necesitas ayuda?';

  @override
  String get supportEmergencyNote => 'En una emergencia llama primero al 110 (Policía).';

  @override
  String get supportFaqCancelA => 'Sí, desde el viaje en la app, hasta que comience. Es gratis si falta más de 1 hora para la recogida; con menos tiempo se considera cancelación tardía según nuestros términos.';

  @override
  String get supportFaqCancelQ => '¿Puedo cancelar una reserva?';

  @override
  String get supportFaqChauffeursA => 'Antes de recibir viajes, revisamos y aprobamos su licencia, cédula, certificado de antecedentes, SOAT y registro del vehículo. Si un documento vence, dejan de recibir viajes hasta renovarlo.';

  @override
  String get supportFaqChauffeursQ => '¿Cómo se verifica a los chóferes?';

  @override
  String get supportFaqCorporateA => 'El administrador de tu empresa te agrega con tu correo. Al reservar eliges \"Facturar a la empresa\", con centro de costo y referencia si hace falta. La empresa recibe un estado de cuenta mensual.';

  @override
  String get supportFaqCorporateQ => '¿Cómo funciona la cuenta corporativa?';

  @override
  String get supportFaqLostA => 'Abre el recibo del viaje, toca \"Ayuda con este viaje\" y elige \"Objeto olvidado\". Contactamos al chófer y coordinamos la devolución contigo.';

  @override
  String get supportFaqLostQ => 'Olvidé algo en el vehículo';

  @override
  String get supportFaqPayA => 'El precio en bolivianos queda fijo al reservar. Pagas al chófer al terminar el viaje, en efectivo o QR. Si tu empresa tiene cuenta corporativa, el viaje va a su factura mensual y no pagas nada.';

  @override
  String get supportFaqPayQ => '¿Cómo pago?';

  @override
  String get supportFaqPromoA => 'Escríbelo al reservar, antes de confirmar. Verás el descuento al instante y queda fijado en el precio. Si cancelas, puedes volver a usarlo.';

  @override
  String get supportFaqPromoQ => '¿Cómo uso un código promocional?';

  @override
  String get supportFaqTitle => 'Preguntas frecuentes';

  @override
  String supportFaqWaitA(int airport, int city) {
    return 'En el aeropuerto, $airport minutos gratis desde el aterrizaje de tu vuelo (lo seguimos en tiempo real). En la ciudad, $city minutos gratis desde la hora de recogida o desde que el chófer llega.';
  }

  @override
  String get supportFaqWaitQ => '¿Cuánto tiempo me espera el chófer?';

  @override
  String get supportFillFields => 'Completa el asunto y el mensaje.';

  @override
  String get supportFilterAnswered => 'Esperando al cliente';

  @override
  String supportFilterPending(int count) {
    return 'Por responder ($count)';
  }

  @override
  String get supportFilterResolved => 'Resueltas';

  @override
  String supportFromUser(String name, String role) {
    return '$name ($role)';
  }

  @override
  String get supportHelpCenter => 'Centro de ayuda';

  @override
  String supportLinkedTrip(String code) {
    return 'Vinculada al viaje $code';
  }

  @override
  String get supportMessage => 'Mensaje';

  @override
  String get supportMessageHint => 'Cuéntanos qué pasó';

  @override
  String get supportMyRequests => 'Mis solicitudes';

  @override
  String get supportNewRequest => 'Nueva solicitud';

  @override
  String get supportPickCategory => 'Elige una opción.';

  @override
  String get supportReopen => 'Reabrir';

  @override
  String get supportReopenedDone => 'Solicitud reabierta';

  @override
  String get supportResolve => 'Ya está resuelto';

  @override
  String get supportResolveTeam => 'Marcar resuelta';

  @override
  String get supportResolvedDone => 'Solicitud resuelta';

  @override
  String get supportResolvedHint => 'Esta solicitud está resuelta. Si escribes, se vuelve a abrir.';

  @override
  String get supportSafetyNote => 'Los reportes de seguridad se atienden primero. Si estás en peligro ahora, llama al 110.';

  @override
  String get supportSend => 'Enviar';

  @override
  String get supportSendFailed => 'No se pudo enviar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get supportSent => 'Solicitud enviada. Te avisaremos cuando respondamos.';

  @override
  String get supportStatusAnswered => 'Respondida';

  @override
  String get supportStatusAnsweredTeam => 'Esperando al cliente';

  @override
  String get supportStatusOpen => 'Enviada';

  @override
  String get supportStatusOpenTeam => 'Por responder';

  @override
  String get supportStatusResolved => 'Resuelta';

  @override
  String get supportSubject => 'Asunto';

  @override
  String get supportSubjectHint => 'En pocas palabras';

  @override
  String get supportTeamName => 'Equipo Luxelane';

  @override
  String get supportTitle => 'Ayuda';

  @override
  String get supportTripHelpBody => 'Tu solicitud quedará vinculada al viaje para que el equipo vea todos los detalles.';

  @override
  String get supportTripHelpCta => 'Ayuda con este viaje';

  @override
  String get supportTripHelpTitle => 'Ayuda con este viaje';

  @override
  String supportTripRef(String code) {
    return 'Viaje $code';
  }

  @override
  String get supportUnread => 'No leída';

  @override
  String get supportUrgent => 'Urgente';

  @override
  String supportUrgentBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reportes de seguridad sin responder',
      one: '1 reporte de seguridad sin responder',
    );
    return '$_temp0';
  }

  @override
  String get supportWriteHint => 'Escribe un mensaje';

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
  String tripPriceDaysLine(int days, int hours, String rate) {
    return '$days días × $hours h × $rate';
  }

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
  String tripsRouteByDays(String origin, int days, int hours) {
    return '$origin · $days días × $hours h';
  }

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
