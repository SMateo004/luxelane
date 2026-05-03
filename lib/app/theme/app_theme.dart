import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

abstract class LuxColors {
  // Dark palette (app-wide)
  static const black         = Color(0xFF080808);
  static const blackSurface  = Color(0xFF111111);
  static const blackElevated = Color(0xFF1A1A1A);
  static const blackBorder   = Color(0xFF242424);
  // Accent — used very sparingly
  static const gold          = Color(0xFFC9A84C);
  static const sapphire      = Color(0xFFC9A84C);
  static const sapphireLight     = Color(0xFFE2C97E);
  static const sapphireDark      = Color(0xFF9C7A2A);
  static const sapphireSubtle    = Color(0x14C9A84C);
  // On-dark text
  static const white         = Color(0xFFF5F5F5);
  static const whiteSecondary = Color(0xFF9A9A9A);
  static const whiteTertiary = Color(0xFF525252);
  // Light sections (web landing)
  static const cream         = Color(0xFFF3F1ED);
  static const creamBorder   = Color(0xFFE0DDD6);
  static const darkText      = Color(0xFF0D0D0D);
  static const midGray       = Color(0xFF6B6B6B);
  // Semantic
  static const error         = Color(0xFFCF4B4B);
  static const success       = Color(0xFF4B9B6F);
  static const warning       = Color(0xFFC9984C);
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
  static const _serif = 'Cormorant';
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
    color: LuxColors.sapphire, letterSpacing: 1.2,
  );
  static const caption = TextStyle(
    fontFamily: _sans, fontSize: 11, fontWeight: FontWeight.w400,
    color: LuxColors.whiteTertiary, letterSpacing: 0.4,
  );
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

ThemeData get luxTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: LuxColors.black,
  colorScheme: const ColorScheme.dark(
    primary: LuxColors.sapphire,
    onPrimary: LuxColors.black,
    secondary: LuxColors.sapphireLight,
    onSecondary: LuxColors.black,
    surface: LuxColors.blackSurface,
    onSurface: LuxColors.white,
    error: LuxColors.error,
    onError: LuxColors.white,
  ),
  textTheme: const TextTheme(
    displayLarge:   LuxTypography.displayLarge,
    displayMedium:  LuxTypography.displayMedium,
    headlineLarge:  LuxTypography.headlineLarge,
    headlineMedium: LuxTypography.headlineMedium,
    titleLarge:     LuxTypography.titleLarge,
    titleMedium:    LuxTypography.titleMedium,
    bodyLarge:      LuxTypography.bodyLarge,
    bodyMedium:     LuxTypography.bodyMedium,
    labelLarge:     LuxTypography.labelLarge,
    bodySmall:      LuxTypography.caption,
  ),
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
      backgroundColor: LuxColors.sapphire,
      foregroundColor: LuxColors.black,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.sm)),
      textStyle: LuxTypography.labelLarge.copyWith(color: LuxColors.black),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LuxColors.sapphire,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: LuxColors.sapphire),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.sm)),
      textStyle: LuxTypography.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LuxColors.sapphire,
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
      borderSide: const BorderSide(color: LuxColors.sapphire, width: 1.5),
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
  cardTheme: CardTheme(
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
    selectedItemColor: LuxColors.sapphire,
    unselectedItemColor: LuxColors.whiteTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: LuxColors.blackSurface,
    selectedIconTheme: IconThemeData(color: LuxColors.sapphire),
    unselectedIconTheme: IconThemeData(color: LuxColors.whiteTertiary),
    selectedLabelTextStyle: LuxTypography.labelLarge,
    unselectedLabelTextStyle: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 11,
      color: LuxColors.whiteTertiary,
    ),
    indicatorColor: LuxColors.sapphireSubtle,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.sapphire : LuxColors.blackElevated,
    ),
    checkColor: WidgetStateProperty.all(LuxColors.black),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    side: const BorderSide(color: LuxColors.whiteTertiary),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.sapphire : LuxColors.whiteTertiary,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? LuxColors.sapphireSubtle : LuxColors.blackElevated,
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
);

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
