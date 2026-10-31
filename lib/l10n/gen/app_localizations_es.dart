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
}
