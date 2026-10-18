// ============================================================
// Luxelane shared tokens that are not colours.
//
// Colours live in app_theme.dart (`LuxColors`, the "Marfil" palette: ivory
// surfaces, ink text, sapphire accent) and `LD` in home_design.dart for the
// web. Luxelane never uses champagne or gold.
// ============================================================

import 'package:intl/intl.dart';

/// Prices are charged in Bolivianos.
abstract class LuxMoney {
  static const currencyCode = 'BOB';
  static const symbol = 'Bs';

  /// `Bs 1.250` (es/pt) or `Bs 1,250` (en); `cents` adds two decimals.
  /// Uses the current app language (Intl.defaultLocale, kept in sync with
  /// the device by IntlLocaleSync).
  static String format(num amount, {bool cents = false}) {
    final pattern = cents ? '#,##0.00' : '#,##0';
    return '$symbol ${NumberFormat(pattern, Intl.getCurrentLocale()).format(amount)}';
  }
}
