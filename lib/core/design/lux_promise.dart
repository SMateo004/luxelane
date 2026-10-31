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
  // Siguen siendo `const` en español porque otras pantallas los usan en
  // expresiones const; el texto traducido está en L10n (commonPromise…).
  static const fixedPrice =
      'Precio fijo al reservar'; // i18n-ignore: const en español, traducido en commonPromiseFixedPrice
  static const fixedPriceLong =
      'El precio que ves al confirmar lo calcula Luxelane para tu trayecto.'; // i18n-ignore: const en español, traducido en commonPromiseFixedPriceLong
  static const chauffeurs =
      'Chóferes con documentos verificados'; // i18n-ignore: const en español, traducido en commonPromiseChauffeurs
  static const chauffeursLong =
      'Luxelane revisa los documentos de cada chófer antes de que reciba viajes.'; // i18n-ignore: const en español, traducido en commonPromiseChauffeursLong
}

/// A promise rendered as an icon + short line (and optional detail).
@immutable
class LuxAssurance {
  const LuxAssurance(this.icon, this.title, [this.detail]);
  final IconData icon;
  final String title;
  final String? detail;

  static const LuxAssurance fixedPrice = _PromiseAssurance(
    Icons.lock_outline_rounded,
    LuxPromise.fixedPrice,
    LuxPromise.fixedPriceLong,
  );
  static const LuxAssurance chauffeurs = _PromiseAssurance(
    Icons.verified_user_outlined,
    LuxPromise.chauffeurs,
    LuxPromise.chauffeursLong,
  );
}

/// Las dos promesas fijas, const y con el texto en el idioma activo.
class _PromiseAssurance extends LuxAssurance {
  const _PromiseAssurance(super.icon, super.title, [super.detail]);

  bool get _isFixedPrice => super.title == LuxPromise.fixedPrice;

  @override
  String get title => _isFixedPrice
      ? L10n.current.commonPromiseFixedPrice
      : L10n.current.commonPromiseChauffeurs;

  @override
  String? get detail => _isFixedPrice
      ? L10n.current.commonPromiseFixedPriceLong
      : L10n.current.commonPromiseChauffeursLong;
}
