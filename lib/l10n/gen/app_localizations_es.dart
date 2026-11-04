// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get adminDrvAppSection => 'Solicitudes de chófer';

  @override
  String get adminDrvAppSectionSubtitle =>
      'Datos, vehículo y documentos de quienes quieren conducir.';

  @override
  String get adminDrvAppTabInbox => 'Solicitudes';

  @override
  String get adminDrvAppTabExpiries => 'Vencimientos próximos';

  @override
  String get adminDrvAppReload => 'Recargar';

  @override
  String get adminDrvAppRetry => 'Reintentar';

  @override
  String get adminDrvAppStatusFilter => 'Filtrar por estado';

  @override
  String get adminDrvAppInboxEmpty => 'No hay solicitudes en este estado';

  @override
  String get adminDrvAppInboxEmptyHint =>
      'Elige otro estado arriba para ver más.';

  @override
  String get adminDrvAppInboxError => 'No se pudieron cargar las solicitudes.';

  @override
  String adminDrvAppInboxTruncated(String count) {
    return 'Se muestran las $count más recientes.';
  }

  @override
  String adminDrvAppSubmittedAt(String date) {
    return 'Enviada el $date';
  }

  @override
  String adminDrvAppUpdatedAt(String date) {
    return 'Actualizada el $date';
  }

  @override
  String get adminDrvAppNoName => 'Sin nombre';

  @override
  String adminDrvAppOpen(String name) {
    return 'Abrir la solicitud de $name';
  }

  @override
  String get adminDrvAppOpenShort => 'Ver solicitud';

  @override
  String get adminDrvAppBack => 'Volver a la bandeja';

  @override
  String get adminDrvAppDetailError => 'No se pudo cargar la solicitud.';

  @override
  String get adminDrvAppPersonalTitle => 'Datos personales';

  @override
  String get adminDrvAppPersonalMissing =>
      'Aún no completó sus datos personales.';

  @override
  String get adminDrvAppFullName => 'Nombre completo';

  @override
  String get adminDrvAppNationalId => 'Número de documento';

  @override
  String get adminDrvAppLicenseNumber => 'Número de licencia';

  @override
  String get adminDrvAppLicenseExpiry => 'Vencimiento de la licencia';

  @override
  String get adminDrvAppEmail => 'Correo';

  @override
  String get adminDrvAppStatus => 'Estado';

  @override
  String get adminDrvAppVehicleTitle => 'Vehículo';

  @override
  String get adminDrvAppVehicleMissing => 'Aún no registró el vehículo.';

  @override
  String get adminDrvAppMake => 'Marca';

  @override
  String get adminDrvAppModel => 'Modelo';

  @override
  String get adminDrvAppYear => 'Año';

  @override
  String get adminDrvAppColor => 'Color';

  @override
  String get adminDrvAppPlate => 'Placa';

  @override
  String get adminDrvAppBodyType => 'Carrocería';

  @override
  String get adminDrvAppPassengers => 'Pasajeros';

  @override
  String get adminDrvAppClass => 'Clase';

  @override
  String get adminDrvAppPendingVehicle =>
      'Cambio de vehículo pendiente de revisión.';

  @override
  String get adminDrvAppDocsTitle => 'Documentos';

  @override
  String get adminDrvAppRequirementsMissing => 'Requisitos sin configurar';

  @override
  String get adminDrvAppRequirementsMissingBody =>
      'Falta la lista driverRequirements en config/ops: el chófer no puede enviar la solicitud y no se puede aprobar. Se muestran los documentos subidos.';

  @override
  String get adminDrvAppRequired => 'Obligatorio';

  @override
  String get adminDrvAppOptional => 'Opcional';

  @override
  String get adminDrvAppNotRequested => 'Fuera de los requisitos';

  @override
  String adminDrvAppDocVersion(String version) {
    return 'Versión $version';
  }

  @override
  String adminDrvAppDocExpires(String date) {
    return 'Vence el $date';
  }

  @override
  String adminDrvAppDocExpired(String date) {
    return 'Venció el $date';
  }

  @override
  String get adminDrvAppDocExpiryMissing => 'Sin fecha de vencimiento';

  @override
  String adminDrvAppDocRejectReason(String reason) {
    return 'Motivo del rechazo: $reason';
  }

  @override
  String adminDrvAppDocNote(String note) {
    return 'Nota: $note';
  }

  @override
  String get adminDrvAppDocNotUploaded => 'Sin subir';

  @override
  String get adminDrvAppViewDoc => 'Ver documento';

  @override
  String adminDrvAppViewDocLabel(String document) {
    return 'Ver documento: $document';
  }

  @override
  String get adminDrvAppApproveDoc => 'Aprobar';

  @override
  String adminDrvAppApproveDocLabel(String document) {
    return 'Aprobar documento: $document';
  }

  @override
  String get adminDrvAppRejectDoc => 'Rechazar';

  @override
  String adminDrvAppRejectDocLabel(String document) {
    return 'Rechazar documento: $document';
  }

  @override
  String adminDrvAppApproveTitle(String document) {
    return '¿Aprobar $document?';
  }

  @override
  String adminDrvAppApproveBody(String version) {
    return 'Se aprueba la versión $version. Queda en la auditoría con tu cuenta.';
  }

  @override
  String get adminDrvAppApproveConfirm => 'Aprobar documento';

  @override
  String get adminDrvAppDocApproved => 'Documento aprobado.';

  @override
  String get adminDrvAppDocRejected =>
      'Documento rechazado. El chófer verá el motivo.';

  @override
  String adminDrvAppRejectTitle(String document) {
    return 'Rechazar $document';
  }

  @override
  String get adminDrvAppRejectReasonLabel => 'Motivo del rechazo';

  @override
  String get adminDrvAppRejectReasonHint => 'Elige un motivo';

  @override
  String get adminDrvAppRejectReasonRequired =>
      'Elige un motivo para rechazar.';

  @override
  String get adminDrvAppRejectNoteLabel => 'Nota para el chófer (opcional)';

  @override
  String get adminDrvAppRejectConfirm => 'Rechazar documento';

  @override
  String get adminDrvAppCancel => 'Cancelar';

  @override
  String get adminDrvAppClose => 'Cerrar';

  @override
  String get adminDrvAppViewerLoading => 'Abriendo el documento…';

  @override
  String get adminDrvAppViewerExpiry =>
      'El enlace caduca en 5 minutos. Si caduca, cierra el visor y vuelve a abrirlo.';

  @override
  String get adminDrvAppViewerLogged =>
      'Cada apertura queda en la bitácora de accesos.';

  @override
  String get adminDrvAppViewerPdf => 'Este documento es un PDF.';

  @override
  String get adminDrvAppViewerOpenPdf => 'Abrir PDF en otra pestaña';

  @override
  String get adminDrvAppViewerPdfError =>
      'No se pudo abrir el PDF. Cierra el visor y vuelve a intentarlo.';

  @override
  String get adminDrvAppViewerImageError =>
      'No se pudo mostrar la imagen. Si el enlace caducó, cierra el visor y vuelve a abrirlo.';

  @override
  String adminDrvAppViewerImageLabel(String document) {
    return 'Imagen del documento: $document';
  }

  @override
  String get adminDrvAppViewerError => 'No se pudo abrir el documento.';

  @override
  String get adminDrvAppDecide => 'Decisión final';

  @override
  String get adminDrvAppDecisionTitle => 'Decisión final de la solicitud';

  @override
  String get adminDrvAppDecisionBody =>
      'Aprobar exige todos los documentos obligatorios aprobados y vigentes. El chófer recibe un aviso con el resultado.';

  @override
  String get adminDrvAppDecisionApprove => 'Aprobar';

  @override
  String get adminDrvAppDecisionNeedsChanges => 'Pedir cambios';

  @override
  String get adminDrvAppDecisionReject => 'Rechazar';

  @override
  String get adminDrvAppDecisionReasonLabel => 'Motivo (queda en la auditoría)';

  @override
  String adminDrvAppDecisionReasonHint(String min, String max) {
    return 'Entre $min y $max caracteres';
  }

  @override
  String adminDrvAppDecisionReasonShort(String min) {
    return 'Escribe al menos $min caracteres.';
  }

  @override
  String get adminDrvAppDecisionConfirm => 'Confirmar decisión';

  @override
  String get adminDrvAppDecisionNotDecidable =>
      'Solo se decide una solicitud enviada, en revisión o con cambios pedidos.';

  @override
  String adminDrvAppDecisionDone(String status) {
    return 'Decisión guardada: $status.';
  }

  @override
  String adminDrvAppErrDocsNotApproved(String documents) {
    return 'No se puede aprobar: estos documentos obligatorios no están aprobados o vigentes: $documents.';
  }

  @override
  String get adminDrvAppErrDocsNotApprovedAny =>
      'No se puede aprobar: hay documentos obligatorios sin aprobar o vencidos.';

  @override
  String get adminDrvAppErrStaleVersion =>
      'El chófer subió una versión nueva; recarga la solicitud.';

  @override
  String get adminDrvAppErrNotReviewable =>
      'Este documento no se puede revisar en su estado actual.';

  @override
  String get adminDrvAppErrNotDecidable =>
      'Esta solicitud ya no admite decisión; recarga.';

  @override
  String get adminDrvAppErrRequirements =>
      'Requisitos sin configurar: no se puede aprobar.';

  @override
  String get adminDrvAppErrStepsIncomplete =>
      'Faltan pasos de la solicitud (datos personales o vehículo).';

  @override
  String get adminDrvAppErrNotFound =>
      'No se encontró el documento o el chófer; recarga.';

  @override
  String get adminDrvAppErrInvalid =>
      'Revisa los datos: el motivo necesita entre 10 y 500 caracteres.';

  @override
  String get adminDrvAppErrPermission =>
      'Permiso denegado: se necesita rol de administrador.';

  @override
  String get adminDrvAppErrGeneric =>
      'No se pudo completar. Inténtalo de nuevo en unos minutos.';

  @override
  String get adminDrvAppAccessLog => 'Bitácora de accesos';

  @override
  String get adminDrvAppAccessLogHint =>
      'Quién abrió cada documento de esta solicitud y cuándo, de lo más reciente a lo más antiguo.';

  @override
  String get adminDrvAppAccessLogEmpty =>
      'Nadie abrió todavía los documentos de esta solicitud.';

  @override
  String get adminDrvAppAccessLogError =>
      'No se pudo cargar la bitácora de accesos.';

  @override
  String adminDrvAppAccessLogEntry(String document, String version) {
    return '$document · versión $version';
  }

  @override
  String adminDrvAppAccessLogWho(String who, String date) {
    return '$who · $date';
  }

  @override
  String adminDrvAppUnknownAdmin(String id) {
    return 'Administrador $id';
  }

  @override
  String adminDrvAppExpiriesPeriod(String days) {
    return 'Próximos $days días';
  }

  @override
  String adminDrvAppExpiriesEmpty(String days) {
    return 'Ningún documento vence en los próximos $days días.';
  }

  @override
  String get adminDrvAppExpiriesError =>
      'No se pudieron cargar los vencimientos.';

  @override
  String adminDrvAppExpiriesTruncated(String count) {
    return 'Hay más resultados; se muestran los $count primeros. Acorta el periodo para ver el resto.';
  }

  @override
  String get adminDrvAppBlocked => 'Bloqueado para ponerse en línea';

  @override
  String get adminDrvAppAllowOnline => 'Autorizar en línea';

  @override
  String adminDrvAppAllowOnlineLabel(String name) {
    return 'Autorizar en línea a $name';
  }

  @override
  String get adminDrvAppAllowOnlineTitle =>
      'Autorizar en línea con documentos vencidos';

  @override
  String adminDrvAppAllowOnlineBody(String name) {
    return '$name podrá ponerse en línea pese a los documentos vencidos actuales, hasta que venza otro. Queda en la auditoría con tu motivo.';
  }

  @override
  String get adminDrvAppAllowOnlineConfirm => 'Autorizar';

  @override
  String get adminDrvAppAllowOnlineDone =>
      'Chófer autorizado para ponerse en línea.';

  @override
  String get adminFlightsSection => 'Vuelos';

  @override
  String get adminFlightsSectionSubtitle =>
      'Vuelos de llegada por revisar y aeropuertos con sus puntos de recogida.';

  @override
  String get adminFlightsTabInbox => 'Bandeja';

  @override
  String get adminFlightsTabAirports => 'Aeropuertos';

  @override
  String get adminFlightsInboxToVerify => 'Por verificar';

  @override
  String get adminFlightsInboxNoData => 'Sin datos';

  @override
  String get adminFlightsInboxDisrupted => 'Cancelados o desviados';

  @override
  String adminFlightsInboxTruncated(String count) {
    return 'Se leyeron las primeras $count reservas con vuelo: puede haber más.';
  }

  @override
  String get adminFlightsInboxEmptyToVerify => 'No hay vuelos por verificar';

  @override
  String get adminFlightsInboxEmptyNoData => 'No hay vuelos sin datos';

  @override
  String get adminFlightsInboxEmptyDisrupted =>
      'No hay vuelos cancelados ni desviados';

  @override
  String get adminFlightsInboxEmptyHint =>
      'Aquí aparecen las reservas con vuelo que piden revisión.';

  @override
  String get adminFlightsInboxError => 'No se pudo cargar la bandeja de vuelos';

  @override
  String get adminFlightsRetry => 'Reintentar';

  @override
  String adminFlightsRowReadyAt(String time) {
    return 'Chófer en el punto: $time';
  }

  @override
  String get adminFlightsRowNoReadyAt => 'Sin hora de recogida';

  @override
  String adminFlightsRowSemantics(String code, String flight, String status) {
    return 'Reserva $code, vuelo $flight, $status. Abrir el detalle';
  }

  @override
  String adminFlightsBookingTitle(String code) {
    return 'Reserva #$code';
  }

  @override
  String get adminFlightsClose => 'Cerrar';

  @override
  String get adminFlightCardTitle => 'Vuelo';

  @override
  String get adminFlightAirport => 'Aeropuerto';

  @override
  String get adminFlightAirline => 'Aerolínea';

  @override
  String get adminFlightNumber => 'Número de vuelo';

  @override
  String get adminFlightType => 'Tipo';

  @override
  String get adminFlightDate => 'Fecha del vuelo';

  @override
  String get adminFlightScheduled => 'Llegada programada';

  @override
  String get adminFlightEstimated => 'Llegada estimada';

  @override
  String get adminFlightActual => 'Llegada real';

  @override
  String get adminFlightStatus => 'Estado del vuelo';

  @override
  String get adminFlightQuality => 'Calidad del dato';

  @override
  String get adminFlightQualityOk => 'Al día';

  @override
  String get adminFlightQualityStale => 'Desactualizado';

  @override
  String get adminFlightQualityNone => 'Sin datos en vivo';

  @override
  String get adminFlightSource => 'Fuente';

  @override
  String get adminFlightSourcePassenger => 'Pasajero';

  @override
  String get adminFlightSourceManual => 'Central';

  @override
  String get adminFlightSourceAuto => 'Automático';

  @override
  String get adminFlightCheckedBag => 'Equipaje facturado';

  @override
  String get adminFlightYes => 'Sí';

  @override
  String get adminFlightNo => 'No';

  @override
  String get adminFlightLastChange => 'Último cambio';

  @override
  String get adminFlightLastObserved => 'Último dato leído';

  @override
  String get adminFlightTimesNote => 'Horas de Bolivia (La Paz, UTC−4).';

  @override
  String adminFlightReadyAt(String time) {
    return 'El chófer debe estar a las $time';
  }

  @override
  String get adminFlightNoReadyAt => 'Sin hora de recogida calculada';

  @override
  String get adminFlightLocked =>
      'Bloqueo manual: las fuentes automáticas no cambian estos datos.';

  @override
  String get adminFlightUnlocked => 'Sin bloqueo manual';

  @override
  String get adminFlightLockTag => 'Bloqueo manual';

  @override
  String adminFlightSetBy(String who, String date) {
    return 'Fijado por $who el $date';
  }

  @override
  String adminFlightLockClearedBy(String who, String date) {
    return 'Bloqueo quitado por $who el $date';
  }

  @override
  String adminFlightChangeReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get adminFlightAdminUnknown => 'un administrador';

  @override
  String get adminFlightLoadError => 'No se pudieron leer los datos del vuelo';

  @override
  String get adminFlightSetButton => 'Fijar datos del vuelo';

  @override
  String get adminFlightClearLockButton => 'Quitar bloqueo manual';

  @override
  String get adminFlightForceNoShowButton => 'Marcar no se presentó';

  @override
  String get adminFlightSetTitle => 'Fijar datos del vuelo';

  @override
  String get adminFlightSetMessage =>
      'Los datos quedan fijados a mano, con bloqueo manual: ninguna fuente automática los cambia hasta quitar el bloqueo. La hora del chófer se vuelve a calcular.';

  @override
  String get adminFlightSetStatusLabel => 'Estado del vuelo';

  @override
  String get adminFlightSetPick => 'Elegir fecha y hora';

  @override
  String get adminFlightSetClearTime => 'Quitar hora';

  @override
  String get adminFlightSetNoTime => 'Sin hora';

  @override
  String adminFlightSetTimeSemantics(String label, String value) {
    return '$label: $value. Cambiar';
  }

  @override
  String get adminFlightSetActualRequired =>
      'Con «Aterrizó» la llegada real es obligatoria';

  @override
  String get adminFlightReasonLabel => 'Motivo (de 10 a 500 caracteres)';

  @override
  String get adminFlightReasonShort =>
      'El motivo necesita al menos 10 caracteres';

  @override
  String get adminFlightCancel => 'Cancelar';

  @override
  String get adminFlightSetConfirm => 'Fijar datos';

  @override
  String get adminFlightSetDone => 'Datos del vuelo fijados';

  @override
  String get adminFlightClearLockTitle => 'Quitar bloqueo manual';

  @override
  String get adminFlightClearLockMessage =>
      'Las fuentes automáticas podrán volver a actualizar este vuelo.';

  @override
  String get adminFlightClearLockConfirm => 'Quitar bloqueo';

  @override
  String get adminFlightClearLockDone => 'Bloqueo manual quitado';

  @override
  String get adminFlightForceNoShowTitle => 'Marcar no se presentó';

  @override
  String adminFlightForceNoShowMessage(String code) {
    return 'La reserva #$code pasará a «No se presentó». No se cobra nada: el pago se decide después en la reserva.';
  }

  @override
  String get adminFlightForceNoShowConfirm => 'Marcar no se presentó';

  @override
  String get adminFlightForceNoShowDone =>
      'Reserva marcada como no se presentó';

  @override
  String get adminFlightErrConfigMissing =>
      'Faltan los minutos de salida del aeropuerto en la configuración de operaciones.';

  @override
  String get adminFlightErrNoFlight => 'Esta reserva no tiene vuelo.';

  @override
  String get adminFlightErrNotFound => 'La reserva ya no existe.';

  @override
  String get adminFlightErrInvalidTransition =>
      'La reserva ya no está en «Chófer en el punto».';

  @override
  String get adminFlightErrNoShowDisabled =>
      '«No se presentó» no está habilitado: falta la política de cancelación.';

  @override
  String get adminFlightErrInvalid => 'Revisa los datos: alguno no es válido.';

  @override
  String get adminFlightErrPermission => 'No tienes permiso para esta acción.';

  @override
  String get adminFlightErrGeneric =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get adminAirportsAdd => 'Nuevo aeropuerto';

  @override
  String get adminAirportsEmpty => 'Aún no hay aeropuertos';

  @override
  String get adminAirportsEmptyHint =>
      'Crea uno para definir sus puntos de recogida.';

  @override
  String get adminAirportsError => 'No se pudieron cargar los aeropuertos';

  @override
  String adminAirportPointSet(String type) {
    return '$type: con punto';
  }

  @override
  String adminAirportPointMissing(String type) {
    return '$type: sin punto';
  }

  @override
  String adminAirportEditSemantics(String code) {
    return 'Editar el aeropuerto $code';
  }

  @override
  String adminAirportEditTitle(String code) {
    return 'Editar aeropuerto $code';
  }

  @override
  String get adminAirportNewTitle => 'Nuevo aeropuerto';

  @override
  String get adminAirportCode => 'Código (3 letras)';

  @override
  String get adminAirportCodeInvalid =>
      'Tres letras mayúsculas, por ejemplo VVI';

  @override
  String get adminAirportCodeLocked => 'El código no se cambia una vez creado';

  @override
  String get adminAirportName => 'Nombre';

  @override
  String get adminAirportNameInvalid => 'Entre 2 y 120 caracteres';

  @override
  String get adminAirportCity => 'Ciudad';

  @override
  String get adminAirportCityInvalid => 'Entre 2 y 80 caracteres';

  @override
  String get adminAirportTimeZone => 'Zona horaria: La Paz (UTC−4)';

  @override
  String adminAirportPointTitle(String type) {
    return 'Punto de recogida · $type';
  }

  @override
  String get adminAirportPointName => 'Nombre del punto';

  @override
  String get adminAirportPointNameInvalid => 'Entre 1 y 80 caracteres';

  @override
  String get adminAirportPointInstructions => 'Indicaciones';

  @override
  String get adminAirportPointInstructionsInvalid => 'Hasta 500 caracteres';

  @override
  String get adminAirportLat => 'Latitud';

  @override
  String get adminAirportLng => 'Longitud';

  @override
  String get adminAirportLatInvalid => 'Latitud entre -90 y 90';

  @override
  String get adminAirportLngInvalid => 'Longitud entre -180 y 180';

  @override
  String get adminAirportZeroInvalid => 'Las coordenadas (0, 0) no son válidas';

  @override
  String get adminAirportPointRemove => 'Quitar punto';

  @override
  String get adminAirportPointAdd => 'Añadir punto';

  @override
  String get adminAirportPointNone =>
      'Sin punto: el chófer verá «Punto por confirmar con central».';

  @override
  String get adminAirportPointWillRemove => 'El punto se quitará al guardar.';

  @override
  String get adminAirportSave => 'Guardar';

  @override
  String get adminAirportSaved => 'Aeropuerto guardado';

  @override
  String get adminAirportFixErrors => 'Revisa los campos marcados';

  @override
  String get adminAirportErrInvalid =>
      'Algún dato no es válido: revisa código, nombre, ciudad y coordenadas.';

  @override
  String get adminPrefsEmpty => 'Sin preferencias para este viaje';

  @override
  String get adminPrefsLoadingLabel => 'Cargando las preferencias del viaje';

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authLoginWelcomeBack => 'Bienvenido de nuevo a Luxelane.';

  @override
  String get authHomeLinkSemantics => 'Luxelane, ir al inicio';

  @override
  String get authLoginEyebrow => 'BIENVENIDO';

  @override
  String get authLoginHeadline => 'Tu chófer,\ncomo lo recuerdas.';

  @override
  String get authLoginSubtitle =>
      'Inicia sesión para reservar y seguir tus trayectos.';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailInvalid => 'Ingresa un correo válido';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordMinLength => 'Mínimo 6 caracteres';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authResetNeedsEmail =>
      'Escribe tu correo arriba y te enviaremos un enlace.';

  @override
  String get authNoAccount => '¿No tienes cuenta? ';

  @override
  String get authCreateOne => 'Crear una';

  @override
  String get authBrandSubtitle =>
      'Tus direcciones, preferencias y viajes, siempre a mano.';

  @override
  String get authBrandPointBooking => 'Reserva en menos de 2 minutos';

  @override
  String get authBrandPointTrips => 'Todos tus viajes en un solo lugar';

  @override
  String get authBrandPointTracking =>
      'Seguimiento de tu chófer en tiempo real';

  @override
  String get authRegisterEyebrow => 'CREAR CUENTA';

  @override
  String get authRegisterHeadline => 'Bienvenido\na Luxelane.';

  @override
  String get authRegisterSubtitle => 'Crea tu cuenta en menos de un minuto.';

  @override
  String get authRegisterBrandSubtitle =>
      'Una cuenta para reservar, seguir y recordar cada trayecto.';

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authRegisterWebSubtitle =>
      'Solo te pediremos lo necesario para tu chófer.';

  @override
  String get authGoogleRegister => 'Registrarte con Google';

  @override
  String get authNameLabel => 'Nombre completo';

  @override
  String get authNameRequired =>
      'Indica tu nombre para que tu chófer pueda recibirte';

  @override
  String get authPhoneLabel => 'Teléfono (con código de país)';

  @override
  String get authPhoneRequired => 'Tu chófer lo necesita para contactarte';

  @override
  String get authTermsRequired =>
      'Acepta los Términos y la Política de privacidad para continuar';

  @override
  String get authRegisterDataNote =>
      'Tu nombre y teléfono permiten a tu chófer recibirte y contactarte.';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? ';

  @override
  String get authSignInLink => 'Inicia sesión';

  @override
  String get authTermsCheckboxSemantics =>
      'Acepto los Términos y la Política de privacidad';

  @override
  String get authTermsReadPrefix => 'He leído y acepto los ';

  @override
  String get authTermsLink => 'Términos';

  @override
  String get authTermsAnd => ' y la ';

  @override
  String get authPrivacyLink => 'Política de privacidad';

  @override
  String get authGoogleContinue => 'Continuar con Google';

  @override
  String get authOrWithEmail => 'o con tu correo';

  @override
  String get authVerifyTitle => 'Verifica tu correo';

  @override
  String get authVerifySentGeneric => 'Te enviamos un enlace a tu correo.';

  @override
  String authVerifySentTo(String email) {
    return 'Te enviamos un enlace a $email.';
  }

  @override
  String get authVerifyBody =>
      'Ábrelo y vuelve aquí. Necesitas el correo verificado para reservar. Si el enlace venció o no llega, pide uno nuevo (revisa también la carpeta de correo no deseado).';

  @override
  String get authVerifyResent => 'Te enviamos un enlace nuevo.';

  @override
  String get authVerifyDone => 'Correo verificado. Ya puedes reservar.';

  @override
  String get authVerifyNotYet =>
      'Aún no vemos el correo verificado. Abre el enlace que te enviamos y vuelve a intentarlo.';

  @override
  String get authVerifyResendLimit => 'Límite de reenvíos alcanzado';

  @override
  String authVerifyResendIn(int seconds) {
    return 'Reenviar enlace ($seconds s)';
  }

  @override
  String get authVerifyResend => 'Reenviar enlace';

  @override
  String get authVerifyConfirm => 'Ya lo verifiqué';

  @override
  String get authVerifyLater => 'Más tarde';

  @override
  String get authMfaTitle => 'Verificación en dos pasos';

  @override
  String get authMfaCodeDigits => 'Escribe las 6 cifras del código.';

  @override
  String get authCancel => 'Cancelar';

  @override
  String get authMfaSignInPrompt =>
      'Abre tu app autenticadora y escribe el código de Luxelane.';

  @override
  String get authMfaCodeLabel => 'Código';

  @override
  String get authMfaSignInButton => 'Entrar';

  @override
  String get authMfaLostAccess =>
      '¿Perdiste el acceso a tu app autenticadora? Contacta con central para recuperar la cuenta.';

  @override
  String get authMfaEnrollDone =>
      'Listo. A partir de ahora, al iniciar sesión te pediremos el código de tu app autenticadora.';

  @override
  String get authMfaBack => 'Volver';

  @override
  String get authMfaEnrollIntro =>
      'Protege tu cuenta con una app autenticadora (por ejemplo, la que trae tu teléfono o tu gestor de contraseñas). Te pedirá un código de 6 cifras al iniciar sesión.';

  @override
  String get authMfaStart => 'Empezar';

  @override
  String get authMfaScanStep =>
      '1. Escanea este código con tu app autenticadora.';

  @override
  String get authMfaQrSemantics => 'Código QR para la app autenticadora';

  @override
  String get authMfaOpenInApp => 'Abrir en la app autenticadora';

  @override
  String authMfaManualKey(String key) {
    return '¿No puedes escanear? Escribe esta clave: $key';
  }

  @override
  String get authMfaHideKey => 'Ocultar clave';

  @override
  String get authMfaShowKey => 'Mostrar clave';

  @override
  String get authMfaNoShare =>
      'No compartas este código ni la clave, y no hagas capturas.';

  @override
  String get authMfaCodeStep => '2. Escribe el código que muestra la app.';

  @override
  String get authMfaActivate => 'Activar';

  @override
  String get authMfaReminderTitle => 'Activa la verificación en dos pasos';

  @override
  String get authMfaReminderBody =>
      'Pronto será obligatoria para entrar. Tarda un minuto.';

  @override
  String get authReauthConfirmed => 'Identidad confirmada. Repite la acción.';

  @override
  String get authReauthPasswordEmpty => 'Escribe tu contraseña.';

  @override
  String get authReauthTitle => 'Confirma que eres tú';

  @override
  String get authReauthPassword =>
      'Por seguridad, escribe tu contraseña para continuar.';

  @override
  String get authReauthGoogle =>
      'Por seguridad, vuelve a entrar con Google para continuar.';

  @override
  String get authReauthNone =>
      'Por seguridad, cierra sesión y vuelve a entrar para continuar.';

  @override
  String get authConfirm => 'Confirmar';

  @override
  String get authTermsAcceptedSnack => 'Listo. Ya puedes reservar.';

  @override
  String get authTermsDialogTitle => 'Acepta los términos para reservar';

  @override
  String get authTermsDialogBody =>
      'Para reservar necesitamos que aceptes la versión vigente de los Términos y la Política de privacidad.';

  @override
  String get authTermsRead => 'Leer los Términos';

  @override
  String get authPrivacyRead => 'Leer la Política de privacidad';

  @override
  String get authNotNow => 'Ahora no';

  @override
  String get authAccept => 'Acepto';

  @override
  String get authErrorOffline =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get authGoogleGenericError =>
      'No pudimos iniciar sesión con Google. Inténtalo de nuevo.';

  @override
  String get authGoogleAccountExists =>
      'Ya tienes una cuenta con este correo. Inicia sesión con tu contraseña.';

  @override
  String get authGooglePopupBlocked =>
      'Tu navegador bloqueó la ventana de Google. Permite las ventanas emergentes e inténtalo de nuevo.';

  @override
  String get authGoogleUnauthorizedDomain =>
      'Este dominio no está autorizado para iniciar sesión con Google.';

  @override
  String get authGoogleNotEnabled =>
      'El inicio de sesión con Google no está habilitado.';

  @override
  String get authDeleteAccountError =>
      'No pudimos eliminar tu cuenta. Revisa tu conexión.';

  @override
  String get authResetLinkError =>
      'No pudimos enviar el enlace. Inténtalo de nuevo.';

  @override
  String get authVerifyTooMany =>
      'Enviamos varios enlaces seguidos. Espera unos minutos antes de pedir otro.';

  @override
  String get authVerifyOffline =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get authVerifyFailed =>
      'No pudimos completar la verificación. Inténtalo de nuevo.';

  @override
  String get bookingPriceOnRequest => 'Cotiza al reservar';

  @override
  String bookingPriceFrom(String price) {
    return 'desde $price';
  }

  @override
  String get bookingPriceChangedTitle => 'El precio cambió';

  @override
  String bookingPriceChangedBody(String newPrice, String previousPrice) {
    return 'El precio de este viaje es ahora $newPrice (antes $previousPrice). ¿Quieres reservar con el precio nuevo?';
  }

  @override
  String get bookingPriceChangedDecline => 'No reservar';

  @override
  String get bookingPriceChangedAccept => 'Reservar';

  @override
  String get bookingFlightTypeRequired =>
      'Indica si tu vuelo es nacional o internacional.';

  @override
  String get bookingPickupMissing =>
      'Vuelve a indicar tu recogida para reservar.';

  @override
  String get bookingPickupPast =>
      'La hora de recogida ya pasó. Elige una nueva hora.';

  @override
  String get bookingQuoteFailed =>
      'No pudimos calcular el precio. Inténtalo de nuevo.';

  @override
  String bookingQuoteReady(String price) {
    return 'El precio de tu viaje es $price. Pulsa Continuar al pago para seguir.';
  }

  @override
  String get bookingHourlyDestination => 'Servicio por horas';

  @override
  String get bookingChooseExperience => 'Elige tu experiencia';

  @override
  String get bookingPriceBreakdown => 'Desglose de precio';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingTotalEstimated => 'Total estimado';

  @override
  String get bookingImportantNote => 'Nota importante:';

  @override
  String get bookingNoteCapacity =>
      'Los límites de capacidad de pasajeros y equipaje deben respetarse por razones de seguridad. Si se exceden, el chófer podrá rechazar el servicio.';

  @override
  String get bookingNoteImages =>
      'Las imágenes del vehículo son solo de referencia. El vehículo real puede variar manteniendo una calidad equivalente o superior.';

  @override
  String get bookingNoteExtras =>
      'Las necesidades adicionales (silla de ruedas, asiento infantil, artículos extra) pueden añadirse en \"Notas de recogida\". Elige Business Van para grupos más grandes o equipaje adicional.';

  @override
  String get bookingForMe => 'Reservar para mí';

  @override
  String get bookingForMeDetail => 'Reserva con la información de tu cuenta';

  @override
  String get bookingForGuest => 'Reservar para un invitado';

  @override
  String get bookingForGuestDetail => 'Seleccionar o añadir un invitado';

  @override
  String get bookingPriceFinal => 'Precio final';

  @override
  String get bookingPriceEstimated => 'Precio estimado';

  @override
  String get bookingPickup => 'Recogida';

  @override
  String get bookingDuration => 'Duración';

  @override
  String bookingHoursAtDisposal(int hours) {
    return '$hours horas a tu disposición';
  }

  @override
  String get bookingDestination => 'Destino';

  @override
  String get bookingBack => 'Volver';

  @override
  String bookingStepOf(int step) {
    return 'PASO $step DE 3';
  }

  @override
  String get bookingVehicle => 'Vehículo';

  @override
  String get bookingStepDetails => 'Detalles';

  @override
  String get bookingConfirm => 'Confirmar';

  @override
  String get bookingContinue => 'Continuar';

  @override
  String get bookingContinueToPayment => 'Continuar al pago';

  @override
  String get bookingTripDetails => 'DETALLES DEL VIAJE';

  @override
  String get bookingPassengers => 'Pasajeros';

  @override
  String get bookingLuggage => 'Equipaje';

  @override
  String get bookingSpecialRequests => 'Solicitudes especiales';

  @override
  String get bookingSpecialRequestsHint =>
      'Asiento infantil, letrero de bienvenida…';

  @override
  String get bookingFlightNumberRequired => 'Número de vuelo *';

  @override
  String get bookingFlightNumber => 'Número de vuelo';

  @override
  String get bookingFlightNumberHint => 'ej. OB 760';

  @override
  String get bookingFlightNumberHintOptional => 'ej. OB 760 (opcional)';

  @override
  String get bookingSummaryTitle => 'RESUMEN DE RESERVA';

  @override
  String get bookingSummaryService => 'Servicio';

  @override
  String get bookingSummaryFrom => 'Desde';

  @override
  String get bookingSummaryTo => 'Hasta';

  @override
  String get bookingSummaryDistance => 'Distancia';

  @override
  String bookingHours(int hours) {
    return '$hours horas';
  }

  @override
  String get bookingSummaryEstDuration => 'Duración est.';

  @override
  String bookingLuggageItems(int count) {
    return '$count bultos';
  }

  @override
  String get bookingSummaryFlight => 'Vuelo';

  @override
  String get bookingSummaryNotes => 'Notas';

  @override
  String get bookingTotalFixedPrice => 'TOTAL · PRECIO FIJO';

  @override
  String get bookingTotalEstimatedUpper => 'TOTAL ESTIMADO';

  @override
  String get bookingPayNextNote =>
      'Pagas en el paso siguiente. Buscamos chófer cuando el pago está confirmado.';

  @override
  String get bookingFlightNote =>
      'Recogida en aeropuerto: indica tu número de vuelo para que tu chófer lo tenga.';

  @override
  String get bookingFlightType => 'Tipo de vuelo *';

  @override
  String get bookingConfirmBooking => 'Confirmar reserva';

  @override
  String get bookingPriceEstimatedUpper => 'PRECIO ESTIMADO';

  @override
  String get bookingPriceFinalUpper => 'PRECIO FINAL';

  @override
  String get bookingRetry => 'Reintentar';

  @override
  String get bookingAuthRegisterTitle => 'Crear una cuenta';

  @override
  String get bookingAuthLoginTitle => 'Inicia sesión para continuar';

  @override
  String get bookingAuthRegisterBody =>
      'Crea tu cuenta de Luxelane para completar la reserva.';

  @override
  String get bookingAuthLoginBody => 'Inicia sesión para confirmar tu reserva.';

  @override
  String get bookingAuthFullName => 'Nombre completo';

  @override
  String get bookingAuthFullNameHint => 'Tu nombre';

  @override
  String get bookingAuthEmail => 'Correo electrónico';

  @override
  String get bookingAuthEmailHint => 'tu@ejemplo.com';

  @override
  String get bookingAuthPassword => 'Contraseña';

  @override
  String get bookingAuthRegister => 'Crear cuenta';

  @override
  String get bookingAuthLogin => 'Iniciar sesión';

  @override
  String get bookingAuthHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get bookingAuthNoAccount => '¿No tienes cuenta? Crear una';

  @override
  String get bookingGuestTitleMr => 'Sr.';

  @override
  String get bookingGuestTitleMrs => 'Sra.';

  @override
  String get bookingGuestTitleMiss => 'Srta.';

  @override
  String get bookingGuestTitleDr => 'Dr.';

  @override
  String get bookingGuestTitleProf => 'Prof.';

  @override
  String get bookingGuestAddTitle => 'Añadir nuevo invitado';

  @override
  String get bookingGuestIntro =>
      'Ingresa los datos de la persona que viajará. Compartiremos estos datos con el chófer asignado para coordinar la recogida.';

  @override
  String get bookingGuestSalutation => 'Tratamiento';

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
  String get bookingGuestPhoneNote =>
      'El chófer asignado usará este número para coordinar la recogida.';

  @override
  String get bookingGuestLanguage => 'Idioma del invitado (opcional)';

  @override
  String get bookingGuestLanguageHint => 'Ej.: español, inglés';

  @override
  String bookingVehiclePassengers(int count) {
    return '$count pasajeros';
  }

  @override
  String bookingVehicleBags(int count) {
    return '$count maletas';
  }

  @override
  String get bookingVehicleDetailsEyebrow => 'DETALLES';

  @override
  String get bookingLuggageNote =>
      'Medidas estándar de referencia. Si llevas equipaje especial (palos de golf, cochecito, instrumentos), indícalo en las notas de recogida.';

  @override
  String get bookingChildSeatNote =>
      'El asiento infantil se solicita con antelación y está sujeto a disponibilidad. Indica la edad del niño en las notas de recogida.';

  @override
  String get bookingCapacityEyebrow => 'CAPACIDAD';

  @override
  String get bookingCapacityTitle => '¿Cuánto cabe?';

  @override
  String bookingCapacityDetail(int passengers, int bags) {
    return 'Hasta $passengers pasajeros y $bags maletas facturadas';
  }

  @override
  String get bookingSeating => 'Asientos';

  @override
  String get bookingNext => 'Siguiente';

  @override
  String get bookingRatingSaveError =>
      'No se pudo guardar tu valoración. Inténtalo de nuevo.';

  @override
  String get bookingAcceptTaken => 'Otro chófer ya aceptó este viaje.';

  @override
  String get bookingAcceptNotVerified =>
      'Tus documentos aún no están verificados por Luxelane.';

  @override
  String get bookingAcceptBusy =>
      'Conéctate y termina tu viaje actual antes de aceptar otro.';

  @override
  String get bookingAcceptUnavailable => 'Este viaje ya no está disponible.';

  @override
  String get bookingAcceptConnection =>
      'No se pudo aceptar el viaje. Revisa tu conexión.';

  @override
  String get bookingAcceptFailed =>
      'No se pudo aceptar el viaje. Inténtalo de nuevo.';

  @override
  String get bookingConnectionError =>
      'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get bookingErrorPricingUnavailable =>
      'No pudimos calcular el precio de este viaje ahora. Inténtalo de nuevo en unos minutos.';

  @override
  String get bookingErrorOutOfArea =>
      'Por ahora solo hacemos viajes dentro de la misma ciudad de la recogida.';

  @override
  String get bookingErrorClassUnavailable =>
      'Esta clase de vehículo no está disponible en este momento. Elige otra.';

  @override
  String get bookingErrorServiceUnavailable =>
      'Las reservas están en pausa por mantenimiento. Vuelve a intentarlo en unos minutos.';

  @override
  String get bookingErrorInvalidHours => 'Elige un número entero de horas.';

  @override
  String get bookingErrorInactiveUser =>
      'Tu cuenta no puede hacer reservas en este momento.';

  @override
  String get bookingErrorSignIn => 'Inicia sesión para reservar.';

  @override
  String get bookingErrorPaymentsUnavailable =>
      'Ahora mismo no podemos recibir reservas. Inténtalo de nuevo más tarde o contacta con central.';

  @override
  String get bookingErrorInvalidRequest =>
      'No pudimos procesar tu reserva. Revisa los datos del viaje e inténtalo de nuevo.';

  @override
  String get bookingErrorServer =>
      'No pudimos completar la reserva por un problema nuestro. Inténtalo de nuevo en unos minutos.';

  @override
  String get bookingCancelConnectionError =>
      'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get bookingCancelServerError =>
      'No se pudo cancelar ahora. Inténtalo de nuevo en unos minutos; si sigue, contacta con central.';

  @override
  String get bookingCancelNotCancellable =>
      'Esta reserva ya no se puede cancelar: el viaje está en curso o terminó.';

  @override
  String get bookingNotFound => 'No encontramos esta reserva en tu cuenta.';

  @override
  String get bookingVehicleSaveError =>
      'No pudimos guardar el cambio. Inténtalo de nuevo.';

  @override
  String get bookingTripsLoadError =>
      'No pudimos cargar tus viajes. Reintenta.';

  @override
  String get businessEyebrow => 'Para Empresas';

  @override
  String get businessTitle => 'Viajes corporativos, redefinidos.';

  @override
  String get businessLead =>
      'Chóferes privados para tu equipo y tus invitados, con facturación centralizada. Cuéntanos qué necesitas y te contactamos en menos de un día hábil.';

  @override
  String get businessSendError =>
      'No pudimos enviar tu solicitud. Inténtalo de nuevo.';

  @override
  String get businessRequired => 'Campo obligatorio';

  @override
  String businessThanks(String name, String email) {
    return 'Gracias, $name. Recibimos tu solicitud y te escribiremos a $email.';
  }

  @override
  String get businessPerkBilling =>
      'Facturación mensual centralizada para tu empresa';

  @override
  String get businessPerkPriority =>
      'Reservas prioritarias para ejecutivos e invitados';

  @override
  String get businessCompany => 'Empresa';

  @override
  String get businessName => 'Tu nombre';

  @override
  String get businessEmail => 'Correo de trabajo';

  @override
  String get businessEmailInvalid => 'Escribe un correo válido';

  @override
  String get businessPhone => 'Teléfono';

  @override
  String get businessTravellers => '¿Cuántas personas viajarían?';

  @override
  String get businessTravellersOver200 => 'Más de 200';

  @override
  String get businessMessage => 'Cuéntanos qué necesitas (opcional)';

  @override
  String get businessSubmit => 'Enviar solicitud';

  @override
  String get commonLockedDocuments =>
      'Para cambiar estos datos, contacta con central.';

  @override
  String get commonStartupErrorTitle => 'No pudimos iniciar la app';

  @override
  String get commonStartupErrorBody =>
      'Cierra la app y vuelve a abrirla en unos minutos.';

  @override
  String commonSeatingPassengers(int count) {
    return '$count pasajeros';
  }

  @override
  String get commonSeatingMaxDetail => 'Capacidad máxima';

  @override
  String get commonSeatingRoomierDetail => 'Más espacio para cada uno';

  @override
  String get commonSeatingChildSeat => 'Con asiento infantil';

  @override
  String get commonSeatingChildSeatDetail => 'Bajo solicitud previa';

  @override
  String get commonHighlightBusiness1 =>
      'Sedán ejecutivo, discreto y silencioso';

  @override
  String get commonHighlightBusiness2 => 'Asientos traseros en cuero para tres';

  @override
  String get commonHighlightBusiness3 =>
      'Maletero para tres maletas facturadas';

  @override
  String get commonHighlightSuv1 => 'SUV ejecutiva, posición de manejo elevada';

  @override
  String get commonHighlightSuv2 => 'Cabina amplia para cuatro pasajeros';

  @override
  String get commonHighlightSuv3 => 'Maletero para cuatro maletas facturadas';

  @override
  String get commonHighlightVan1 => 'Van ejecutiva para grupos y familias';

  @override
  String get commonHighlightVan2 => 'Hasta siete pasajeros en tres filas';

  @override
  String get commonHighlightVan3 => 'Espacio para dos maletas facturadas';

  @override
  String get commonHighlightFirst1 => 'Sedán insignia, nuestro máximo nivel';

  @override
  String get commonHighlightFirst2 => 'Plazas traseras con apoyabrazos central';

  @override
  String get commonHighlightTwoCheckedBags =>
      'Maletero para dos maletas facturadas';

  @override
  String get commonHighlightElectric1 => 'Sedán ejecutivo totalmente eléctrico';

  @override
  String get commonHighlightElectric2 => 'Silencioso y sin emisiones';

  @override
  String get commonLuggageCabinOne => 'maleta de mano';

  @override
  String get commonLuggageCheckedOne => 'maleta facturada';

  @override
  String get commonLuggageOversizeOne => 'maleta extra grande';

  @override
  String get commonLuggageCabinMany => 'maletas de mano';

  @override
  String get commonLuggageCheckedMany => 'maletas facturadas';

  @override
  String get commonLuggageOversizeMany => 'maletas extra grandes';

  @override
  String get commonLuggageCabinSize => 'Hasta 55 × 40 × 20 cm';

  @override
  String get commonLuggageCheckedSize => 'Hasta 75 × 50 × 30 cm';

  @override
  String get commonLuggageOversizeSize => 'Más de 80 cm';

  @override
  String get commonPromiseFixedPrice => 'Precio fijo al reservar';

  @override
  String get commonPromiseFixedPriceLong =>
      'El precio que ves al confirmar lo calcula Luxelane para tu trayecto.';

  @override
  String get commonPromiseChauffeurs => 'Chóferes con documentos verificados';

  @override
  String get commonPromiseChauffeursLong =>
      'Luxelane revisa los documentos de cada chófer antes de que reciba viajes.';

  @override
  String get commonVehicleElectric => 'Eléctrico';

  @override
  String get commonVehicleBusinessDescription => 'Sedán ejecutivo';

  @override
  String get commonVehicleSuvDescription => 'SUV ejecutiva, más espacio';

  @override
  String get commonVehicleFirstDescription => 'Sedán insignia';

  @override
  String get commonVehicleVanDescription => 'Van ejecutiva para grupos';

  @override
  String get commonVehicleElectricDescription => 'Sedán ejecutivo eléctrico';

  @override
  String get commonServiceOneWay => 'Solo ida';

  @override
  String get commonServiceByTheHour => 'Por horas';

  @override
  String get commonServiceOneWayDescription =>
      'Traslado a precio fijo a tu destino';

  @override
  String get commonServiceByTheHourDescription =>
      'Chófer a tu disposición por un tiempo determinado';

  @override
  String get commonStatusPending => 'Pendiente';

  @override
  String get commonStatusConfirmed => 'Confirmado';

  @override
  String get commonStatusDriverArriving => 'En camino';

  @override
  String get commonStatusDriverArrived => 'Chófer llegó';

  @override
  String get commonStatusVerified => 'Verificada';

  @override
  String get commonStatusInProgress => 'En progreso';

  @override
  String get commonStatusCompleted => 'Completado';

  @override
  String get commonStatusCancelled => 'Cancelado';

  @override
  String get commonStatusNoShow => 'No se presentó';

  @override
  String get commonCancelReasonChangedPlans => 'Cambié de planes';

  @override
  String get commonCancelReasonOtherTransport => 'Encontré otro transporte';

  @override
  String get commonCancelReasonDriverLate => 'El chófer tarda demasiado';

  @override
  String get commonReasonOther => 'Otro motivo';

  @override
  String get commonReleaseReasonVehicle => 'Problema con el vehículo';

  @override
  String get commonReleaseReasonEmergency => 'Emergencia personal';

  @override
  String get commonReleaseReasonUnsafe => 'Condiciones inseguras';

  @override
  String get commonReleaseReasonSchedule => 'Conflicto de horario';

  @override
  String get commonFeeBasisNoPolicy => 'Sin política de cancelación';

  @override
  String get commonFeeBasisPolicyInvalid => 'Política inválida (sin recargo)';

  @override
  String get commonFeeBasisPaymentFailed => 'Falló el pago';

  @override
  String get commonFeeBasisNoDriver => 'Sin chófer asignado';

  @override
  String get commonFeeBasisGrace => 'Dentro del plazo tras reservar';

  @override
  String get commonFeeBasisEarly => 'Con antelación suficiente';

  @override
  String get commonFeeBasisLate => 'Tarde (aplica recargo)';

  @override
  String get commonFeeBasisNoShowAdmin =>
      'No se presentó (decisión de central)';

  @override
  String get commonPickupArea => 'Zona de recogida';

  @override
  String get commonDropoffArea => 'Zona de destino';

  @override
  String get commonTariffNegative => 'Los importes no pueden ser negativos';

  @override
  String get commonTariffZeroTransfer => 'Un traslado no puede costar Bs0';

  @override
  String get commonTariffHourlyPrice =>
      'El servicio por horas necesita un precio por hora';

  @override
  String get commonLocationNotificationTitle => 'Luxelane · estás conectado';

  @override
  String get commonLocationNotificationText =>
      'Compartimos tu ubicación para asignarte viajes y guiar al pasajero.';

  @override
  String get commonLocationChannelName => 'Ubicación del chófer';

  @override
  String get commonPricingLoading =>
      'Cargando las tarifas vigentes… inténtalo en unos segundos.';

  @override
  String get commonPricingMaintenance =>
      'Las reservas están en pausa por mantenimiento. Vuelve a intentarlo en unos minutos.';

  @override
  String commonPricingUnavailable(String vehicleClass, String serviceType) {
    return '$vehicleClass no está disponible para \"$serviceType\" en este momento.';
  }

  @override
  String get commonPromptEnjoyJourney => 'Disfruta el trayecto.';

  @override
  String get commonPromptChauffeurWaiting => 'Tu chófer ya te espera.';

  @override
  String get commonPromptChauffeurOnTheWay => 'Tu chófer va en camino.';

  @override
  String get commonPromptNextTripSoon => 'Tu próximo trayecto está cerca.';

  @override
  String get commonPromptMorning => '¿A dónde empieza tu día?';

  @override
  String get commonPromptMidday => '¿A dónde te llevamos?';

  @override
  String get commonPromptAfternoon => '¿Cerramos el día en calma?';

  @override
  String get commonPromptEvening => '¿Volvemos con calma?';

  @override
  String get commonPromptLateNight => 'Estamos aquí a cualquier hora.';

  @override
  String get commonFlightDomestic => 'Nacional';

  @override
  String get commonFlightInternational => 'Internacional';

  @override
  String get commonOriginNoCoords =>
      'No pudimos ubicar la recogida en el mapa. Elige otra dirección.';

  @override
  String commonOriginOutsideArea(String cities) {
    return 'Por ahora operamos en $cities. Elige una recogida en una de esas ciudades.';
  }

  @override
  String commonDestinationOtherCity(String city) {
    return 'El destino debe estar en $city, la misma ciudad de la recogida.';
  }

  @override
  String get commonDestinationSameCity =>
      'El destino debe estar en la misma ciudad que la recogida.';

  @override
  String get commonFlightNumberMissing =>
      'Indica tu número de vuelo: con él calculamos la hora de recogida.';

  @override
  String get commonFlightNumberInvalid =>
      'Número de vuelo no válido. Ejemplo: OB 760 o Z8 315.';

  @override
  String get commonAppTitle => 'Luxelane — Servicio de chófer ejecutivo';

  @override
  String get commonTabBook => 'Reservar';

  @override
  String get commonTabMyTrips => 'Mis viajes';

  @override
  String get commonTabProfile => 'Perfil';

  @override
  String get commonSignIn => 'Iniciar sesión';

  @override
  String get commonMyProfile => 'Mi perfil';

  @override
  String get commonNotFoundTitle => 'Este camino no existe.';

  @override
  String get commonNotFoundBody => 'Te llevamos de vuelta al inicio.';

  @override
  String get commonNotFoundBack => 'VOLVER AL INICIO';

  @override
  String get commonUpdateTitleDriver => 'Actualiza la app para seguir';

  @override
  String get commonUpdateTitleRider => 'Actualiza la app para reservar';

  @override
  String get commonUpdateBodyWeb =>
      'Hay una versión nueva de la web. Recarga la página para seguir reservando.';

  @override
  String get commonUpdateBodyApp =>
      'Hay una versión nueva de la app. Actualízala para seguir reservando.';

  @override
  String get commonUpdateGoToStore => 'Ir a la tienda';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get commonEmailNotVerifiedTitle => 'Verifica tu correo para reservar';

  @override
  String get commonEmailNotVerifiedBody =>
      'Por seguridad, solo se puede reservar con el correo verificado. Abre el enlace que te enviamos o pide uno nuevo.';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get commonVerifyMyEmail => 'Verificar mi correo';

  @override
  String get commonErrorTitle => 'Algo salió mal';

  @override
  String get commonErrorBody =>
      'Hemos sido notificados y estamos trabajando en una solución.';

  @override
  String get commonTryAgain => 'Intentar de nuevo';

  @override
  String get commonOfflineBanner =>
      'Sin conexión. Lo que ves puede no estar al día.';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get commonDone => 'Listo';

  @override
  String commonStepOf(int step, int total) {
    return 'Etapa $step de $total';
  }

  @override
  String get commonSlideToConfirm => 'Desliza para confirmar';

  @override
  String commonUpTo(int count) {
    return 'Hasta $count';
  }

  @override
  String commonHoursTotal(int hours) {
    return '${hours}h en total';
  }

  @override
  String get commonFixedPriceLower => 'precio fijo';

  @override
  String get commonRiderStyle => 'ESTILO DEL PASAJERO';

  @override
  String get commonConfirmBooking => 'Confirmar reserva';

  @override
  String get commonFixedPriceUpper => 'PRECIO FIJO';

  @override
  String get commonMapUnavailable => 'Mapa no disponible';

  @override
  String get commonMapUnavailableDetail =>
      'El mapa no se puede mostrar ahora. Los datos del viaje siguen aquí.';

  @override
  String get commonPointOnMap => 'Punto elegido en el mapa';

  @override
  String get commonSelectLocation => 'Seleccionar ubicación';

  @override
  String get commonMoveMapToChoose => 'Mueve el mapa para elegir el lugar';

  @override
  String get commonSelectedLocation => 'UBICACIÓN SELECCIONADA';

  @override
  String get commonConfirmUpper => 'CONFIRMAR';

  @override
  String get commonAddressNotFound =>
      'No pudimos ubicar esa dirección. Prueba con otra o elígela en el mapa.';

  @override
  String get commonSelectPickupPlace => 'Seleccionar lugar de recogida';

  @override
  String get commonSelectDestination => 'Seleccionar destino';

  @override
  String get commonDestinationWasOtherCity =>
      'El destino estaba en otra ciudad. Elige uno en la ciudad de recogida.';

  @override
  String get commonPickupDateUpper => 'FECHA DE RECOGIDA';

  @override
  String get commonPickupTimeUpper => 'HORA DE RECOGIDA';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonPickupMissing => 'Indica dónde te recogemos.';

  @override
  String commonPickupMovedLater(String when) {
    return 'Esa hora ya no da tiempo: la movimos a $when. Revísala y continúa.';
  }

  @override
  String get commonDestinationMissing =>
      'Indica tu destino para calcular el precio fijo.';

  @override
  String get commonPickupHintAirport =>
      'Recogida — aeropuerto, hotel o dirección';

  @override
  String get commonPickupHint => 'Recogida — dirección, hotel o lugar';

  @override
  String get commonDestinationHintAirport =>
      'Destino — aeropuerto, hotel o dirección';

  @override
  String get commonDestinationOptional => 'Destino (opcional)';

  @override
  String get commonDestinationHint => 'Destino — dirección, hotel o lugar';

  @override
  String get commonBookYourChauffeur => 'RESERVA TU CHÓFER';

  @override
  String get commonPickup => 'Recogida';

  @override
  String get commonDestination => 'Destino';

  @override
  String get commonNow => 'Ahora';

  @override
  String get commonSchedule => 'Programar';

  @override
  String get commonChange => 'Cambiar';

  @override
  String get commonSeeVehiclesAndPrices => 'VER VEHÍCULOS Y PRECIOS';

  @override
  String get commonNoCommitment =>
      'Sin compromiso: verás el precio final antes de confirmar.';

  @override
  String get commonChooseOnMap => 'Elegir en el mapa';

  @override
  String get commonDuration => 'Duración';

  @override
  String get commonFewerHours => 'Menos horas';

  @override
  String get commonMoreHours => 'Más horas';

  @override
  String get commonServiceAirportTransfer => 'Traslado al aeropuerto';

  @override
  String get commonServiceHourly => 'Chófer por horas';

  @override
  String get commonServiceImmediate => 'Recogida inmediata';

  @override
  String get commonHomeLinkLabel => 'Luxelane, inicio';

  @override
  String get commonFleet => 'Flota';

  @override
  String get commonForBusiness => 'Para empresas';

  @override
  String get commonServicesUpper => 'SERVICIOS';

  @override
  String get commonBookUpper => 'RESERVAR';

  @override
  String get commonBookATripUpper => 'RESERVAR UN VIAJE';

  @override
  String get commonMenu => 'Menú';

  @override
  String get commonCloseMenu => 'Cerrar menú';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonServices => 'Servicios';

  @override
  String get commonFooterTagline =>
      'Servicio de chófer privado para quienes valoran su tiempo, su privacidad y cada detalle del camino.';

  @override
  String get commonDriveWithUs => 'Conduce con nosotros';

  @override
  String get commonTerms => 'Términos y condiciones';

  @override
  String get commonPrivacy => 'Política de privacidad';

  @override
  String get commonOurPromise => 'Nuestra promesa';

  @override
  String commonCopyright(String year) {
    return '© $year Luxelane. Todos los derechos reservados.';
  }

  @override
  String get formatToday => 'Hoy';

  @override
  String get formatTomorrow => 'Mañana';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get driverErrorNotEnabled =>
      'Esta cuenta aún no está habilitada como chófer. Luxelane la activa después de revisar tu solicitud.';

  @override
  String get driverErrorLoadAccount =>
      'No pudimos cargar tu cuenta. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get driverNoticeTripsLoadFailed => 'No se pudieron cargar tus viajes.';

  @override
  String get driverNoticeRequestsLoadFailed =>
      'No se pudieron cargar las solicitudes de viaje.';

  @override
  String get driverNoticeFinishTripFirst =>
      'Termina tu viaje actual antes de conectarte.';

  @override
  String get driverNoticeStatusChangeFailed =>
      'No se pudo cambiar tu estado. Reintenta.';

  @override
  String get driverNoticeLocationRequired =>
      'Activa la ubicación para recibir viajes y que el pasajero vea dónde estás.';

  @override
  String get driverNoticeNoShowLocationRequired =>
      'Activa la ubicación: central necesita saber dónde esperaste.';

  @override
  String get driverNoticeNoShowReported =>
      'Avisamos a central. Ya estás libre para otros viajes.';

  @override
  String get driverNoticeReleaseOffline =>
      'Sin conexión: no se liberó el viaje. Vuelve a intentarlo.';

  @override
  String get driverNoticeReleased =>
      'Liberaste el viaje. Central buscará otro chófer.';

  @override
  String get driverNoticeStepOffline =>
      'Sin conexión: no se guardó el paso. Vuelve a intentarlo; no se duplicará.';

  @override
  String get driverNoticeRequestAccepted => 'Viaje aceptado';

  @override
  String get driverHomeLoadError => 'No pudimos abrir tu panel.';

  @override
  String get driverRetry => 'Reintentar';

  @override
  String get driverHomeOnlineTitle => 'Estás en línea.';

  @override
  String get driverHomeOfflineTitle => 'Estás desconectado.';

  @override
  String get driverHomeDocumentsPending =>
      'Tus documentos están en revisión. Podrás aceptar viajes cuando Luxelane los verifique.';

  @override
  String get driverHomeNoVehicle =>
      'No tienes un vehículo activo registrado. Pide a Luxelane que lo active para recibir solicitudes.';

  @override
  String get driverHomeToday => 'Hoy';

  @override
  String get driverHomeNetEarnings => 'Ganancias netas';

  @override
  String get driverHomeTrips => 'Viajes';

  @override
  String get driverHomeRating => 'Valoración';

  @override
  String get driverHomeUpcoming => 'Tus próximas reservas';

  @override
  String driverHourlyFrom(int hours, String place) {
    return '$hours h desde $place';
  }

  @override
  String get driverGoOffline => 'Desconectarse';

  @override
  String get driverGoOnline => 'Conectarse';

  @override
  String get driverOnlineBadge => 'En línea';

  @override
  String get driverSearching => 'Buscando viajes';

  @override
  String driverSearchingClass(String vehicleClass) {
    return 'Buscando viajes de $vehicleClass';
  }

  @override
  String get driverConnectToReceive => 'Conéctate para recibir solicitudes';

  @override
  String get driverDisconnectMe => 'Desconectarme';

  @override
  String get driverMapsNone => 'No hay aplicaciones de mapas disponibles';

  @override
  String driverMapsNavigateTo(String address) {
    return 'Navegar hacia $address';
  }

  @override
  String get driverMapsOpenFailed => 'No se pudieron abrir los mapas';

  @override
  String get driverStopPickup => 'Recogida';

  @override
  String get driverStopDestination => 'Destino';

  @override
  String driverGuestPassenger(String name) {
    return 'Pasajero: $name';
  }

  @override
  String get driverRiderNote => 'Nota del pasajero';

  @override
  String get driverNavigateToPickup => 'Navegar a la recogida';

  @override
  String get driverNavigateToDestination => 'Navegar al destino';

  @override
  String get driverRequestNow => 'Ahora';

  @override
  String driverRequestInMinutes(int minutes) {
    return 'En $minutes min';
  }

  @override
  String driverRouteDistanceDuration(String km, int minutes) {
    return '~$km km · $minutes min';
  }

  @override
  String driverRouteDistance(String km) {
    return '~$km km';
  }

  @override
  String driverRequestTitle(String vehicleClass) {
    return 'NUEVA SOLICITUD · $vehicleClass';
  }

  @override
  String get driverRequestPickupZone => 'ZONA DE RECOGIDA';

  @override
  String get driverRequestDropoffZone => 'ZONA DE DESTINO';

  @override
  String get driverRequestHourly => 'POR HORAS';

  @override
  String driverHoursAvailable(int hours) {
    return '$hours h a disposición';
  }

  @override
  String driverRequestPassengers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasajeros',
      one: '1 pasajero',
    );
    return '$_temp0';
  }

  @override
  String driverRequestLuggage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maletas',
      one: '1 maleta',
    );
    return '$_temp0';
  }

  @override
  String get driverRequestDetailsOnAccept =>
      'Dirección exacta y datos al aceptar';

  @override
  String get driverAcceptTrip => 'Aceptar viaje';

  @override
  String get driverDecline => 'Rechazar';

  @override
  String get driverTripNotFound => 'Viaje no encontrado';

  @override
  String get driverBack => 'Volver';

  @override
  String get driverEstimatedFare => 'Tarifa estimada';

  @override
  String get driverQueueTitle => 'Solicitudes';

  @override
  String get driverQueueEmptyOnline =>
      'Las nuevas solicitudes\naparecerán aquí.';

  @override
  String get driverQueueEmptyOffline => 'Conéctate para\nrecibir solicitudes.';

  @override
  String get driverQueueAvailable => 'Disponibles para ti';

  @override
  String get driverQueueAssigned => 'Tus viajes asignados';

  @override
  String driverQueueFrom(String date, String place) {
    return '$date · desde $place';
  }

  @override
  String driverQueuePax(int count) {
    return '$count pax';
  }

  @override
  String get driverQueueLoading => 'Cargando…';

  @override
  String get driverQueuePendingVerification => 'Pendiente de verificación';

  @override
  String get driverQueueFinishCurrent => 'Termina tu viaje actual';

  @override
  String get driverQueueConnectToAccept => 'Conéctate para aceptar';

  @override
  String get driverSignOut => 'Cerrar sesión';

  @override
  String get driverContinue => 'Continuar';

  @override
  String get driverFieldRequired => 'Requerido';

  @override
  String get driverFieldInvalid => 'Inválido';

  @override
  String get driverEarningsTitle => 'Ganancias';

  @override
  String get driverEarningsCompleted => 'Viajes completados';

  @override
  String get driverEarningsNetTitle => 'TUS GANANCIAS NETAS';

  @override
  String driverEarningsRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes completados',
      one: '1 viaje completado',
    );
    return '$_temp0';
  }

  @override
  String get driverEarningsFares => 'Tarifas de tus viajes';

  @override
  String get driverEarningsCommission => 'Comisión Luxelane';

  @override
  String driverEarningsProvisionalNote(String pct) {
    return 'Los viajes provisionales se calculan con una comisión del $pct % hasta que se confirme su liquidación.';
  }

  @override
  String driverEarningsRefunded(String date) {
    return '$date · reembolsado';
  }

  @override
  String driverEarningsFareLine(String date, String fare, String pct) {
    return '$date · tarifa $fare · $pct %';
  }

  @override
  String get driverEarningsProvisional => 'Provisional';

  @override
  String get driverEarningsEmpty => 'Tu primer viaje\naparecerá aquí.';

  @override
  String get driverSlideDepart => 'Salir hacia la recogida';

  @override
  String get driverSlideArrived => 'He llegado';

  @override
  String get driverSlideStart => 'Iniciar viaje';

  @override
  String get driverSlideComplete => 'Completar viaje';

  @override
  String get driverStepConfirmed => 'Dirígete a la recogida.';

  @override
  String get driverStepArriving => 'En camino a la recogida.';

  @override
  String get driverStepLocked =>
      'Verificación bloqueada. Contacta con central.';

  @override
  String get driverStepAskCode => 'Pide al pasajero su código de recogida.';

  @override
  String get driverStepVerified => 'Pasajero verificado. Desliza para iniciar.';

  @override
  String get driverStepInProgress => 'Viaje en curso · rumbo al destino.';

  @override
  String get driverStepNoShow =>
      'Avisaste que el pasajero no apareció. Central lo revisa.';

  @override
  String get driverStepActive => 'Viaje activo.';

  @override
  String get driverLockedFiveCodes =>
      'Cinco códigos incorrectos: central debe verificar este viaje.';

  @override
  String get driverEnterCode => 'Ingresar código del pasajero';

  @override
  String get driverCannotDoTrip => 'No puedo hacer este viaje';

  @override
  String get driverReleaseTitle => 'Liberar este viaje';

  @override
  String get driverReleaseBody =>
      'El viaje vuelve a buscar chófer y central recibe un aviso. Queda registrado en tu historial.';

  @override
  String get driverReleaseConfirm => 'Liberar viaje';

  @override
  String get driverReleaseReasonVehicleIssue => 'Problema con el vehículo';

  @override
  String get driverReleaseReasonPersonalEmergency => 'Emergencia personal';

  @override
  String get driverReleaseReasonUnsafeConditions => 'Condiciones inseguras';

  @override
  String get driverReleaseReasonScheduleConflict => 'Conflicto de horario';

  @override
  String get driverReleaseReasonOther => 'Otro motivo';

  @override
  String get driverNoShowTitle => '¿El pasajero no aparece?';

  @override
  String get driverNoShowBody =>
      'Central recibirá un aviso con tu ubicación y revisará la reserva. Quedarás libre para otros viajes.';

  @override
  String get driverNoShowKeepWaiting => 'Seguir esperando';

  @override
  String get driverNoShowNotify => 'Avisar a central';

  @override
  String get driverNoShowButton => 'El pasajero no aparece';

  @override
  String driverNoShowAvailableAt(String time) {
    return 'Disponible a partir de las $time.';
  }

  @override
  String get driverFlightAirportPickup => 'Recogida en aeropuerto';

  @override
  String get driverFlightCheckStatus => 'Ver estado en mivuelo.att.gob.bo';

  @override
  String get driverFlightYourCityAirport => 'el aeropuerto de tu ciudad';

  @override
  String get driverFlightDialogTitle => 'Primero cambia de aeropuerto';

  @override
  String driverFlightDialogBody(String airport, String flight) {
    return 'Al abrir mivuelo.att.gob.bo, cambia primero el aeropuerto a $airport, el que corresponde a tu ciudad. Después busca el vuelo $flight en las llegadas.\n\nCopiaremos el número de vuelo para que solo tengas que pegarlo.';
  }

  @override
  String get driverCancel => 'Cancelar';

  @override
  String get driverFlightDialogOpen => 'Entendido, abrir';

  @override
  String get driverFlightOpenFailed => 'No se pudo abrir mivuelo.att.gob.bo';

  @override
  String get driverCallDispatch => 'Llamar a central';

  @override
  String get driverCodeLockedSecurity =>
      'Por seguridad, la verificación quedó bloqueada. Contacta con central.';

  @override
  String get driverCodeAsk => 'Pide el código al pasajero';

  @override
  String get driverCodeHint =>
      'Lo ve en su app. Sin él no se puede iniciar el viaje.';

  @override
  String driverCodeSemantics(int entered, int length) {
    return 'Código, $entered de $length dígitos';
  }

  @override
  String get driverCodeDelete => 'Borrar';

  @override
  String get driverCodeVerified => 'Pasajero verificado';

  @override
  String get driverCodeVerifiedHint =>
      'Desliza «Iniciar viaje» cuando estéis listos.';

  @override
  String get driverCodeContactDispatch => 'Contacta con central';

  @override
  String get driverNavDrive => 'Conducir';

  @override
  String get driverNavRequests => 'Solicitudes';

  @override
  String get driverNavEarnings => 'Ganancias';

  @override
  String get driverNavProfile => 'Perfil';

  @override
  String get regIntroTitle => 'Conducir con Luxelane';

  @override
  String get regIntroBody =>
      'Para registrarte como chófer, esta cuenta pasa a ser una cuenta de chófer.';

  @override
  String get regIntroPointOneWay =>
      'La cuenta deja de ser de pasajero y no se vuelve a usar para reservar viajes.';

  @override
  String get regIntroPointBookings =>
      'Si ya hiciste reservas como pasajero con este correo, crea otra cuenta con un correo distinto para registrarte como chófer.';

  @override
  String get regIntroPointReview =>
      'Después completarás tus datos, los de tu vehículo y tus documentos. Luxelane los revisa antes de habilitarte.';

  @override
  String get regIntroStart => 'Convertir en cuenta de chófer';

  @override
  String get regIntroConfirmTitle => '¿Convertir esta cuenta?';

  @override
  String get regIntroConfirmBody =>
      'Esta cuenta ya no se podrá usar como pasajero. No se puede deshacer.';

  @override
  String get regIntroConfirmYes => 'Sí, convertir';

  @override
  String get regCancel => 'Cancelar';

  @override
  String get regSignOut => 'Cerrar sesión';

  @override
  String get regTitle => 'Tu solicitud de chófer';

  @override
  String regStepOf(int current, int total, String title) {
    return 'Paso $current de $total: $title';
  }

  @override
  String regProgressLabel(int current, int total) {
    return 'Progreso de la solicitud: paso $current de $total';
  }

  @override
  String get regStepPersonal => 'Tus datos';

  @override
  String get regStepVehicle => 'Tu vehículo';

  @override
  String get regStepDocuments => 'Documentos';

  @override
  String get regStepSecurity => 'Verificación en dos pasos';

  @override
  String get regStepSummary => 'Resumen y envío';

  @override
  String get regBack => 'Atrás';

  @override
  String get regContinue => 'Continuar';

  @override
  String get regSaveContinue => 'Guardar y continuar';

  @override
  String get regRetry => 'Reintentar';

  @override
  String get regSaving => 'Guardando…';

  @override
  String get regFullName => 'Nombre completo';

  @override
  String get regNationalId => 'Número de documento de identidad';

  @override
  String get regLicenseNumber => 'Número de licencia de conducir';

  @override
  String get regLicenseExpiry => 'Vencimiento de la licencia';

  @override
  String get regPickDate => 'Elegir fecha';

  @override
  String get regFieldRequired => 'Completa este campo';

  @override
  String get regFullNameInvalid =>
      'Escribe tu nombre completo (2 a 120 caracteres)';

  @override
  String get regIdInvalid => 'Usa solo letras, números y guiones (4 a 20)';

  @override
  String get regDateInFuture => 'Elige una fecha posterior a hoy';

  @override
  String get regPrivacyNote =>
      'Tus números de documento solo los ve el equipo de Luxelane que revisa la solicitud.';

  @override
  String get regMake => 'Marca';

  @override
  String get regModel => 'Modelo';

  @override
  String get regYear => 'Año';

  @override
  String regYearInvalid(int min, int max) {
    return 'Año entre $min y $max';
  }

  @override
  String get regTextInvalid => 'Entre 1 y 40 caracteres';

  @override
  String get regColor => 'Color';

  @override
  String get regColorOtherText => 'Escribe el color';

  @override
  String get regColorOtherInvalid => 'Entre 1 y 20 caracteres';

  @override
  String get regPlate => 'Placa';

  @override
  String get regPlateInvalid => 'Solo letras y números (4 a 10)';

  @override
  String get regBodyType => 'Tipo de vehículo';

  @override
  String get regPassengers => 'Pasajeros';

  @override
  String get regVehicleClass => 'Clase de servicio';

  @override
  String get regVehicleChangeNote =>
      'Si cambias de vehículo después de la aprobación, el nuevo queda en revisión hasta que Luxelane lo apruebe.';

  @override
  String get regDocsIntro =>
      'Sube cada documento con una foto nítida, con buena luz y sin reflejos.';

  @override
  String get regDocsNotConfigured =>
      'Luxelane aún no definió qué documentos se piden. Puedes completar tus datos; el envío se habilita cuando estén definidos.';

  @override
  String get regDocRequired => 'Obligatorio';

  @override
  String get regDocOptional => 'Opcional';

  @override
  String regDocExpires(String date) {
    return 'Vence: $date';
  }

  @override
  String regDocRejectedReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get regDocUpload => 'Subir';

  @override
  String get regDocReupload => 'Volver a subir';

  @override
  String get regDocUploading => 'Subiendo…';

  @override
  String get regWebUploadBlocked =>
      'Los documentos y las fotos se suben desde la app de Luxelane en tu teléfono. Aquí puedes completar tus datos y los del vehículo.';

  @override
  String get regUploadFailed =>
      'No se pudo subir la foto. Revisa tu conexión y vuelve a intentarlo.';

  @override
  String get regPhotoTooSmall =>
      'La foto tiene poca resolución. Tómala más cerca y con buena luz.';

  @override
  String get regPhotoUnreadable => 'No pudimos leer la foto. Vuelve a tomarla.';

  @override
  String get regHelpIdDocument =>
      'Apoya el documento en una superficie lisa, con buena luz y sin reflejos. Que se vean las cuatro esquinas y que el texto se lea.';

  @override
  String get regHelpPaper =>
      'Fotografía la hoja completa, de frente y sin sombras.';

  @override
  String get regHelpProfile =>
      'Tu cara de frente, sin gafas de sol ni gorra, con fondo claro.';

  @override
  String get regHelpLive =>
      'Se toma en el momento con la cámara frontal. Mira a la cámara con buena luz.';

  @override
  String get regHelpVehicle =>
      'El vehículo completo desde este lado, con buena luz.';

  @override
  String get regHelpInterior =>
      'El interior completo desde este punto, con buena luz.';

  @override
  String get regHelpPlate => 'La placa de frente, completa y legible.';

  @override
  String get regFrameHint =>
      'La cámara se abre a pantalla completa: encuadra como en este marco.';

  @override
  String get regFrameLabel => 'Guía de encuadre';

  @override
  String get regTakePhoto => 'Tomar foto';

  @override
  String get regFromGallery => 'Elegir de la galería';

  @override
  String get regLiveCameraOnly =>
      'Esta foto solo se toma con la cámara, no desde la galería.';

  @override
  String get regReviewTitle => 'Revisa la foto';

  @override
  String get regReviewHint =>
      'Comprueba que se lea bien y que no esté cortada.';

  @override
  String get regPhotoPreviewLabel => 'Vista previa de la foto';

  @override
  String get regRetake => 'Repetir';

  @override
  String get regUsePhoto => 'Usar esta foto';

  @override
  String get regExpiryNeeded => 'Fecha de vencimiento del documento';

  @override
  String get regExpiryRequired => 'Indica la fecha de vencimiento';

  @override
  String get regPhotoCancelled => 'No se tomó ninguna foto.';

  @override
  String get regCameraUnavailable =>
      'No se pudo abrir la cámara. Revisa los permisos de la app.';

  @override
  String get regSecurityBody =>
      'Para enviar la solicitud y, después, conectarte, tu cuenta necesita la verificación en dos pasos con una app autenticadora.';

  @override
  String get regSecurityEnroll => 'Activar la verificación en dos pasos';

  @override
  String get regSecurityReady =>
      'La verificación en dos pasos está activa en esta sesión.';

  @override
  String get regSecuritySignInAgain =>
      'Ya la tienes activada. Cierra sesión y vuelve a entrar con el código de tu app autenticadora para continuar.';

  @override
  String get regSecurityCheck => 'Comprobar de nuevo';

  @override
  String get regSecurityNeededToSubmit =>
      'Antes de enviar, activa la verificación en dos pasos.';

  @override
  String get regSummaryIntro => 'Revisa tu solicitud antes de enviarla.';

  @override
  String get regSummaryPersonal => 'Datos personales';

  @override
  String get regSummaryVehicle => 'Vehículo';

  @override
  String regSummaryDocs(int done, int total) {
    return 'Documentos obligatorios listos: $done de $total';
  }

  @override
  String regSummaryMissing(String list) {
    return 'Faltan: $list';
  }

  @override
  String get regSummaryIncomplete =>
      'Completa tus datos y los del vehículo para poder enviar.';

  @override
  String get regEdit => 'Editar';

  @override
  String get regSubmit => 'Enviar solicitud';

  @override
  String get regSubmitted => 'Solicitud enviada.';

  @override
  String get regStatusReviewTitle => 'Solicitud en revisión';

  @override
  String get regStatusReviewBody =>
      'Luxelane está revisando tu solicitud. Recibirás un aviso en la app cuando haya una respuesta.';

  @override
  String get regStatusNeedsChanges =>
      'Luxelane pidió cambios en tu solicitud. Revisa los documentos marcados y vuelve a enviarla.';

  @override
  String get regStatusRejectedTitle => 'Solicitud no aprobada';

  @override
  String get regStatusRejectedBody =>
      'Esta solicitud no fue aprobada y está cerrada.';

  @override
  String get regRefresh => 'Actualizar';

  @override
  String get regOnlineNeedsMfa =>
      'Para conectarte, activa la verificación en dos pasos.';

  @override
  String get regOnlineNeedsMfaSignIn =>
      'Para conectarte, cierra sesión y vuelve a entrar con el código de tu app autenticadora.';

  @override
  String get regOnlineMfaAction => 'Activar';

  @override
  String get regDocTypeProfilePhoto => 'Foto de perfil';

  @override
  String get regDocTypeLivePhoto => 'Foto en vivo';

  @override
  String get regDocTypeNationalIdFront => 'Documento de identidad (anverso)';

  @override
  String get regDocTypeNationalIdBack => 'Documento de identidad (reverso)';

  @override
  String get regDocTypeLicenseFront => 'Licencia de conducir (anverso)';

  @override
  String get regDocTypeLicenseBack => 'Licencia de conducir (reverso)';

  @override
  String get regDocTypeCriminalRecord => 'Certificado de antecedentes';

  @override
  String get regDocTypeVehicleOwnership =>
      'Documento de propiedad del vehículo';

  @override
  String get regDocTypeVehicleSoat => 'Seguro obligatorio de accidentes (SOAT)';

  @override
  String get regDocTypeVehicleInspection => 'Inspección técnica del vehículo';

  @override
  String get regDocTypeVehicleInsurance => 'Seguro del vehículo';

  @override
  String get regDocTypeVehiclePermit => 'Permiso de operación del vehículo';

  @override
  String get regDocTypeOwnerAuthorization => 'Autorización del propietario';

  @override
  String get regDocTypeVehiclePhotoFront => 'Vehículo: frente';

  @override
  String get regDocTypeVehiclePhotoBack => 'Vehículo: parte trasera';

  @override
  String get regDocTypeVehiclePhotoLeft => 'Vehículo: lado izquierdo';

  @override
  String get regDocTypeVehiclePhotoRight => 'Vehículo: lado derecho';

  @override
  String get regDocTypeVehiclePhotoInteriorFront =>
      'Vehículo: interior delantero';

  @override
  String get regDocTypeVehiclePhotoInteriorBack => 'Vehículo: interior trasero';

  @override
  String get regDocTypeVehiclePhotoPlate => 'Vehículo: placa';

  @override
  String get regAppStatusDraft => 'Borrador';

  @override
  String get regAppStatusSubmitted => 'Enviada';

  @override
  String get regAppStatusInReview => 'En revisión';

  @override
  String get regAppStatusNeedsChanges => 'Necesita cambios';

  @override
  String get regAppStatusApproved => 'Aprobada';

  @override
  String get regAppStatusRejected => 'Rechazada';

  @override
  String get regDocStatusPendingUpload => 'Por subir';

  @override
  String get regDocStatusUploaded => 'Subido, en revisión';

  @override
  String get regDocStatusApproved => 'Aprobado';

  @override
  String get regDocStatusRejected => 'Rechazado';

  @override
  String get regDocStatusExpired => 'Vencido';

  @override
  String get regRejectIllegible => 'No se lee bien';

  @override
  String get regRejectExpired => 'Está vencido';

  @override
  String get regRejectWrongDocument => 'No es el documento pedido';

  @override
  String get regRejectIncomplete => 'Está incompleto o cortado';

  @override
  String get regRejectDataMismatch =>
      'Los datos no coinciden con los de la solicitud';

  @override
  String get regRejectLowQuality => 'Imagen de baja calidad';

  @override
  String get regRejectOther => 'Otro motivo';

  @override
  String get regColorBlack => 'Negro';

  @override
  String get regColorWhite => 'Blanco';

  @override
  String get regColorSilver => 'Plateado';

  @override
  String get regColorGray => 'Gris';

  @override
  String get regColorBlue => 'Azul';

  @override
  String get regColorRed => 'Rojo';

  @override
  String get regColorGreen => 'Verde';

  @override
  String get regColorBeige => 'Beige';

  @override
  String get regColorBrown => 'Marrón';

  @override
  String get regColorOther => 'Otro';

  @override
  String get regBodySedan => 'Sedán';

  @override
  String get regBodySuv => 'SUV';

  @override
  String get regBodyVan => 'Van';

  @override
  String get driverTripClosedCompletedTitle => 'Viaje terminado';

  @override
  String get driverTripClosedCompletedBody => 'Lo verás en tu historial.';

  @override
  String get driverTripClosedNoShowTitle =>
      'Marcaste que el pasajero no se presentó';

  @override
  String get driverTripClosedNoShowBody => 'Central revisará el viaje.';

  @override
  String get driverTripClosedCancelledTitle => 'El viaje se canceló';

  @override
  String get driverTripClosedCancelledBody =>
      'Ya no tienes que ir a la recogida.';

  @override
  String get driverTripClosedOtherTitle => 'Este viaje ya no está a tu cargo';

  @override
  String get driverTripClosedOtherBody =>
      'Si tienes dudas, consulta con central.';

  @override
  String get driverTripClosedBack => 'Volver a solicitudes';

  @override
  String get driverHistoryLoadFailed =>
      'No se pudieron cargar tus viajes terminados.';

  @override
  String get driverHistoryLoading => 'Cargando tus viajes terminados';

  @override
  String driverEarningsTripArea(String area) {
    return 'Por horas · $area';
  }

  @override
  String get driverEarningsAreaUnknown => 'Zona sin registrar';

  @override
  String get errorTooManyAttempts =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get errorSessionExpired =>
      'Tu sesión expiró. Vuelve a iniciar sesión.';

  @override
  String get errorMfaRequired =>
      'Activa la verificación en dos pasos (Perfil) y vuelve a iniciar sesión para continuar.';

  @override
  String get errorReauthRequired =>
      'Por seguridad, vuelve a iniciar sesión para continuar.';

  @override
  String get errorNoConnection =>
      'Sin conexión con el servidor. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorReauthWrongPassword => 'La contraseña no coincide.';

  @override
  String get errorReauthUserMismatch =>
      'Usa la misma cuenta con la que entraste.';

  @override
  String get errorReauthFailed =>
      'No pudimos confirmar tu identidad. Inténtalo de nuevo.';

  @override
  String get errorInvalidArgument => 'Revisa los datos e inténtalo de nuevo.';

  @override
  String get errorPermissionDenied => 'No tienes permiso para hacer esto.';

  @override
  String get errorFailedPrecondition =>
      'Esto no se puede hacer en este momento.';

  @override
  String get errorNotFound => 'No encontramos el registro.';

  @override
  String get errorGeneric => 'No se pudo completar. Inténtalo de nuevo.';

  @override
  String get errorDeleteActiveBookings =>
      'Tienes viajes activos o reservados. Cancélalos o espera a que terminen antes de eliminar tu cuenta.';

  @override
  String get errorDeleteAdminAccount =>
      'Las cuentas de administración se eliminan desde la consola.';

  @override
  String get errorDeleteAccountFailed =>
      'No pudimos eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String get errorTermsOutdated =>
      'Los términos se acaban de actualizar. Vuelve a abrirlos y acéptalos de nuevo.';

  @override
  String get errorAcceptTermsFailed =>
      'No pudimos registrar tu aceptación. Inténtalo de nuevo.';

  @override
  String get errorBusinessLeadTooMany =>
      'Ya recibimos varias solicitudes desde aquí. Inténtalo más tarde o escríbenos.';

  @override
  String get errorBusinessLeadInvalid => 'Revisa los datos del formulario.';

  @override
  String get errorBusinessLeadFailed =>
      'No pudimos enviar tu solicitud. Inténtalo de nuevo.';

  @override
  String get errorBadCredentials => 'Correo o contraseña incorrectos.';

  @override
  String errorPasswordResetSent(String email) {
    return 'Si hay una cuenta con $email, te enviamos un enlace para restablecer tu contraseña. Revisa también el correo no deseado.';
  }

  @override
  String get errorLoginFailed =>
      'No pudimos iniciar sesión. Inténtalo de nuevo.';

  @override
  String get errorRegisterEmailInUse =>
      'No pudimos crear la cuenta con ese correo. Si ya te registraste, inicia sesión o recupera tu contraseña.';

  @override
  String get errorInvalidEmail => 'Ese correo no es válido. Revísalo.';

  @override
  String get errorWeakPassword =>
      'La contraseña es muy débil: usa al menos 6 caracteres.';

  @override
  String get errorRegisterFailed =>
      'No pudimos crear la cuenta. Inténtalo de nuevo.';

  @override
  String get errorPasswordResetFailed =>
      'No pudimos enviar el enlace. Inténtalo de nuevo.';

  @override
  String get errorServerDefault =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get errorEmailNotVerified => 'Verifica tu correo para poder reservar.';

  @override
  String get errorTermsRequired =>
      'Acepta los términos vigentes para poder reservar.';

  @override
  String get errorAuthDefault =>
      'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get errorAuthCancelledDefault => 'Inicio de sesión cancelado.';

  @override
  String get errorNetworkDefault => 'No internet connection';

  @override
  String get errorNotFoundDefault => 'No encontramos lo que buscabas.';

  @override
  String get errorPaymentDefault =>
      'No se pudo procesar el pago. Inténtalo de nuevo.';

  @override
  String get errorPermissionDefault => 'No tienes permiso para hacer esto.';

  @override
  String get errorPriceChanged => 'El precio de este viaje cambió.';

  @override
  String get errorCancellationFeeChanged => 'El recargo por cancelar cambió.';

  @override
  String get errorAppUpdateDriver =>
      'Actualiza la app para seguir con tus viajes.';

  @override
  String get errorAppUpdateRider => 'Actualiza la app para reservar.';

  @override
  String get errorValidationDefault => 'Revisa los datos e inténtalo de nuevo.';

  @override
  String get errorMfaEnterCode =>
      'Introduce el código de tu app autenticadora.';

  @override
  String get errorMfaWrongCode =>
      'Código incorrecto. Usa el código actual de tu app autenticadora (y revisa que la hora del teléfono sea automática).';

  @override
  String get errorMfaRecentLogin =>
      'Por seguridad, cierra sesión, vuelve a entrar y repite el alta.';

  @override
  String get errorMfaUnverifiedEmail =>
      'Verifica tu correo antes de activar la verificación en dos pasos.';

  @override
  String get errorMfaNoConnection =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorMfaQrExpired =>
      'El código QR venció. Empieza el alta de nuevo.';

  @override
  String get errorMfaNotEnabled =>
      'La verificación en dos pasos aún no está activada. Avisa a central.';

  @override
  String get errorMfaNoTotp =>
      'Tu cuenta no tiene una app autenticadora registrada. Contacta con central.';

  @override
  String get errorMfaFailed =>
      'No se pudo completar la verificación. Inténtalo de nuevo.';

  @override
  String get errorAccountBlocked =>
      'Tu cuenta está bloqueada. Escríbenos a soporte si crees que es un error.';

  @override
  String get errorDriverSuspended => 'Cuenta suspendida. Contacta con central.';

  @override
  String get errorAppCheckFailed =>
      'No se pudo verificar la app. Actualízala o inténtalo más tarde.';

  @override
  String get errorProfileNotFound =>
      'No encontramos tu perfil. Vuelve a iniciar sesión.';

  @override
  String get regErrorHasBookings =>
      'Esta cuenta ya tiene reservas como pasajero. Para registrarte como chófer, crea una cuenta con otro correo.';

  @override
  String get regErrorDriverAccount =>
      'Una cuenta de chófer no puede usar pagos de pasajero.';

  @override
  String get regErrorNotARider =>
      'Esta cuenta no puede iniciar una solicitud de chófer.';

  @override
  String get regErrorAdminAccount =>
      'Una cuenta de administración no puede registrarse como chófer.';

  @override
  String get regErrorInactiveUser => 'Tu cuenta está bloqueada.';

  @override
  String get regErrorNotADriver =>
      'Esta cuenta aún no tiene una solicitud de chófer.';

  @override
  String get regErrorLockedAfterApproval =>
      'Tus datos ya fueron aprobados; solo Luxelane puede cambiarlos.';

  @override
  String get regErrorApplicationClosed =>
      'Esta solicitud está cerrada y ya no admite cambios.';

  @override
  String get regErrorPlateInUse =>
      'Esa placa ya está registrada en otro vehículo activo.';

  @override
  String get regErrorInvalidFile =>
      'El archivo no es una imagen válida o supera el tamaño permitido. Toma la foto otra vez.';

  @override
  String get regErrorFileMissing =>
      'No encontramos el archivo subido. Vuelve a intentarlo.';

  @override
  String get regErrorUnexpectedVersion =>
      'El documento cambió mientras lo subías. Actualiza la pantalla y vuelve a intentarlo.';

  @override
  String get regErrorDocumentExpired =>
      'La fecha de vencimiento ya pasó. Sube un documento vigente.';

  @override
  String get regErrorRequirementsNotConfigured =>
      'Aún no podemos recibir solicitudes: faltan por definir los documentos que se piden. Puedes guardar tus datos y enviar más adelante.';

  @override
  String get regErrorStepsIncomplete =>
      'Completa tus datos personales y los del vehículo antes de enviar.';

  @override
  String get regErrorDocumentsMissing =>
      'Faltan documentos obligatorios o hay alguno vencido o rechazado.';

  @override
  String get regErrorInvalidRequest =>
      'Revisa los datos marcados e inténtalo de nuevo.';

  @override
  String get regErrorDriverDocsBlocked =>
      'Tienes documentos obligatorios vencidos. Súbelos de nuevo para volver a conectarte.';

  @override
  String get regErrorProfileNotFound =>
      'No encontramos tu perfil. Cierra sesión y vuelve a entrar.';

  @override
  String get regErrorDocumentsNotApproved =>
      'No se puede aprobar: hay documentos obligatorios sin aprobar o vencidos.';

  @override
  String get regErrorNotDecidable =>
      'La solicitud no está en un estado que admita esta decisión.';

  @override
  String get regErrorNotReviewable =>
      'Este documento no se puede revisar en su estado actual.';

  @override
  String get regErrorStaleVersion =>
      'El chófer subió una versión más nueva. Actualiza y revisa la última.';

  @override
  String get regErrorDocumentNotFound =>
      'Ese documento no existe o aún no se subió.';

  @override
  String get regErrorDriverNotFound => 'No encontramos a ese chófer.';

  @override
  String get regErrorApplicationNotFound => 'No encontramos esa solicitud.';

  @override
  String get regErrorPurgeDisabled =>
      'El borrado de documentos está desactivado.';

  @override
  String get regErrorGeneric =>
      'No pudimos completar este paso. Inténtalo de nuevo.';

  @override
  String get bookingErrorFlightConfigMissing =>
      'Aún no se pueden reservar recogidas con vuelo. Inténtalo más tarde.';

  @override
  String get bookingErrorAirportUnknown =>
      'Este aeropuerto aún no está disponible para recogidas.';

  @override
  String get bookingErrorFlightNotAirportPickup =>
      'El vuelo solo se indica cuando la recogida es en el aeropuerto de llegada.';

  @override
  String get bookingFlightSectionTitle => 'Tu vuelo';

  @override
  String get bookingFlightAirline => 'Aerolínea (opcional)';

  @override
  String get bookingFlightDate => 'Fecha del vuelo';

  @override
  String get bookingFlightTime => 'Hora de llegada según tu billete';

  @override
  String get bookingFlightPickDate => 'Elegir fecha';

  @override
  String get bookingFlightPickTime => 'Elegir hora';

  @override
  String get bookingFlightDateMissing => 'Indica la fecha del vuelo';

  @override
  String get bookingFlightTimeMissing =>
      'Indica la hora de llegada de tu billete';

  @override
  String get bookingFlightCheckedBagQuestion => '¿Llevas equipaje facturado?';

  @override
  String get bookingFlightCheckedBagYes => 'Sí, con equipaje facturado';

  @override
  String get bookingFlightCheckedBagNo => 'No, solo de mano';

  @override
  String get bookingFlightCheckedBagHelp =>
      'Si declaras sin equipaje y lo llevas, tu chófer puede irse antes de que salgas.';

  @override
  String rideFlightDelayed(String time) {
    return 'Tu vuelo figura con retraso. Nueva hora de recogida: $time.';
  }

  @override
  String get rideFlightDisrupted =>
      'Tu vuelo figura como cancelado o desviado. Central revisará tu reserva.';

  @override
  String get driverFlightCardTitle => 'Vuelo';

  @override
  String driverFlightStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String driverRequestAirportFlight(String airport, String type) {
    return 'Aeropuerto $airport · $type';
  }

  @override
  String get flightStatusScheduled => 'Programado';

  @override
  String get flightStatusDelayed => 'Retrasado';

  @override
  String get flightStatusLanded => 'Aterrizó';

  @override
  String get flightStatusCancelled => 'Cancelado';

  @override
  String get flightStatusDiverted => 'Desviado';

  @override
  String get flightStatusUnknown => 'Sin datos';

  @override
  String get flightPickupPointPending => 'Punto por confirmar con central';

  @override
  String flightNoLiveData(String time) {
    return 'Sin datos de vuelo en vivo: hora programada $time';
  }

  @override
  String flightBeAtPointAt(String time) {
    return 'Debes estar en el punto a las $time';
  }

  @override
  String flightDriverWillBeAt(String time) {
    return 'Hora de recogida en el punto: $time';
  }

  @override
  String flightEstimatedArrival(String time) {
    return 'Llegada estimada: $time';
  }

  @override
  String flightScheduledArrival(String time) {
    return 'Llegada programada: $time';
  }

  @override
  String flightActualArrival(String time) {
    return 'Aterrizó: $time';
  }

  @override
  String get homePickOriginTitle => 'Seleccionar lugar de recogida';

  @override
  String get homePickDestinationTitle => 'Seleccionar destino';

  @override
  String get homeDestinationOtherCity =>
      'El destino estaba en otra ciudad. Elige uno en la ciudad de recogida.';

  @override
  String get homeEnterPickup => 'Ingresa un lugar de recogida';

  @override
  String homePickupMoved(String when) {
    return 'Esa hora ya no da tiempo: la movimos a $when. Revísala y continúa.';
  }

  @override
  String get homeEnterDestination => 'Ingresa un destino';

  @override
  String get homeLocationUnavailable =>
      'No pudimos usar tu ubicación. Permite el acceso a la ubicación en tu navegador o en los ajustes del teléfono, o elige el punto en el mapa.';

  @override
  String get homeMyProfile => 'Mi perfil';

  @override
  String get homeSeeVehicles => 'Ver vehículos y precios';

  @override
  String homeHourlyFrom(int hours, String place) {
    return '$hours h desde $place';
  }

  @override
  String get homeNextTripSemantics => 'Ver tu próximo trayecto';

  @override
  String get homeNextTripEyebrow => 'TU PRÓXIMO TRAYECTO';

  @override
  String get homePickupLabel => 'Lugar de recogida';

  @override
  String get homePickupHint => 'Recogida';

  @override
  String get homeUseMyLocation => 'Usar mi ubicación';

  @override
  String get homeDestinationLabel => 'Destino';

  @override
  String get homeDestinationHint => '¿A dónde vas?';

  @override
  String get homeChooseOnMap => 'Elegir en el mapa';

  @override
  String get homeRepeatLast => 'Repetir último';

  @override
  String homeRouteSummary(String km, int minutes) {
    return '$km km · $minutes min';
  }

  @override
  String homePreferredClass(String vehicleClass) {
    return 'Tu $vehicleClass';
  }

  @override
  String get homePickupDateHelp => 'FECHA DE RECOGIDA';

  @override
  String get homePickupTimeHelp => 'HORA DE RECOGIDA';

  @override
  String get homePickerCancel => 'Cancelar';

  @override
  String get homePickerNext => 'Siguiente';

  @override
  String get homePickerDone => 'Listo';

  @override
  String get homeChangePickupTime => 'Cambiar fecha y hora de recogida';

  @override
  String homeAsap(String time) {
    return 'Lo antes posible · $time';
  }

  @override
  String get homeSchedule => 'Programar';

  @override
  String get homeDuration => 'Duración';

  @override
  String get homeWebHeadlineStart => 'Tu chófer ';

  @override
  String get homeWebHeadlineEnd => 'te espera.';

  @override
  String get homeWebPickup => 'RECOGIDA';

  @override
  String get homeWebWhereAreYou => '¿Dónde estás?';

  @override
  String get homeWebDestination => 'DESTINO';

  @override
  String get homeWebDuration => 'DURACIÓN';

  @override
  String get homeWebDateTime => 'FECHA Y HORA';

  @override
  String get homeWebChangeLocation => 'CAMBIAR UBICACIÓN';

  @override
  String get homeWebOneWay => 'Solo ida';

  @override
  String get homeWebHourly => 'Por horas';

  @override
  String get homeWebSeePrices => 'VER PRECIOS';

  @override
  String get homeWebConfirm => 'CONFIRMAR';

  @override
  String homeWebHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get homeWebMarqueeFixedPrices => 'Precios Fijos';

  @override
  String get homeWebMarqueeChauffeurs => 'Chóferes Profesionales';

  @override
  String get homeWebMarqueeFleet => 'Flota Premium';

  @override
  String get homeWebMarqueeAirport => 'Traslados Aeroportuarios';

  @override
  String get homeWebMarqueeCorporate => 'Viajes Corporativos';

  @override
  String get homeWebFleetEyebrow => 'Nuestra Flota';

  @override
  String get homeWebFleetTitle => 'Vehículos premium,\nsin excepciones.';

  @override
  String get homeWebFleetSwipe => 'DESLIZA PARA EXPLORAR →';

  @override
  String get homeWebReview1Quote =>
      'Absolutamente impecable de principio a fin. El chófer llegó antes de tiempo y el auto estaba inmaculado. No usaré a nadie más.';

  @override
  String get homeWebReview1Location => 'Londres, Reino Unido';

  @override
  String get homeWebReview2Quote =>
      'Los precios fijos y los chóferes confiables hacen de Luxelane el único servicio en el que confío para todos mis viajes de negocios.';

  @override
  String get homeWebReview2Location => 'Nueva York, EE. UU.';

  @override
  String get homeWebReview3Quote =>
      'Del aeropuerto al hotel, cada detalle fue manejado a la perfección. Así es como debería sentirse el viaje de lujo.';

  @override
  String get homeWebReview3Location => 'París, Francia';

  @override
  String get homeWebBusinessPerkBilling => 'Facturación y cobros centralizados';

  @override
  String get homeWebBusinessPerkPriority =>
      'Reservas prioritarias para ejecutivos';

  @override
  String get homeWebBusinessEyebrow => 'Para Empresas';

  @override
  String get homeWebBusinessTitle => 'Viajes corporativos,\nredefinidos.';

  @override
  String get homeWebBusinessBody =>
      'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.';

  @override
  String get homeWebLearnMore => 'Más información';

  @override
  String get homeWebCtaEyebrow => 'CUANDO QUIERAS. DONDE QUIERAS.';

  @override
  String get homeWebCtaTitleStart => 'Tu próximo viaje,';

  @override
  String get homeWebCtaTitleEnd => 'en tus términos.';

  @override
  String get homeWebCtaPromise => 'Precio fijo  ·  Chóferes profesionales';

  @override
  String get homeWebCtaBook => 'Reservar un viaje';

  @override
  String get homeWebCtaFleet => 'Ver flota';

  @override
  String get homeWebBookTagline => 'Servicio de Chófer Premium';

  @override
  String get homeWebBookStandardLabel => 'El Estándar';

  @override
  String get homeWebBookStandardSub => 'La Promesa Que Cumplimos';

  @override
  String get homeWebBookStandardTag => 'El Estándar Luxelane';

  @override
  String get homeWebBookStandardHeadline => 'El estándar que\notros siguen.';

  @override
  String get homeWebBookStandardBullet1 =>
      'Chóferes con documentos verificados';

  @override
  String get homeWebBookStandardBullet2 => 'Precio fijo al reservar';

  @override
  String get homeWebBookExperienceLabel => 'La Experiencia';

  @override
  String get homeWebBookExperienceSub => 'Cada Detalle Considerado';

  @override
  String get homeWebBookExperienceHeadline => 'Cada detalle,\ncuidado.';

  @override
  String get homeWebBookExperienceBody =>
      'Desde listas de reproducción seleccionadas hasta privacidad con cancelación de ruido — tus preferencias recordadas, siempre.';

  @override
  String get homeWebBookExperienceBullet1 => 'Interiores de cuero premium';

  @override
  String get homeWebBookExperienceBullet2 => 'Wi-Fi y carga inalámbrica';

  @override
  String get homeWebBookExperienceBullet3 => 'Servicio de champán disponible';

  @override
  String get homeWebBookExperienceBullet4 => 'Control de clima ambiental';

  @override
  String get homeWebBookBusinessSub => 'Viajes Corporativos Redefinidos';

  @override
  String get homeWebBookBusinessBullet1 => 'Facturación centralizada';

  @override
  String get homeWebBookEyebrow => 'NUESTRA EXPERIENCIA EXCLUSIVA';

  @override
  String get homeWebBookScroll => 'DESLIZA';

  @override
  String incidentSmsHeader(String id) {
    return 'SOS. Reserva #$id.';
  }

  @override
  String incidentSmsLocation(String link) {
    return 'Ubicación: $link';
  }

  @override
  String get incidentSmsNoLocation => 'Ubicación no disponible.';

  @override
  String get incidentNoNumbersHelp => 'Contacta con las autoridades locales.';

  @override
  String get incidentSendingTitle => 'Avisando a central…';

  @override
  String get incidentSendingBody => 'No cierres la app.';

  @override
  String get incidentFailedTitle => 'No pudimos avisar a central';

  @override
  String get incidentOfflineBody =>
      'No hay conexión. Llama o envía el mensaje ya preparado.';

  @override
  String get incidentCancelledTitle => 'Aviso cancelado';

  @override
  String get incidentCancelledBody =>
      'Central fue avisada. Ya no compartimos tu ubicación.';

  @override
  String get incidentOpenTitle => 'Avisamos a central';

  @override
  String get incidentOpenBody =>
      'Central fue avisada. Compartimos tu ubicación mientras dure el aviso.';

  @override
  String get incidentAckTitle => 'Central recibió tu aviso';

  @override
  String get incidentAckBody => 'Una persona de central lo está atendiendo.';

  @override
  String get incidentClosedTitle => 'Aviso cerrado';

  @override
  String get incidentClosedBody =>
      'Central cerró el aviso. Ya no compartimos tu ubicación.';

  @override
  String get incidentCancelRequestedBody =>
      'Central te llamará para verificar que estás bien. Ya no compartimos tu ubicación.';

  @override
  String get incidentHelp => 'Ayuda';

  @override
  String get incidentIdleBody => 'Mantén pulsado SOS para avisar a central.';

  @override
  String get incidentFalseAlarmQuestion => '¿Fue una falsa alarma?';

  @override
  String get incidentFalseAlarmBody =>
      'Cancelaremos el aviso. Central lo verá igualmente y queda registrado.';

  @override
  String get incidentBack => 'Volver';

  @override
  String get incidentCancelAlert => 'Cancelar aviso';

  @override
  String incidentSentTimes(int count) {
    return 'Aviso enviado $count veces.';
  }

  @override
  String get incidentCallDispatch => 'Llamar a central';

  @override
  String get incidentSmsDispatch => 'Enviar SMS a central';

  @override
  String get incidentRetry => 'Reintentar el aviso';

  @override
  String get incidentAlertAgain => 'Avisar de nuevo';

  @override
  String get incidentHoldToAlertAgain => 'Mantén pulsado para avisar de nuevo';

  @override
  String get incidentFalseAlarm => 'Fue una falsa alarma';

  @override
  String get incidentConfirmTitle => '¿Avisar a central?';

  @override
  String get incidentConfirmBody =>
      'Central recibirá tu aviso y tu ubicación mientras dure.';

  @override
  String get incidentConfirmCancel => 'Cancelar';

  @override
  String get incidentConfirmSend => 'Avisar a central';

  @override
  String incidentSosSemantics(String label) {
    return '$label SOS';
  }

  @override
  String get incidentSosHint =>
      'Mantén pulsado dos segundos para avisar a central. Con lector de pantalla, toca dos veces y confirma.';

  @override
  String get incidentLive => 'Ayuda en curso';

  @override
  String get incidentErrorOffline =>
      'No pudimos avisar a central: sin conexión.';

  @override
  String get incidentErrorOutsideWindow =>
      'El botón de ayuda funciona durante el viaje.';

  @override
  String get incidentErrorRateLimited =>
      'Ya enviaste varios avisos. Llama a central si lo necesitas.';

  @override
  String get incidentErrorNotAllowed => 'Este viaje ya no está a tu nombre.';

  @override
  String get incidentErrorGeneric => 'No pudimos avisar a central.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Usa el idioma del teléfono: $language';
  }

  @override
  String get languageSaveError =>
      'No se pudo guardar el idioma en tu cuenta. Se usará en este dispositivo.';

  @override
  String get legalSpanishOnlyNotice =>
      'Este documento solo está disponible en español por ahora.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones';

  @override
  String get notificationsNow => 'Ahora';

  @override
  String notificationsMinutesAgo(int minutes) {
    return 'Hace ${minutes}m';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return 'Hace ${hours}h';
  }

  @override
  String get paymentOurFault =>
      'No pudimos completar el pago por un problema nuestro. Inténtalo de nuevo en unos minutos.';

  @override
  String get paymentMethodDisabled =>
      'Este método de pago no está disponible ahora. Elige otro o contacta con central.';

  @override
  String get paymentAlreadyPaid => 'Esta reserva ya está pagada.';

  @override
  String get paymentNotAwaiting =>
      'Esta reserva ya no admite pagos. Revisa su estado en Mis viajes.';

  @override
  String get paymentBookingNotFound => 'No encontramos esta reserva.';

  @override
  String get paymentInvalidOperationNumber =>
      'Revisa el número de operación: usa solo letras, números, espacios y . _ / -';

  @override
  String get paymentAccountNotEnabled =>
      'tu cuenta aún no tiene pagos habilitados';

  @override
  String get paymentServerUnreachable =>
      'no se pudo contactar con el servidor de pagos';

  @override
  String get paymentCardInUse =>
      'Esta tarjeta paga una reserva pendiente. Cancélala o espera a que termine antes de quitar la tarjeta.';

  @override
  String get paymentRemoveCardError =>
      'No pudimos quitar la tarjeta. Inténtalo de nuevo.';

  @override
  String get paymentSetDefaultError =>
      'No pudimos cambiar la tarjeta predeterminada. Inténtalo de nuevo.';

  @override
  String get paymentProfileError =>
      'No pudimos preparar tu perfil de pagos. Inténtalo de nuevo.';

  @override
  String get paymentLoadError =>
      'No pudimos cargar el pago de tu reserva. Revisa tu conexión.';

  @override
  String get paymentCardUnavailable =>
      'El pago con tarjeta no está disponible ahora. Elige otro método.';

  @override
  String get paymentCardFailed =>
      'No se pudo completar el pago con tarjeta. Revisa los datos e inténtalo de nuevo.';

  @override
  String get paymentCardIncomplete =>
      'Ingresa los datos completos de la tarjeta';

  @override
  String get paymentCardAdded => 'Tarjeta agregada exitosamente';

  @override
  String get paymentAddMethodTitle => 'Agregar método de pago';

  @override
  String get paymentBack => 'Volver';

  @override
  String get paymentCardDetails => 'Datos de la tarjeta';

  @override
  String get paymentAddCardSecure =>
      'Protegido por Stripe · Cumplimiento PCI DSS';

  @override
  String get paymentAddCard => 'Agregar tarjeta';

  @override
  String get paymentBookingTitle => 'Pago de tu reserva';

  @override
  String get paymentViewTrip => 'Ver mi viaje';

  @override
  String get paymentNoPending => 'Esta reserva no tiene un pago pendiente.';

  @override
  String get paymentConfirmedTitle => 'Pago confirmado';

  @override
  String get paymentConfirmedMessage =>
      'Ya buscamos a tu chófer. Te avisaremos cuando esté asignado.';

  @override
  String get paymentExpiredTitle => 'El plazo para pagar terminó';

  @override
  String paymentExpiredMessage(String reference) {
    return 'La reserva se canceló porque no recibimos el pago a tiempo. Si ya habías pagado, contacta con central e indica la referencia $reference.';
  }

  @override
  String get paymentNewBooking => 'Hacer una nueva reserva';

  @override
  String get paymentClosedTitle => 'Esta reserva ya no admite pagos';

  @override
  String get paymentClosedMessage =>
      'Consulta el detalle y el comprobante en tu viaje.';

  @override
  String get paymentRejected =>
      'No pudimos confirmar tu pago. Revisa los datos y vuelve a avisarnos, o contacta con central.';

  @override
  String get paymentNoMethods =>
      'Ahora mismo no podemos recibir el pago desde aquí. Contacta con central para completar tu reserva.';

  @override
  String get paymentChangeMethod => 'Cambiar método de pago';

  @override
  String get paymentSearchAfterConfirm =>
      'Buscamos chófer cuando el pago está confirmado.';

  @override
  String get paymentAmountDueEyebrow => 'IMPORTE A PAGAR';

  @override
  String get paymentReference => 'Referencia';

  @override
  String paymentDeadlinePassed(String time) {
    return 'El plazo para pagar terminó a las $time.';
  }

  @override
  String paymentTimeLeft(String span, String time) {
    return 'Quedan $span para pagar (hasta las $time).';
  }

  @override
  String paymentSpanMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String paymentSpanHours(int hours) {
    return '$hours h';
  }

  @override
  String paymentSpanHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String paymentCopy(String label) {
    return 'Copiar $label';
  }

  @override
  String paymentCopied(String label) {
    return '$label copiada.';
  }

  @override
  String get paymentMethodManualQr => 'QR o transferencia bancaria';

  @override
  String get paymentMethodCard => 'Tarjeta';

  @override
  String get paymentHowToPay => '¿CÓMO QUIERES PAGAR?';

  @override
  String get paymentManualEyebrow => 'PAGA POR QR O TRANSFERENCIA';

  @override
  String get paymentQrLabel => 'Código QR para pagar';

  @override
  String get paymentQrError =>
      'No pudimos mostrar el QR. Usa los datos de la cuenta.';

  @override
  String get paymentHolder => 'Titular';

  @override
  String get paymentBank => 'Banco';

  @override
  String get paymentAccountType => 'Tipo de cuenta';

  @override
  String get paymentAccount => 'Cuenta';

  @override
  String paymentPayExactly(String amount, String reference) {
    return 'Paga exactamente $amount y escribe la referencia $reference en el concepto o glosa.';
  }

  @override
  String get paymentOperationLabel => 'Número de operación (opcional)';

  @override
  String get paymentOperationHint => 'El que aparece en tu comprobante';

  @override
  String get paymentIPaid => 'Ya pagué';

  @override
  String get paymentWaitingTitle => 'Esperando confirmación';

  @override
  String get paymentWaitingMessage =>
      'Central está revisando tu pago. Te avisaremos aquí y en tus notificaciones cuando lo confirme.';

  @override
  String paymentOperationNumber(String number) {
    return 'Número de operación: $number';
  }

  @override
  String get paymentConfirming => 'Confirmando tu pago…';

  @override
  String get paymentPayWithCard => 'Pagar con tarjeta';

  @override
  String get paymentRetry => 'Reintentar';

  @override
  String get paymentAddCardsOnPhone =>
      'Agrega tus tarjetas desde la app de Luxelane en tu teléfono.';

  @override
  String get paymentRemoveCardTitle => '¿Quitar esta tarjeta?';

  @override
  String get paymentRemoveCardMessage =>
      'Dejará de estar disponible para tus próximas reservas.';

  @override
  String get paymentCancel => 'Cancelar';

  @override
  String get paymentRemove => 'Quitar';

  @override
  String get paymentMethodsTitle => 'Métodos de pago';

  @override
  String get paymentPerBooking => 'Cada reserva se paga en su paso de pago.';

  @override
  String get paymentSavedCards => 'Tarjetas guardadas';

  @override
  String get paymentSetDefaultHint =>
      'Toca una tarjeta para usarla por defecto al reservar.';

  @override
  String get paymentEncrypted => 'Pagos cifrados y protegidos por Stripe';

  @override
  String get paymentEmptyCards => 'Paga sin pensarlo.';

  @override
  String paymentCardDefaultExpires(String expiry) {
    return 'Predeterminada · vence $expiry';
  }

  @override
  String paymentCardExpires(String expiry) {
    return 'Vence $expiry';
  }

  @override
  String get paymentRemoveCard => 'Quitar tarjeta';

  @override
  String get paymentReceiptMethodManual => 'QR o transferencia';

  @override
  String get paymentPendingTitle => 'Pago pendiente';

  @override
  String paymentReportedMessage(String amount) {
    return 'Avisaste que pagaste $amount. Central lo está revisando.';
  }

  @override
  String paymentPendingMessage(String amount) {
    return 'Paga $amount para que busquemos a tu chófer.';
  }

  @override
  String get paymentViewPayment => 'Ver el pago';

  @override
  String get paymentPayNow => 'Pagar ahora';

  @override
  String get paymentReceiptTitle => 'Comprobante de pago';

  @override
  String get paymentReceiptHide => 'Ocultar comprobante';

  @override
  String get paymentReceiptShow => 'Ver comprobante';

  @override
  String get paymentReceiptNotInvoice => 'Este comprobante no es una factura.';

  @override
  String get paymentReceiptPaid => 'Pagado';

  @override
  String get paymentReceiptDate => 'Fecha';

  @override
  String get paymentReceiptMethod => 'Método';

  @override
  String get paymentReceiptRetained => 'Retención por cancelación';

  @override
  String get paymentReceiptRefundPending => 'Devolución pendiente';

  @override
  String get paymentReceiptRefundPendingNote =>
      'Central la registrará y te avisaremos cuando quede hecha.';

  @override
  String get paymentReceiptRefunded => 'Devuelto';

  @override
  String get paymentReceiptRefundedNote =>
      'Te devolvemos el dinero al método con el que pagaste.';

  @override
  String get paymentReceiptBalanceDue => 'Saldo pendiente';

  @override
  String get paymentReceiptBalanceNote =>
      'El importe final del viaje fue mayor que lo pagado.';

  @override
  String get prefsNoPreference => 'Sin preferencia';

  @override
  String get prefsLanguagesTitle => 'Idiomas del chófer';

  @override
  String get prefsLanguageEs => 'Español';

  @override
  String get prefsLanguageEn => 'Inglés';

  @override
  String get prefsLanguagePt => 'Portugués';

  @override
  String get prefsTemperatureTitle => 'Temperatura';

  @override
  String get prefsTemperatureCool => 'Fresca';

  @override
  String get prefsTemperatureMild => 'Templada';

  @override
  String get prefsConversationTitle => 'Conversación';

  @override
  String get prefsConversationChatty => 'Me gusta conversar';

  @override
  String get prefsConversationQuiet => 'Prefiero silencio';

  @override
  String get prefsMusicTitle => 'Música';

  @override
  String get prefsMusicClassical => 'Clásica';

  @override
  String get prefsMusicJazz => 'Jazz';

  @override
  String get prefsMusicInstrumental => 'Instrumental';

  @override
  String get prefsMusicPop => 'Pop';

  @override
  String get prefsMusicRock => 'Rock';

  @override
  String get prefsMusicLatin => 'Latina';

  @override
  String get prefsMusicElectronic => 'Electrónica';

  @override
  String get prefsMusicFolk => 'Folclore';

  @override
  String get prefsMusicNone => 'Sin música';

  @override
  String get prefsPlaylistTitle => 'Lista de música';

  @override
  String get prefsNeedsTitle => 'Necesidades';

  @override
  String get prefsNeedExtraLuggage => 'Equipaje extra';

  @override
  String get prefsNeedLuggageAssistance => 'Ayuda con el equipaje';

  @override
  String get prefsNeedChildSeat => 'Silla infantil';

  @override
  String get prefsNeedBoosterSeat => 'Alzador infantil';

  @override
  String get prefsNeedBoardingAssistance => 'Asistencia para subir';

  @override
  String get prefsNeedFoldingWheelchair => 'Silla de ruedas plegable';

  @override
  String get prefsNeedPetInCarrier => 'Mascota en transportín';

  @override
  String get prefsNeedPrivateHint => 'Solo tu chófer asignado lo verá.';

  @override
  String get prefsNoteTitle => 'Nota para el chófer';

  @override
  String get prefsNoteWarning =>
      'No escribas datos sensibles: claves, tarjetas ni datos de salud.';

  @override
  String get prefsDriverWillSee => 'Tu chófer verá estas preferencias.';

  @override
  String get prefsCardTitle => 'Preferencias del pasajero';

  @override
  String get prefsOpenPlaylist => 'Abrir lista';

  @override
  String get prefsOpenPlaylistTitle => 'Abrir fuera de la app';

  @override
  String get prefsOpenPlaylistBody =>
      'La lista se abrirá fuera de Luxelane, en el navegador o en otra aplicación.';

  @override
  String get prefsOpenPlaylistConfirm => 'Abrir';

  @override
  String get prefsCancel => 'Cancelar';

  @override
  String get prefsOpenPlaylistError => 'No se pudo abrir la lista.';

  @override
  String prefsLanguagesSummary(String languages) {
    return 'Idiomas: $languages';
  }

  @override
  String get prefsErrorPlaylist =>
      'Ese enlace de lista no se puede usar. Revisa que empiece por https y sea de un servicio admitido.';

  @override
  String get prefsErrorNote =>
      'Revisa la nota: hasta 200 caracteres y sin enlaces.';

  @override
  String get prefsSaved => 'Preferencias guardadas.';

  @override
  String get prefsScreenTitle => 'Preferencias';

  @override
  String get prefsEmpty =>
      'Aún no tienes preferencias. Añade las que quieras que tu chófer conozca.';

  @override
  String get prefsEmptyShort => 'Sin preferencias todavía';

  @override
  String get prefsSave => 'Guardar';

  @override
  String get prefsPlaylistHelp =>
      'Pega un enlace https. Se abre siempre fuera de la app.';

  @override
  String get prefsPlaylistInvalid => 'El enlace debe empezar por https://';

  @override
  String get prefsNoteHint => 'Por ejemplo, dónde esperarte';

  @override
  String get prefsTripTitle => 'Preferencias de este viaje';

  @override
  String get prefsTripFromProfile => 'Las de tu perfil.';

  @override
  String get prefsTripChanged => 'Cambiadas solo para este viaje.';

  @override
  String get prefsTripEdit => 'Cambiar para este viaje';

  @override
  String get prefsTripSkip => 'Omitir';

  @override
  String get prefsTripReset => 'Usar las de mi perfil';

  @override
  String get prefsTripApply => 'Usar en este viaje';

  @override
  String get prefsTripEmpty => 'Sin preferencias para este viaje.';

  @override
  String get profileSaveError =>
      'No pudimos guardar los cambios. Inténtalo de nuevo.';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileDriverDocuments => 'Licencia y vehículo';

  @override
  String get profileAccount => 'Cuenta';

  @override
  String get profileEmail => 'Correo';

  @override
  String get profilePhone => 'Teléfono';

  @override
  String get profilePhoneMissing => 'Añádelo para tu chófer';

  @override
  String get profilePaymentMethods => 'Métodos de pago';

  @override
  String get profileTwoStep => 'Verificación en dos pasos';

  @override
  String get profileAuthenticatorApp => 'App autenticadora';

  @override
  String get profileLegal => 'Legal';

  @override
  String get profileTerms => 'Términos y condiciones';

  @override
  String get profilePrivacy => 'Privacidad';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileAccountDeleted => 'Tu cuenta fue eliminada.';

  @override
  String get profileDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get profileDeleteBody =>
      'Borraremos tu perfil, tus tarjetas guardadas y tus avisos, y no podrás volver a entrar con esta cuenta. Conservamos el registro de viajes y pagos que exige la ley.\n\nEsta acción no se puede deshacer.';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileDelete => 'Eliminar';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileName => 'Nombre';

  @override
  String get profileRequired => 'Requerido';

  @override
  String get profilePhoneInvalid => 'Tu chófer lo necesita para contactarte';

  @override
  String get profileSaveChanges => 'Guardar cambios';

  @override
  String get profileRoleAdmin => 'Administración';

  @override
  String get profileRoleDriver => 'Chófer Luxelane';

  @override
  String profileMemberSince(int year) {
    return 'Miembro desde $year';
  }

  @override
  String profileRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '$count viaje',
    );
    return '$_temp0';
  }

  @override
  String get profileVehicleColorTitle => 'Color del vehículo';

  @override
  String get profileColor => 'Color';

  @override
  String get profileSave => 'Guardar';

  @override
  String get profileLocked => 'Bloqueado';

  @override
  String get profileLicence => 'Licencia';

  @override
  String profileLicenceDetail(String number, String expiry) {
    return '$number · vence $expiry';
  }

  @override
  String profileVehicleDetail(String vehicleClass, String plate) {
    return '$vehicleClass · placa $plate';
  }

  @override
  String get profilePreferencesEntry => 'Preferencias para tu chófer';

  @override
  String get rideLoadNotFound => 'No encontramos esta reserva en tu cuenta.';

  @override
  String get rideLoadOffline =>
      'No pudimos cargar tu reserva. Revisa tu conexión.';

  @override
  String get rideLoadFailed =>
      'No pudimos cargar tu reserva. Inténtalo de nuevo.';

  @override
  String get ridePendingSearching =>
      'Estamos asignando a tu chófer. Te avisaremos en cuanto esté confirmado.';

  @override
  String get ridePendingReleasedCall =>
      'Tu chófer anterior no pudo hacer el viaje. Estamos buscando otro y central ya está avisada. Si lo necesitas, llama a central.';

  @override
  String get ridePendingReleased =>
      'Tu chófer anterior no pudo hacer el viaje. Estamos buscando otro y central ya está avisada.';

  @override
  String get ridePendingPickupPassedCall =>
      'Ya pasó la hora de recogida y aún no hay chófer asignado. Llama a central o cancela la reserva.';

  @override
  String get ridePendingPickupPassed =>
      'Ya pasó la hora de recogida y aún no hay chófer asignado. Puedes esperar o cancelar la reserva.';

  @override
  String rideCodeShareText(String code) {
    return 'Tu código de recogida es $code. Dáselo a tu chófer al subir; sin él no puede iniciar el viaje.';
  }

  @override
  String get rideCodeLoading => 'Cargando tu código de recogida';

  @override
  String get rideCodeTitle => 'CÓDIGO DE RECOGIDA';

  @override
  String rideCodeSemantics(String digits) {
    return 'Código de recogida $digits';
  }

  @override
  String get rideCodeHint =>
      'Dáselo a tu chófer al subir. Sin él no puede iniciar el viaje.';

  @override
  String rideCodeGuestHint(String guest) {
    return 'Compártelo con $guest: se lo dará al chófer al subir.';
  }

  @override
  String get rideCodeShare => 'Compartir código';

  @override
  String get rideRetry => 'Reintentar';

  @override
  String get rideCancelledSnack => 'Reserva cancelada';

  @override
  String get rideCancelFeeChangedAgain =>
      'La retención cambió de nuevo. Inténtalo otra vez.';

  @override
  String get rideCancelBooking => 'Cancelar reserva';

  @override
  String rideCancelFee(String amount) {
    return 'Según la política de cancelación, si cancelas ahora se retienen $amount de lo que pagaste.';
  }

  @override
  String rideCancelFeeChanged(String amount) {
    return 'La retención cambió. Según la política de cancelación, si cancelas ahora se retienen $amount de lo que pagaste.';
  }

  @override
  String rideCancelRefund(String amount) {
    return '$amount quedan pendientes de devolución. Te avisaremos cuando central la registre.';
  }

  @override
  String get rideCancelReasonLabel => 'Motivo';

  @override
  String get rideCancelReasonChangedPlans => 'Cambié de planes';

  @override
  String get rideCancelReasonOtherTransport => 'Encontré otro transporte';

  @override
  String get rideCancelReasonDriverLate => 'El chófer tarda demasiado';

  @override
  String get rideCancelReasonOther => 'Otro motivo';

  @override
  String get rideBack => 'Volver';

  @override
  String get rideCancelWithFee => 'Cancelar con retención';

  @override
  String get rideCancelledMessage => 'Esta reserva fue cancelada.';

  @override
  String rideCancelledWithFee(String amount) {
    return 'Esta reserva fue cancelada. Retención por cancelación: $amount.';
  }

  @override
  String get rideStatusLoading => 'Cargando tu reserva…';

  @override
  String get rideStatusAwaitingPayment =>
      'Tu reserva espera el pago. Buscamos chófer cuando esté confirmado.';

  @override
  String get rideStatusConfirmed =>
      'Tu reserva está confirmada. Te avisaremos cuando tu chófer salga hacia ti.';

  @override
  String get rideStatusDriverArriving =>
      'Tu chófer va de camino al punto de recogida.';

  @override
  String get rideStatusDriverArrived =>
      'Tu chófer ha llegado y te espera. Tómate tu tiempo.';

  @override
  String get rideStatusVerified =>
      'Código verificado. Tu viaje empieza en un momento.';

  @override
  String get rideStatusInProgress =>
      'Disfruta del trayecto. Llegarás a tu destino en breve.';

  @override
  String get rideStatusCompleted =>
      'Has llegado. Gracias por viajar con Luxelane.';

  @override
  String get rideStatusNoShow =>
      'Tu chófer no te encontró en el punto de recogida. Central fue avisada.';

  @override
  String get rideYourDriverLower => 'tu chófer';

  @override
  String get rideYourDriver => 'Tu chófer';

  @override
  String get rideRatingThanks => '¡Gracias por tu valoración!';

  @override
  String get rideRateTrip => 'Calificar viaje';

  @override
  String get rideCallDriver => 'Llamar a tu chófer';

  @override
  String get rideCancelling => 'Cancelando…';

  @override
  String get rideBackHome => 'Volver al inicio';

  @override
  String get rideAssigningTitle => 'Asignando a tu chófer';

  @override
  String get rideAssigningDetail =>
      'Verás su nombre, vehículo y valoración aquí.';

  @override
  String get rideCodeVerified => 'Código verificado';

  @override
  String get rideCodeVerifiedDetail => 'Tu chófer ya puede iniciar el viaje.';

  @override
  String get rideCompleted => 'Viaje completado';

  @override
  String get rideRatingTitle => 'Califica tu viaje';

  @override
  String get rideRatingLater => 'Ahora no';

  @override
  String get rideRatingSend => 'Enviar';

  @override
  String get rideRating5 => 'Excelente';

  @override
  String get rideRating4 => 'Bueno';

  @override
  String get rideRating3 => 'Regular';

  @override
  String get rideRating2 => 'Malo';

  @override
  String get rideRating1 => 'Muy malo';

  @override
  String get rideErrorNetwork =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get rideErrorNotAtPickup =>
      'El código aparece cuando tu chófer llega a la recogida.';

  @override
  String get rideErrorWrongCode => 'Código incorrecto.';

  @override
  String get rideErrorWrongCodeOne => 'Código incorrecto. Te queda 1 intento.';

  @override
  String rideErrorWrongCodeMany(int left) {
    return 'Código incorrecto. Te quedan $left intentos.';
  }

  @override
  String get rideErrorLocked =>
      'Por seguridad, la verificación quedó bloqueada. Contacta con central.';

  @override
  String get rideErrorExpired =>
      'El código venció. Contacta con central para continuar.';

  @override
  String get rideErrorUnavailable =>
      'El código no está disponible ahora. Contacta con central.';

  @override
  String get rideErrorNotYours => 'Este viaje ya no está a tu cargo.';

  @override
  String get rideErrorTooEarly =>
      'Aún no terminó el tiempo de espera. Espera un poco más.';

  @override
  String get rideErrorNoShowDisabled =>
      'Esta opción no está disponible. Contacta con central.';

  @override
  String get rideErrorLocationRequired =>
      'Activa la ubicación: central necesita saber dónde esperaste.';

  @override
  String get rideErrorNotReleasable =>
      'Ya no puedes liberar este viaje. Contacta con central.';

  @override
  String get rideErrorInvalidTransition =>
      'El viaje cambió de estado. Actualizamos la pantalla.';

  @override
  String get rideErrorGeneric => 'No se pudo completar. Inténtalo de nuevo.';

  @override
  String get servicesPromiseEyebrow => 'Nuestra promesa';

  @override
  String get servicesPromiseTitle => 'Tranquilidad, por escrito.';

  @override
  String get servicesStepsEyebrow => 'Cómo funciona';

  @override
  String get servicesStepsTitle => 'Tres pasos.\nNada más.';

  @override
  String get servicesFleetEyebrow => 'La flota';

  @override
  String get servicesFleetTitle => 'Elige cómo llegar.';

  @override
  String get servicesFleetBody =>
      'Vehículos de gama alta, impecables y preparados antes de cada servicio.';

  @override
  String get servicesMostChosen => 'LA MÁS ELEGIDA';

  @override
  String servicesCapacity(int count) {
    return 'Hasta $count pasajeros';
  }

  @override
  String get servicesPriceFrom => 'DESDE';

  @override
  String get servicesQuoteOnBooking => 'Cotiza al reservar';

  @override
  String get servicesFaqEyebrow => 'Preguntas frecuentes';

  @override
  String get servicesFaqTitle => 'Todo lo que\nquieres saber.';

  @override
  String get servicesBookNow => 'RESERVAR AHORA';

  @override
  String get servicesAirportEyebrow => 'Traslado al aeropuerto';

  @override
  String get servicesAirportTitle =>
      'Aterriza.\nNosotros nos\nocupamos del resto.';

  @override
  String get servicesAirportLead =>
      'Tu chófer te espera en llegadas con tu nombre y se encarga del equipaje. Tú solo sales por la puerta.';

  @override
  String get servicesAirportStep1Title => 'Reserva en 2 minutos';

  @override
  String get servicesAirportStep1Body =>
      'Indica aeropuerto, destino y hora. Añade tu número de vuelo y verás el precio final al instante.';

  @override
  String get servicesAirportStep2Title => 'Recibe a tu chófer';

  @override
  String get servicesAirportStep2Body =>
      'Antes de la recogida tendrás su nombre, vehículo y contacto en la app.';

  @override
  String get servicesAirportStep3Title => 'Sal y relájate';

  @override
  String get servicesAirportStep3Body =>
      'Te espera en llegadas, se ocupa del equipaje y te lleva directo a tu destino.';

  @override
  String get servicesAirportStoryEyebrow => 'La llegada';

  @override
  String get servicesAirportStoryTitle =>
      'El primer momento\nde tu viaje, resuelto.';

  @override
  String get servicesAirportStoryBody =>
      'Después de un vuelo largo, lo último que quieres son colas, negociaciones o incertidumbre. Un chófer de Luxelane convierte la llegada en una transición tranquila hacia tu hotel, tu reunión o tu casa.';

  @override
  String get servicesAirportStoryPoint1 =>
      'Ayuda con el equipaje, de la cinta al maletero';

  @override
  String get servicesAirportStoryPoint2 =>
      'Conexiones entre aeropuertos y hoteles sin complicaciones';

  @override
  String get servicesAirportFaq1Question => '¿Dónde me espera el chófer?';

  @override
  String get servicesAirportFaq1Answer =>
      'En la zona de llegadas. Recibirás sus datos de contacto en la app antes de la recogida.';

  @override
  String get servicesAirportFaq2Question => '¿Puedo cancelar mi reserva?';

  @override
  String get servicesAirportFaq2Answer =>
      'Sí, desde la app antes de que empiece el viaje. Si según la política de cancelación corresponde un recargo, lo verás antes de confirmar.';

  @override
  String get servicesAirportFaq3Question => '¿Cuánto equipaje puedo llevar?';

  @override
  String get servicesAirportFaq3Answer =>
      'Depende de la clase de vehículo. Si viajas con mucho equipaje o en grupo, la Business Van ofrece espacio para hasta 7 pasajeros.';

  @override
  String get servicesAirportClosingTitle =>
      'Tu próximo vuelo\nya tiene chófer.';

  @override
  String get servicesAirportClosingBody =>
      'Reserva ahora. Precio fijo al reservar y chóferes con documentos verificados.';

  @override
  String get servicesHourlyEyebrow => 'Chófer por horas';

  @override
  String get servicesHourlyTitle => 'Tu agenda.\nTu ritmo.\nTu chófer.';

  @override
  String get servicesHourlyLead =>
      'Un chófer y un vehículo exclusivamente para ti, de 2 a 24 horas. Cambia de planes cuantas veces quieras: él se adapta.';

  @override
  String get servicesHourlyStopsTitle => 'Paradas ilimitadas';

  @override
  String get servicesHourlyStopsDetail =>
      'Reuniones, compras o visitas: tu chófer te espera en cada parada.';

  @override
  String get servicesHourlyStep1Title => 'Elige la duración';

  @override
  String get servicesHourlyStep1Body =>
      'Indica el punto de recogida, el día y cuántas horas necesitas. Mínimo 2, máximo 24.';

  @override
  String get servicesHourlyStep2Title => 'Diseña tu jornada';

  @override
  String get servicesHourlyStep2Body =>
      'Comparte tu itinerario en las notas o decídelo sobre la marcha. No hace falta destino final.';

  @override
  String get servicesHourlyStep3Title => 'Disfruta sin mirar el reloj';

  @override
  String get servicesHourlyStep3Body =>
      'Tu chófer y tu vehículo están a tu disposición durante todo el tiempo reservado.';

  @override
  String get servicesHourlyStoryEyebrow => 'Para cada ocasión';

  @override
  String get servicesHourlyStoryTitle =>
      'Un día entero,\nsin pensar en cómo moverte.';

  @override
  String get servicesHourlyStoryBody =>
      'Desde una agenda de reuniones hasta una tarde descubriendo la ciudad, el servicio por horas te da la libertad de un vehículo privado sin ninguna de sus preocupaciones.';

  @override
  String get servicesHourlyStoryPoint1 =>
      'Viajes de negocios: de reunión en reunión, sin esperas';

  @override
  String get servicesHourlyStoryPoint2 =>
      'Eventos y cenas: llegada impecable, salida sin prisas';

  @override
  String get servicesHourlyStoryPoint3 =>
      'Turismo privado: la ciudad a tu ritmo, con un chófer local';

  @override
  String get servicesHourlyStoryPoint4 =>
      'Compras y ocio: tu chófer guarda tus bolsas y te espera';

  @override
  String get servicesHourlyFaq1Question => '¿Cómo reservo un chófer por horas?';

  @override
  String get servicesHourlyFaq1Answer =>
      'Selecciona el lugar de recogida, la duración, el día y la hora. Después elige la clase de vehículo y confirma. Verás el precio final antes de pagar.';

  @override
  String get servicesHourlyFaq2Question =>
      '¿Puedo cambiar el itinerario durante el servicio?';

  @override
  String get servicesHourlyFaq2Answer =>
      'Sí. El chófer y el vehículo están a tu disposición durante todas las horas reservadas, con tantas paradas como necesites.';

  @override
  String get servicesHourlyFaq3Question => '¿Puedo ampliar el número de horas?';

  @override
  String get servicesHourlyFaq3Answer =>
      'Sí, puedes modificar la reserva antes de la hora de inicio. La duración mínima es de 2 horas y la máxima de 24.';

  @override
  String get servicesHourlyFaq4Question =>
      '¿Puede empezar o terminar en un aeropuerto?';

  @override
  String get servicesHourlyFaq4Answer =>
      'Sí. El servicio puede empezar o terminar en un aeropuerto, siempre que el inicio y el final estén en la misma ciudad.';

  @override
  String get servicesHourlyFaq5Question =>
      '¿Cuándo recibiré los datos del chófer?';

  @override
  String get servicesHourlyFaq5Answer =>
      'Antes de la recogida tendrás en la app el nombre del chófer, el vehículo y su contacto.';

  @override
  String get servicesHourlyClosingTitle =>
      'Reserva el tiempo.\nNosotros ponemos el camino.';

  @override
  String get servicesHourlyClosingBody =>
      'Desde 2 horas, con precio fijo y un chófer profesional a tu entera disposición.';

  @override
  String get servicesImmediateEyebrow => 'Recogida inmediata';

  @override
  String get servicesImmediateTitle => 'Cuando lo\nnecesites.';

  @override
  String get servicesImmediateLead =>
      'La misma excelencia de una reserva anticipada, sin planificar.';

  @override
  String get servicesImmediateTrackingTitle => 'Seguimiento en tiempo real';

  @override
  String get servicesImmediateTrackingDetail =>
      'Ve en el mapa dónde está tu chófer y cuándo llega.';

  @override
  String get servicesImmediateStep1Title => 'Indica origen y destino';

  @override
  String get servicesImmediateStep1Body =>
      'Escribe la dirección o elígela en el mapa. Verás el precio final antes de confirmar.';

  @override
  String get servicesImmediateStep2Title => 'Confirma con un toque';

  @override
  String get servicesImmediateStep2Body =>
      'Pagas la reserva. Con el pago confirmado buscamos chófer y te mostramos su nombre y vehículo.';

  @override
  String get servicesImmediateStep3Title => 'Síguelo en el mapa';

  @override
  String get servicesImmediateStep3Body =>
      'Recibe un aviso cuando tu chófer esté en camino y otro cuando haya llegado.';

  @override
  String get servicesImmediateStoryEyebrow => 'Sin planificar';

  @override
  String get servicesImmediateStoryTitle =>
      'Lo imprevisto,\ncon la misma elegancia.';

  @override
  String get servicesImmediateStoryBody =>
      'Una reunión que se alarga, un cambio de planes, una cena que merece un final a la altura. La recogida inmediata pone un vehículo premium y un chófer profesional a tu alcance.';

  @override
  String get servicesImmediateStoryPoint1 =>
      'Vehículos premium, impecables en cada servicio';

  @override
  String get servicesImmediateStoryPoint2 =>
      'Chóferes con documentos verificados';

  @override
  String get servicesImmediateStoryPoint3 =>
      'Precio fijo calculado antes de confirmar, sin tarifas dinámicas';

  @override
  String get servicesImmediateFaq1Question =>
      '¿Cuánto tarda en llegar el chófer?';

  @override
  String get servicesImmediateFaq1Answer =>
      'Depende de tu ubicación y de la disponibilidad. Verás la hora estimada de llegada antes de confirmar y podrás seguir al chófer en el mapa.';

  @override
  String get servicesImmediateFaq2Question =>
      '¿El precio cambia según la demanda?';

  @override
  String get servicesImmediateFaq2Answer =>
      'No. El precio se fija antes de confirmar y no cambia: sin tarifas dinámicas ni cargos ocultos.';

  @override
  String get servicesImmediateFaq3Question =>
      '¿Puedo programar el viaje para más tarde?';

  @override
  String get servicesImmediateFaq3Answer =>
      'Sí. Elige \"Programar\" en el formulario y selecciona el día y la hora que prefieras.';

  @override
  String get servicesImmediateFaq4Question => '¿Qué pasa si necesito cancelar?';

  @override
  String get servicesImmediateFaq4Answer =>
      'Puedes cancelar desde la app antes de que empiece el viaje. Si según la política de cancelación corresponde un recargo, lo verás antes de confirmar.';

  @override
  String get servicesImmediateClosingTitle => 'Tu chófer,\na un toque.';

  @override
  String get servicesImmediateClosingBody =>
      'Confirma ahora y sigue a tu chófer en tiempo real hasta la puerta.';

  @override
  String get tripsTitle => 'Mis viajes';

  @override
  String get tripsRetry => 'Reintentar';

  @override
  String get tripsUpcoming => 'Próximos';

  @override
  String get tripsPast => 'Anteriores';

  @override
  String get tripsEmptyMessage => 'Tu primer trayecto\nte está esperando.';

  @override
  String get tripsEmptyAction => 'Reservar ahora';

  @override
  String tripsHourlyTitle(int hours) {
    return '$hours h a disposición';
  }

  @override
  String tripsFrom(String when, String origin) {
    return '$when · desde $origin';
  }

  @override
  String get tripsTrackOnMap => 'Seguir en el mapa';

  @override
  String get tripsRate => 'Calificar viaje';

  @override
  String get tripsViewBooking => 'Ver reserva';

  @override
  String get tripsAwaitingPayment => 'Esperando pago';

  @override
  String get tripsPaid => 'Pagada';
}
