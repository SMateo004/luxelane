import 'package:flutter/material.dart';

/// Single source of truth for every service promise shown to travellers.
///
/// High-value clients read inconsistency as risk: if one page says
/// "15 minutes of free waiting" and another says "60", neither is believed.
/// Every page, card and summary pulls its reassurance copy from here.
abstract class LuxPromise {
  // Solo hechos que el sistema cumple hoy (Parte B de experiencia, E2): el
  // precio lo calcula el servidor antes de confirmar y Luxelane revisa los
  // documentos de cada chófer. Nada de cancelación gratuita, esperas,
  // seguimiento de vuelo, atención 24/7 ni propinas: no están respaldados
  // (test/experiencia/promesas_test.dart lo vigila).
  static const fixedPrice = 'Precio fijo al reservar';
  static const fixedPriceLong =
      'El precio que ves al confirmar lo calcula Luxelane para tu trayecto.';
  static const chauffeurs = 'Chóferes con documentos verificados';
  static const chauffeursLong =
      'Luxelane revisa los documentos de cada chófer antes de que reciba viajes.';
  static const privacy = 'Discreción y privacidad absolutas';
}

/// A promise rendered as an icon + short line (and optional detail).
@immutable
class LuxAssurance {
  const LuxAssurance(this.icon, this.title, [this.detail]);
  final IconData icon;
  final String title;
  final String? detail;

  static const fixedPrice = LuxAssurance(
    Icons.lock_outline_rounded,
    LuxPromise.fixedPrice,
    LuxPromise.fixedPriceLong,
  );
  static const chauffeurs = LuxAssurance(
    Icons.verified_user_outlined,
    LuxPromise.chauffeurs,
    LuxPromise.chauffeursLong,
  );
  static const privacy = LuxAssurance(
    Icons.shield_moon_outlined,
    LuxPromise.privacy,
    'Tus datos, tus rutas y tus conversaciones permanecen confidenciales.',
  );
}
