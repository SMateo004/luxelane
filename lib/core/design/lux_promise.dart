import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Single source of truth for every service promise shown to travellers.
///
/// High-value clients read inconsistency as risk: if one page says
/// "15 minutes of free waiting" and another says "60", neither is believed.
/// Every page, card and summary pulls its reassurance copy from here.
abstract class LuxPromise {
  // Solo hechos que el sistema cumple hoy (Parte B de experiencia, E2): el
  // precio lo calcula el servidor antes de confirmar y Luxelane revisa los
  // documentos de cada chófer. Nada de cancelación gratuita, esperas,
  // seguimiento de vuelo, atención 24/7, propinas, puntualidad garantizada
  // ni «discreción y privacidad absolutas»: no están respaldados
  // (test/experiencia/promesas_test.dart lo vigila).
  //
  // Textos en el idioma activo (commonPromise… en lib/l10n/src/common.json).
  static String get fixedPrice => L10n.current.commonPromiseFixedPrice;
  static String get fixedPriceLong => L10n.current.commonPromiseFixedPriceLong;
  static String get chauffeurs => L10n.current.commonPromiseChauffeurs;
  static String get chauffeursLong => L10n.current.commonPromiseChauffeursLong;
}

/// A promise rendered as an icon + short line (and optional detail).
@immutable
class LuxAssurance {
  const LuxAssurance(this.icon, this.title, [this.detail]);
  final IconData icon;
  final String title;
  final String? detail;

  static const LuxAssurance fixedPrice =
      _PromiseAssurance(Icons.lock_outline_rounded, isFixedPrice: true);
  static const LuxAssurance chauffeurs =
      _PromiseAssurance(Icons.verified_user_outlined, isFixedPrice: false);
}

/// Las dos promesas fijas, const y con el texto en el idioma activo.
class _PromiseAssurance extends LuxAssurance {
  const _PromiseAssurance(IconData icon, {required this.isFixedPrice})
      : super(icon, '');

  final bool isFixedPrice;

  @override
  String get title =>
      isFixedPrice ? LuxPromise.fixedPrice : LuxPromise.chauffeurs;

  @override
  String? get detail =>
      isFixedPrice ? LuxPromise.fixedPriceLong : LuxPromise.chauffeursLong;
}
