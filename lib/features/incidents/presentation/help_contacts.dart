import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../../l10n/l10n.dart';

/// Enlace de mapa a la última ubicación conocida.
String mapLink(double lat, double lng) =>
    'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

/// Texto del SMS que la persona solo tiene que enviar a central. Siempre en
/// español: lo lee central, que trabaja en español como el panel, sea cual
/// sea el idioma de la app.
String incidentSmsBody(String bookingShortId, {double? lat, double? lng}) {
  final t = lookupAppLocalizations(const Locale('es'));
  return [
    t.incidentSmsHeader(bookingShortId),
    if (lat != null && lng != null)
      t.incidentSmsLocation(mapLink(lat, lng))
    else
      t.incidentSmsNoLocation,
  ].join(' ');
}

/// `sms:` prellenado a central. iOS separa el cuerpo con `&`, Android con
/// `?`.
Uri incidentSmsUri(
  String phone,
  String bookingShortId, {
  double? lat,
  double? lng,
  TargetPlatform? platform,
}) {
  final body = Uri.encodeComponent(
    incidentSmsBody(bookingShortId, lat: lat, lng: lng),
  );
  final sep =
      (platform ?? defaultTargetPlatform) == TargetPlatform.iOS ? '&' : '?';
  return Uri.parse('sms:${phone.replaceAll(' ', '')}${sep}body=$body');
}

Uri telUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));

/// Mismo ID corto que el panel y los avisos (#ABC123).
String bookingShortId(String id) =>
    (id.length > 6 ? id.substring(0, 6) : id).toUpperCase();

/// Texto si no hay números configurados: nunca se inventa uno.
String get kNoNumbersHelp => L10n.current.incidentNoNumbersHelp;
