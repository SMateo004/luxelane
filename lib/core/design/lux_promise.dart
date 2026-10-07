import 'package:flutter/material.dart';

/// Single source of truth for every service promise shown to travellers.
///
/// High-value clients read inconsistency as risk: if one page says
/// "15 minutes of free waiting" and another says "60", neither is believed.
/// Every page, card and summary pulls its reassurance copy from here.
abstract class LuxPromise {
  static const fixedPrice = 'Precio fijo, todo incluido';
  static const fixedPriceLong =
      'El precio que ves es el precio final: peajes, impuestos y propina incluidos.';
  static const freeCancel = 'Cancelación gratuita hasta 1 h antes';
  static const freeCancelLong =
      'Cancela o modifica sin coste hasta 1 hora antes de la recogida.';
  static const waitAirport = '60 min de espera gratuita en aeropuertos';
  static const waitStandard = '15 min de espera gratuita en otras recogidas';
  static const flightTracking = 'Seguimiento de vuelo en tiempo real';
  static const flightTrackingLong =
      'Seguimos tu vuelo y ajustamos la recogida si se adelanta o se retrasa, sin coste.';
  static const chauffeurs = 'Chóferes profesionales verificados';
  static const chauffeursLong =
      'Cada chófer supera verificación de antecedentes, inspección del vehículo y formación en servicio.';
  static const support = 'Atención al cliente 24/7';
  static const privacy = 'Discreción y privacidad absolutas';
}

/// A promise rendered as an icon + short line (and optional detail).
@immutable
class LuxAssurance {
  const LuxAssurance(this.icon, this.title, [this.detail]);
  final IconData icon;
  final String title;
  final String? detail;

  static const fixedPrice = LuxAssurance(Icons.lock_outline_rounded,
      LuxPromise.fixedPrice, LuxPromise.fixedPriceLong);
  static const freeCancel = LuxAssurance(Icons.event_available_outlined,
      LuxPromise.freeCancel, LuxPromise.freeCancelLong);
  static const waitAirport = LuxAssurance(
      Icons.hourglass_bottom_rounded,
      LuxPromise.waitAirport,
      'Tu chófer te espera en llegadas con un cartel con tu nombre.');
  static const waitStandard = LuxAssurance(
      Icons.hourglass_bottom_rounded,
      LuxPromise.waitStandard,
      'Sin prisas: el tiempo de cortesía está incluido en el precio.');
  static const flightTracking = LuxAssurance(Icons.flight_land_rounded,
      LuxPromise.flightTracking, LuxPromise.flightTrackingLong);
  static const chauffeurs = LuxAssurance(Icons.verified_user_outlined,
      LuxPromise.chauffeurs, LuxPromise.chauffeursLong);
  static const support = LuxAssurance(
      Icons.support_agent_outlined,
      LuxPromise.support,
      'Una persona real, a cualquier hora, antes, durante y después del viaje.');
  static const privacy = LuxAssurance(
      Icons.shield_moon_outlined,
      LuxPromise.privacy,
      'Tus datos, tus rutas y tus conversaciones permanecen confidenciales.');
}
