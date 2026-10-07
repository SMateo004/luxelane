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

  /// No description provided for @bookingAllFeesIncluded.
  ///
  /// In es, this message translates to:
  /// **'Todos los cargos incluidos'**
  String get bookingAllFeesIncluded;

  /// No description provided for @bookingApplyOffer.
  ///
  /// In es, this message translates to:
  /// **'Aplicar oferta'**
  String get bookingApplyOffer;

  /// No description provided for @bookingAssuranceFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo, sin sorpresas'**
  String get bookingAssuranceFixedPrice;

  /// No description provided for @bookingAssuranceVerified.
  ///
  /// In es, this message translates to:
  /// **'Chóferes verificados'**
  String get bookingAssuranceVerified;

  /// No description provided for @bookingAuthCreateAccountCta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get bookingAuthCreateAccountCta;

  /// No description provided for @bookingAuthEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get bookingAuthEmail;

  /// No description provided for @bookingAuthEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@ejemplo.com'**
  String get bookingAuthEmailHint;

  /// No description provided for @bookingAuthFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get bookingAuthFullName;

  /// No description provided for @bookingAuthFullNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get bookingAuthFullNameHint;

  /// No description provided for @bookingAuthHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get bookingAuthHaveAccount;

  /// No description provided for @bookingAuthHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get bookingAuthHidePassword;

  /// No description provided for @bookingAuthNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Crear una'**
  String get bookingAuthNoAccount;

  /// No description provided for @bookingAuthPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get bookingAuthPassword;

  /// No description provided for @bookingAuthShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get bookingAuthShowPassword;

  /// No description provided for @bookingAuthSignInCta.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get bookingAuthSignInCta;

  /// No description provided for @bookingAuthSubtitleLogin.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para confirmar tu reserva.'**
  String get bookingAuthSubtitleLogin;

  /// No description provided for @bookingAuthSubtitleRegister.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta de Luxelane para completar la reserva.'**
  String get bookingAuthSubtitleRegister;

  /// No description provided for @bookingAuthTitleLogin.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get bookingAuthTitleLogin;

  /// No description provided for @bookingAuthTitleRegister.
  ///
  /// In es, this message translates to:
  /// **'Crear una cuenta'**
  String get bookingAuthTitleRegister;

  /// No description provided for @bookingBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get bookingBackHome;

  /// No description provided for @bookingBaseFare.
  ///
  /// In es, this message translates to:
  /// **'Tarifa base'**
  String get bookingBaseFare;

  /// No description provided for @bookingBreakdownHeading.
  ///
  /// In es, this message translates to:
  /// **'DESGLOSE'**
  String get bookingBreakdownHeading;

  /// No description provided for @bookingCapacityLuggageInfo.
  ///
  /// In es, this message translates to:
  /// **'Basado en tamaños estándar de equipaje, que pueden diferir de los tuyos. Puedes especificar los detalles de tu equipaje en las \"Notas de recogida\" en el siguiente paso.'**
  String get bookingCapacityLuggageInfo;

  /// No description provided for @bookingCapacityTitle.
  ///
  /// In es, this message translates to:
  /// **'Capacidad'**
  String get bookingCapacityTitle;

  /// Shown when a saved card has no brand
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get bookingCardFallback;

  /// No description provided for @bookingChauffeurAtDisposal.
  ///
  /// In es, this message translates to:
  /// **'Chófer a disposición · {hours} h'**
  String bookingChauffeurAtDisposal(int hours);

  /// No description provided for @bookingChooseExperience.
  ///
  /// In es, this message translates to:
  /// **'Elige tu experiencia'**
  String get bookingChooseExperience;

  /// Ride type page header
  ///
  /// In es, this message translates to:
  /// **'Elegir servicio'**
  String get bookingChooseService;

  /// No description provided for @bookingConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reserva'**
  String get bookingConfirmCta;

  /// No description provided for @bookingConfirmedEyebrow.
  ///
  /// In es, this message translates to:
  /// **'RESERVA CONFIRMADA'**
  String get bookingConfirmedEyebrow;

  /// No description provided for @bookingConfirmedHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te esperará.'**
  String get bookingConfirmedHeadline;

  /// No description provided for @bookingConfirmedSemantics.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get bookingConfirmedSemantics;

  /// No description provided for @bookingCountdownOnTheWay.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer está en camino.'**
  String get bookingCountdownOnTheWay;

  /// No description provided for @bookingDateTime.
  ///
  /// In es, this message translates to:
  /// **'{date} · {time}'**
  String bookingDateTime(String date, String time);

  /// No description provided for @bookingDescriptiveText.
  ///
  /// In es, this message translates to:
  /// **'Premium hecho práctico. Asientos espaciosos, un viaje suave y recogidas puntuales que mantienen tu día en ritmo.'**
  String get bookingDescriptiveText;

  /// No description provided for @bookingDestinationLabel.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get bookingDestinationLabel;

  /// No description provided for @bookingDistanceKm.
  ///
  /// In es, this message translates to:
  /// **'{distance} km'**
  String bookingDistanceKm(String distance);

  /// No description provided for @bookingErrorCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la reserva'**
  String get bookingErrorCreateFailed;

  /// No description provided for @bookingErrorInvalidFlight.
  ///
  /// In es, this message translates to:
  /// **'Revisa el número de vuelo (ej. LA 8810).'**
  String get bookingErrorInvalidFlight;

  /// No description provided for @bookingErrorPaymentNotAuthorised.
  ///
  /// In es, this message translates to:
  /// **'No pudimos autorizar tu tarjeta. Inténtalo de nuevo o elige otra.'**
  String get bookingErrorPaymentNotAuthorised;

  /// No description provided for @bookingErrorQuoteExpired.
  ///
  /// In es, this message translates to:
  /// **'La cotización venció. Vuelve a confirmar para ver el precio actualizado.'**
  String get bookingErrorQuoteExpired;

  /// No description provided for @bookingErrorQuoteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cotizar el viaje'**
  String get bookingErrorQuoteFailed;

  /// No description provided for @bookingErrorQuoteMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta la cotización del viaje'**
  String get bookingErrorQuoteMissing;

  /// No description provided for @bookingErrorRateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar tu calificación'**
  String get bookingErrorRateFailed;

  /// No description provided for @bookingErrorTooManyPassengers.
  ///
  /// In es, this message translates to:
  /// **'El número de pasajeros supera la capacidad del vehículo.'**
  String get bookingErrorTooManyPassengers;

  /// No description provided for @bookingEstimatedTax.
  ///
  /// In es, this message translates to:
  /// **'Impuesto estimado'**
  String get bookingEstimatedTax;

  /// No description provided for @bookingEstimatedTotal.
  ///
  /// In es, this message translates to:
  /// **'TOTAL ESTIMADO'**
  String get bookingEstimatedTotal;

  /// No description provided for @bookingFixedPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'PRECIO FIJO'**
  String get bookingFixedPriceLabel;

  /// No description provided for @bookingFixedPricePaidByCard.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo · tarjeta autorizada'**
  String get bookingFixedPricePaidByCard;

  /// No description provided for @bookingFixedPricePayDriver.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo · pago al chófer'**
  String get bookingFixedPricePayDriver;

  /// No description provided for @bookingFlight.
  ///
  /// In es, this message translates to:
  /// **'Vuelo {flight}'**
  String bookingFlight(String flight);

  /// No description provided for @bookingFlightNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de vuelo'**
  String get bookingFlightNumber;

  /// No description provided for @bookingFlightNumberHint.
  ///
  /// In es, this message translates to:
  /// **'ej. LA 8810 (opcional)'**
  String get bookingFlightNumberHint;

  /// No description provided for @bookingForGuest.
  ///
  /// In es, this message translates to:
  /// **'Reservar para un invitado'**
  String get bookingForGuest;

  /// No description provided for @bookingForGuestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar o añadir un invitado'**
  String get bookingForGuestSubtitle;

  /// No description provided for @bookingForMyself.
  ///
  /// In es, this message translates to:
  /// **'Reservar para mí'**
  String get bookingForMyself;

  /// No description provided for @bookingForMyselfSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reserva con la información de tu cuenta'**
  String get bookingForMyselfSubtitle;

  /// No description provided for @bookingFreeCancellationShort.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 1 h antes'**
  String get bookingFreeCancellationShort;

  /// No description provided for @bookingGuestDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la información de tu invitado y bríndale un servicio premium. Lo mantendremos informado sobre su trayecto durante todo el proceso. No te preocupes, no compartiremos ninguna información de pago o facturación con él.'**
  String get bookingGuestDialogBody;

  /// No description provided for @bookingGuestDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir nuevo invitado'**
  String get bookingGuestDialogTitle;

  /// Guest shown on the 'Book for a guest' card, e.g. 'Sr. Juan Pérez'
  ///
  /// In es, this message translates to:
  /// **'{title} {firstName} {lastName}'**
  String bookingGuestDisplayName(String title, String firstName, String lastName);

  /// No description provided for @bookingGuestEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo del invitado'**
  String get bookingGuestEmailHint;

  /// No description provided for @bookingGuestFirstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get bookingGuestFirstName;

  /// No description provided for @bookingGuestFirstNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del invitado'**
  String get bookingGuestFirstNameHint;

  /// No description provided for @bookingGuestLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get bookingGuestLastName;

  /// No description provided for @bookingGuestLastNameHint.
  ///
  /// In es, this message translates to:
  /// **'Apellido del invitado'**
  String get bookingGuestLastNameHint;

  /// No description provided for @bookingGuestPhone.
  ///
  /// In es, this message translates to:
  /// **'Número de móvil del invitado'**
  String get bookingGuestPhone;

  /// No description provided for @bookingGuestPhoneHelp.
  ///
  /// In es, this message translates to:
  /// **'Tu invitado recibirá las notificaciones del trayecto en este número'**
  String get bookingGuestPhoneHelp;

  /// No description provided for @bookingGuestTitleDr.
  ///
  /// In es, this message translates to:
  /// **'Dr.'**
  String get bookingGuestTitleDr;

  /// No description provided for @bookingGuestTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento'**
  String get bookingGuestTitleLabel;

  /// No description provided for @bookingGuestTitleMr.
  ///
  /// In es, this message translates to:
  /// **'Sr.'**
  String get bookingGuestTitleMr;

  /// No description provided for @bookingGuestTitleMrs.
  ///
  /// In es, this message translates to:
  /// **'Sra.'**
  String get bookingGuestTitleMrs;

  /// No description provided for @bookingGuestTitleMs.
  ///
  /// In es, this message translates to:
  /// **'Srta.'**
  String get bookingGuestTitleMs;

  /// No description provided for @bookingGuestTitleProf.
  ///
  /// In es, this message translates to:
  /// **'Prof.'**
  String get bookingGuestTitleProf;

  /// No description provided for @bookingHeroTagline.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo · Sin sorpresas · Disponible en todo el mundo'**
  String get bookingHeroTagline;

  /// Large two-line heading on the web booking page; keep the line break
  ///
  /// In es, this message translates to:
  /// **'Elige tu\nexperiencia'**
  String get bookingHeroTitle;

  /// No description provided for @bookingHoursShort.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String bookingHoursShort(int hours);

  /// No description provided for @bookingIncludedChargers.
  ///
  /// In es, this message translates to:
  /// **'Cargadores para iOS y Android a bordo'**
  String get bookingIncludedChargers;

  /// No description provided for @bookingIncludedFreeCancellation.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 1 hora antes de la recogida'**
  String get bookingIncludedFreeCancellation;

  /// No description provided for @bookingIncludedMeetGreet.
  ///
  /// In es, this message translates to:
  /// **'Recibimiento personalizado'**
  String get bookingIncludedMeetGreet;

  /// No description provided for @bookingIncludedTissues.
  ///
  /// In es, this message translates to:
  /// **'Pañuelos y toallitas desinfectantes de cortesía'**
  String get bookingIncludedTissues;

  /// No description provided for @bookingIncludedTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué incluye'**
  String get bookingIncludedTitle;

  /// No description provided for @bookingIncludedWaiting.
  ///
  /// In es, this message translates to:
  /// **'Hasta {minutes} minutos de espera gratuita'**
  String bookingIncludedWaiting(int minutes);

  /// No description provided for @bookingIncludedWater.
  ///
  /// In es, this message translates to:
  /// **'Agua fría de cortesía incluida'**
  String get bookingIncludedWater;

  /// No description provided for @bookingLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu reserva'**
  String get bookingLoadErrorTitle;

  /// No description provided for @bookingLuggage.
  ///
  /// In es, this message translates to:
  /// **'Equipaje'**
  String get bookingLuggage;

  /// No description provided for @bookingLuggageCarryOn.
  ///
  /// In es, this message translates to:
  /// **'{count} x De mano'**
  String bookingLuggageCarryOn(int count);

  /// No description provided for @bookingLuggageChecked.
  ///
  /// In es, this message translates to:
  /// **'{count} x Facturada estándar'**
  String bookingLuggageChecked(int count);

  /// No description provided for @bookingLuggageExtraLarge.
  ///
  /// In es, this message translates to:
  /// **'{count} x Extra grande'**
  String bookingLuggageExtraLarge(int count);

  /// No description provided for @bookingNotFound.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no está disponible.'**
  String get bookingNotFound;

  /// No description provided for @bookingNoteCapacity.
  ///
  /// In es, this message translates to:
  /// **'Los límites de capacidad de pasajeros y equipaje deben respetarse por razones de seguridad. Si se exceden, el chófer podrá rechazar el servicio.'**
  String get bookingNoteCapacity;

  /// No description provided for @bookingNoteExtras.
  ///
  /// In es, this message translates to:
  /// **'Las necesidades adicionales (silla de ruedas, asiento infantil, artículos extra) pueden añadirse en \"Notas de recogida\". Elige Business Van para grupos más grandes o equipaje adicional.'**
  String get bookingNoteExtras;

  /// No description provided for @bookingNoteImages.
  ///
  /// In es, this message translates to:
  /// **'Las imágenes del vehículo son solo de referencia. El vehículo real puede variar manteniendo una calidad equivalente o superior.'**
  String get bookingNoteImages;

  /// No description provided for @bookingPassengers.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros'**
  String get bookingPassengers;

  /// Already-formatted unitPassengers and unitBags
  ///
  /// In es, this message translates to:
  /// **'{passengers} · {bags}'**
  String bookingPassengersAndBags(String passengers, String bags);

  /// No description provided for @bookingPayOnTripBody.
  ///
  /// In es, this message translates to:
  /// **'Pagas el precio fijo a tu chófer en efectivo o con QR. Nada se cobra al reservar.'**
  String get bookingPayOnTripBody;

  /// No description provided for @bookingPayOnTripTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago al finalizar el viaje'**
  String get bookingPayOnTripTitle;

  /// No description provided for @bookingPaymentFailed.
  ///
  /// In es, this message translates to:
  /// **'El pago falló'**
  String get bookingPaymentFailed;

  /// No description provided for @bookingPaymentMethodHeading.
  ///
  /// In es, this message translates to:
  /// **'MÉTODO DE PAGO'**
  String get bookingPaymentMethodHeading;

  /// No description provided for @bookingPickupInDays.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Recogida en 1 día} other{Recogida en {days} días}}'**
  String bookingPickupInDays(int days);

  /// No description provided for @bookingPickupInHours.
  ///
  /// In es, this message translates to:
  /// **'Recogida en {hours} h'**
  String bookingPickupInHours(int hours);

  /// No description provided for @bookingPickupInHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'Recogida en {hours} h {minutes} min'**
  String bookingPickupInHoursMinutes(int hours, int minutes);

  /// No description provided for @bookingPickupInMinutes.
  ///
  /// In es, this message translates to:
  /// **'Recogida en {minutes} min'**
  String bookingPickupInMinutes(int minutes);

  /// No description provided for @bookingPickupLabel.
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get bookingPickupLabel;

  /// No description provided for @bookingPleaseNote.
  ///
  /// In es, this message translates to:
  /// **'Nota importante:'**
  String get bookingPleaseNote;

  /// No description provided for @bookingPriceBreakdownTitle.
  ///
  /// In es, this message translates to:
  /// **'Desglose de precio'**
  String get bookingPriceBreakdownTitle;

  /// No description provided for @bookingPriceConfirmedBody.
  ///
  /// In es, this message translates to:
  /// **'El precio fijo de tu viaje es {price}. No cambiará aunque haya tráfico.'**
  String bookingPriceConfirmedBody(String price);

  /// Dialog shown when the server quote differs from the on-screen estimate
  ///
  /// In es, this message translates to:
  /// **'Precio confirmado'**
  String get bookingPriceConfirmedTitle;

  /// No description provided for @bookingReference.
  ///
  /// In es, this message translates to:
  /// **'Código de reserva: {code}'**
  String bookingReference(String code);

  /// Web reserve button; vehicle is the class name in upper case
  ///
  /// In es, this message translates to:
  /// **'RESERVAR {vehicle}'**
  String bookingReserveCta(String vehicle);

  /// No description provided for @bookingRoutePreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de ruta'**
  String get bookingRoutePreview;

  /// No description provided for @bookingSeating.
  ///
  /// In es, this message translates to:
  /// **'Asientos'**
  String get bookingSeating;

  /// No description provided for @bookingSeatingFive.
  ///
  /// In es, this message translates to:
  /// **'Cinco pasajeros'**
  String get bookingSeatingFive;

  /// No description provided for @bookingSeatingInfantSeat.
  ///
  /// In es, this message translates to:
  /// **'Asiento de bebé'**
  String get bookingSeatingInfantSeat;

  /// No description provided for @bookingSeatingInfo.
  ///
  /// In es, this message translates to:
  /// **'Elige la configuración de asientos que mejor se adapte a tus necesidades. Los asientos especiales (infantil / bebé) deben solicitarse con anticipación y están sujetos a disponibilidad.'**
  String get bookingSeatingInfo;

  /// No description provided for @bookingSeatingThree.
  ///
  /// In es, this message translates to:
  /// **'Tres pasajeros'**
  String get bookingSeatingThree;

  /// No description provided for @bookingSeatingTwo.
  ///
  /// In es, this message translates to:
  /// **'Dos pasajeros'**
  String get bookingSeatingTwo;

  /// No description provided for @bookingSeatsUpTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta {count} pax'**
  String bookingSeatsUpTo(int count);

  /// No description provided for @bookingSelectRouteError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el punto de recogida y el destino'**
  String get bookingSelectRouteError;

  /// No description provided for @bookingSelectedBadge.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONADO'**
  String get bookingSelectedBadge;

  /// No description provided for @bookingSlideBusiness1.
  ///
  /// In es, this message translates to:
  /// **'Confort ejecutivo en cada trayecto'**
  String get bookingSlideBusiness1;

  /// No description provided for @bookingSlideBusiness2.
  ///
  /// In es, this message translates to:
  /// **'Puntual, profesional y perfectamente refinado'**
  String get bookingSlideBusiness2;

  /// No description provided for @bookingSlideBusiness3.
  ///
  /// In es, this message translates to:
  /// **'Llega con confianza, en cada ocasión'**
  String get bookingSlideBusiness3;

  /// No description provided for @bookingSlideBusiness4.
  ///
  /// In es, this message translates to:
  /// **'Premium hecho práctico para el ejecutivo moderno'**
  String get bookingSlideBusiness4;

  /// No description provided for @bookingSlideElectric1.
  ///
  /// In es, this message translates to:
  /// **'Totalmente eléctrico, silencioso y de nivel ejecutivo'**
  String get bookingSlideElectric1;

  /// No description provided for @bookingSlideElectric2.
  ///
  /// In es, this message translates to:
  /// **'Cero emisiones, máxima experiencia de lujo'**
  String get bookingSlideElectric2;

  /// No description provided for @bookingSlideFirst1.
  ///
  /// In es, this message translates to:
  /// **'Un nivel extraordinario de lujo te espera'**
  String get bookingSlideFirst1;

  /// No description provided for @bookingSlideFirst2.
  ///
  /// In es, this message translates to:
  /// **'Diseñado para quienes exigen lo mejor'**
  String get bookingSlideFirst2;

  /// No description provided for @bookingSlideFirst3.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y elegancia en cada traslado'**
  String get bookingSlideFirst3;

  /// No description provided for @bookingSlideFirst4.
  ///
  /// In es, this message translates to:
  /// **'Primera clase, de puerta a puerta'**
  String get bookingSlideFirst4;

  /// No description provided for @bookingSlideVan1.
  ///
  /// In es, this message translates to:
  /// **'Espacio y confort para todo tu equipo'**
  String get bookingSlideVan1;

  /// No description provided for @bookingSlideVan2.
  ///
  /// In es, this message translates to:
  /// **'Traslados grupales sin estrés y con puntualidad'**
  String get bookingSlideVan2;

  /// No description provided for @bookingSlideVan3.
  ///
  /// In es, this message translates to:
  /// **'El viaje perfecto para familias y grupos'**
  String get bookingSlideVan3;

  /// No description provided for @bookingSlideVan4.
  ///
  /// In es, this message translates to:
  /// **'Capacidad premium, sin compromiso en el confort'**
  String get bookingSlideVan4;

  /// No description provided for @bookingSpecialRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes especiales'**
  String get bookingSpecialRequests;

  /// No description provided for @bookingSpecialRequestsHint.
  ///
  /// In es, this message translates to:
  /// **'Asiento infantil, letrero de bienvenida…'**
  String get bookingSpecialRequestsHint;

  /// No description provided for @bookingStepDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get bookingStepDetails;

  /// No description provided for @bookingStepOf.
  ///
  /// In es, this message translates to:
  /// **'PASO {step} DE {total}'**
  String bookingStepOf(int step, int total);

  /// No description provided for @bookingStepVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get bookingStepVehicle;

  /// No description provided for @bookingSummaryDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get bookingSummaryDistance;

  /// No description provided for @bookingSummaryDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get bookingSummaryDuration;

  /// No description provided for @bookingSummaryEstDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración est.'**
  String get bookingSummaryEstDuration;

  /// No description provided for @bookingSummaryFlight.
  ///
  /// In es, this message translates to:
  /// **'Vuelo'**
  String get bookingSummaryFlight;

  /// No description provided for @bookingSummaryFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get bookingSummaryFrom;

  /// No description provided for @bookingSummaryHeading.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN DE RESERVA'**
  String get bookingSummaryHeading;

  /// No description provided for @bookingSummaryNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get bookingSummaryNotes;

  /// No description provided for @bookingSummaryService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get bookingSummaryService;

  /// No description provided for @bookingSummaryTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get bookingSummaryTo;

  /// No description provided for @bookingTripDetailsHeading.
  ///
  /// In es, this message translates to:
  /// **'DETALLES DEL VIAJE'**
  String get bookingTripDetailsHeading;

  /// No description provided for @bookingViewMyBooking.
  ///
  /// In es, this message translates to:
  /// **'VER MI RESERVA'**
  String get bookingViewMyBooking;

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

  /// No description provided for @driverAcceptRide.
  ///
  /// In es, this message translates to:
  /// **'Aceptar viaje'**
  String get driverAcceptRide;

  /// No description provided for @driverActionArrived.
  ///
  /// In es, this message translates to:
  /// **'He llegado'**
  String get driverActionArrived;

  /// No description provided for @driverActionCompleteTrip.
  ///
  /// In es, this message translates to:
  /// **'Completar viaje'**
  String get driverActionCompleteTrip;

  /// No description provided for @driverActionGoToPickup.
  ///
  /// In es, this message translates to:
  /// **'Ir al punto de recogida'**
  String get driverActionGoToPickup;

  /// No description provided for @driverActionGoToPickupShort.
  ///
  /// In es, this message translates to:
  /// **'Ir a la recogida'**
  String get driverActionGoToPickupShort;

  /// No description provided for @driverActionStartTrip.
  ///
  /// In es, this message translates to:
  /// **'Iniciar viaje'**
  String get driverActionStartTrip;

  /// No description provided for @driverActiveRide.
  ///
  /// In es, this message translates to:
  /// **'Viaje activo'**
  String get driverActiveRide;

  /// No description provided for @driverCompletedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 viaje completado} other{{count} viajes completados}}'**
  String driverCompletedCount(int count);

  /// No description provided for @driverCompletedTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados'**
  String get driverCompletedTrips;

  /// Driver home: title when the driver data cannot load
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get driverConnectionErrorTitle;

  /// No description provided for @driverDecline.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get driverDecline;

  /// Driver home: signed-in user is not a chauffeur
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta no tiene acceso de chófer.'**
  String get driverErrorUnauthorized;

  /// No description provided for @driverEstimatedFare.
  ///
  /// In es, this message translates to:
  /// **'Tarifa estimada'**
  String get driverEstimatedFare;

  /// No description provided for @driverGoOnline.
  ///
  /// In es, this message translates to:
  /// **'Conectarse'**
  String get driverGoOnline;

  /// No description provided for @driverMapsOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron abrir los mapas'**
  String get driverMapsOpenError;

  /// No description provided for @driverMsgHeadToPickup.
  ///
  /// In es, this message translates to:
  /// **'Dirígete al punto de recogida'**
  String get driverMsgHeadToPickup;

  /// No description provided for @driverMsgInProgress.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso · ve al destino'**
  String get driverMsgInProgress;

  /// No description provided for @driverMsgOnTheWay.
  ///
  /// In es, this message translates to:
  /// **'En camino a la recogida · llegando pronto'**
  String get driverMsgOnTheWay;

  /// No description provided for @driverMsgWaitingPassenger.
  ///
  /// In es, this message translates to:
  /// **'Esperando al pasajero'**
  String get driverMsgWaitingPassenger;

  /// No description provided for @driverNavigateTo.
  ///
  /// In es, this message translates to:
  /// **'Navegar hacia {address}'**
  String driverNavigateTo(String address);

  /// No description provided for @driverNavigateToDestination.
  ///
  /// In es, this message translates to:
  /// **'Navegar hacia el destino'**
  String get driverNavigateToDestination;

  /// No description provided for @driverNavigateToPickup.
  ///
  /// In es, this message translates to:
  /// **'Navegar hacia la recogida'**
  String get driverNavigateToPickup;

  /// No description provided for @driverNoCompletedTrips.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay viajes completados'**
  String get driverNoCompletedTrips;

  /// No description provided for @driverNoMapsApps.
  ///
  /// In es, this message translates to:
  /// **'No hay aplicaciones de mapas disponibles'**
  String get driverNoMapsApps;

  /// No description provided for @driverOfferExpiring.
  ///
  /// In es, this message translates to:
  /// **'Oferta por expirar'**
  String get driverOfferExpiring;

  /// No description provided for @driverOfflineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa el interruptor para conectarte'**
  String get driverOfflineSubtitle;

  /// No description provided for @driverOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás desconectado'**
  String get driverOfflineTitle;

  /// No description provided for @driverOnbBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get driverOnbBack;

  /// No description provided for @driverOnbColor.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get driverOnbColor;

  /// Pre-filled vehicle colour
  ///
  /// In es, this message translates to:
  /// **'Negro'**
  String get driverOnbDefaultColor;

  /// No description provided for @driverOnbExpiryFormat.
  ///
  /// In es, this message translates to:
  /// **'Usa MM/AAAA'**
  String get driverOnbExpiryFormat;

  /// No description provided for @driverOnbInvalid.
  ///
  /// In es, this message translates to:
  /// **'Inválido'**
  String get driverOnbInvalid;

  /// No description provided for @driverOnbInvalidMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes inválido'**
  String get driverOnbInvalidMonth;

  /// No description provided for @driverOnbLicenseExpired.
  ///
  /// In es, this message translates to:
  /// **'Licencia vencida'**
  String get driverOnbLicenseExpired;

  /// No description provided for @driverOnbLicenseExpiry.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento (MM/AAAA)'**
  String get driverOnbLicenseExpiry;

  /// No description provided for @driverOnbLicenseNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de licencia'**
  String get driverOnbLicenseNumber;

  /// No description provided for @driverOnbLicenseSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos serán revisados antes de que puedas aceptar viajes.'**
  String get driverOnbLicenseSubtitle;

  /// No description provided for @driverOnbLicenseTitle.
  ///
  /// In es, this message translates to:
  /// **'Licencia de conducir'**
  String get driverOnbLicenseTitle;

  /// No description provided for @driverOnbLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get driverOnbLogout;

  /// No description provided for @driverOnbMake.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get driverOnbMake;

  /// No description provided for @driverOnbModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get driverOnbModel;

  /// No description provided for @driverOnbPlate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get driverOnbPlate;

  /// No description provided for @driverOnbReviewNotice.
  ///
  /// In es, this message translates to:
  /// **'Un administrador verificará tus documentos antes de que puedas conectarte.'**
  String get driverOnbReviewNotice;

  /// No description provided for @driverOnbSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar tus datos. Inténtalo de nuevo.'**
  String get driverOnbSaveError;

  /// No description provided for @driverOnbVehicleClass.
  ///
  /// In es, this message translates to:
  /// **'Categoría del vehículo'**
  String get driverOnbVehicleClass;

  /// No description provided for @driverOnbVehicleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra el vehículo que vas a conducir.'**
  String get driverOnbVehicleSubtitle;

  /// No description provided for @driverOnbVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu vehículo'**
  String get driverOnbVehicleTitle;

  /// No description provided for @driverOnbYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get driverOnbYear;

  /// No description provided for @driverOnlineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esperando nuevas solicitudes de viaje'**
  String get driverOnlineSubtitle;

  /// No description provided for @driverOnlineTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás conectado'**
  String get driverOnlineTitle;

  /// No description provided for @driverPaid.
  ///
  /// In es, this message translates to:
  /// **'PAGADO'**
  String get driverPaid;

  /// No description provided for @driverQueueAvailable.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUDES DISPONIBLES'**
  String get driverQueueAvailable;

  /// No description provided for @driverQueueEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Las nuevas reservas aparecerán aquí'**
  String get driverQueueEmptyBody;

  /// No description provided for @driverQueueEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin trabajos aún'**
  String get driverQueueEmptyTitle;

  /// No description provided for @driverQueueMyActive.
  ///
  /// In es, this message translates to:
  /// **'MIS TRABAJOS ACTIVOS'**
  String get driverQueueMyActive;

  /// No description provided for @driverQueueOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Activa tu disponibilidad en la pestaña Inicio'**
  String get driverQueueOfflineBody;

  /// No description provided for @driverQueueOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para recibir trabajos'**
  String get driverQueueOfflineTitle;

  /// No description provided for @driverQueueTitle.
  ///
  /// In es, this message translates to:
  /// **'Cola de trabajos'**
  String get driverQueueTitle;

  /// Incoming request sheet eyebrow (uppercase)
  ///
  /// In es, this message translates to:
  /// **'SOLICITUD EXCLUSIVA PARA TI'**
  String get driverRequestExclusive;

  /// Incoming request sheet eyebrow (uppercase)
  ///
  /// In es, this message translates to:
  /// **'NUEVA SOLICITUD DE VIAJE'**
  String get driverRequestNew;

  /// Countdown to accept an exclusive offer
  ///
  /// In es, this message translates to:
  /// **'Responde en {seconds}s'**
  String driverRespondIn(int seconds);

  /// Stat card label (completed trips); shown uppercase
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get driverStatCompleted;

  /// Stat card label, earnings tab and page title
  ///
  /// In es, this message translates to:
  /// **'Ganancias'**
  String get driverStatEarnings;

  /// No description provided for @driverTabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get driverTabHome;

  /// No description provided for @driverTabJobs.
  ///
  /// In es, this message translates to:
  /// **'Trabajos'**
  String get driverTabJobs;

  /// No description provided for @driverTabProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get driverTabProfile;

  /// No description provided for @driverTodaySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de hoy'**
  String get driverTodaySummary;

  /// No description provided for @driverTotalEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ganancias totales'**
  String get driverTotalEarnings;

  /// No description provided for @driverTripNotFound.
  ///
  /// In es, this message translates to:
  /// **'Viaje no encontrado'**
  String get driverTripNotFound;

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

  /// Bell tooltip / screen-reader label when there are unread notifications
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 notificación sin leer} other{{count} notificaciones sin leer}}'**
  String notifBellUnread(int count);

  /// No description provided for @notifEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notificaciones'**
  String get notifEmpty;

  /// No description provided for @notifHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {hours} h'**
  String notifHoursAgo(int hours);

  /// No description provided for @notifJustNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get notifJustNow;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notifMarkAllRead;

  /// No description provided for @notifMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes} min'**
  String notifMinutesAgo(int minutes);

  /// No description provided for @notifTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifTitle;

  /// No description provided for @rideArrived.
  ///
  /// In es, this message translates to:
  /// **'¡Has llegado!'**
  String get rideArrived;

  /// No description provided for @rideArrivesIn.
  ///
  /// In es, this message translates to:
  /// **'Llega en {eta}'**
  String rideArrivesIn(String eta);

  /// No description provided for @rideAssigning.
  ///
  /// In es, this message translates to:
  /// **'Asignando a tu chófer'**
  String get rideAssigning;

  /// No description provided for @rideAssigningBody.
  ///
  /// In es, this message translates to:
  /// **'Estamos confirmando a tu chófer. Te avisaremos apenas esté asignado.'**
  String get rideAssigningBody;

  /// No description provided for @rideBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get rideBackHome;

  /// No description provided for @rideCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get rideCancelled;

  /// eta is a duration like '4 min'
  ///
  /// In es, this message translates to:
  /// **'Tu chófer llega en {eta}'**
  String rideChauffeurArrivesIn(String eta);

  /// No description provided for @rideChauffeurConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Chófer confirmado'**
  String get rideChauffeurConfirmed;

  /// No description provided for @rideChauffeurOnTheWay.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer está en camino'**
  String get rideChauffeurOnTheWay;

  /// No description provided for @rideChauffeurWaiting.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te espera'**
  String get rideChauffeurWaiting;

  /// No description provided for @rideFlightArrivesAt.
  ///
  /// In es, this message translates to:
  /// **'Llega {time}'**
  String rideFlightArrivesAt(String time);

  /// No description provided for @rideFlightLandedAt.
  ///
  /// In es, this message translates to:
  /// **'Aterrizó {time}'**
  String rideFlightLandedAt(String time);

  /// No description provided for @rideFlightTitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelo {number}'**
  String rideFlightTitle(String number);

  /// No description provided for @rideFlightTitleTerminal.
  ///
  /// In es, this message translates to:
  /// **'Vuelo {number} · Terminal {terminal}'**
  String rideFlightTitleTerminal(String number, String terminal);

  /// No description provided for @rideHeadingToDestination.
  ///
  /// In es, this message translates to:
  /// **'En camino a tu destino'**
  String get rideHeadingToDestination;

  /// No description provided for @rideLive.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get rideLive;

  /// No description provided for @rideLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu reserva…'**
  String get rideLoading;

  /// No description provided for @rideNotifArrivedBody.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te espera en el punto de recogida.'**
  String get rideNotifArrivedBody;

  /// No description provided for @rideNotifArrivedTitle.
  ///
  /// In es, this message translates to:
  /// **'El chófer ha llegado'**
  String get rideNotifArrivedTitle;

  /// No description provided for @rideNotifArrivingBody.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer se dirige a tu punto de recogida.'**
  String get rideNotifArrivingBody;

  /// No description provided for @rideNotifArrivingTitle.
  ///
  /// In es, this message translates to:
  /// **'El chófer está en camino'**
  String get rideNotifArrivingTitle;

  /// No description provided for @rideNotifAssignedBody.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer confirmó la reserva.'**
  String get rideNotifAssignedBody;

  /// No description provided for @rideNotifAssignedTitle.
  ///
  /// In es, this message translates to:
  /// **'Chófer asignado'**
  String get rideNotifAssignedTitle;

  /// No description provided for @rideNotifCompletedBody.
  ///
  /// In es, this message translates to:
  /// **'¡Has llegado! Gracias por viajar con Luxelane.'**
  String get rideNotifCompletedBody;

  /// No description provided for @rideNotifCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'Viaje completado'**
  String get rideNotifCompletedTitle;

  /// No description provided for @rideNotifStartedBody.
  ///
  /// In es, this message translates to:
  /// **'Ya estás en camino hacia tu destino.'**
  String get rideNotifStartedBody;

  /// No description provided for @rideNotifStartedTitle.
  ///
  /// In es, this message translates to:
  /// **'Viaje iniciado'**
  String get rideNotifStartedTitle;

  /// Pickup date/time line; time is already formatted
  ///
  /// In es, this message translates to:
  /// **'Recogida {time}'**
  String ridePickupAt(String time);

  /// No description provided for @rideRateTrip.
  ///
  /// In es, this message translates to:
  /// **'Calificar viaje'**
  String get rideRateTrip;

  /// No description provided for @rideRatingCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get rideRatingCommentHint;

  /// No description provided for @rideRatingExcellent.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get rideRatingExcellent;

  /// No description provided for @rideRatingFair.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get rideRatingFair;

  /// No description provided for @rideRatingGood.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get rideRatingGood;

  /// No description provided for @rideRatingPoor.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get rideRatingPoor;

  /// No description provided for @rideRatingStars.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 estrella} other{{count} estrellas}}'**
  String rideRatingStars(int count);

  /// No description provided for @rideRatingThanks.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por tu calificación!'**
  String get rideRatingThanks;

  /// No description provided for @rideRatingTitle.
  ///
  /// In es, this message translates to:
  /// **'Califica tu viaje'**
  String get rideRatingTitle;

  /// No description provided for @rideRatingVeryPoor.
  ///
  /// In es, this message translates to:
  /// **'Muy malo'**
  String get rideRatingVeryPoor;

  /// No description provided for @rideThanks.
  ///
  /// In es, this message translates to:
  /// **'Gracias por viajar con Luxelane'**
  String get rideThanks;

  /// No description provided for @rideThanksForRating.
  ///
  /// In es, this message translates to:
  /// **'Gracias por calificar'**
  String get rideThanksForRating;

  /// No description provided for @rideVerifiedChauffeur.
  ///
  /// In es, this message translates to:
  /// **'Chófer verificado'**
  String get rideVerifiedChauffeur;

  /// No description provided for @rideVerifiedTrips.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Verificado · 1 viaje} other{Verificado · {count} viajes}}'**
  String rideVerifiedTrips(int count);

  /// No description provided for @rideViewReceipt.
  ///
  /// In es, this message translates to:
  /// **'Ver recibo'**
  String get rideViewReceipt;

  /// No description provided for @rideYouArriveIn.
  ///
  /// In es, this message translates to:
  /// **'Llegas en {eta}'**
  String rideYouArriveIn(String eta);

  /// No description provided for @rideYourChauffeur.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer'**
  String get rideYourChauffeur;

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
  /// **'Un traslado al aeropuerto de pago es un servicio de transporte con un conductor profesional reservado con antelación, con un precio fijo en bolivianos que se confirma antes de reservar.'**
  String get servicesAirportFaq3A;

  /// No description provided for @servicesAirportFaq3Q.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es un traslado al aeropuerto de pago?'**
  String get servicesAirportFaq3Q;

  /// No description provided for @servicesAirportFeatureFlexBody.
  ///
  /// In es, this message translates to:
  /// **'Manténgase flexible: cancele sin costo hasta 1 hora antes de la recogida, desde la app.'**
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
  /// **'Tarifa fija por hora: conoces el precio antes de reservar'**
  String get servicesHourlyBullet4;

  /// No description provided for @servicesHourlyBullet5.
  ///
  /// In es, this message translates to:
  /// **'Fiabilidad: Chóferes formados en los más altos estándares'**
  String get servicesHourlyBullet5;

  /// No description provided for @servicesHourlyBullet6.
  ///
  /// In es, this message translates to:
  /// **'Chóferes verificados por nuestro equipo'**
  String get servicesHourlyBullet6;

  /// No description provided for @servicesHourlyBullet7.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en vivo de tu chófer desde la app'**
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
  /// **'Cuando se asigna tu chófer recibirás una notificación y verás en la app su nombre, vehículo, placa y teléfono.'**
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
  /// **'Disponible en Santa Cruz de la Sierra · Reserva desde la app o la web'**
  String get servicesHourlyReachBanner;

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
  /// **'Disponible en Santa Cruz de la Sierra'**
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

  /// No description provided for @tripDestination.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get tripDestination;

  /// No description provided for @tripFlightNumber.
  ///
  /// In es, this message translates to:
  /// **'Vuelo {number}'**
  String tripFlightNumber(String number);

  /// No description provided for @tripFreeWaitLeft.
  ///
  /// In es, this message translates to:
  /// **'Espera gratuita: {minutes} min'**
  String tripFreeWaitLeft(int minutes);

  /// No description provided for @tripFreeWaitOver.
  ///
  /// In es, this message translates to:
  /// **'Espera gratuita terminada a las {time}'**
  String tripFreeWaitOver(String time);

  /// No description provided for @tripFreeWaitOverDriver.
  ///
  /// In es, this message translates to:
  /// **'Contacta al pasajero antes de retirarte.'**
  String get tripFreeWaitOverDriver;

  /// No description provided for @tripFreeWaitOverRider.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer sigue esperándote. Avísale si necesitas más tiempo.'**
  String get tripFreeWaitOverRider;

  /// summary is waitAirportSummary/waitCitySummary
  ///
  /// In es, this message translates to:
  /// **'Hasta las {time} · {summary}'**
  String tripFreeWaitUntil(String time, String summary);

  /// No description provided for @tripMeetGreetBody.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te esperará en la salida de llegadas con un cartel con tu nombre.'**
  String get tripMeetGreetBody;

  /// No description provided for @tripMeetGreetBodyNamed.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te esperará en la salida de llegadas con un cartel con el nombre «{name}».'**
  String tripMeetGreetBodyNamed(String name);

  /// No description provided for @tripMeetGreetTitle.
  ///
  /// In es, this message translates to:
  /// **'Meet & greet en llegadas'**
  String get tripMeetGreetTitle;

  /// No description provided for @tripMeetGreetWait.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de espera gratuita desde que aterriza tu vuelo.'**
  String tripMeetGreetWait(int minutes);

  /// No description provided for @tripNameSignSemantics.
  ///
  /// In es, this message translates to:
  /// **'Cartel con el nombre {name}. Toca para cerrar.'**
  String tripNameSignSemantics(String name);

  /// No description provided for @tripNameSignTapToClose.
  ///
  /// In es, this message translates to:
  /// **'Toca la pantalla para cerrar'**
  String get tripNameSignTapToClose;

  /// No description provided for @tripPassenger.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get tripPassenger;

  /// No description provided for @tripPickup.
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get tripPickup;

  /// No description provided for @tripPriceBaseFare.
  ///
  /// In es, this message translates to:
  /// **'Tarifa base'**
  String get tripPriceBaseFare;

  /// No description provided for @tripPriceBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Desglose del precio'**
  String get tripPriceBreakdown;

  /// No description provided for @tripPriceDistanceLine.
  ///
  /// In es, this message translates to:
  /// **'{km} km × {rate}'**
  String tripPriceDistanceLine(String km, String rate);

  /// No description provided for @tripPriceEstimatedTotal.
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get tripPriceEstimatedTotal;

  /// No description provided for @tripPriceFinalNote.
  ///
  /// In es, this message translates to:
  /// **'El precio fijo final se confirma antes de reservar.'**
  String get tripPriceFinalNote;

  /// No description provided for @tripPriceHoursLine.
  ///
  /// In es, this message translates to:
  /// **'{hours} h × {rate}'**
  String tripPriceHoursLine(int hours, String rate);

  /// No description provided for @tripPriceMinimumAdjustment.
  ///
  /// In es, this message translates to:
  /// **'Ajuste a tarifa mínima'**
  String get tripPriceMinimumAdjustment;

  /// No description provided for @tripReceiptAdjustment.
  ///
  /// In es, this message translates to:
  /// **'Ajuste'**
  String get tripReceiptAdjustment;

  /// No description provided for @tripReceiptCancelled.
  ///
  /// In es, this message translates to:
  /// **'RESERVA CANCELADA'**
  String get tripReceiptCancelled;

  /// No description provided for @tripReceiptCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get tripReceiptCard;

  /// No description provided for @tripReceiptCompleted.
  ///
  /// In es, this message translates to:
  /// **'VIAJE COMPLETADO'**
  String get tripReceiptCompleted;

  /// No description provided for @tripReceiptCopied.
  ///
  /// In es, this message translates to:
  /// **'Recibo copiado al portapapeles'**
  String get tripReceiptCopied;

  /// No description provided for @tripReceiptCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar recibo'**
  String get tripReceiptCopy;

  /// No description provided for @tripReceiptCurrencyNote.
  ///
  /// In es, this message translates to:
  /// **'Montos en bolivianos (BOB).'**
  String get tripReceiptCurrencyNote;

  /// No description provided for @tripReceiptDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get tripReceiptDuration;

  /// No description provided for @tripReceiptFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo'**
  String get tripReceiptFixedPrice;

  /// No description provided for @tripReceiptFlight.
  ///
  /// In es, this message translates to:
  /// **'Vuelo'**
  String get tripReceiptFlight;

  /// No description provided for @tripReceiptNoCharge.
  ///
  /// In es, this message translates to:
  /// **'Sin cargo'**
  String get tripReceiptNoCharge;

  /// No description provided for @tripReceiptNumber.
  ///
  /// In es, this message translates to:
  /// **'Nº {code}'**
  String tripReceiptNumber(String code);

  /// No description provided for @tripReceiptPassengers.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros'**
  String get tripReceiptPassengers;

  /// No description provided for @tripReceiptPayChauffeur.
  ///
  /// In es, this message translates to:
  /// **'Pago al chófer'**
  String get tripReceiptPayChauffeur;

  /// No description provided for @tripReceiptPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Forma de pago'**
  String get tripReceiptPaymentMethod;

  /// No description provided for @tripReceiptPlainFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde: {place}'**
  String tripReceiptPlainFrom(String place);

  /// First line of the copyable plain-text receipt
  ///
  /// In es, this message translates to:
  /// **'Luxelane — Recibo {code}'**
  String tripReceiptPlainHeader(String code);

  /// No description provided for @tripReceiptPlainTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta: {place}'**
  String tripReceiptPlainTo(String place);

  /// No description provided for @tripReceiptPlainTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {amount}'**
  String tripReceiptPlainTotal(String amount);

  /// No description provided for @tripReceiptService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get tripReceiptService;

  /// No description provided for @tripReceiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Recibo'**
  String get tripReceiptTitle;

  /// No description provided for @tripReceiptTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get tripReceiptTotal;

  /// No description provided for @tripReceiptVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get tripReceiptVehicle;

  /// No description provided for @tripShowSign.
  ///
  /// In es, this message translates to:
  /// **'Mostrar cartel'**
  String get tripShowSign;

  /// No description provided for @tripsBookNow.
  ///
  /// In es, this message translates to:
  /// **'Reservar ahora'**
  String get tripsBookNow;

  /// No description provided for @tripsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes viajes.\nReserva tu primera experiencia.'**
  String get tripsEmpty;

  /// No description provided for @tripsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus viajes. Revisa tu conexión.'**
  String get tripsLoadError;

  /// No description provided for @tripsPast.
  ///
  /// In es, this message translates to:
  /// **'ANTERIORES'**
  String get tripsPast;

  /// Trip card title for an hourly booking
  ///
  /// In es, this message translates to:
  /// **'{origin} · {hours} h'**
  String tripsRouteByHour(String origin, int hours);

  /// No description provided for @tripsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get tripsTitle;

  /// No description provided for @tripsUpcoming.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMOS'**
  String get tripsUpcoming;

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
