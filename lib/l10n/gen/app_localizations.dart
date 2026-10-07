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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Luxelane'**
  String get appName;

  /// No description provided for @appNameDriver.
  ///
  /// In es, this message translates to:
  /// **'Luxelane Chófer'**
  String get appNameDriver;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonCall.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get commonCall;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonConnectionError.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get commonConnectionError;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get commonCopy;

  /// No description provided for @commonCouldNotOpenApp.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la aplicación'**
  String get commonCouldNotOpenApp;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonGenericError.
  ///
  /// In es, this message translates to:
  /// **'Algo no salió bien'**
  String get commonGenericError;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get commonLoading;

  /// No description provided for @commonOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get commonOptional;

  /// No description provided for @commonRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get commonRefresh;

  /// No description provided for @commonRequired.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get commonRequired;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get commonSend;

  /// No description provided for @commonWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get commonWhatsApp;

  /// No description provided for @flightCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get flightCancelled;

  /// No description provided for @flightDelayed.
  ///
  /// In es, this message translates to:
  /// **'Retrasado {minutes} min'**
  String flightDelayed(int minutes);

  /// No description provided for @flightLanded.
  ///
  /// In es, this message translates to:
  /// **'Aterrizó'**
  String get flightLanded;

  /// No description provided for @flightOnTime.
  ///
  /// In es, this message translates to:
  /// **'A tiempo'**
  String get flightOnTime;

  /// Company tax ID and address under the contact details
  ///
  /// In es, this message translates to:
  /// **'NIT {nit} · {address}'**
  String legalCompanyDetails(String nit, String address);

  /// No description provided for @legalContactComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Los canales de contacto se publicarán pronto.'**
  String get legalContactComingSoon;

  /// Label of the support email contact tile
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get legalContactEmail;

  /// No description provided for @legalContactHeadline.
  ///
  /// In es, this message translates to:
  /// **'Estamos para ayudarte'**
  String get legalContactHeadline;

  /// No description provided for @legalContactIntro.
  ///
  /// In es, this message translates to:
  /// **'Escríbenos por cualquier consulta sobre una reserva, tu cuenta o tus datos. Si tienes un viaje en curso, usa los botones de contacto con tu chófer en la pantalla del viaje.'**
  String get legalContactIntro;

  /// App bar title of the contact page
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get legalContactTitle;

  /// No description provided for @legalDeleteActiveTrip.
  ///
  /// In es, this message translates to:
  /// **'Tienes un viaje en curso. Podrás eliminar tu cuenta cuando termine.'**
  String get legalDeleteActiveTrip;

  /// No description provided for @legalDeleteButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get legalDeleteButton;

  /// No description provided for @legalDeleteConfirmPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe {keyword} para confirmar.'**
  String legalDeleteConfirmPrompt(String keyword);

  /// No description provided for @legalDeleteConnectionError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta. Revisa tu conexión.'**
  String get legalDeleteConnectionError;

  /// No description provided for @legalDeleteEffectBookings.
  ///
  /// In es, this message translates to:
  /// **'Cancelamos tus reservas pendientes.'**
  String get legalDeleteEffectBookings;

  /// No description provided for @legalDeleteEffectDriver.
  ///
  /// In es, this message translates to:
  /// **'Si eres chófer, también borramos tu perfil de chófer y desactivamos tu vehículo.'**
  String get legalDeleteEffectDriver;

  /// No description provided for @legalDeleteEffectPermanent.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get legalDeleteEffectPermanent;

  /// No description provided for @legalDeleteEffectProfile.
  ///
  /// In es, this message translates to:
  /// **'Borramos tu perfil, tus notificaciones y tu acceso.'**
  String get legalDeleteEffectProfile;

  /// No description provided for @legalDeleteEffectTrips.
  ///
  /// In es, this message translates to:
  /// **'Quitamos tu nombre, teléfono y notas de tus viajes anteriores. Los registros de esos viajes se conservan sin datos de contacto por obligaciones contables.'**
  String get legalDeleteEffectTrips;

  /// No description provided for @legalDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta. Inténtalo de nuevo o contáctanos.'**
  String get legalDeleteFailed;

  /// No description provided for @legalDeleteHeadline.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tu cuenta'**
  String get legalDeleteHeadline;

  /// No description provided for @legalDeleteIntro.
  ///
  /// In es, this message translates to:
  /// **'Al eliminar tu cuenta:'**
  String get legalDeleteIntro;

  /// Word the user must type to confirm account deletion. Uppercase, no spaces.
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR'**
  String get legalDeleteKeyword;

  /// Button that opens the login page from the account deletion page
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get legalDeleteSignIn;

  /// No description provided for @legalDeleteSignInPrompt.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con la cuenta que quieres eliminar.'**
  String get legalDeleteSignInPrompt;

  /// No description provided for @legalDeleteSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta fue eliminada.'**
  String get legalDeleteSuccess;

  /// App bar title of the account deletion page
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get legalDeleteTitle;

  /// Warning banner on legal pages while company details are still placeholders
  ///
  /// In es, this message translates to:
  /// **'Borrador: este documento contiene datos pendientes entre corchetes y debe ser revisado por un abogado antes de publicarse.'**
  String get legalDraftBanner;

  /// Date the legal document was last revised
  ///
  /// In es, this message translates to:
  /// **'Última actualización: {date}'**
  String legalLastUpdated(DateTime date);

  /// No description provided for @serviceByTheHour.
  ///
  /// In es, this message translates to:
  /// **'Por horas'**
  String get serviceByTheHour;

  /// No description provided for @serviceByTheHourDesc.
  ///
  /// In es, this message translates to:
  /// **'Chófer a tu disposición por un tiempo determinado'**
  String get serviceByTheHourDesc;

  /// No description provided for @serviceOneWay.
  ///
  /// In es, this message translates to:
  /// **'Solo ida'**
  String get serviceOneWay;

  /// No description provided for @serviceOneWayDesc.
  ///
  /// In es, this message translates to:
  /// **'Traslado a precio fijo a tu destino'**
  String get serviceOneWayDesc;

  /// No description provided for @statusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get statusCancelled;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get statusCompleted;

  /// No description provided for @statusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get statusConfirmed;

  /// No description provided for @statusDriverArrived.
  ///
  /// In es, this message translates to:
  /// **'Chófer llegó'**
  String get statusDriverArrived;

  /// No description provided for @statusDriverArriving.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get statusDriverArriving;

  /// No description provided for @statusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get statusInProgress;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @unitBags.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 maleta} other{{count} maletas}}'**
  String unitBags(int count);

  /// No description provided for @unitHours.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hora} other{{count} horas}}'**
  String unitHours(int count);

  /// No description provided for @unitHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String unitHoursMinutes(int hours, String minutes);

  /// No description provided for @unitMinutesShort.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String unitMinutesShort(int minutes);

  /// No description provided for @unitPassengers.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pasajero} other{{count} pasajeros}}'**
  String unitPassengers(int count);

  /// No description provided for @unitTrips.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 viaje} other{{count} viajes}}'**
  String unitTrips(int count);

  /// No description provided for @vehicleBusiness.
  ///
  /// In es, this message translates to:
  /// **'Business Class'**
  String get vehicleBusiness;

  /// No description provided for @vehicleBusinessDesc.
  ///
  /// In es, this message translates to:
  /// **'Mercedes E-Class o similar'**
  String get vehicleBusinessDesc;

  /// No description provided for @vehicleBusinessVan.
  ///
  /// In es, this message translates to:
  /// **'Business Van'**
  String get vehicleBusinessVan;

  /// No description provided for @vehicleBusinessVanDesc.
  ///
  /// In es, this message translates to:
  /// **'Mercedes V-Class · Hasta 7'**
  String get vehicleBusinessVanDesc;

  /// No description provided for @vehicleElectric.
  ///
  /// In es, this message translates to:
  /// **'Eléctrico'**
  String get vehicleElectric;

  /// No description provided for @vehicleElectricDesc.
  ///
  /// In es, this message translates to:
  /// **'Tesla Model S o similar'**
  String get vehicleElectricDesc;

  /// No description provided for @vehicleFirstClass.
  ///
  /// In es, this message translates to:
  /// **'First Class'**
  String get vehicleFirstClass;

  /// No description provided for @vehicleFirstClassDesc.
  ///
  /// In es, this message translates to:
  /// **'Mercedes S-Class o similar'**
  String get vehicleFirstClassDesc;

  /// No description provided for @waitAirportSummary.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de espera gratuita desde el aterrizaje'**
  String waitAirportSummary(int minutes);

  /// No description provided for @waitCitySummary.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de espera gratuita'**
  String waitCitySummary(int minutes);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
