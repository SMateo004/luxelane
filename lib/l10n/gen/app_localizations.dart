import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// Título de la pantalla de inicio de sesión (web) y botón principal para entrar.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// Subtítulo bajo «Iniciar sesión» en la web.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo a Luxelane.'**
  String get authLoginWelcomeBack;

  /// Etiqueta de lector de pantalla del logo que lleva al inicio (inicio de sesión y registro).
  ///
  /// In es, this message translates to:
  /// **'Luxelane, ir al inicio'**
  String get authHomeLinkSemantics;

  /// Antetítulo en mayúsculas de la pantalla de inicio de sesión (móvil).
  ///
  /// In es, this message translates to:
  /// **'BIENVENIDO'**
  String get authLoginEyebrow;

  /// Titular grande del inicio de sesión (móvil) y del panel de marca en la web; el salto de línea es intencional.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer,\ncomo lo recuerdas.'**
  String get authLoginHeadline;

  /// Texto bajo el titular del inicio de sesión (móvil).
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para reservar y seguir tus trayectos.'**
  String get authLoginSubtitle;

  /// Etiqueta del campo de correo (inicio de sesión y registro).
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// Error del campo de correo cuando no parece un correo.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get authEmailInvalid;

  /// Etiqueta del campo de contraseña.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// Error del campo de contraseña si es demasiado corta.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordMinLength;

  /// Enlace para pedir un enlace de cambio de contraseña.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// Aviso al pedir el cambio de contraseña sin haber escrito el correo.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo arriba y te enviaremos un enlace.'**
  String get authResetNeedsEmail;

  /// Texto antes del enlace «Crear una» (el espacio final separa del enlace).
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get authNoAccount;

  /// Enlace a la pantalla de registro, tras «¿No tienes cuenta?».
  ///
  /// In es, this message translates to:
  /// **'Crear una'**
  String get authCreateOne;

  /// Subtítulo del panel de marca de la web en el inicio de sesión.
  ///
  /// In es, this message translates to:
  /// **'Tus direcciones, preferencias y viajes, siempre a mano.'**
  String get authBrandSubtitle;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Reserva en menos de 2 minutos'**
  String get authBrandPointBooking;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Todos tus viajes en un solo lugar'**
  String get authBrandPointTrips;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de tu chófer en tiempo real'**
  String get authBrandPointTracking;

  /// Antetítulo en mayúsculas de la pantalla de registro (móvil).
  ///
  /// In es, this message translates to:
  /// **'CREAR CUENTA'**
  String get authRegisterEyebrow;

  /// Titular grande del registro (móvil y panel de marca web); el salto de línea es intencional.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido\na Luxelane.'**
  String get authRegisterHeadline;

  /// Texto bajo el titular del registro (móvil).
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta en menos de un minuto.'**
  String get authRegisterSubtitle;

  /// Subtítulo del panel de marca de la web en el registro.
  ///
  /// In es, this message translates to:
  /// **'Una cuenta para reservar, seguir y recordar cada trayecto.'**
  String get authRegisterBrandSubtitle;

  /// Título del registro (web) y botón para crear la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// Subtítulo bajo «Crear cuenta» en la web.
  ///
  /// In es, this message translates to:
  /// **'Solo te pediremos lo necesario para tu chófer.'**
  String get authRegisterWebSubtitle;

  /// Botón de registro con la cuenta de Google.
  ///
  /// In es, this message translates to:
  /// **'Registrarte con Google'**
  String get authGoogleRegister;

  /// Etiqueta del campo de nombre en el registro.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authNameLabel;

  /// Error si el nombre está vacío en el registro.
  ///
  /// In es, this message translates to:
  /// **'Indica tu nombre para que tu chófer pueda recibirte'**
  String get authNameRequired;

  /// Etiqueta del campo de teléfono en el registro.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (con código de país)'**
  String get authPhoneLabel;

  /// Error si el teléfono es demasiado corto en el registro.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer lo necesita para contactarte'**
  String get authPhoneRequired;

  /// Error si no se marcó la casilla de términos al registrarse.
  ///
  /// In es, this message translates to:
  /// **'Acepta los Términos y la Política de privacidad para continuar'**
  String get authTermsRequired;

  /// Nota bajo el botón de registro: para qué se piden nombre y teléfono.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre y teléfono permiten a tu chófer recibirte y contactarte.'**
  String get authRegisterDataNote;

  /// Texto antes del enlace «Inicia sesión» (el espacio final separa del enlace).
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get authHaveAccount;

  /// Enlace a la pantalla de inicio de sesión desde el registro.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignInLink;

  /// Etiqueta de lector de pantalla de la casilla de términos.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos y la Política de privacidad'**
  String get authTermsCheckboxSemantics;

  /// Primera parte de «He leído y acepto los Términos y la Política de privacidad.»; sigue el enlace «Términos» (espacio final).
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto los '**
  String get authTermsReadPrefix;

  /// Enlace a los Términos dentro de la frase de la casilla.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get authTermsLink;

  /// Unión entre los enlaces «Términos» y «Política de privacidad» (espacios a ambos lados).
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get authTermsAnd;

  /// Enlace a la Política de privacidad dentro de la frase de la casilla.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get authPrivacyLink;

  /// Botón para entrar con la cuenta de Google (también en «Confirma que eres tú»).
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authGoogleContinue;

  /// Separador entre Google y el formulario de correo; se muestra en mayúsculas.
  ///
  /// In es, this message translates to:
  /// **'o con tu correo'**
  String get authOrWithEmail;

  /// Título de la pantalla «Verifica tu correo».
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo'**
  String get authVerifyTitle;

  /// Encabezado de «Verifica tu correo» cuando no se conoce la dirección.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace a tu correo.'**
  String get authVerifySentGeneric;

  /// Encabezado de «Verifica tu correo» con la dirección.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace a {email}.'**
  String authVerifySentTo(String email);

  /// Explicación de «Verifica tu correo».
  ///
  /// In es, this message translates to:
  /// **'Ábrelo y vuelve aquí. Necesitas el correo verificado para reservar. Si el enlace venció o no llega, pide uno nuevo (revisa también la carpeta de correo no deseado).'**
  String get authVerifyBody;

  /// Aviso tras reenviar el enlace de verificación.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace nuevo.'**
  String get authVerifyResent;

  /// Aviso al comprobar que el correo ya está verificado.
  ///
  /// In es, this message translates to:
  /// **'Correo verificado. Ya puedes reservar.'**
  String get authVerifyDone;

  /// Error si al comprobar el correo aún no está verificado.
  ///
  /// In es, this message translates to:
  /// **'Aún no vemos el correo verificado. Abre el enlace que te enviamos y vuelve a intentarlo.'**
  String get authVerifyNotYet;

  /// Botón de reenvío deshabilitado tras el máximo de reenvíos.
  ///
  /// In es, this message translates to:
  /// **'Límite de reenvíos alcanzado'**
  String get authVerifyResendLimit;

  /// Botón de reenvío mientras corre la espera, con los segundos que faltan.
  ///
  /// In es, this message translates to:
  /// **'Reenviar enlace ({seconds} s)'**
  String authVerifyResendIn(int seconds);

  /// Botón para reenviar el enlace de verificación.
  ///
  /// In es, this message translates to:
  /// **'Reenviar enlace'**
  String get authVerifyResend;

  /// Botón para comprobar que el correo ya se verificó.
  ///
  /// In es, this message translates to:
  /// **'Ya lo verifiqué'**
  String get authVerifyConfirm;

  /// Botón para dejar la verificación del correo para después.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get authVerifyLater;

  /// Título de las pantallas de verificación en dos pasos (alta y segundo paso al entrar).
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get authMfaTitle;

  /// Error si el código de la app autenticadora no tiene 6 cifras.
  ///
  /// In es, this message translates to:
  /// **'Escribe las 6 cifras del código.'**
  String get authMfaCodeDigits;

  /// Botón o descripción emergente para cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get authCancel;

  /// Instrucción del segundo paso al iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Abre tu app autenticadora y escribe el código de Luxelane.'**
  String get authMfaSignInPrompt;

  /// Etiqueta del campo del código de 6 cifras.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get authMfaCodeLabel;

  /// Botón para entrar con el código del segundo paso.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get authMfaSignInButton;

  /// Ayuda si se perdió la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'¿Perdiste el acceso a tu app autenticadora? Contacta con central para recuperar la cuenta.'**
  String get authMfaLostAccess;

  /// Mensaje al terminar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Listo. A partir de ahora, al iniciar sesión te pediremos el código de tu app autenticadora.'**
  String get authMfaEnrollDone;

  /// Botón para volver tras el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get authMfaBack;

  /// Explicación antes de empezar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Protege tu cuenta con una app autenticadora (por ejemplo, la que trae tu teléfono o tu gestor de contraseñas). Te pedirá un código de 6 cifras al iniciar sesión.'**
  String get authMfaEnrollIntro;

  /// Botón para empezar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get authMfaStart;

  /// Paso 1 del alta: escanear el código QR.
  ///
  /// In es, this message translates to:
  /// **'1. Escanea este código con tu app autenticadora.'**
  String get authMfaScanStep;

  /// Etiqueta de lector de pantalla del código QR.
  ///
  /// In es, this message translates to:
  /// **'Código QR para la app autenticadora'**
  String get authMfaQrSemantics;

  /// Botón para abrir el alta directamente en la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Abrir en la app autenticadora'**
  String get authMfaOpenInApp;

  /// Clave para escribir a mano si no se puede escanear; {key} es la clave o puntos si está oculta.
  ///
  /// In es, this message translates to:
  /// **'¿No puedes escanear? Escribe esta clave: {key}'**
  String authMfaManualKey(String key);

  /// Botón para ocultar la clave escrita.
  ///
  /// In es, this message translates to:
  /// **'Ocultar clave'**
  String get authMfaHideKey;

  /// Botón para mostrar la clave escrita.
  ///
  /// In es, this message translates to:
  /// **'Mostrar clave'**
  String get authMfaShowKey;

  /// Advertencia de seguridad bajo el código QR.
  ///
  /// In es, this message translates to:
  /// **'No compartas este código ni la clave, y no hagas capturas.'**
  String get authMfaNoShare;

  /// Paso 2 del alta: escribir el código.
  ///
  /// In es, this message translates to:
  /// **'2. Escribe el código que muestra la app.'**
  String get authMfaCodeStep;

  /// Botón para terminar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get authMfaActivate;

  /// Título del aviso para dar de alta la verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'Activa la verificación en dos pasos'**
  String get authMfaReminderTitle;

  /// Detalle del aviso de verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'Pronto será obligatoria para entrar. Tarda un minuto.'**
  String get authMfaReminderBody;

  /// Aviso tras confirmar la identidad: hay que repetir la acción.
  ///
  /// In es, this message translates to:
  /// **'Identidad confirmada. Repite la acción.'**
  String get authReauthConfirmed;

  /// Error si se confirma sin escribir la contraseña.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get authReauthPasswordEmpty;

  /// Título del diálogo para volver a identificarse.
  ///
  /// In es, this message translates to:
  /// **'Confirma que eres tú'**
  String get authReauthTitle;

  /// Explicación del diálogo con contraseña.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, escribe tu contraseña para continuar.'**
  String get authReauthPassword;

  /// Explicación del diálogo con cuenta de Google.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a entrar con Google para continuar.'**
  String get authReauthGoogle;

  /// Explicación del diálogo sin método disponible.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, cierra sesión y vuelve a entrar para continuar.'**
  String get authReauthNone;

  /// Botón para confirmar la contraseña.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get authConfirm;

  /// Aviso tras aceptar los términos vigentes desde el diálogo.
  ///
  /// In es, this message translates to:
  /// **'Listo. Ya puedes reservar.'**
  String get authTermsAcceptedSnack;

  /// Título del diálogo que pide aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Acepta los términos para reservar'**
  String get authTermsDialogTitle;

  /// Texto del diálogo que pide aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Para reservar necesitamos que aceptes la versión vigente de los Términos y la Política de privacidad.'**
  String get authTermsDialogBody;

  /// Botón para abrir los Términos.
  ///
  /// In es, this message translates to:
  /// **'Leer los Términos'**
  String get authTermsRead;

  /// Botón para abrir la Política de privacidad.
  ///
  /// In es, this message translates to:
  /// **'Leer la Política de privacidad'**
  String get authPrivacyRead;

  /// Botón para cerrar el diálogo sin aceptar.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get authNotNow;

  /// Botón para aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Acepto'**
  String get authAccept;

  /// Error sin conexión al entrar con Google.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get authErrorOffline;

  /// Error genérico al entrar con Google.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión con Google. Inténtalo de nuevo.'**
  String get authGoogleGenericError;

  /// Error de Google: ya hay una cuenta con ese correo y contraseña.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una cuenta con este correo. Inicia sesión con tu contraseña.'**
  String get authGoogleAccountExists;

  /// Error de Google en la web: el navegador bloqueó la ventana.
  ///
  /// In es, this message translates to:
  /// **'Tu navegador bloqueó la ventana de Google. Permite las ventanas emergentes e inténtalo de nuevo.'**
  String get authGooglePopupBlocked;

  /// Error de Google en la web: dominio no autorizado.
  ///
  /// In es, this message translates to:
  /// **'Este dominio no está autorizado para iniciar sesión con Google.'**
  String get authGoogleUnauthorizedDomain;

  /// Error de Google: el inicio de sesión con Google está desactivado.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con Google no está habilitado.'**
  String get authGoogleNotEnabled;

  /// Error al eliminar la cuenta sin respuesta del servidor.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta. Revisa tu conexión.'**
  String get authDeleteAccountError;

  /// Error al enviar el enlace para cambiar la contraseña.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el enlace. Inténtalo de nuevo.'**
  String get authResetLinkError;

  /// Error de verificación del correo: demasiados enlaces seguidos.
  ///
  /// In es, this message translates to:
  /// **'Enviamos varios enlaces seguidos. Espera unos minutos antes de pedir otro.'**
  String get authVerifyTooMany;

  /// Error de verificación del correo sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e inténtalo de nuevo.'**
  String get authVerifyOffline;

  /// Error genérico de verificación del correo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la verificación. Inténtalo de nuevo.'**
  String get authVerifyFailed;

  /// Fecha relativa: hoy (antes de la hora, «Hoy · 18:30»).
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get formatToday;

  /// Fecha relativa: mañana («Mañana · 09:15»).
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get formatTomorrow;

  /// Saludo de la mañana en el inicio (de 5 a 12 h).
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get greetingMorning;

  /// Saludo de la tarde en el inicio (de 12 a 19 h).
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get greetingAfternoon;

  /// Saludo de la noche en el inicio (de 19 a 5 h).
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get greetingEvening;

  /// Título de la sección del perfil donde se elige el idioma de la app.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// Opción del selector de idioma: seguir el idioma del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// Detalle bajo «Sistema»: qué idioma resulta del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Usa el idioma del teléfono: {language}'**
  String languageSystemDetail(String language);

  /// Aviso si el idioma no se guardó en el servidor; la app ya cambió de idioma.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el idioma en tu cuenta. Se usará en este dispositivo.'**
  String get languageSaveError;

  /// Aviso sobre las páginas legales (términos, privacidad) cuando la app está en inglés o portugués: el texto legal sigue en español hasta que el abogado entregue las traducciones. En español no se muestra.
  ///
  /// In es, this message translates to:
  /// **'Este documento solo está disponible en español por ahora.'**
  String get legalSpanishOnlyNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
