// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String ridePreferencesKnown(String preferences) {
    return 'Tu chófer conoce tu estilo: $preferences';
  }

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
}
