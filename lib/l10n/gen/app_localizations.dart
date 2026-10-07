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

  /// No description provided for @servicesAirportArriveBody.
  ///
  /// In es, this message translates to:
  /// **'Un servicio de chófer de Luxelane busca alcanzar los estándares más altos posibles para todos sus pasajeros. Nuestros conductores profesionales pueden hacer un seguimiento de su vuelo y ajustar la hora de recogida si hay retrasos fuera de su control.'**
  String get servicesAirportArriveBody;

  /// No description provided for @servicesAirportArriveTitle.
  ///
  /// In es, this message translates to:
  /// **'Llegue o salga del aeropuerto'**
  String get servicesAirportArriveTitle;

  /// No description provided for @servicesAirportClassesTitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre nuestras clases de servicio'**
  String get servicesAirportClassesTitle;

  /// No description provided for @servicesAirportConnectionsBody.
  ///
  /// In es, this message translates to:
  /// **'Reservar un servicio de Luxelane es fácil. Simplemente proporcione los datos de recogida y destino y seleccione la clase del vehículo. El precio que ve es el precio que paga, sin cargos ocultos.'**
  String get servicesAirportConnectionsBody;

  /// No description provided for @servicesAirportConnectionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Reservas de conexiones entre aeropuertos'**
  String get servicesAirportConnectionsTitle;

  /// No description provided for @servicesAirportFaq1A.
  ///
  /// In es, this message translates to:
  /// **'Un traslado al aeropuerto es un servicio de coche privado que lleva a los pasajeros de avión hacia y desde el aeropuerto. Los conductores profesionales pueden recoger a los pasajeros en la terminal después de recoger su equipaje.'**
  String get servicesAirportFaq1A;

  /// No description provided for @servicesAirportFaq1Q.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hace un traslado al aeropuerto?'**
  String get servicesAirportFaq1Q;

  /// No description provided for @servicesAirportFaq2A.
  ///
  /// In es, this message translates to:
  /// **'Los traslados al aeropuerto son una forma estupenda de evitar el estrés tanto al inicio como al final de un vuelo. Luxelane ofrece una amplia gama de opciones de traslado que se adaptan a tus necesidades.'**
  String get servicesAirportFaq2A;

  /// No description provided for @servicesAirportFaq2Q.
  ///
  /// In es, this message translates to:
  /// **'¿Merece la pena reservar un traslado desde el aeropuerto?'**
  String get servicesAirportFaq2Q;

  /// No description provided for @servicesAirportFaq3A.
  ///
  /// In es, this message translates to:
  /// **'Un traslado al aeropuerto de pago es un servicio de transporte con un conductor profesional reservado con antelación. El precio incluye propinas, peajes y cualquier otro gasto adicional.'**
  String get servicesAirportFaq3A;

  /// No description provided for @servicesAirportFaq3Q.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es un traslado al aeropuerto de pago?'**
  String get servicesAirportFaq3Q;

  /// No description provided for @servicesAirportFeatureFlexBody.
  ///
  /// In es, this message translates to:
  /// **'Manténgase flexible. Es rápido y fácil cancelar o hacer cambios en cualquier viaje.'**
  String get servicesAirportFeatureFlexBody;

  /// No description provided for @servicesAirportFeatureFlexTitle.
  ///
  /// In es, this message translates to:
  /// **'Flexibilidad de viaje'**
  String get servicesAirportFeatureFlexTitle;

  /// No description provided for @servicesAirportFeatureFlightBody.
  ///
  /// In es, this message translates to:
  /// **'Relájese con la hora gratuita de espera y el seguimiento de vuelos.'**
  String get servicesAirportFeatureFlightBody;

  /// No description provided for @servicesAirportFeatureFlightTitle.
  ///
  /// In es, this message translates to:
  /// **'Viaje al aeropuerto sin problemas'**
  String get servicesAirportFeatureFlightTitle;

  /// No description provided for @servicesAirportFeaturePriceBody.
  ///
  /// In es, this message translates to:
  /// **'Acceda a un servicio de primera calidad a precios basados en la distancia.'**
  String get servicesAirportFeaturePriceBody;

  /// Airport booking panel: complimentary waiting time (WaitingPolicy.airportFreeMinutes)
  ///
  /// In es, this message translates to:
  /// **'El chófer esperará {minutes} minutos sin coste adicional.'**
  String servicesAirportFreeWait(int minutes);

  /// No description provided for @servicesAirportHeroEyebrow.
  ///
  /// In es, this message translates to:
  /// **'SERVICIO DE TRASLADOS'**
  String get servicesAirportHeroEyebrow;

  /// No description provided for @servicesAirportHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Al aeropuerto sin\nestrés ni esperas'**
  String get servicesAirportHeroTitle;

  /// No description provided for @servicesAirportPanelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ida o Por horas · Sin esperas'**
  String get servicesAirportPanelSubtitle;

  /// No description provided for @servicesAirportPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Traslados al aeropuerto'**
  String get servicesAirportPanelTitle;

  /// Service landing pages: link back to the home page
  ///
  /// In es, this message translates to:
  /// **'← Volver al inicio'**
  String get servicesBackHome;

  /// Service landing pages: CTA button
  ///
  /// In es, this message translates to:
  /// **'RESERVAR AHORA'**
  String get servicesBookNow;

  /// Service landing pages: navigation bar CTA
  ///
  /// In es, this message translates to:
  /// **'RESERVAR UN VIAJE'**
  String get servicesBookRide;

  /// No description provided for @servicesFaqTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get servicesFaqTitle;

  /// No description provided for @servicesFeaturePriceTitle.
  ///
  /// In es, this message translates to:
  /// **'Precios competitivos'**
  String get servicesFeaturePriceTitle;

  /// Footer of the service landing pages
  ///
  /// In es, this message translates to:
  /// **'© {year} Luxelane · Todos los derechos reservados'**
  String servicesFooterRights(String year);

  /// Booking panel: pickup field hint
  ///
  /// In es, this message translates to:
  /// **'De - Dirección, aeropuerto, hotel...'**
  String get servicesFromHint;

  /// No description provided for @servicesHourlyBullet1.
  ///
  /// In es, this message translates to:
  /// **'Define tu itinerario: Tú decides dónde y cuándo ir'**
  String get servicesHourlyBullet1;

  /// No description provided for @servicesHourlyBullet2.
  ///
  /// In es, this message translates to:
  /// **'Ahorra tiempo: Te dejaremos y recogeremos en la puerta de cada parada'**
  String get servicesHourlyBullet2;

  /// No description provided for @servicesHourlyBullet3.
  ///
  /// In es, this message translates to:
  /// **'Disfruta con tranquilidad: Viaja en un vehículo premium'**
  String get servicesHourlyBullet3;

  /// No description provided for @servicesHourlyBullet4.
  ///
  /// In es, this message translates to:
  /// **'Tarifas competitivas: Incluye 40 km de recorrido por hora'**
  String get servicesHourlyBullet4;

  /// No description provided for @servicesHourlyBullet5.
  ///
  /// In es, this message translates to:
  /// **'Fiabilidad: Chóferes formados en los más altos estándares'**
  String get servicesHourlyBullet5;

  /// No description provided for @servicesHourlyBullet6.
  ///
  /// In es, this message translates to:
  /// **'Sostenibilidad: Cada viaje se compensa con emisiones de carbono'**
  String get servicesHourlyBullet6;

  /// No description provided for @servicesHourlyBullet7.
  ///
  /// In es, this message translates to:
  /// **'Wifi disponible en la mayoría de los vehículos'**
  String get servicesHourlyBullet7;

  /// No description provided for @servicesHourlyBullet8.
  ///
  /// In es, this message translates to:
  /// **'Diseñado para la ciudad: Comienza y termina en la misma ciudad'**
  String get servicesHourlyBullet8;

  /// Hourly booking panel: duration selector; duration is unitHours(n)
  ///
  /// In es, this message translates to:
  /// **'Duración - {duration}'**
  String servicesHourlyDurationField(String duration);

  /// No description provided for @servicesHourlyFaq1A.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el lugar de recogida, elige la duración, el día y la hora, elige una clase de vehículo y completa tu reserva.'**
  String get servicesHourlyFaq1A;

  /// No description provided for @servicesHourlyFaq1Q.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo reservo un chófer por horas?'**
  String get servicesHourlyFaq1Q;

  /// No description provided for @servicesHourlyFaq2A.
  ///
  /// In es, this message translates to:
  /// **'Sí. El conductor y el vehículo están a tu disposición en todo momento durante las horas de la reserva.'**
  String get servicesHourlyFaq2A;

  /// No description provided for @servicesHourlyFaq2Q.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo modificar mi itinerario durante el viaje?'**
  String get servicesHourlyFaq2Q;

  /// No description provided for @servicesHourlyFaq3A.
  ///
  /// In es, this message translates to:
  /// **'Una hora antes de la recogida se te enviarán un SMS y un correo electrónico con el nombre y número del conductor.'**
  String get servicesHourlyFaq3A;

  /// No description provided for @servicesHourlyFaq3Q.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo recibiré los datos del chófer?'**
  String get servicesHourlyFaq3Q;

  /// No description provided for @servicesHourlyFaq4A.
  ///
  /// In es, this message translates to:
  /// **'Sí, la reserva puede empezar o terminar en un aeropuerto. El lugar de inicio y finalización deben estar en la misma ciudad.'**
  String get servicesHourlyFaq4A;

  /// No description provided for @servicesHourlyFaq4Q.
  ///
  /// In es, this message translates to:
  /// **'¿La reserva puede empezar en un aeropuerto?'**
  String get servicesHourlyFaq4Q;

  /// No description provided for @servicesHourlyFaq5A.
  ///
  /// In es, this message translates to:
  /// **'Sí, puedes editar la reserva antes de la hora de inicio. La duración mínima es {min} horas, máximo {max} horas.'**
  String servicesHourlyFaq5A(int min, int max);

  /// No description provided for @servicesHourlyFaq5Q.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo aumentar el número de horas?'**
  String get servicesHourlyFaq5Q;

  /// No description provided for @servicesHourlyHeroEyebrow.
  ///
  /// In es, this message translates to:
  /// **'CONTRATACIÓN POR HORAS'**
  String get servicesHourlyHeroEyebrow;

  /// No description provided for @servicesHourlyHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Alquiler de chófer\npor horas y días'**
  String get servicesHourlyHeroTitle;

  /// No description provided for @servicesHourlyPanelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu itinerario · Tu ritmo'**
  String get servicesHourlyPanelSubtitle;

  /// No description provided for @servicesHourlyPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Chófer por horas'**
  String get servicesHourlyPanelTitle;

  /// No description provided for @servicesHourlyReachBanner.
  ///
  /// In es, this message translates to:
  /// **'Disponible en más de 60 países · Cientos de ciudades'**
  String get servicesHourlyReachBanner;

  /// No description provided for @servicesHourlyReview1.
  ///
  /// In es, this message translates to:
  /// **'El chófer fue increíble, me ayudó con mis maletas y se detuvo en todos los lugares que quería ver.'**
  String get servicesHourlyReview1;

  /// No description provided for @servicesHourlyReview1Origin.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos'**
  String get servicesHourlyReview1Origin;

  /// No description provided for @servicesHourlyReview2.
  ///
  /// In es, this message translates to:
  /// **'Los chóferes no son simples conductores sino profesionales altamente capacitados.'**
  String get servicesHourlyReview2;

  /// No description provided for @servicesHourlyReview2Origin.
  ///
  /// In es, this message translates to:
  /// **'Portugal'**
  String get servicesHourlyReview2Origin;

  /// No description provided for @servicesHourlyReview3.
  ///
  /// In es, this message translates to:
  /// **'La aplicación que todos los viajeros necesitan conocer. No he encontrado un lugar donde no funcione.'**
  String get servicesHourlyReview3;

  /// No description provided for @servicesHourlyReview3Origin.
  ///
  /// In es, this message translates to:
  /// **'Canadá'**
  String get servicesHourlyReview3Origin;

  /// No description provided for @servicesHourlyReviewsTitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que dicen nuestros clientes'**
  String get servicesHourlyReviewsTitle;

  /// No description provided for @servicesHourlyServiceBody.
  ///
  /// In es, this message translates to:
  /// **'Olvídate de cambiar de medio de transporte cuando tengas que hacer viajes con múltiples paradas. Con Luxelane, defines tu itinerario: tú decides dónde y cuándo ir.'**
  String get servicesHourlyServiceBody;

  /// No description provided for @servicesHourlyServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio de chófer por horas'**
  String get servicesHourlyServiceTitle;

  /// No description provided for @servicesHourlyUseBusinessBody.
  ///
  /// In es, this message translates to:
  /// **'Concéntrate en lo importante. Desplázate fácilmente entre reuniones sin preocuparte por la logística.'**
  String get servicesHourlyUseBusinessBody;

  /// No description provided for @servicesHourlyUseBusinessTitle.
  ///
  /// In es, this message translates to:
  /// **'Viajes de negocios'**
  String get servicesHourlyUseBusinessTitle;

  /// No description provided for @servicesHourlyUseCasesTitle.
  ///
  /// In es, this message translates to:
  /// **'Diseñado para cada ocasión'**
  String get servicesHourlyUseCasesTitle;

  /// No description provided for @servicesHourlyUseEventsBody.
  ///
  /// In es, this message translates to:
  /// **'Disfruta de una llegada triunfal y una salida sin contratiempos de cualquier evento.'**
  String get servicesHourlyUseEventsBody;

  /// No description provided for @servicesHourlyUseEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Conciertos y eventos'**
  String get servicesHourlyUseEventsTitle;

  /// No description provided for @servicesHourlyUseLeisureBody.
  ///
  /// In es, this message translates to:
  /// **'Ya sea un almuerzo, compras o tu lista de tareas, tu chófer estará listo cuando lo necesites.'**
  String get servicesHourlyUseLeisureBody;

  /// No description provided for @servicesHourlyUseLeisureTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividades de ocio'**
  String get servicesHourlyUseLeisureTitle;

  /// No description provided for @servicesHourlyUseSightseeingBody.
  ///
  /// In es, this message translates to:
  /// **'Descubre la ciudad a tu manera, a tu ritmo, con un chófer local siempre a tu disposición.'**
  String get servicesHourlyUseSightseeingBody;

  /// No description provided for @servicesHourlyUseSightseeingTitle.
  ///
  /// In es, this message translates to:
  /// **'Visitas turísticas'**
  String get servicesHourlyUseSightseeingTitle;

  /// Service landing pages: top navigation item
  ///
  /// In es, this message translates to:
  /// **'PARA EMPRESAS'**
  String get servicesNavBusiness;

  /// Service landing pages: top navigation item
  ///
  /// In es, this message translates to:
  /// **'FLOTA'**
  String get servicesNavFleet;

  /// Service landing pages: top navigation link
  ///
  /// In es, this message translates to:
  /// **'INICIO'**
  String get servicesNavHome;

  /// Service landing pages: top navigation item
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS'**
  String get servicesNavServices;

  /// No description provided for @servicesPickupChauffeursBody.
  ///
  /// In es, this message translates to:
  /// **'Viaje con confianza gracias a los chóferes expertos que le ofrecen la mejor calidad y discreción.'**
  String get servicesPickupChauffeursBody;

  /// No description provided for @servicesPickupChauffeursTitle.
  ///
  /// In es, this message translates to:
  /// **'Chóferes profesionales'**
  String get servicesPickupChauffeursTitle;

  /// No description provided for @servicesPickupComfortBody.
  ///
  /// In es, this message translates to:
  /// **'Un viaje privado en un vehículo de alta gama hace que cada viaje sea un placer.'**
  String get servicesPickupComfortBody;

  /// No description provided for @servicesPickupComfortTitle.
  ///
  /// In es, this message translates to:
  /// **'Comodidad'**
  String get servicesPickupComfortTitle;

  /// No description provided for @servicesPickupConvenienceBody.
  ///
  /// In es, this message translates to:
  /// **'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques.'**
  String get servicesPickupConvenienceBody;

  /// No description provided for @servicesPickupConvenienceTitle.
  ///
  /// In es, this message translates to:
  /// **'Conveniencia'**
  String get servicesPickupConvenienceTitle;

  /// No description provided for @servicesPickupHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Chóferes profesionales a su alcance'**
  String get servicesPickupHeroSubtitle;

  /// No description provided for @servicesPickupHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Servicio de\nRecogida Inmediata!'**
  String get servicesPickupHeroTitle;

  /// No description provided for @servicesPickupIntroBody.
  ///
  /// In es, this message translates to:
  /// **'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques en la aplicación Luxelane.'**
  String get servicesPickupIntroBody;

  /// No description provided for @servicesPickupIntroEyebrow.
  ///
  /// In es, this message translates to:
  /// **'RECOGIDA INMEDIATA'**
  String get servicesPickupIntroEyebrow;

  /// No description provided for @servicesPickupIntroTitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre el servicio de recogida inmediata'**
  String get servicesPickupIntroTitle;

  /// No description provided for @servicesPickupPriceBody.
  ///
  /// In es, this message translates to:
  /// **'Acceda a un servicio de primera calidad a precios basados en la distancia, justos para todos.'**
  String get servicesPickupPriceBody;

  /// No description provided for @servicesPickupQualityBody.
  ///
  /// In es, this message translates to:
  /// **'Hacer que su experiencia sea excelente es nuestra máxima prioridad en todos sus viajes.'**
  String get servicesPickupQualityBody;

  /// No description provided for @servicesPickupQualityTitle.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get servicesPickupQualityTitle;

  /// No description provided for @servicesPickupReliabilityBody.
  ///
  /// In es, this message translates to:
  /// **'Reserve con seguridad y manténgase informado con actualizaciones del estado del viaje en tiempo real.'**
  String get servicesPickupReliabilityBody;

  /// No description provided for @servicesPickupReliabilityTitle.
  ///
  /// In es, this message translates to:
  /// **'Fiabilidad'**
  String get servicesPickupReliabilityTitle;

  /// No description provided for @servicesPickupSplitBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando necesite una forma segura de desplazarse por la ciudad, piense en el servicio de recogida inmediata de Luxelane. La combinación perfecta entre el servicio tradicional de traslados y el transporte privado.'**
  String get servicesPickupSplitBody;

  /// No description provided for @servicesPickupSplitEyebrow.
  ///
  /// In es, this message translates to:
  /// **'CÓMODO · SEGURO · INMEDIATO'**
  String get servicesPickupSplitEyebrow;

  /// No description provided for @servicesPickupSplitTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómodos viajes a la carta en cuestión de minutos'**
  String get servicesPickupSplitTitle;

  /// Wraps a customer review in quotation marks
  ///
  /// In es, this message translates to:
  /// **'“{quote}”'**
  String servicesQuote(String quote);

  /// Service landing pages: booking panel CTA
  ///
  /// In es, this message translates to:
  /// **'SELECCIONAR'**
  String get servicesSelect;

  /// Booking panel: destination field hint
  ///
  /// In es, this message translates to:
  /// **'A - Dirección, aeropuerto, hotel...'**
  String get servicesToHint;

  /// Booking panel toggle: one-way transfer (the other option is serviceByTheHour)
  ///
  /// In es, this message translates to:
  /// **'Ida'**
  String get servicesToggleOneWay;

  /// Vehicle class luggage capacity
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hasta 1 maleta grande} other{Hasta {count} maletas grandes}}'**
  String servicesUpToLargeBags(int count);

  /// Vehicle class capacity
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hasta 1 persona} other{Hasta {count} personas}}'**
  String servicesUpToPeople(int count);

  /// No description provided for @servicesVehicleBusinessModels.
  ///
  /// In es, this message translates to:
  /// **'Mercedes Clase E, BMW Serie 5 o similar'**
  String get servicesVehicleBusinessModels;

  /// No description provided for @servicesVehicleFirstModels.
  ///
  /// In es, this message translates to:
  /// **'Mercedes Clase S, BMW Serie 7 o similar'**
  String get servicesVehicleFirstModels;

  /// No description provided for @servicesVehicleGroups.
  ///
  /// In es, this message translates to:
  /// **'Ideal para grupos y familias'**
  String get servicesVehicleGroups;

  /// No description provided for @servicesVehicleMostCities.
  ///
  /// In es, this message translates to:
  /// **'Disponible en la mayoría de ciudades'**
  String get servicesVehicleMostCities;

  /// No description provided for @servicesVehiclePremiumLuxury.
  ///
  /// In es, this message translates to:
  /// **'Servicio de lujo premium'**
  String get servicesVehiclePremiumLuxury;

  /// No description provided for @servicesVehicleVanModels.
  ///
  /// In es, this message translates to:
  /// **'Mercedes Clase V, Toyota Alphard o similar'**
  String get servicesVehicleVanModels;

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
