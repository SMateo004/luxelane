// ============================================================
// Luxelane brand tokens — "Marino + Champagne"
//
// Single source of truth for colour, motion and money formatting.
// `LuxColors` (dark app surfaces) and `LD` (light editorial surfaces)
// are both derived from this palette — never hardcode hex values in
// widgets; add a token here instead.
//
// Contrast (WCAG 2.1):
//   ink on champagne ............ 8.6:1  → primary CTA
//   champagne on ink ............ 8.6:1  → accent text on dark
//   champagneDeep on paper ...... 4.6:1  → accent text/lines on light
//   mist on ink ................. 5.3:1  → secondary text on dark
//   slate on paper .............. 5.6:1  → secondary text on light
// ============================================================

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

abstract class LuxPalette {
  // Marino (navy) — trust
  static const ink       = Color(0xFF0B1220);
  static const surface   = Color(0xFF111A2B);
  static const elevated  = Color(0xFF18233A);
  static const line      = Color(0xFF24314A);

  // Champagne — hospitality
  static const champagne      = Color(0xFFC6A15B);
  static const champagneLight = Color(0xFFD9BC82);
  static const champagneDeep  = Color(0xFF8C6A2E);
  static const champagneTint  = Color(0xFFF5EEDF);

  // Paper — light editorial surfaces
  static const paper  = Color(0xFFFAF8F4);
  static const paper2 = Color(0xFFF2EEE7);
  static const paper3 = Color(0xFFE8E2D6);
  static const hairline = Color(0xFFE4DED2);

  // Text tones
  static const snow  = Color(0xFFF5F3EE); // primary on dark
  static const mist  = Color(0xFF9AA3B2); // secondary on dark
  static const fog   = Color(0xFF7A8699); // tertiary on dark (≥ 4.5:1)
  static const ink2  = Color(0xFF2A3346); // secondary on light
  static const slate = Color(0xFF5E6676); // tertiary on light

  // Information only (links, info badges) — not a brand accent
  static const sapphire = Color(0xFF3B6FB6);

  // Semantic
  static const success = Color(0xFF3E9C74);
  static const error   = Color(0xFFD2524E);
  static const warning = Color(0xFFD69A3C);
}

/// Shared motion language: one easing curve, three durations.
abstract class LuxMotion {
  static const fast   = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow   = Duration(milliseconds: 400);
  static const curve  = Cubic(0.16, 1, 0.3, 1);
}

/// Prices are charged in Bolivianos.
abstract class LuxMoney {
  static const currencyCode = 'BOB';
  static const symbol = 'Bs';

  static final _whole = NumberFormat('#,##0', 'es');
  static final _cents = NumberFormat('#,##0.00', 'es');

  /// `Bs 1.250` / `Bs 1.250,50` (with [cents]).
  static String format(num amount, {bool cents = false}) =>
      '$symbol ${(cents ? _cents : _whole).format(amount)}';
}
