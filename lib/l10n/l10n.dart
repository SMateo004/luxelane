import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/enums/enums.dart';
import '../core/models/models.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Languages the app ships in. Order matters: the first is the template.
const supportedAppLocales = [Locale('es'), Locale('en'), Locale('pt')];

/// Language used when none of the device's preferred languages is
/// supported (e.g. a French or German traveller): English.
const fallbackAppLocale = Locale('en');

/// Picks the first of the device's preferred languages that we support,
/// matching on language only (es-BO, es-419, pt-BR, en-GB… all resolve).
/// Passed to `MaterialApp.localeListResolutionCallback`; because the app
/// never sets `MaterialApp.locale`, Flutter re-runs this whenever the user
/// changes the system language, and the UI updates live.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == locale.languageCode) return s;
    }
  }
  return fallbackAppLocale;
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Current app language tag (es, en, pt) for intl formatters.
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}

/// Keeps `package:intl`'s default locale (dates, numbers, LuxMoney) in sync
/// with the resolved app locale. Insert via `MaterialApp.builder`.
class IntlLocaleSync extends StatelessWidget {
  const IntlLocaleSync({super.key, required this.child, this.onLocaleChanged});
  final Widget child;

  /// Called after the locale changes (e.g. to store it on the user profile).
  final ValueChanged<String>? onLocaleChanged;

  static String? _last;

  @override
  Widget build(BuildContext context) {
    final tag = Localizations.localeOf(context).languageCode;
    if (Intl.defaultLocale != tag) Intl.defaultLocale = tag;
    if (_last != tag) {
      _last = tag;
      if (onLocaleChanged != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onLocaleChanged!(tag));
      }
    }
    return child;
  }
}

extension VehicleClassL10n on VehicleClass {
  String localizedLabel(AppLocalizations l) => switch (this) {
        VehicleClass.business => l.vehicleBusiness,
        VehicleClass.firstClass => l.vehicleFirstClass,
        VehicleClass.businessVan => l.vehicleBusinessVan,
        VehicleClass.electric => l.vehicleElectric,
      };

  String localizedDescription(AppLocalizations l) => switch (this) {
        VehicleClass.business => l.vehicleBusinessDesc,
        VehicleClass.firstClass => l.vehicleFirstClassDesc,
        VehicleClass.businessVan => l.vehicleBusinessVanDesc,
        VehicleClass.electric => l.vehicleElectricDesc,
      };
}

extension ServiceTypeL10n on ServiceType {
  String localizedLabel(AppLocalizations l) => switch (this) {
        ServiceType.oneWay => l.serviceOneWay,
        ServiceType.byTheHour => l.serviceByTheHour,
      };

  String localizedDescription(AppLocalizations l) => switch (this) {
        ServiceType.oneWay => l.serviceOneWayDesc,
        ServiceType.byTheHour => l.serviceByTheHourDesc,
      };
}

extension BookingStatusL10n on BookingStatus {
  String localizedLabel(AppLocalizations l) => switch (this) {
        BookingStatus.pending => l.statusPending,
        BookingStatus.confirmed => l.statusConfirmed,
        BookingStatus.driverArriving => l.statusDriverArriving,
        BookingStatus.driverArrived => l.statusDriverArrived,
        BookingStatus.inProgress => l.statusInProgress,
        BookingStatus.completed => l.statusCompleted,
        BookingStatus.cancelled => l.statusCancelled,
      };
}

extension FlightInfoL10n on FlightInfo {
  String localizedLabel(AppLocalizations l) {
    if (cancelled) return l.flightCancelled;
    if (arrived) return l.flightLanded;
    if (delayed) return l.flightDelayed(delayMin);
    return l.flightOnTime;
  }
}

/// "4 min", "1 h 05 min" in the current language.
String localizedDuration(AppLocalizations l, Duration d) {
  final m = d.inMinutes;
  if (m < 60) return l.unitMinutesShort(m);
  return l.unitHoursMinutes(m ~/ 60, (m % 60).toString().padLeft(2, '0'));
}
