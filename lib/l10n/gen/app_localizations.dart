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

  /// No description provided for @adminActionFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción. Inténtalo de nuevo.'**
  String get adminActionFailed;

  /// No description provided for @adminActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get adminActive;

  /// No description provided for @adminAppVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get adminAppVersion;

  /// No description provided for @adminAssignNearest.
  ///
  /// In es, this message translates to:
  /// **'Asignar chófer más cercano'**
  String get adminAssignNearest;

  /// No description provided for @adminAttentionBanner.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 reserva sin chófer con recogida en menos de 2 horas} other{{count} reservas sin chófer con recogida en menos de 2 horas}}'**
  String adminAttentionBanner(int count);

  /// No description provided for @adminAttentionView.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get adminAttentionView;

  /// No description provided for @adminAuditBy.
  ///
  /// In es, this message translates to:
  /// **'Admin: {id}'**
  String adminAuditBy(String id);

  /// No description provided for @adminBackend.
  ///
  /// In es, this message translates to:
  /// **'Backend'**
  String get adminBackend;

  /// No description provided for @adminBookingActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get adminBookingActions;

  /// No description provided for @adminBookingDriver.
  ///
  /// In es, this message translates to:
  /// **'Chófer: {name}'**
  String adminBookingDriver(String name);

  /// No description provided for @adminBookingRider.
  ///
  /// In es, this message translates to:
  /// **'Pasajero: {name}'**
  String adminBookingRider(String name);

  /// No description provided for @adminBusinessPerformance.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento del negocio'**
  String get adminBusinessPerformance;

  /// No description provided for @adminCancelBooking.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get adminCancelBooking;

  /// No description provided for @adminCancelBookingBody.
  ///
  /// In es, this message translates to:
  /// **'El pasajero y el chófer asignado recibirán un aviso.'**
  String get adminCancelBookingBody;

  /// No description provided for @adminCancelBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar la reserva {code}?'**
  String adminCancelBookingTitle(String code);

  /// No description provided for @adminChangeRoleTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol de {name}'**
  String adminChangeRoleTitle(String name);

  /// No description provided for @adminCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get adminCurrency;

  /// No description provided for @adminCurrencyValue.
  ///
  /// In es, this message translates to:
  /// **'Bolivianos (Bs)'**
  String get adminCurrencyValue;

  /// No description provided for @adminDeleteBookingBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará permanentemente la reserva #{id}. Esta acción no se puede deshacer.'**
  String adminDeleteBookingBody(String id);

  /// No description provided for @adminDeleteBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar reserva?'**
  String get adminDeleteBookingTitle;

  /// No description provided for @adminDeleteBookingTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar reserva'**
  String get adminDeleteBookingTooltip;

  /// No description provided for @adminDisable.
  ///
  /// In es, this message translates to:
  /// **'Deshabilitar'**
  String get adminDisable;

  /// No description provided for @adminDocumentsVerified.
  ///
  /// In es, this message translates to:
  /// **'Documentos verificados'**
  String get adminDocumentsVerified;

  /// No description provided for @adminFieldBase.
  ///
  /// In es, this message translates to:
  /// **'Base (Bs)'**
  String get adminFieldBase;

  /// No description provided for @adminFieldMinimum.
  ///
  /// In es, this message translates to:
  /// **'Mínimo (Bs)'**
  String get adminFieldMinimum;

  /// No description provided for @adminFieldPerHour.
  ///
  /// In es, this message translates to:
  /// **'Por hora (Bs)'**
  String get adminFieldPerHour;

  /// No description provided for @adminFieldPerKm.
  ///
  /// In es, this message translates to:
  /// **'Por km (Bs)'**
  String get adminFieldPerKm;

  /// No description provided for @adminFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminFilterAll;

  /// No description provided for @adminFilterUnassigned.
  ///
  /// In es, this message translates to:
  /// **'Sin chófer'**
  String get adminFilterUnassigned;

  /// No description provided for @adminFirestoreRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas de precios de Firestore'**
  String get adminFirestoreRules;

  /// No description provided for @adminGlobalSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración global de la app'**
  String get adminGlobalSettings;

  /// No description provided for @adminInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get adminInactive;

  /// No description provided for @adminKpiAwaitingDriver.
  ///
  /// In es, this message translates to:
  /// **'Esperando chófer'**
  String get adminKpiAwaitingDriver;

  /// No description provided for @adminKpiCompleted.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados'**
  String get adminKpiCompleted;

  /// No description provided for @adminKpiDriversCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 chófer} other{{count} chóferes}}'**
  String adminKpiDriversCount(int count);

  /// No description provided for @adminKpiInProgress.
  ///
  /// In es, this message translates to:
  /// **'{count} en progreso'**
  String adminKpiInProgress(int count);

  /// No description provided for @adminKpiPending.
  ///
  /// In es, this message translates to:
  /// **'Reservas pendientes'**
  String get adminKpiPending;

  /// No description provided for @adminKpiToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy: {amount}'**
  String adminKpiToday(String amount);

  /// No description provided for @adminKpiTotalRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos totales'**
  String get adminKpiTotalRevenue;

  /// No description provided for @adminKpiUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios registrados'**
  String get adminKpiUsers;

  /// Driver's license number
  ///
  /// In es, this message translates to:
  /// **'Licencia: {number}'**
  String adminLicense(String number);

  /// No description provided for @adminLiveStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas en vivo'**
  String get adminLiveStats;

  /// No description provided for @adminMaintenanceBanner.
  ///
  /// In es, this message translates to:
  /// **'MODO MANTENIMIENTO ACTIVO — Los pasajeros no pueden reservar nuevos viajes.'**
  String get adminMaintenanceBanner;

  /// No description provided for @adminMaintenanceMode.
  ///
  /// In es, this message translates to:
  /// **'Modo mantenimiento'**
  String get adminMaintenanceMode;

  /// No description provided for @adminMaintenanceModeDesc.
  ///
  /// In es, this message translates to:
  /// **'Deshabilita todas las reservas y muestra la pantalla de mantenimiento a los usuarios.'**
  String get adminMaintenanceModeDesc;

  /// No description provided for @adminMemberSince.
  ///
  /// In es, this message translates to:
  /// **'Miembro desde {date}'**
  String adminMemberSince(String date);

  /// No description provided for @adminNoAuditLogs.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay registros de auditoría'**
  String get adminNoAuditLogs;

  /// No description provided for @adminNoAuditLogsHint.
  ///
  /// In es, this message translates to:
  /// **'Las acciones administrativas aparecerán aquí en tiempo real'**
  String get adminNoAuditLogsHint;

  /// No description provided for @adminNoBookings.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron reservas'**
  String get adminNoBookings;

  /// No description provided for @adminNoDrivers.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron chóferes'**
  String get adminNoDrivers;

  /// No description provided for @adminNoUsersMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún usuario coincide con la búsqueda'**
  String get adminNoUsersMatch;

  /// No description provided for @adminNoVehicles.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay vehículos registrados'**
  String get adminNoVehicles;

  /// No description provided for @adminNoVehiclesHint.
  ///
  /// In es, this message translates to:
  /// **'Los vehículos vinculados a chóferes aparecen aquí'**
  String get adminNoVehiclesHint;

  /// No description provided for @adminNoticeBookingCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get adminNoticeBookingCancelled;

  /// No description provided for @adminNoticeBookingDeleted.
  ///
  /// In es, this message translates to:
  /// **'Reserva eliminada'**
  String get adminNoticeBookingDeleted;

  /// No description provided for @adminNoticeDriverAssigned.
  ///
  /// In es, this message translates to:
  /// **'Chófer asignado'**
  String get adminNoticeDriverAssigned;

  /// No description provided for @adminNoticeDriverVerified.
  ///
  /// In es, this message translates to:
  /// **'Chófer verificado'**
  String get adminNoticeDriverVerified;

  /// No description provided for @adminNoticeMaintenanceOff.
  ///
  /// In es, this message translates to:
  /// **'Modo mantenimiento desactivado'**
  String get adminNoticeMaintenanceOff;

  /// No description provided for @adminNoticeMaintenanceOn.
  ///
  /// In es, this message translates to:
  /// **'Modo mantenimiento activado'**
  String get adminNoticeMaintenanceOn;

  /// No description provided for @adminNoticeNoDriver.
  ///
  /// In es, this message translates to:
  /// **'No hay chóferes disponibles cerca para esta clase de vehículo'**
  String get adminNoticeNoDriver;

  /// No description provided for @adminNoticePricingUpdated.
  ///
  /// In es, this message translates to:
  /// **'Regla de precios actualizada'**
  String get adminNoticePricingUpdated;

  /// No description provided for @adminNoticeRoleUpdated.
  ///
  /// In es, this message translates to:
  /// **'Rol actualizado'**
  String get adminNoticeRoleUpdated;

  /// No description provided for @adminNoticeSettingsSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get adminNoticeSettingsSaved;

  /// No description provided for @adminOffline.
  ///
  /// In es, this message translates to:
  /// **'Fuera de línea'**
  String get adminOffline;

  /// No description provided for @adminOnline.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get adminOnline;

  /// No description provided for @adminOverview.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get adminOverview;

  /// No description provided for @adminPanelBadge.
  ///
  /// In es, this message translates to:
  /// **'Panel admin'**
  String get adminPanelBadge;

  /// No description provided for @adminPlatform.
  ///
  /// In es, this message translates to:
  /// **'Plataforma'**
  String get adminPlatform;

  /// No description provided for @adminPlatformValue.
  ///
  /// In es, this message translates to:
  /// **'Flutter Web + móvil'**
  String get adminPlatformValue;

  /// No description provided for @adminPriceBaseAndKm.
  ///
  /// In es, this message translates to:
  /// **'{base} base + {perKm}/km'**
  String adminPriceBaseAndKm(String base, String perKm);

  /// No description provided for @adminPriceBasePlusKm.
  ///
  /// In es, this message translates to:
  /// **'{base} + {perKm}/km'**
  String adminPriceBasePlusKm(String base, String perKm);

  /// No description provided for @adminPriceMinimum.
  ///
  /// In es, this message translates to:
  /// **'Mín.: {amount}'**
  String adminPriceMinimum(String amount);

  /// No description provided for @adminPricePerHour.
  ///
  /// In es, this message translates to:
  /// **'{amount}/h'**
  String adminPricePerHour(String amount);

  /// No description provided for @adminPricingNote.
  ///
  /// In es, this message translates to:
  /// **'Los precios reflejan el modelo DefaultPricing. Si la colección pricingRules está vacía, los precios se calculan localmente.'**
  String get adminPricingNote;

  /// No description provided for @adminPricingRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas de precios (Bs)'**
  String get adminPricingRules;

  /// No description provided for @adminPushNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones push'**
  String get adminPushNotifications;

  /// No description provided for @adminPushNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Habilita notificaciones a nivel del sistema para nuevas reservas.'**
  String get adminPushNotificationsDesc;

  /// No description provided for @adminRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get adminRecentActivity;

  /// No description provided for @adminRegisteredDrivers.
  ///
  /// In es, this message translates to:
  /// **'Chóferes registrados'**
  String get adminRegisteredDrivers;

  /// No description provided for @adminRegisteredVehicles.
  ///
  /// In es, this message translates to:
  /// **'Vehículos registrados'**
  String get adminRegisteredVehicles;

  /// No description provided for @adminReportsAvgRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación promedio'**
  String get adminReportsAvgRating;

  /// No description provided for @adminReportsAvgTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket promedio'**
  String get adminReportsAvgTicket;

  /// No description provided for @adminReportsByAdmin.
  ///
  /// In es, this message translates to:
  /// **'Operaciones'**
  String get adminReportsByAdmin;

  /// No description provided for @adminReportsByRider.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get adminReportsByRider;

  /// No description provided for @adminReportsBySystem.
  ///
  /// In es, this message translates to:
  /// **'Automática'**
  String get adminReportsBySystem;

  /// No description provided for @adminReportsByUnknown.
  ///
  /// In es, this message translates to:
  /// **'Sin registro'**
  String get adminReportsByUnknown;

  /// No description provided for @adminReportsCancellationRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de cancelación'**
  String get adminReportsCancellationRate;

  /// No description provided for @adminReportsCancellations.
  ///
  /// In es, this message translates to:
  /// **'Cancelaciones por origen'**
  String get adminReportsCancellations;

  /// No description provided for @adminReportsCancelledOf.
  ///
  /// In es, this message translates to:
  /// **'{cancelled} de {total} reservas'**
  String adminReportsCancelledOf(int cancelled, int total);

  /// No description provided for @adminReportsColDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get adminReportsColDate;

  /// No description provided for @adminReportsColDriver.
  ///
  /// In es, this message translates to:
  /// **'Chófer'**
  String get adminReportsColDriver;

  /// No description provided for @adminReportsColRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get adminReportsColRating;

  /// No description provided for @adminReportsColRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos (Bs)'**
  String get adminReportsColRevenue;

  /// No description provided for @adminReportsColTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get adminReportsColTrips;

  /// No description provided for @adminReportsCopied.
  ///
  /// In es, this message translates to:
  /// **'CSV copiado al portapapeles'**
  String get adminReportsCopied;

  /// No description provided for @adminReportsDailyTable.
  ///
  /// In es, this message translates to:
  /// **'Ver datos por día'**
  String get adminReportsDailyTable;

  /// No description provided for @adminReportsDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String adminReportsDays(int days);

  /// No description provided for @adminReportsDownloaded.
  ///
  /// In es, this message translates to:
  /// **'CSV descargado'**
  String get adminReportsDownloaded;

  /// No description provided for @adminReportsDrivers.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento de chóferes'**
  String get adminReportsDrivers;

  /// No description provided for @adminReportsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay reservas con recogida en este período.'**
  String get adminReportsEmpty;

  /// No description provided for @adminReportsExportDaily.
  ///
  /// In es, this message translates to:
  /// **'Exportar días (CSV)'**
  String get adminReportsExportDaily;

  /// No description provided for @adminReportsExportDrivers.
  ///
  /// In es, this message translates to:
  /// **'Exportar chóferes (CSV)'**
  String get adminReportsExportDrivers;

  /// No description provided for @adminReportsLateCancellations.
  ///
  /// In es, this message translates to:
  /// **'Cancelaciones tardías'**
  String get adminReportsLateCancellations;

  /// No description provided for @adminReportsLateHint.
  ///
  /// In es, this message translates to:
  /// **'Del pasajero, dentro de la ventana con cargo'**
  String get adminReportsLateHint;

  /// No description provided for @adminReportsNoCancellations.
  ///
  /// In es, this message translates to:
  /// **'Sin cancelaciones en este período.'**
  String get adminReportsNoCancellations;

  /// No description provided for @adminReportsNoDrivers.
  ///
  /// In es, this message translates to:
  /// **'Ningún chófer completó viajes en este período.'**
  String get adminReportsNoDrivers;

  /// No description provided for @adminReportsNoPrevious.
  ///
  /// In es, this message translates to:
  /// **'Sin datos del período anterior'**
  String get adminReportsNoPrevious;

  /// No description provided for @adminReportsPeakHour.
  ///
  /// In es, this message translates to:
  /// **'Hora pico: {hour}'**
  String adminReportsPeakHour(String hour);

  /// No description provided for @adminReportsPeakHours.
  ///
  /// In es, this message translates to:
  /// **'Demanda por hora de recogida'**
  String get adminReportsPeakHours;

  /// No description provided for @adminReportsPeakHoursHint.
  ///
  /// In es, this message translates to:
  /// **'Todas las reservas del período, incluidas las canceladas.'**
  String get adminReportsPeakHoursHint;

  /// No description provided for @adminReportsPerTrip.
  ///
  /// In es, this message translates to:
  /// **'Por viaje completado'**
  String get adminReportsPerTrip;

  /// No description provided for @adminReportsRange.
  ///
  /// In es, this message translates to:
  /// **'Recogidas del {from} al {to} (hora local)'**
  String adminReportsRange(String from, String to);

  /// No description provided for @adminReportsRatingCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin calificaciones} =1{1 calificación} other{{count} calificaciones}}'**
  String adminReportsRatingCount(int count);

  /// No description provided for @adminReportsRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get adminReportsRevenue;

  /// No description provided for @adminReportsRevenuePerDay.
  ///
  /// In es, this message translates to:
  /// **'Ingresos por día (Bs)'**
  String get adminReportsRevenuePerDay;

  /// No description provided for @adminReportsServiceMix.
  ///
  /// In es, this message translates to:
  /// **'Viajes por tipo de servicio'**
  String get adminReportsServiceMix;

  /// No description provided for @adminReportsTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportes de operaciones'**
  String get adminReportsTitle;

  /// No description provided for @adminReportsTooltipBookings.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 reserva} other{{count} reservas}}'**
  String adminReportsTooltipBookings(int count);

  /// No description provided for @adminReportsTooltipTrips.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 viaje} other{{count} viajes}}'**
  String adminReportsTooltipTrips(int count);

  /// No description provided for @adminReportsTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados'**
  String get adminReportsTrips;

  /// No description provided for @adminReportsTripsPerDay.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados por día'**
  String get adminReportsTripsPerDay;

  /// No description provided for @adminReportsUnknownDriver.
  ///
  /// In es, this message translates to:
  /// **'Chófer sin nombre'**
  String get adminReportsUnknownDriver;

  /// No description provided for @adminReportsUnserved.
  ///
  /// In es, this message translates to:
  /// **'Sin chófer asignado'**
  String get adminReportsUnserved;

  /// No description provided for @adminReportsUnservedHint.
  ///
  /// In es, this message translates to:
  /// **'Canceladas automáticamente'**
  String get adminReportsUnservedHint;

  /// No description provided for @adminReportsVehicleMix.
  ///
  /// In es, this message translates to:
  /// **'Viajes por categoría'**
  String get adminReportsVehicleMix;

  /// No description provided for @adminReportsVsPrevious.
  ///
  /// In es, this message translates to:
  /// **'{delta} vs. período anterior'**
  String adminReportsVsPrevious(String delta);

  /// No description provided for @adminRevenueTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de ingresos 7 días (Bs)'**
  String get adminRevenueTrend;

  /// No description provided for @adminSearchUsers.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuarios…'**
  String get adminSearchUsers;

  /// No description provided for @adminSectionAudit.
  ///
  /// In es, this message translates to:
  /// **'Auditoría'**
  String get adminSectionAudit;

  /// No description provided for @adminSectionBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get adminSectionBookings;

  /// No description provided for @adminSectionCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get adminSectionCompanies;

  /// No description provided for @adminSectionDashboard.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get adminSectionDashboard;

  /// No description provided for @adminSectionDrivers.
  ///
  /// In es, this message translates to:
  /// **'Chóferes'**
  String get adminSectionDrivers;

  /// No description provided for @adminSectionPricing.
  ///
  /// In es, this message translates to:
  /// **'Precios'**
  String get adminSectionPricing;

  /// No description provided for @adminSectionReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get adminSectionReports;

  /// No description provided for @adminSectionSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get adminSectionSettings;

  /// No description provided for @adminSectionUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get adminSectionUsers;

  /// No description provided for @adminSectionVehicles.
  ///
  /// In es, this message translates to:
  /// **'Vehículos'**
  String get adminSectionVehicles;

  /// No description provided for @adminSignOutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres cerrar sesión del panel de administración?'**
  String get adminSignOutConfirm;

  /// No description provided for @adminSystemInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del sistema'**
  String get adminSystemInfo;

  /// No description provided for @adminTitle.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get adminTitle;

  /// No description provided for @adminTotalBookings.
  ///
  /// In es, this message translates to:
  /// **'Total de reservas'**
  String get adminTotalBookings;

  /// No description provided for @adminTwoFactor.
  ///
  /// In es, this message translates to:
  /// **'Autenticación admin de dos factores'**
  String get adminTwoFactor;

  /// No description provided for @adminTwoFactorDesc.
  ///
  /// In es, this message translates to:
  /// **'Requiere 2FA para todas las acciones administrativas.'**
  String get adminTwoFactorDesc;

  /// No description provided for @adminVehicleDetails.
  ///
  /// In es, this message translates to:
  /// **'Placa: {plate} · Clase: {vehicleClass}'**
  String adminVehicleDetails(String plate, String vehicleClass);

  /// No description provided for @adminVerifiedDrivers.
  ///
  /// In es, this message translates to:
  /// **'Chóferes verificados'**
  String get adminVerifiedDrivers;

  /// No description provided for @adminVerify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get adminVerify;

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

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authAlreadyHaveAccount;

  /// Two-line web brand panel headline; keep the line break
  ///
  /// In es, this message translates to:
  /// **'Servicio de chófer\npremium.'**
  String get authBrandHeadline;

  /// No description provided for @authBrandTagline.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo. Chóferes verificados.'**
  String get authBrandTagline;

  /// Link text inside authConsentText
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get authConsentPrivacyLink;

  /// No description provided for @authConsentRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar los términos y la política de privacidad'**
  String get authConsentRequired;

  /// Link text inside authConsentText
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get authConsentTermsLink;

  /// Register consent sentence. {terms} is replaced by the authConsentTermsLink link text and {privacy} by authConsentPrivacyLink; adjust articles and word order around them as the language needs
  ///
  /// In es, this message translates to:
  /// **'Acepto los {terms} y la {privacy}'**
  String authConsentText(String terms, String privacy);

  /// No description provided for @authCreateOne.
  ///
  /// In es, this message translates to:
  /// **'Crear una'**
  String get authCreateOne;

  /// No description provided for @authEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get authEmailInvalid;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la solicitud. Inténtalo de nuevo.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico no es válido'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está desactivada. Contáctanos para más información.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este correo'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es demasiado débil. Usa al menos 6 caracteres.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get authErrorWrongCredentials;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authFullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authFullNameLabel;

  /// Large two-line mobile login headline; keep the line break
  ///
  /// In es, this message translates to:
  /// **'Bienvenido\nde nuevo.'**
  String get authLoginHeadline;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en tu cuenta'**
  String get authLoginSubtitle;

  /// Login page title and submit button
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// No description provided for @authLoginWelcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo a Luxelane.'**
  String get authLoginWelcomeBack;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authNoAccount;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {count} caracteres'**
  String authPasswordTooShort(int count);

  /// No description provided for @authPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get authPhoneLabel;

  /// Mobile register headline
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta.'**
  String get authRegisterHeadline;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a Luxelane hoy'**
  String get authRegisterSubtitle;

  /// Register page title (web) and submit button
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// No description provided for @authResetEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Correo de restablecimiento enviado'**
  String get authResetEmailSent;

  /// No description provided for @authResetNeedsEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo para restablecer la contraseña'**
  String get authResetNeedsEmail;

  /// No description provided for @authSignInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignInLink;

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
  /// **'Precio fijo · Sin sorpresas · Chóferes verificados'**
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
  /// **'Espera gratuita incluida: 60 min en aeropuerto, 15 en ciudad'**
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

  /// No description provided for @coreClearField.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get coreClearField;

  /// No description provided for @coreConfirmBooking.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reserva'**
  String get coreConfirmBooking;

  /// Android foreground-service notification while a chauffeur is on duty
  ///
  /// In es, this message translates to:
  /// **'Compartiendo tu ubicación mientras estás disponible'**
  String get coreDriverLocationNotification;

  /// No description provided for @coreErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Hemos sido notificados y estamos trabajando en una solución.'**
  String get coreErrorBody;

  /// No description provided for @coreErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get coreErrorTitle;

  /// No description provided for @coreFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo'**
  String get coreFixedPrice;

  /// No description provided for @coreHoursTotal.
  ///
  /// In es, this message translates to:
  /// **'{hours} h en total'**
  String coreHoursTotal(int hours);

  /// Developer-facing placeholder; keep GOOGLE_MAPS_KEY as is
  ///
  /// In es, this message translates to:
  /// **'Agrega GOOGLE_MAPS_KEY para habilitar el mapa'**
  String get coreMapKeyMissing;

  /// No description provided for @coreMapPickerHint.
  ///
  /// In es, this message translates to:
  /// **'Mueve el mapa para seleccionar una ubicación'**
  String get coreMapPickerHint;

  /// No description provided for @coreMapPickerSelected.
  ///
  /// In es, this message translates to:
  /// **'Ubicación seleccionada'**
  String get coreMapPickerSelected;

  /// No description provided for @coreMapPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ubicación'**
  String get coreMapPickerTitle;

  /// No description provided for @coreMapView.
  ///
  /// In es, this message translates to:
  /// **'Vista del mapa'**
  String get coreMapView;

  /// No description provided for @coreRoleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get coreRoleAdmin;

  /// No description provided for @coreRoleDriver.
  ///
  /// In es, this message translates to:
  /// **'Chófer'**
  String get coreRoleDriver;

  /// No description provided for @coreRoleRider.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get coreRoleRider;

  /// Passenger capacity next to a person icon
  ///
  /// In es, this message translates to:
  /// **'Hasta {count}'**
  String coreVehicleCapacity(int count);

  /// No description provided for @corpAddCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Agregar centro de costo'**
  String get corpAddCostCenter;

  /// No description provided for @corpAddMember.
  ///
  /// In es, this message translates to:
  /// **'Agregar miembro'**
  String get corpAddMember;

  /// No description provided for @corpAddMemberAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get corpAddMemberAction;

  /// No description provided for @corpAddMemberHint.
  ///
  /// In es, this message translates to:
  /// **'Podrá facturar sus viajes a la empresa. Si aún no tiene cuenta, se unirá al registrarse con este correo.'**
  String get corpAddMemberHint;

  /// No description provided for @corpAdminEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo del administrador'**
  String get corpAdminEmail;

  /// No description provided for @corpAdminEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Si aún no tiene cuenta, se unirá al registrarse con este correo.'**
  String get corpAdminEmailHint;

  /// No description provided for @corpAdminEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay empresas.'**
  String get corpAdminEmpty;

  /// No description provided for @corpAdminIntro.
  ///
  /// In es, this message translates to:
  /// **'Las empresas reciben una factura mensual por los viajes de sus miembros. El administrador de cada empresa gestiona miembros y centros de costo desde su portal.'**
  String get corpAdminIntro;

  /// No description provided for @corpAdminTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas corporativas'**
  String get corpAdminTitle;

  /// No description provided for @corpBillCompanyHint.
  ///
  /// In es, this message translates to:
  /// **'Factura mensual a la empresa'**
  String get corpBillCompanyHint;

  /// No description provided for @corpBillCompanyNotice.
  ///
  /// In es, this message translates to:
  /// **'Este viaje se incluye en la factura mensual de {company}. No pagas nada al chófer.'**
  String corpBillCompanyNotice(String company);

  /// No description provided for @corpBillPersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get corpBillPersonal;

  /// No description provided for @corpBillPersonalHint.
  ///
  /// In es, this message translates to:
  /// **'Lo pagas tú'**
  String get corpBillPersonalHint;

  /// No description provided for @corpBillTo.
  ///
  /// In es, this message translates to:
  /// **'Facturar a'**
  String get corpBillTo;

  /// No description provided for @corpBilledTo.
  ///
  /// In es, this message translates to:
  /// **'Facturado a {company}'**
  String corpBilledTo(String company);

  /// No description provided for @corpBillingDetails.
  ///
  /// In es, this message translates to:
  /// **'Datos de facturación'**
  String get corpBillingDetails;

  /// No description provided for @corpBillingEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo de facturación'**
  String get corpBillingEmail;

  /// No description provided for @corpByCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Por centro de costo'**
  String get corpByCostCenter;

  /// No description provided for @corpByTraveler.
  ///
  /// In es, this message translates to:
  /// **'Por persona'**
  String get corpByTraveler;

  /// No description provided for @corpCancelInvite.
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get corpCancelInvite;

  /// No description provided for @corpColAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto (Bs)'**
  String get corpColAmount;

  /// No description provided for @corpColBookedBy.
  ///
  /// In es, this message translates to:
  /// **'Reservado por'**
  String get corpColBookedBy;

  /// No description provided for @corpColDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get corpColDate;

  /// No description provided for @corpColFrom.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get corpColFrom;

  /// No description provided for @corpColPassenger.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get corpColPassenger;

  /// No description provided for @corpColTo.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get corpColTo;

  /// No description provided for @corpColVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get corpColVehicle;

  /// No description provided for @corpCompanyCreated.
  ///
  /// In es, this message translates to:
  /// **'Empresa creada'**
  String get corpCompanyCreated;

  /// No description provided for @corpCompanyName.
  ///
  /// In es, this message translates to:
  /// **'Razón social'**
  String get corpCompanyName;

  /// No description provided for @corpCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de costo'**
  String get corpCostCenter;

  /// No description provided for @corpCostCenterNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get corpCostCenterNone;

  /// No description provided for @corpCostCenterOptional.
  ///
  /// In es, this message translates to:
  /// **'Centro de costo (opcional)'**
  String get corpCostCenterOptional;

  /// No description provided for @corpCostCenterRequired.
  ///
  /// In es, this message translates to:
  /// **'Centro de costo (obligatorio)'**
  String get corpCostCenterRequired;

  /// No description provided for @corpCostCenters.
  ///
  /// In es, this message translates to:
  /// **'Centros de costo'**
  String get corpCostCenters;

  /// No description provided for @corpCostCentersHint.
  ///
  /// In es, this message translates to:
  /// **'Aparecen al reservar para que cada viaje quede asignado a un área o proyecto.'**
  String get corpCostCentersHint;

  /// No description provided for @corpCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get corpCreate;

  /// No description provided for @corpCreateCompany.
  ///
  /// In es, this message translates to:
  /// **'Nueva empresa'**
  String get corpCreateCompany;

  /// No description provided for @corpDriverNoCollect.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corporativa ({company}): no cobres al pasajero.'**
  String corpDriverNoCollect(String company);

  /// No description provided for @corpEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get corpEmail;

  /// No description provided for @corpErrorCompanyInactive.
  ///
  /// In es, this message translates to:
  /// **'La cuenta corporativa está suspendida.'**
  String get corpErrorCompanyInactive;

  /// No description provided for @corpErrorCostCenterRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige un centro de costo para facturar a la empresa.'**
  String get corpErrorCostCenterRequired;

  /// No description provided for @corpErrorCostCentersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Agrega al menos un centro de costo antes de exigirlo.'**
  String get corpErrorCostCentersEmpty;

  /// No description provided for @corpErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Revisa el correo electrónico.'**
  String get corpErrorInvalidEmail;

  /// No description provided for @corpErrorInvalidName.
  ///
  /// In es, this message translates to:
  /// **'Escribe la razón social.'**
  String get corpErrorInvalidName;

  /// No description provided for @corpErrorInvalidTaxId.
  ///
  /// In es, this message translates to:
  /// **'El NIT debe tener solo números (5 a 15).'**
  String get corpErrorInvalidTaxId;

  /// No description provided for @corpErrorLastAdmin.
  ///
  /// In es, this message translates to:
  /// **'La empresa necesita al menos un administrador.'**
  String get corpErrorLastAdmin;

  /// No description provided for @corpErrorNotARider.
  ///
  /// In es, this message translates to:
  /// **'Esa cuenta es de chófer o de administración; solo pasajeros pueden ser miembros.'**
  String get corpErrorNotARider;

  /// No description provided for @corpErrorNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'No puedes facturar este viaje a la empresa. Elige pago personal.'**
  String get corpErrorNotAllowed;

  /// No description provided for @corpErrorOtherCompany.
  ///
  /// In es, this message translates to:
  /// **'Esa persona ya pertenece a otra empresa.'**
  String get corpErrorOtherCompany;

  /// No description provided for @corpExportCsv.
  ///
  /// In es, this message translates to:
  /// **'Exportar detalle (CSV)'**
  String get corpExportCsv;

  /// No description provided for @corpFormerMember.
  ///
  /// In es, this message translates to:
  /// **'Exmiembro'**
  String get corpFormerMember;

  /// No description provided for @corpInviteCancelled.
  ///
  /// In es, this message translates to:
  /// **'Invitación cancelada'**
  String get corpInviteCancelled;

  /// No description provided for @corpKpiCancelled.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin cancelaciones} =1{1 cancelación en total} other{{count} cancelaciones en total}}'**
  String corpKpiCancelled(int count);

  /// No description provided for @corpKpiCompleted.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados'**
  String get corpKpiCompleted;

  /// No description provided for @corpKpiLateCancellations.
  ///
  /// In es, this message translates to:
  /// **'Cancelaciones tardías'**
  String get corpKpiLateCancellations;

  /// No description provided for @corpKpiToInvoice.
  ///
  /// In es, this message translates to:
  /// **'A facturar'**
  String get corpKpiToInvoice;

  /// No description provided for @corpKpiToInvoiceHint.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados del mes'**
  String get corpKpiToInvoiceHint;

  /// No description provided for @corpKpiUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos o en curso'**
  String get corpKpiUpcoming;

  /// No description provided for @corpMakeAdmin.
  ///
  /// In es, this message translates to:
  /// **'Hacer administrador'**
  String get corpMakeAdmin;

  /// No description provided for @corpMakeMember.
  ///
  /// In es, this message translates to:
  /// **'Quitar permisos de administrador'**
  String get corpMakeMember;

  /// No description provided for @corpMemberActions.
  ///
  /// In es, this message translates to:
  /// **'Opciones del miembro'**
  String get corpMemberActions;

  /// No description provided for @corpMemberAdded.
  ///
  /// In es, this message translates to:
  /// **'Listo. Si la persona ya tenía cuenta, se agregó; si no, se unirá al registrarse.'**
  String get corpMemberAdded;

  /// No description provided for @corpMemberRemoved.
  ///
  /// In es, this message translates to:
  /// **'Miembro quitado'**
  String get corpMemberRemoved;

  /// No description provided for @corpMemberUpdated.
  ///
  /// In es, this message translates to:
  /// **'Permisos actualizados'**
  String get corpMemberUpdated;

  /// No description provided for @corpMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get corpMembers;

  /// No description provided for @corpNewCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Nuevo centro de costo'**
  String get corpNewCostCenter;

  /// No description provided for @corpNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get corpNextMonth;

  /// No description provided for @corpNoAccess.
  ///
  /// In es, this message translates to:
  /// **'Solo los administradores de la empresa pueden ver este portal.'**
  String get corpNoAccess;

  /// No description provided for @corpNoCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Sin centro de costo'**
  String get corpNoCostCenter;

  /// No description provided for @corpNoMembers.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay miembros.'**
  String get corpNoMembers;

  /// No description provided for @corpNoRidesMonth.
  ///
  /// In es, this message translates to:
  /// **'No hay viajes facturados a la empresa en este mes.'**
  String get corpNoRidesMonth;

  /// No description provided for @corpOpenPortal.
  ///
  /// In es, this message translates to:
  /// **'Abrir portal'**
  String get corpOpenPortal;

  /// No description provided for @corpPendingInvites.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones pendientes'**
  String get corpPendingInvites;

  /// No description provided for @corpPendingInvitesHint.
  ///
  /// In es, this message translates to:
  /// **'Se unirán al crear su cuenta con estos correos.'**
  String get corpPendingInvitesHint;

  /// No description provided for @corpPortalTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corporativa'**
  String get corpPortalTitle;

  /// No description provided for @corpPrevMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get corpPrevMonth;

  /// No description provided for @corpProfileAdminHint.
  ///
  /// In es, this message translates to:
  /// **'Administras esta cuenta: estado de cuenta, miembros y ajustes'**
  String get corpProfileAdminHint;

  /// No description provided for @corpProfileMemberHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes facturar tus viajes a la empresa'**
  String get corpProfileMemberHint;

  /// No description provided for @corpProfileSection.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corporativa'**
  String get corpProfileSection;

  /// No description provided for @corpReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar cuenta'**
  String get corpReactivate;

  /// No description provided for @corpReactivated.
  ///
  /// In es, this message translates to:
  /// **'Cuenta reactivada'**
  String get corpReactivated;

  /// No description provided for @corpReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get corpReference;

  /// No description provided for @corpReferenceHint.
  ///
  /// In es, this message translates to:
  /// **'Proyecto, orden de compra, cliente…'**
  String get corpReferenceHint;

  /// No description provided for @corpRemoveCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get corpRemoveCostCenter;

  /// No description provided for @corpRemoveMember.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la empresa'**
  String get corpRemoveMember;

  /// No description provided for @corpRemoveMemberBody.
  ///
  /// In es, this message translates to:
  /// **'{name} ya no podrá facturar viajes a la empresa. Sus viajes anteriores siguen en el estado de cuenta.'**
  String corpRemoveMemberBody(String name);

  /// No description provided for @corpRequireCostCenter.
  ///
  /// In es, this message translates to:
  /// **'Exigir centro de costo'**
  String get corpRequireCostCenter;

  /// No description provided for @corpRequireCostCenterHint.
  ///
  /// In es, this message translates to:
  /// **'No se podrá reservar a cuenta de la empresa sin elegir uno.'**
  String get corpRequireCostCenterHint;

  /// No description provided for @corpRidesOfMonth.
  ///
  /// In es, this message translates to:
  /// **'Viajes del mes'**
  String get corpRidesOfMonth;

  /// No description provided for @corpRoleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get corpRoleAdmin;

  /// No description provided for @corpRoleMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get corpRoleMember;

  /// No description provided for @corpRoute.
  ///
  /// In es, this message translates to:
  /// **'{from} → {to}'**
  String corpRoute(String from, String to);

  /// No description provided for @corpSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get corpSave;

  /// No description provided for @corpSettingsSaved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get corpSettingsSaved;

  /// No description provided for @corpSuspend.
  ///
  /// In es, this message translates to:
  /// **'Suspender cuenta'**
  String get corpSuspend;

  /// No description provided for @corpSuspended.
  ///
  /// In es, this message translates to:
  /// **'Cuenta suspendida'**
  String get corpSuspended;

  /// No description provided for @corpSuspendedBanner.
  ///
  /// In es, this message translates to:
  /// **'La cuenta está suspendida: sus miembros no pueden facturar viajes a la empresa. Escríbenos para reactivarla.'**
  String get corpSuspendedBanner;

  /// No description provided for @corpSuspendedShort.
  ///
  /// In es, this message translates to:
  /// **'Cuenta suspendida'**
  String get corpSuspendedShort;

  /// No description provided for @corpTabMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get corpTabMembers;

  /// No description provided for @corpTabSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get corpTabSettings;

  /// No description provided for @corpTabStatement.
  ///
  /// In es, this message translates to:
  /// **'Estado de cuenta'**
  String get corpTabStatement;

  /// No description provided for @corpTaxId.
  ///
  /// In es, this message translates to:
  /// **'NIT'**
  String get corpTaxId;

  /// No description provided for @corpTaxIdShort.
  ///
  /// In es, this message translates to:
  /// **'NIT {taxId}'**
  String corpTaxIdShort(String taxId);

  /// No description provided for @docApprovedCount.
  ///
  /// In es, this message translates to:
  /// **'{approved} de {total} aprobados'**
  String docApprovedCount(int approved, int total);

  /// No description provided for @docBannerExpiring.
  ///
  /// In es, this message translates to:
  /// **'Tu {doc} vence pronto. Sube la versión renovada.'**
  String docBannerExpiring(String doc);

  /// No description provided for @docBannerInReview.
  ///
  /// In es, this message translates to:
  /// **'Estamos revisando tus documentos. Te avisaremos al aprobarlos.'**
  String get docBannerInReview;

  /// No description provided for @docBannerToUpload.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Falta 1 documento para que puedas recibir viajes.} other{Faltan {count} documentos para que puedas recibir viajes.}}'**
  String docBannerToUpload(int count);

  /// No description provided for @docCriminalRecord.
  ///
  /// In es, this message translates to:
  /// **'Certificado de antecedentes'**
  String get docCriminalRecord;

  /// No description provided for @docCriminalRecordHint.
  ///
  /// In es, this message translates to:
  /// **'REJAP o FELCC, emitido en los últimos 3 meses'**
  String get docCriminalRecordHint;

  /// No description provided for @docErrorAlreadyExpired.
  ///
  /// In es, this message translates to:
  /// **'Ese documento ya está vencido.'**
  String get docErrorAlreadyExpired;

  /// No description provided for @docErrorExpiryRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica la fecha de vencimiento.'**
  String get docErrorExpiryRequired;

  /// No description provided for @docErrorFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar. Inténtalo de nuevo.'**
  String get docErrorFailed;

  /// No description provided for @docErrorReasonRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo del rechazo.'**
  String get docErrorReasonRequired;

  /// No description provided for @docErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo pesa más de 10 MB.'**
  String get docErrorTooLarge;

  /// No description provided for @docExpiredOn.
  ///
  /// In es, this message translates to:
  /// **'Venció el {date}'**
  String docExpiredOn(String date);

  /// No description provided for @docExpiresOn.
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String docExpiresOn(String date);

  /// No description provided for @docExpiryPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo vence tu {doc}?'**
  String docExpiryPickerTitle(String doc);

  /// No description provided for @docIdCard.
  ///
  /// In es, this message translates to:
  /// **'Cédula de identidad'**
  String get docIdCard;

  /// No description provided for @docIdCardHint.
  ///
  /// In es, this message translates to:
  /// **'Ambos lados, legible'**
  String get docIdCardHint;

  /// No description provided for @docLicense.
  ///
  /// In es, this message translates to:
  /// **'Licencia de conducir'**
  String get docLicense;

  /// No description provided for @docLicenseHint.
  ///
  /// In es, this message translates to:
  /// **'Categoría profesional, ambos lados'**
  String get docLicenseHint;

  /// No description provided for @docPendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 en revisión} other{{count} en revisión}}'**
  String docPendingCount(int count);

  /// No description provided for @docPendingHint.
  ///
  /// In es, this message translates to:
  /// **'Lo revisamos normalmente en menos de 24 horas.'**
  String get docPendingHint;

  /// No description provided for @docPrivacyNote.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos solo los ve el equipo de Luxelane para verificarte. Se borran si eliminas tu cuenta.'**
  String get docPrivacyNote;

  /// No description provided for @docProfileLink.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos y verificación'**
  String get docProfileLink;

  /// No description provided for @docRejectedReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String docRejectedReason(String reason);

  /// No description provided for @docReplace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get docReplace;

  /// No description provided for @docReviewAction.
  ///
  /// In es, this message translates to:
  /// **'Revisar documentos'**
  String get docReviewAction;

  /// No description provided for @docReviewAllApproved.
  ///
  /// In es, this message translates to:
  /// **'Todos los documentos están aprobados y vigentes.'**
  String get docReviewAllApproved;

  /// No description provided for @docReviewApprove.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get docReviewApprove;

  /// No description provided for @docReviewApproved.
  ///
  /// In es, this message translates to:
  /// **'Documento aprobado'**
  String get docReviewApproved;

  /// No description provided for @docReviewConfirmExpiry.
  ///
  /// In es, this message translates to:
  /// **'Confirma la fecha de vencimiento'**
  String get docReviewConfirmExpiry;

  /// No description provided for @docReviewOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver archivo'**
  String get docReviewOpen;

  /// No description provided for @docReviewReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get docReviewReject;

  /// No description provided for @docReviewRejectReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get docReviewRejectReason;

  /// No description provided for @docReviewRejectReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: la foto está borrosa'**
  String get docReviewRejectReasonHint;

  /// No description provided for @docReviewRejectTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar documento'**
  String get docReviewRejectTitle;

  /// No description provided for @docReviewRejected.
  ///
  /// In es, this message translates to:
  /// **'Documento rechazado; avisamos al chófer'**
  String get docReviewRejected;

  /// No description provided for @docReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentos de {name}'**
  String docReviewTitle(String name);

  /// No description provided for @docSoat.
  ///
  /// In es, this message translates to:
  /// **'SOAT'**
  String get docSoat;

  /// No description provided for @docSoatHint.
  ///
  /// In es, this message translates to:
  /// **'Seguro obligatorio vigente del vehículo'**
  String get docSoatHint;

  /// No description provided for @docStatusApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get docStatusApproved;

  /// No description provided for @docStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get docStatusExpired;

  /// No description provided for @docStatusExpiring.
  ///
  /// In es, this message translates to:
  /// **'Por vencer'**
  String get docStatusExpiring;

  /// No description provided for @docStatusMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get docStatusMissing;

  /// No description provided for @docStatusPending.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get docStatusPending;

  /// No description provided for @docStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get docStatusRejected;

  /// No description provided for @docSummaryBody.
  ///
  /// In es, this message translates to:
  /// **'Para recibir viajes revisamos y aprobamos estos documentos. Sube fotos nítidas o PDF; te avisamos cuando estén revisados.'**
  String get docSummaryBody;

  /// No description provided for @docSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación pendiente'**
  String get docSummaryTitle;

  /// No description provided for @docSummaryVerified.
  ///
  /// In es, this message translates to:
  /// **'Chófer verificado'**
  String get docSummaryVerified;

  /// No description provided for @docSummaryVerifiedBody.
  ///
  /// In es, this message translates to:
  /// **'Todos tus documentos están aprobados. Te avisaremos 30 y 7 días antes de que venza alguno.'**
  String get docSummaryVerifiedBody;

  /// No description provided for @docTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get docTitle;

  /// No description provided for @docToUploadCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 por subir} other{{count} por subir}}'**
  String docToUploadCount(int count);

  /// No description provided for @docUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get docUpload;

  /// No description provided for @docUploaded.
  ///
  /// In es, this message translates to:
  /// **'Documento enviado a revisión'**
  String get docUploaded;

  /// No description provided for @docUploadedOn.
  ///
  /// In es, this message translates to:
  /// **'Subido el {date}'**
  String docUploadedOn(String date);

  /// No description provided for @docVehicleRegistration.
  ///
  /// In es, this message translates to:
  /// **'Registro del vehículo (RUAT)'**
  String get docVehicleRegistration;

  /// No description provided for @docVehicleRegistrationHint.
  ///
  /// In es, this message translates to:
  /// **'Certificado de propiedad o RUAT a tu nombre o autorizado'**
  String get docVehicleRegistrationHint;

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

  /// Booking bar field label (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get homeBarDateTime;

  /// Booking field label
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get homeBarDestination;

  /// Destination field placeholder
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vas?'**
  String get homeBarDestinationHint;

  /// Booking field label (by the hour)
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get homeBarDuration;

  /// Booking bar field label (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get homeBarPickup;

  /// Pickup field placeholder
  ///
  /// In es, this message translates to:
  /// **'¿Dónde estás?'**
  String get homeBarPickupHint;

  /// Booking bar submit button (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Ver opciones'**
  String get homeBarSeeOptions;

  /// No description provided for @homeBookBulletAdvance.
  ///
  /// In es, this message translates to:
  /// **'Reserva con anticipación'**
  String get homeBookBulletAdvance;

  /// No description provided for @homeBookBulletDirectContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto directo con tu chófer'**
  String get homeBookBulletDirectContact;

  /// No description provided for @homeBookBulletFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo, siempre'**
  String get homeBookBulletFixedPrice;

  /// No description provided for @homeBookBulletFlightTracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de vuelos'**
  String get homeBookBulletFlightTracking;

  /// No description provided for @homeBookBulletFreeWait.
  ///
  /// In es, this message translates to:
  /// **'Espera gratuita incluida'**
  String get homeBookBulletFreeWait;

  /// No description provided for @homeBookBulletGuests.
  ///
  /// In es, this message translates to:
  /// **'Reservas para invitados'**
  String get homeBookBulletGuests;

  /// No description provided for @homeBookBulletMeetGreet.
  ///
  /// In es, this message translates to:
  /// **'Meet & greet con cartel'**
  String get homeBookBulletMeetGreet;

  /// No description provided for @homeBookBulletReceipts.
  ///
  /// In es, this message translates to:
  /// **'Recibo de cada viaje'**
  String get homeBookBulletReceipts;

  /// No description provided for @homeBookBulletTracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en tiempo real'**
  String get homeBookBulletTracking;

  /// No description provided for @homeBookBusinessSub.
  ///
  /// In es, this message translates to:
  /// **'Viajes corporativos redefinidos'**
  String get homeBookBusinessSub;

  /// No description provided for @homeBookCoverSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio de chófer premium'**
  String get homeBookCoverSubtitle;

  /// No description provided for @homeBookExperienceBody.
  ///
  /// In es, this message translates to:
  /// **'Del aeropuerto a tu destino: seguimos tu vuelo, tu chófer te espera con un cartel con tu nombre y la espera está incluida — 60 min en aeropuerto, 15 en ciudad.'**
  String get homeBookExperienceBody;

  /// No description provided for @homeBookExperienceHeadline.
  ///
  /// In es, this message translates to:
  /// **'Cada detalle,\ncuidado.'**
  String get homeBookExperienceHeadline;

  /// No description provided for @homeBookExperienceLabel.
  ///
  /// In es, this message translates to:
  /// **'La experiencia'**
  String get homeBookExperienceLabel;

  /// No description provided for @homeBookExperienceSub.
  ///
  /// In es, this message translates to:
  /// **'Cada detalle considerado'**
  String get homeBookExperienceSub;

  /// Eyebrow above the page-flip showcase (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Nuestra experiencia distintiva'**
  String get homeBookEyebrow;

  /// Primary CTA across the landing and the web header (often uppercased)
  ///
  /// In es, this message translates to:
  /// **'Reservar un viaje'**
  String get homeBookRide;

  /// Vertical scroll cue next to the page-flip showcase (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Desliza'**
  String get homeBookScrollCue;

  /// No description provided for @homeBookStandardBody.
  ///
  /// In es, this message translates to:
  /// **'Cada chófer es verificado por nuestro equipo: revisamos su licencia, sus documentos y su vehículo antes de su primer viaje.'**
  String get homeBookStandardBody;

  /// No description provided for @homeBookStandardHeadline.
  ///
  /// In es, this message translates to:
  /// **'El estándar que\notros siguen.'**
  String get homeBookStandardHeadline;

  /// No description provided for @homeBookStandardLabel.
  ///
  /// In es, this message translates to:
  /// **'El estándar'**
  String get homeBookStandardLabel;

  /// No description provided for @homeBookStandardSub.
  ///
  /// In es, this message translates to:
  /// **'La promesa que cumplimos'**
  String get homeBookStandardSub;

  /// No description provided for @homeBookStandardTag.
  ///
  /// In es, this message translates to:
  /// **'El estándar Luxelane'**
  String get homeBookStandardTag;

  /// No description provided for @homeBusinessBody.
  ///
  /// In es, this message translates to:
  /// **'Reserva para tu equipo y tus invitados con precio fijo en bolivianos, seguimiento en vivo y un recibo de cada viaje.'**
  String get homeBusinessBody;

  /// No description provided for @homeBusinessEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get homeBusinessEyebrow;

  /// No description provided for @homeBusinessLearnMore.
  ///
  /// In es, this message translates to:
  /// **'Más información'**
  String get homeBusinessLearnMore;

  /// No description provided for @homeBusinessPerkFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo confirmado antes de reservar'**
  String get homeBusinessPerkFixedPrice;

  /// No description provided for @homeBusinessPerkFlights.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de vuelos y recogida ajustada'**
  String get homeBusinessPerkFlights;

  /// No description provided for @homeBusinessPerkGuests.
  ///
  /// In es, this message translates to:
  /// **'Reservas para invitados y equipos'**
  String get homeBusinessPerkGuests;

  /// No description provided for @homeBusinessPerkMeetGreet.
  ///
  /// In es, this message translates to:
  /// **'Meet & greet con cartel en el aeropuerto'**
  String get homeBusinessPerkMeetGreet;

  /// No description provided for @homeBusinessPerkMonitoring.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en vivo de cada viaje'**
  String get homeBusinessPerkMonitoring;

  /// No description provided for @homeBusinessPerkReceipts.
  ///
  /// In es, this message translates to:
  /// **'Recibo de cada viaje en la app'**
  String get homeBusinessPerkReceipts;

  /// No description provided for @homeBusinessTitle.
  ///
  /// In es, this message translates to:
  /// **'Viajes corporativos,\nredefinidos.'**
  String get homeBusinessTitle;

  /// Eyebrow above the closing CTA (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Cuando quieras. Donde quieras.'**
  String get homeCtaEyebrow;

  /// No description provided for @homeCtaHighlights.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo  ·  Chóferes verificados  ·  Reserva anticipada'**
  String get homeCtaHighlights;

  /// Closing CTA headline. Text inside <i>…</i> is set in italics; keep the tags.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo viaje,\n<i>en tus términos.</i>'**
  String get homeCtaTitle;

  /// No description provided for @homeCtaViewFleet.
  ///
  /// In es, this message translates to:
  /// **'Ver flota'**
  String get homeCtaViewFleet;

  /// Selected pickup date and time, e.g. 'Oct 7, 14:30'
  ///
  /// In es, this message translates to:
  /// **'{date}, {time}'**
  String homeDateTimeShort(String date, String time);

  /// No description provided for @homeErrorDestinationRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un destino'**
  String get homeErrorDestinationRequired;

  /// No description provided for @homeErrorPickupRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un lugar de recogida'**
  String get homeErrorPickupRequired;

  /// No description provided for @homeFleetEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Nuestra flota'**
  String get homeFleetEyebrow;

  /// No description provided for @homeFleetModelVan.
  ///
  /// In es, this message translates to:
  /// **'Mercedes V-Class o similar'**
  String get homeFleetModelVan;

  /// Hint above the horizontal fleet carousel (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Desliza para explorar →'**
  String get homeFleetSwipeHint;

  /// No description provided for @homeFleetTagExtraLuggage.
  ///
  /// In es, this message translates to:
  /// **'Equipaje extra'**
  String get homeFleetTagExtraLuggage;

  /// No description provided for @homeFleetTagFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo'**
  String get homeFleetTagFixedPrice;

  /// No description provided for @homeFleetTagGroups.
  ///
  /// In es, this message translates to:
  /// **'Ideal para grupos'**
  String get homeFleetTagGroups;

  /// No description provided for @homeFleetTagTracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en vivo'**
  String get homeFleetTagTracking;

  /// No description provided for @homeFleetTagVerified.
  ///
  /// In es, this message translates to:
  /// **'Chófer verificado'**
  String get homeFleetTagVerified;

  /// No description provided for @homeFleetTitle.
  ///
  /// In es, this message translates to:
  /// **'Vehículos premium,\nsin excepciones.'**
  String get homeFleetTitle;

  /// No description provided for @homeFooterContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get homeFooterContact;

  /// No description provided for @homeFooterCopyright.
  ///
  /// In es, this message translates to:
  /// **'© {year} Luxelane. Todos los derechos reservados.'**
  String homeFooterCopyright(String year);

  /// No description provided for @homeFooterPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get homeFooterPrivacy;

  /// No description provided for @homeFooterTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get homeFooterTerms;

  /// No description provided for @homeFormPickupHint.
  ///
  /// In es, this message translates to:
  /// **'Calle, barrio, aeropuerto…'**
  String get homeFormPickupHint;

  /// No description provided for @homeFormPickupLabel.
  ///
  /// In es, this message translates to:
  /// **'Lugar de recogida'**
  String get homeFormPickupLabel;

  /// Hero headline. Text inside <i>…</i> is set in italics; keep the tags.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer <i>te espera.</i>'**
  String get homeHeroTitle;

  /// Compact hour count in the duration stepper
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String homeHoursShort(int hours);

  /// No description provided for @homeHowItWorksEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona'**
  String get homeHowItWorksEyebrow;

  /// Tooltip for the locate button
  ///
  /// In es, this message translates to:
  /// **'Usar mi ubicación'**
  String get homeLocateMe;

  /// Button on the inline map preview (uppercased)
  ///
  /// In es, this message translates to:
  /// **'Cambiar ubicación'**
  String get homeMapChangeLocation;

  /// No description provided for @homeMarqueeAirportTransfers.
  ///
  /// In es, this message translates to:
  /// **'Traslados aeroportuarios'**
  String get homeMarqueeAirportTransfers;

  /// No description provided for @homeMarqueeBookInMinutes.
  ///
  /// In es, this message translates to:
  /// **'Reserva en minutos'**
  String get homeMarqueeBookInMinutes;

  /// No description provided for @homeMarqueeCorporateTravel.
  ///
  /// In es, this message translates to:
  /// **'Viajes corporativos'**
  String get homeMarqueeCorporateTravel;

  /// No description provided for @homeMarqueeFixedPrices.
  ///
  /// In es, this message translates to:
  /// **'Precios fijos en Bs'**
  String get homeMarqueeFixedPrices;

  /// No description provided for @homeMarqueeFreeWait.
  ///
  /// In es, this message translates to:
  /// **'Espera gratuita'**
  String get homeMarqueeFreeWait;

  /// No description provided for @homeMarqueeHourly.
  ///
  /// In es, this message translates to:
  /// **'Chófer por horas'**
  String get homeMarqueeHourly;

  /// No description provided for @homeMarqueePremiumFleet.
  ///
  /// In es, this message translates to:
  /// **'Flota premium'**
  String get homeMarqueePremiumFleet;

  /// Landing nav link (shown uppercased)
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get homeNavBusiness;

  /// Landing nav / footer link (shown uppercased)
  ///
  /// In es, this message translates to:
  /// **'Flota'**
  String get homeNavFleet;

  /// Landing nav / footer link (shown uppercased)
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get homeNavServices;

  /// Map picker dialog title
  ///
  /// In es, this message translates to:
  /// **'Seleccionar destino'**
  String get homePickDestinationTitle;

  /// Map picker dialog title
  ///
  /// In es, this message translates to:
  /// **'Seleccionar lugar de recogida'**
  String get homePickPickupTitle;

  /// No description provided for @homePromiseCancelBody.
  ///
  /// In es, this message translates to:
  /// **'Cancela sin costo hasta 1 hora antes de la recogida, desde la app.'**
  String get homePromiseCancelBody;

  /// No description provided for @homePromiseCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita'**
  String get homePromiseCancelTitle;

  /// No description provided for @homePromiseFixedPriceBody.
  ///
  /// In es, this message translates to:
  /// **'Ves el precio final antes de reservar, sin recargos por tráfico. Incluye {airportMinutes} min de espera en aeropuerto y {cityMinutes} en ciudad.'**
  String homePromiseFixedPriceBody(int airportMinutes, int cityMinutes);

  /// No description provided for @homePromiseFixedPriceTitle.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo en Bs'**
  String get homePromiseFixedPriceTitle;

  /// No description provided for @homePromiseTrackingBody.
  ///
  /// In es, this message translates to:
  /// **'Sigue a tu chófer en el mapa y recibe avisos cuando está en camino y cuando llega.'**
  String get homePromiseTrackingBody;

  /// No description provided for @homePromiseTrackingTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en vivo'**
  String get homePromiseTrackingTitle;

  /// No description provided for @homePromiseVerifiedBody.
  ///
  /// In es, this message translates to:
  /// **'Licencia y documentos revisados por nuestro equipo antes de su primer viaje.'**
  String get homePromiseVerifiedBody;

  /// No description provided for @homePromiseVerifiedTitle.
  ///
  /// In es, this message translates to:
  /// **'Chóferes verificados'**
  String get homePromiseVerifiedTitle;

  /// Route estimate badge, e.g. '12.4 km · 25 min'
  ///
  /// In es, this message translates to:
  /// **'{distance} km · {duration}'**
  String homeRouteSummary(String distance, String duration);

  /// Mobile home submit button
  ///
  /// In es, this message translates to:
  /// **'Buscar vehículos'**
  String get homeSearchVehicles;

  /// Services dropdown item
  ///
  /// In es, this message translates to:
  /// **'Traslado al aeropuerto'**
  String get homeServiceAirportTransfer;

  /// Services dropdown item
  ///
  /// In es, this message translates to:
  /// **'Contratación por horas'**
  String get homeServiceHourly;

  /// Services dropdown item
  ///
  /// In es, this message translates to:
  /// **'Recogida inmediata'**
  String get homeServiceImmediatePickup;

  /// Web header link
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get homeShellMyTrips;

  /// Web header link
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get homeShellSignIn;

  /// Web side rail button
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get homeShellSignOut;

  /// Bottom nav / rail tab
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homeShellTabHome;

  /// Bottom nav / rail tab
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get homeShellTabProfile;

  /// Bottom nav / rail tab
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get homeShellTabTrips;

  /// No description provided for @homeStepBookBody.
  ///
  /// In es, this message translates to:
  /// **'Elige origen, destino, fecha y clase de vehículo.'**
  String get homeStepBookBody;

  /// No description provided for @homeStepBookTitle.
  ///
  /// In es, this message translates to:
  /// **'Reserva en un minuto'**
  String get homeStepBookTitle;

  /// No description provided for @homeStepChauffeurBody.
  ///
  /// In es, this message translates to:
  /// **'Recibe los datos de tu chófer y síguelo en tiempo real.'**
  String get homeStepChauffeurBody;

  /// No description provided for @homeStepChauffeurTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te espera'**
  String get homeStepChauffeurTitle;

  /// No description provided for @homeStepPriceBody.
  ///
  /// In es, this message translates to:
  /// **'Te mostramos el precio final en bolivianos. Ese es el que pagas.'**
  String get homeStepPriceBody;

  /// No description provided for @homeStepPriceTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu precio fijo'**
  String get homeStepPriceTitle;

  /// No description provided for @homeTrustEyebrow.
  ///
  /// In es, this message translates to:
  /// **'La promesa Luxelane'**
  String get homeTrustEyebrow;

  /// No description provided for @homeTrustTitle.
  ///
  /// In es, this message translates to:
  /// **'Viajar con confianza,\nde principio a fin.'**
  String get homeTrustTitle;

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

  /// No description provided for @paymentsAccountNotSetUp.
  ///
  /// In es, this message translates to:
  /// **'La cuenta no está configurada para pagos'**
  String get paymentsAccountNotSetUp;

  /// No description provided for @paymentsAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get paymentsAdd;

  /// No description provided for @paymentsAddCard.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarjeta'**
  String get paymentsAddCard;

  /// No description provided for @paymentsAddMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar método de pago'**
  String get paymentsAddMethodTitle;

  /// No description provided for @paymentsAddNewCard.
  ///
  /// In es, this message translates to:
  /// **'Agregar nueva tarjeta'**
  String get paymentsAddNewCard;

  /// No description provided for @paymentsCardAdded.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta agregada exitosamente'**
  String get paymentsCardAdded;

  /// No description provided for @paymentsCardDetails.
  ///
  /// In es, this message translates to:
  /// **'Datos de la tarjeta'**
  String get paymentsCardDetails;

  /// No description provided for @paymentsCardExpires.
  ///
  /// In es, this message translates to:
  /// **'Vence {month}/{year}'**
  String paymentsCardExpires(String month, String year);

  /// Shown when the card brand is unknown
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentsCardFallback;

  /// No description provided for @paymentsCardIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos completos de la tarjeta'**
  String get paymentsCardIncomplete;

  /// Badge on the default card
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get paymentsDefault;

  /// No description provided for @paymentsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Agrega una tarjeta para reservar viajes'**
  String get paymentsEmptyBody;

  /// No description provided for @paymentsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin métodos de pago'**
  String get paymentsEmptyTitle;

  /// No description provided for @paymentsError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación con tu tarjeta. Inténtalo de nuevo.'**
  String get paymentsError;

  /// No description provided for @paymentsMethodsTitle.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get paymentsMethodsTitle;

  /// No description provided for @paymentsRemoveCard.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tarjeta'**
  String get paymentsRemoveCard;

  /// No description provided for @paymentsSavedCards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas guardadas'**
  String get paymentsSavedCards;

  /// No description provided for @paymentsSecured.
  ///
  /// In es, this message translates to:
  /// **'Protegido por Stripe'**
  String get paymentsSecured;

  /// No description provided for @paymentsSecuredPci.
  ///
  /// In es, this message translates to:
  /// **'Protegido por Stripe · Cumplimiento PCI DSS'**
  String get paymentsSecuredPci;

  /// Short button to make a card the default; keep it short
  ///
  /// In es, this message translates to:
  /// **'Predeterminar'**
  String get paymentsSetDefault;

  /// No description provided for @profileContactHelp.
  ///
  /// In es, this message translates to:
  /// **'Contacto y ayuda'**
  String get profileContactHelp;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profileDeleteAccount;

  /// No description provided for @profileEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get profileLoadError;

  /// No description provided for @profileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileNameLabel;

  /// No description provided for @profileSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profileSaveChanges;

  /// No description provided for @profileSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y legal'**
  String get profileSectionHelp;

  /// No description provided for @profileSectionStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get profileSectionStats;

  /// No description provided for @profileSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileSignOut;

  /// No description provided for @profileStatRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get profileStatRating;

  /// No description provided for @profileStatTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get profileStatTrips;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// No description provided for @profileVersion.
  ///
  /// In es, this message translates to:
  /// **'Luxelane v{version}'**
  String profileVersion(String version);

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

  /// No description provided for @rideCancelBooking.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get rideCancelBooking;

  /// No description provided for @rideCancelChauffeurNotified.
  ///
  /// In es, this message translates to:
  /// **'Avisaremos a tu chófer.'**
  String get rideCancelChauffeurNotified;

  /// No description provided for @rideCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get rideCancelConfirm;

  /// No description provided for @rideCancelDone.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva fue cancelada.'**
  String get rideCancelDone;

  /// No description provided for @rideCancelFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la reserva. Inténtalo de nuevo.'**
  String get rideCancelFailed;

  /// No description provided for @rideCancelFree.
  ///
  /// In es, this message translates to:
  /// **'La cancelación es gratuita: faltan más de 1 hora para la recogida.'**
  String get rideCancelFree;

  /// No description provided for @rideCancelKeep.
  ///
  /// In es, this message translates to:
  /// **'Mantener reserva'**
  String get rideCancelKeep;

  /// No description provided for @rideCancelLate.
  ///
  /// In es, this message translates to:
  /// **'Faltan menos de 1 hora para la recogida. Revisa nuestros términos sobre cancelaciones tardías.'**
  String get rideCancelLate;

  /// No description provided for @rideCancelNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no se puede cancelar desde la app.'**
  String get rideCancelNotAllowed;

  /// No description provided for @rideCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar esta reserva?'**
  String get rideCancelTitle;

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

  /// No description provided for @routerGoHome.
  ///
  /// In es, this message translates to:
  /// **'Ir al inicio'**
  String get routerGoHome;

  /// No description provided for @routerNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'La página que buscas no existe o se ha movido.'**
  String get routerNotFoundBody;

  /// No description provided for @routerNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'Página no encontrada'**
  String get routerNotFoundTitle;

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
