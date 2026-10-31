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

  /// Error de pago por un fallo del servidor; no culpa a la persona.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar el pago por un problema nuestro. Inténtalo de nuevo en unos minutos.'**
  String get paymentOurFault;

  /// Error: el método de pago elegido está desactivado.
  ///
  /// In es, this message translates to:
  /// **'Este método de pago no está disponible ahora. Elige otro o contacta con central.'**
  String get paymentMethodDisabled;

  /// Error: la reserva ya está pagada.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya está pagada.'**
  String get paymentAlreadyPaid;

  /// Error: la reserva ya no espera un pago.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no admite pagos. Revisa su estado en Mis viajes.'**
  String get paymentNotAwaiting;

  /// Error: no se encontró la reserva (o no es de la persona).
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta reserva.'**
  String get paymentBookingNotFound;

  /// Error: el número de operación tiene caracteres no permitidos. Los caracteres finales son literales.
  ///
  /// In es, this message translates to:
  /// **'Revisa el número de operación: usa solo letras, números, espacios y . _ / -'**
  String get paymentInvalidOperationNumber;

  /// Error del pago con tarjeta: la cuenta no tiene pagos habilitados (en minúscula, va dentro de otro mensaje).
  ///
  /// In es, this message translates to:
  /// **'tu cuenta aún no tiene pagos habilitados'**
  String get paymentAccountNotEnabled;

  /// Error del pago con tarjeta: no hubo respuesta del servidor de pagos (en minúscula).
  ///
  /// In es, this message translates to:
  /// **'no se pudo contactar con el servidor de pagos'**
  String get paymentServerUnreachable;

  /// Error al quitar una tarjeta que paga una reserva pendiente.
  ///
  /// In es, this message translates to:
  /// **'Esta tarjeta paga una reserva pendiente. Cancélala o espera a que termine antes de quitar la tarjeta.'**
  String get paymentCardInUse;

  /// Error al quitar una tarjeta guardada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos quitar la tarjeta. Inténtalo de nuevo.'**
  String get paymentRemoveCardError;

  /// Error al cambiar la tarjeta predeterminada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cambiar la tarjeta predeterminada. Inténtalo de nuevo.'**
  String get paymentSetDefaultError;

  /// Error al crear el perfil de pagos de la persona.
  ///
  /// In es, this message translates to:
  /// **'No pudimos preparar tu perfil de pagos. Inténtalo de nuevo.'**
  String get paymentProfileError;

  /// Error al cargar el estado del pago de una reserva.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el pago de tu reserva. Revisa tu conexión.'**
  String get paymentLoadError;

  /// Error: el pago con tarjeta no se puede usar en este momento.
  ///
  /// In es, this message translates to:
  /// **'El pago con tarjeta no está disponible ahora. Elige otro método.'**
  String get paymentCardUnavailable;

  /// Error: el formulario de tarjeta no completó el pago.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el pago con tarjeta. Revisa los datos e inténtalo de nuevo.'**
  String get paymentCardFailed;

  /// Aviso al agregar una tarjeta sin todos los datos.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos completos de la tarjeta'**
  String get paymentCardIncomplete;

  /// Aviso tras guardar una tarjeta nueva.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta agregada exitosamente'**
  String get paymentCardAdded;

  /// Título de la pantalla para agregar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Agregar método de pago'**
  String get paymentAddMethodTitle;

  /// Etiqueta del botón de volver en las pantallas de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get paymentBack;

  /// Encabezado del formulario de la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Datos de la tarjeta'**
  String get paymentCardDetails;

  /// Nota de seguridad bajo el formulario de tarjeta. Stripe y PCI DSS no se traducen.
  ///
  /// In es, this message translates to:
  /// **'Protegido por Stripe · Cumplimiento PCI DSS'**
  String get paymentAddCardSecure;

  /// Botón o acción para agregar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarjeta'**
  String get paymentAddCard;

  /// Título de la pantalla de pago de una reserva.
  ///
  /// In es, this message translates to:
  /// **'Pago de tu reserva'**
  String get paymentBookingTitle;

  /// Botón para ir al detalle del viaje desde el pago.
  ///
  /// In es, this message translates to:
  /// **'Ver mi viaje'**
  String get paymentViewTrip;

  /// Estado vacío: la reserva no tiene pago pendiente.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva no tiene un pago pendiente.'**
  String get paymentNoPending;

  /// Título cuando central confirmó el pago.
  ///
  /// In es, this message translates to:
  /// **'Pago confirmado'**
  String get paymentConfirmedTitle;

  /// Mensaje tras confirmar el pago; sin plazos.
  ///
  /// In es, this message translates to:
  /// **'Ya buscamos a tu chófer. Te avisaremos cuando esté asignado.'**
  String get paymentConfirmedMessage;

  /// Título cuando venció el plazo para pagar.
  ///
  /// In es, this message translates to:
  /// **'El plazo para pagar terminó'**
  String get paymentExpiredTitle;

  /// Explicación de la reserva cancelada por falta de pago, con la referencia del pago.
  ///
  /// In es, this message translates to:
  /// **'La reserva se canceló porque no recibimos el pago a tiempo. Si ya habías pagado, contacta con central e indica la referencia {reference}.'**
  String paymentExpiredMessage(String reference);

  /// Botón para empezar una reserva nueva.
  ///
  /// In es, this message translates to:
  /// **'Hacer una nueva reserva'**
  String get paymentNewBooking;

  /// Título cuando la reserva ya no acepta pagos (devuelta, cancelada…).
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no admite pagos'**
  String get paymentClosedTitle;

  /// Mensaje bajo «Esta reserva ya no admite pagos».
  ///
  /// In es, this message translates to:
  /// **'Consulta el detalle y el comprobante en tu viaje.'**
  String get paymentClosedMessage;

  /// Aviso cuando central no pudo confirmar el pago avisado.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu pago. Revisa los datos y vuelve a avisarnos, o contacta con central.'**
  String get paymentRejected;

  /// Aviso cuando ningún método de pago se puede usar en este dispositivo.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo no podemos recibir el pago desde aquí. Contacta con central para completar tu reserva.'**
  String get paymentNoMethods;

  /// Botón para volver a elegir el método de pago.
  ///
  /// In es, this message translates to:
  /// **'Cambiar método de pago'**
  String get paymentChangeMethod;

  /// Nota al pie de la pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Buscamos chófer cuando el pago está confirmado.'**
  String get paymentSearchAfterConfirm;

  /// Rótulo en mayúsculas sobre el importe a pagar.
  ///
  /// In es, this message translates to:
  /// **'IMPORTE A PAGAR'**
  String get paymentAmountDueEyebrow;

  /// Etiqueta de la referencia del pago (código a escribir en el concepto).
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get paymentReference;

  /// El plazo para pagar ya pasó; {time} es la hora.
  ///
  /// In es, this message translates to:
  /// **'El plazo para pagar terminó a las {time}.'**
  String paymentDeadlinePassed(String time);

  /// Tiempo que queda para pagar; {span} es «24 min» o «1 h 5 min», {time} la hora límite.
  ///
  /// In es, this message translates to:
  /// **'Quedan {span} para pagar (hasta las {time}).'**
  String paymentTimeLeft(String span, String time);

  /// Duración solo con minutos, dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String paymentSpanMinutes(int minutes);

  /// Duración en horas exactas dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String paymentSpanHours(int hours);

  /// Duración en horas y minutos dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String paymentSpanHoursMinutes(int hours, int minutes);

  /// Etiqueta del botón de copiar; {label} es «referencia» o «cuenta», en minúscula.
  ///
  /// In es, this message translates to:
  /// **'Copiar {label}'**
  String paymentCopy(String label);

  /// Aviso tras copiar; {label} es «Referencia» o «Cuenta» (femenino).
  ///
  /// In es, this message translates to:
  /// **'{label} copiada.'**
  String paymentCopied(String label);

  /// Método de pago: QR o transferencia bancaria.
  ///
  /// In es, this message translates to:
  /// **'QR o transferencia bancaria'**
  String get paymentMethodManualQr;

  /// Método de pago: tarjeta (también cuando no se conoce la marca).
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentMethodCard;

  /// Rótulo en mayúsculas sobre la lista de métodos.
  ///
  /// In es, this message translates to:
  /// **'¿CÓMO QUIERES PAGAR?'**
  String get paymentHowToPay;

  /// Rótulo en mayúsculas sobre los datos de cobro.
  ///
  /// In es, this message translates to:
  /// **'PAGA POR QR O TRANSFERENCIA'**
  String get paymentManualEyebrow;

  /// Etiqueta del lector de pantalla para la imagen del QR.
  ///
  /// In es, this message translates to:
  /// **'Código QR para pagar'**
  String get paymentQrLabel;

  /// Aviso si la imagen del QR no carga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos mostrar el QR. Usa los datos de la cuenta.'**
  String get paymentQrError;

  /// Etiqueta: titular de la cuenta de cobro (el valor lo escribe el admin y no se traduce).
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get paymentHolder;

  /// Etiqueta: banco de la cuenta de cobro.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get paymentBank;

  /// Etiqueta: tipo de cuenta de cobro.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get paymentAccountType;

  /// Etiqueta: número de cuenta de cobro (femenino en español y portugués: «Cuenta copiada»).
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get paymentAccount;

  /// Instrucción del pago manual: importe exacto y referencia para el concepto.
  ///
  /// In es, this message translates to:
  /// **'Paga exactamente {amount} y escribe la referencia {reference} en el concepto o glosa.'**
  String paymentPayExactly(String amount, String reference);

  /// Etiqueta del campo del número de operación del banco.
  ///
  /// In es, this message translates to:
  /// **'Número de operación (opcional)'**
  String get paymentOperationLabel;

  /// Ayuda del campo del número de operación.
  ///
  /// In es, this message translates to:
  /// **'El que aparece en tu comprobante'**
  String get paymentOperationHint;

  /// Botón para avisar que ya se hizo el pago manual.
  ///
  /// In es, this message translates to:
  /// **'Ya pagué'**
  String get paymentIPaid;

  /// Estado: el pago avisado espera que central lo confirme.
  ///
  /// In es, this message translates to:
  /// **'Esperando confirmación'**
  String get paymentWaitingTitle;

  /// Explicación mientras central revisa el pago.
  ///
  /// In es, this message translates to:
  /// **'Central está revisando tu pago. Te avisaremos aquí y en tus notificaciones cuando lo confirme.'**
  String get paymentWaitingMessage;

  /// Número de operación que escribió la persona.
  ///
  /// In es, this message translates to:
  /// **'Número de operación: {number}'**
  String paymentOperationNumber(String number);

  /// Estado tras completar el formulario de tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Confirmando tu pago…'**
  String get paymentConfirming;

  /// Botón para abrir el pago con tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Pagar con tarjeta'**
  String get paymentPayWithCard;

  /// Botón para reintentar el pago con tarjeta tras un error.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get paymentRetry;

  /// Aviso en la web: las tarjetas se agregan desde la app del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Agrega tus tarjetas desde la app de Luxelane en tu teléfono.'**
  String get paymentAddCardsOnPhone;

  /// Título del diálogo para quitar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta tarjeta?'**
  String get paymentRemoveCardTitle;

  /// Texto del diálogo para quitar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Dejará de estar disponible para tus próximas reservas.'**
  String get paymentRemoveCardMessage;

  /// Botón para cerrar el diálogo sin quitar la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get paymentCancel;

  /// Botón del diálogo que quita la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get paymentRemove;

  /// Título de la pantalla de métodos de pago del perfil.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get paymentMethodsTitle;

  /// Estado vacío cuando no hay tarjetas que guardar: cada reserva se paga en su pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Cada reserva se paga en su paso de pago.'**
  String get paymentPerBooking;

  /// Encabezado de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas guardadas'**
  String get paymentSavedCards;

  /// Pie de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Toca una tarjeta para usarla por defecto al reservar.'**
  String get paymentSetDefaultHint;

  /// Nota de seguridad bajo la lista de tarjetas. Stripe no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Pagos cifrados y protegidos por Stripe'**
  String get paymentEncrypted;

  /// Estado vacío de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Paga sin pensarlo.'**
  String get paymentEmptyCards;

  /// Detalle de la tarjeta predeterminada; {expiry} es «MM/AA».
  ///
  /// In es, this message translates to:
  /// **'Predeterminada · vence {expiry}'**
  String paymentCardDefaultExpires(String expiry);

  /// Detalle de una tarjeta; {expiry} es «MM/AA».
  ///
  /// In es, this message translates to:
  /// **'Vence {expiry}'**
  String paymentCardExpires(String expiry);

  /// Etiqueta del botón para quitar una tarjeta de la lista.
  ///
  /// In es, this message translates to:
  /// **'Quitar tarjeta'**
  String get paymentRemoveCard;

  /// Método en el comprobante: QR o transferencia.
  ///
  /// In es, this message translates to:
  /// **'QR o transferencia'**
  String get paymentReceiptMethodManual;

  /// Título de la tarjeta del viaje cuando falta pagar.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente'**
  String get paymentPendingTitle;

  /// La persona avisó que pagó; {amount} es el importe con «Bs».
  ///
  /// In es, this message translates to:
  /// **'Avisaste que pagaste {amount}. Central lo está revisando.'**
  String paymentReportedMessage(String amount);

  /// Falta pagar; {amount} es el importe con «Bs».
  ///
  /// In es, this message translates to:
  /// **'Paga {amount} para que busquemos a tu chófer.'**
  String paymentPendingMessage(String amount);

  /// Botón para abrir el pago ya avisado.
  ///
  /// In es, this message translates to:
  /// **'Ver el pago'**
  String get paymentViewPayment;

  /// Botón para abrir la pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Pagar ahora'**
  String get paymentPayNow;

  /// Título del comprobante de pago.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de pago'**
  String get paymentReceiptTitle;

  /// Etiqueta del botón que pliega el comprobante.
  ///
  /// In es, this message translates to:
  /// **'Ocultar comprobante'**
  String get paymentReceiptHide;

  /// Etiqueta del botón que despliega el comprobante.
  ///
  /// In es, this message translates to:
  /// **'Ver comprobante'**
  String get paymentReceiptShow;

  /// Aclaración del comprobante: no es una factura.
  ///
  /// In es, this message translates to:
  /// **'Este comprobante no es una factura.'**
  String get paymentReceiptNotInvoice;

  /// Fila del comprobante: importe pagado.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get paymentReceiptPaid;

  /// Fila del comprobante: fecha del pago.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get paymentReceiptDate;

  /// Fila del comprobante: método de pago.
  ///
  /// In es, this message translates to:
  /// **'Método'**
  String get paymentReceiptMethod;

  /// Fila del comprobante: retención por cancelar.
  ///
  /// In es, this message translates to:
  /// **'Retención por cancelación'**
  String get paymentReceiptRetained;

  /// Fila del comprobante: devolución aún no registrada.
  ///
  /// In es, this message translates to:
  /// **'Devolución pendiente'**
  String get paymentReceiptRefundPending;

  /// Nota bajo la devolución pendiente; sin plazos.
  ///
  /// In es, this message translates to:
  /// **'Central la registrará y te avisaremos cuando quede hecha.'**
  String get paymentReceiptRefundPendingNote;

  /// Fila del comprobante: importe devuelto.
  ///
  /// In es, this message translates to:
  /// **'Devuelto'**
  String get paymentReceiptRefunded;

  /// Nota bajo el importe devuelto.
  ///
  /// In es, this message translates to:
  /// **'Te devolvemos el dinero al método con el que pagaste.'**
  String get paymentReceiptRefundedNote;

  /// Fila del comprobante: saldo que falta pagar.
  ///
  /// In es, this message translates to:
  /// **'Saldo pendiente'**
  String get paymentReceiptBalanceDue;

  /// Nota bajo el saldo pendiente; sin promesas de contacto.
  ///
  /// In es, this message translates to:
  /// **'El importe final del viaje fue mayor que lo pagado.'**
  String get paymentReceiptBalanceNote;
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
