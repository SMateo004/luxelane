import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lux_tokens.dart';

export 'lux_tokens.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

abstract class LuxColors {
  // Dark surfaces — marino
  static const black         = LuxPalette.ink;
  static const blackSurface  = LuxPalette.surface;
  static const blackElevated = LuxPalette.elevated;
  static const blackBorder   = LuxPalette.line;
  // Brand accent — champagne (use ink text on top of it)
  static const accent        = LuxPalette.champagne;
  static const accentLight   = LuxPalette.champagneLight;
  static const accentSubtle  = Color(0x1FC6A15B); // champagne @ 12%
  static const onAccent      = LuxPalette.ink;
  // Information (links, info badges)
  static const info          = LuxPalette.sapphire;
  // On-dark text
  static const white          = LuxPalette.snow;
  static const whiteSecondary = LuxPalette.mist;
  static const whiteTertiary  = LuxPalette.fog;
  // Light sections
  static const cream         = LuxPalette.paper2;
  static const creamBorder   = LuxPalette.hairline;
  static const darkText      = LuxPalette.ink;
  static const midGray       = LuxPalette.slate;
  // Semantic
  static const error         = LuxPalette.error;
  static const success       = LuxPalette.success;
  static const warning       = LuxPalette.warning;
}

abstract class LuxSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

abstract class LuxRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 12;
  static const double xl = 16;
}

abstract class LuxTypography {
  static const _serif = 'Cormorant Garamond';
  static const _sans  = 'Montserrat';

  static const displayLarge = TextStyle(
    fontFamily: _serif, fontSize: 48, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.5, height: 1.1,
  );
  static const displayMedium = TextStyle(
    fontFamily: _serif, fontSize: 36, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.3, height: 1.15,
  );
  static const headlineLarge = TextStyle(
    fontFamily: _serif, fontSize: 28, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.2,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _sans, fontSize: 20, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.5,
  );
  static const titleLarge = TextStyle(
    fontFamily: _sans, fontSize: 16, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.8,
  );
  static const titleMedium = TextStyle(
    fontFamily: _sans, fontSize: 14, fontWeight: FontWeight.w600,
    color: LuxColors.white, letterSpacing: 0.4,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _sans, fontSize: 16, fontWeight: FontWeight.w400,
    color: LuxColors.white, letterSpacing: 0.2,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _sans, fontSize: 14, fontWeight: FontWeight.w400,
    color: LuxColors.whiteSecondary, letterSpacing: 0.2,
  );
  static const labelLarge = TextStyle(
    fontFamily: _sans, fontSize: 13, fontWeight: FontWeight.w500,
    color: LuxColors.accent, letterSpacing: 1.2,
  );
  static const caption = TextStyle(
    fontFamily: _sans, fontSize: 11, fontWeight: FontWeight.w400,
    color: LuxColors.whiteTertiary, letterSpacing: 0.4,
  );
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

ThemeData get luxTheme {
  // Build base text theme using GoogleFonts — guarantees fonts load on all platforms
  final serif = GoogleFonts.cormorantGaramond;
  final sans  = GoogleFonts.montserrat;

  final textTheme = TextTheme(
    displayLarge:   serif(fontSize: 48, fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.5, height: 1.1),
    displayMedium:  serif(fontSize: 36, fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.3, height: 1.15),
    headlineLarge:  serif(fontSize: 28, fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.2),
    headlineMedium: sans(fontSize: 20,  fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.5),
    titleLarge:     sans(fontSize: 16,  fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.8),
    titleMedium:    sans(fontSize: 14,  fontWeight: FontWeight.w600, color: LuxColors.white, letterSpacing: 0.4),
    bodyLarge:      sans(fontSize: 16,  fontWeight: FontWeight.w400, color: LuxColors.white, letterSpacing: 0.2),
    bodyMedium:     sans(fontSize: 14,  fontWeight: FontWeight.w400, color: LuxColors.whiteSecondary, letterSpacing: 0.2),
    labelLarge:     sans(fontSize: 13,  fontWeight: FontWeight.w500, color: LuxColors.accent, letterSpacing: 1.2),
    bodySmall:      sans(fontSize: 11,  fontWeight: FontWeight.w400, color: LuxColors.whiteTertiary, letterSpacing: 0.4),
  );

  return ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: LuxColors.black,
  colorScheme: const ColorScheme.dark(
    primary: LuxColors.accent,
    onPrimary: LuxColors.onAccent,
    secondary: LuxColors.accentLight,
    onSecondary: LuxColors.onAccent,
    surface: LuxColors.blackSurface,
    onSurface: LuxColors.white,
    error: LuxColors.error,
    onError: LuxColors.white,
  ),
  textTheme: textTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: LuxColors.black,
    foregroundColor: LuxColors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: LuxTypography.headlineMedium,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // Ink on champagne ≈ 8.6:1 contrast.
      backgroundColor: LuxColors.accent,
      foregroundColor: LuxColors.onAccent,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.sm)),
      textStyle: LuxTypography.labelLarge.copyWith(color: LuxColors.onAccent),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LuxColors.accent,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: LuxColors.accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.sm)),
      textStyle: LuxTypography.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LuxColors.accent,
      textStyle: LuxTypography.labelLarge,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LuxColors.blackElevated,
    hintStyle: LuxTypography.bodyMedium,
    labelStyle: LuxTypography.bodyMedium,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.sm),
      borderSide: const BorderSide(color: LuxColors.whiteTertiary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.sm),
      borderSide: const BorderSide(color: LuxColors.blackBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.sm),
      borderSide: const BorderSide(color: LuxColors.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.sm),
      borderSide: const BorderSide(color: LuxColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.sm),
      borderSide: const BorderSide(color: LuxColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  cardTheme: CardThemeData(
    color: LuxColors.blackSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      side: const BorderSide(color: LuxColors.blackBorder),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: LuxColors.blackBorder,
    thickness: 1,
    space: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: LuxColors.blackSurface,
    selectedItemColor: LuxColors.accent,
    unselectedItemColor: LuxColors.whiteTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: LuxColors.blackSurface,
    selectedIconTheme: IconThemeData(color: LuxColors.accent),
    unselectedIconTheme: IconThemeData(color: LuxColors.whiteTertiary),
    selectedLabelTextStyle: LuxTypography.labelLarge,
    unselectedLabelTextStyle: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 11,
      color: LuxColors.whiteTertiary,
    ),
    indicatorColor: LuxColors.accentSubtle,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.accent : LuxColors.blackElevated,
    ),
    checkColor: WidgetStateProperty.all(LuxColors.black),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    side: const BorderSide(color: LuxColors.whiteTertiary),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.accent : LuxColors.whiteTertiary,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.accentSubtle : LuxColors.blackElevated,
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: LuxColors.blackSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      side: const BorderSide(color: LuxColors.blackBorder),
    ),
    textStyle: LuxTypography.bodyMedium,
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: LuxColors.blackElevated,
      borderRadius: BorderRadius.circular(LuxRadius.sm),
    ),
    textStyle: LuxTypography.caption,
  ),
); // ThemeData
} // luxTheme

// ---------------------------------------------------------------------------
// Responsive breakpoints
// ---------------------------------------------------------------------------

abstract class LuxBreakpoints {
  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1280;
}

bool isWeb(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= LuxBreakpoints.mobile;
bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= LuxBreakpoints.desktop;
double contentMaxWidth(BuildContext ctx) => isDesktop(ctx) ? 1100 : double.infinity;
