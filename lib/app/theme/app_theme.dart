import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/lux_raised.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

/// App palette — "Marfil". The same light tokens the public web uses
/// (`LD.*` in `home_design.dart`): ivory surfaces, ink text and a single
/// sapphire accent. Luxelane never paints black surfaces.
abstract class LuxColors {
  // Surfaces
  static const bg = Color(0xFFFAFBFE); // LD.bg — page background
  static const surface = Color(0xFFFFFFFF); // cards, sheets, bars
  static const surfaceMuted = Color(0xFFF2F5FB); // LD.bg2 — inputs, chips
  static const surfaceDeep = Color(0xFFE8EDF7); // LD.bg3 — pressed / tracks
  static const border = Color(0xFFDDE4F0); // LD.border
  // Ink (text & icons)
  static const ink = Color(0xFF0D1B2E); // LD.ink
  static const inkSecondary = Color(0xFF2C3D55); // LD.ink2
  static const inkTertiary = Color(0xFF637490); // LD.ink3
  // Accent — sapphire, the only accent
  static const sapphire = Color(0xFF1B4F8A); // LD.sph
  static const sapphireLight = Color(0xFF2E6FBF); // LD.sphLt
  static const sapphireDark = Color(0xFF0D3066); // LD.sphDim
  static const sapphireTint = Color(0xFFEEF3FA); // LD.sphTint
  static const sapphireSubtle = Color(0x141B4F8A);

  /// Text and icons placed on a sapphire fill (primary buttons, badges).
  static const onAccent = Color(0xFFFFFFFF);

  /// Soft navy shadow for floating elements over the map.
  static const shadow = Color(0x1A0D1B2E);
  // Semantic — tuned for AA contrast on ivory
  static const error = Color(0xFFB83A3A);
  static const success = Color(0xFF2F7D55);
  static const warning = Color(0xFFA8741F);
}

/// Shared soft elevation: floating cards over the map and bottom sheets.
const luxSoftShadow = [
  BoxShadow(color: LuxColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
];

abstract class LuxSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Radios: controles 12, tarjetas 16, hojas 24. Curvas suaves pero firmes.
abstract class LuxRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Elevación: tres niveles y nada más. Sombras difusas en tinta, nunca
/// negras, para que las superficies floten sin pesar.
abstract class LuxElevation {
  /// Tarjetas en reposo sobre el fondo marfil.
  static const low = [
    BoxShadow(color: Color(0x0A0D1B2E), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// Elementos flotantes: paneles sobre el mapa, tarjeta seleccionada.
  static const mid = luxSoftShadow;

  /// Hojas modales y avisos.
  static const high = [
    BoxShadow(color: Color(0x240D1B2E), blurRadius: 40, offset: Offset(0, 16)),
  ];
}

abstract class LuxTypography {
  static const _serif = 'Cormorant Garamond';
  static const _sans = 'Montserrat';

  static const displayLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    color: LuxColors.ink,
    letterSpacing: -0.5,
    height: 1.05,
  );
  static const displayMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: LuxColors.ink,
    letterSpacing: -0.3,
    height: 1.1,
  );
  static const headlineLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: LuxColors.ink,
    letterSpacing: -0.1,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: LuxColors.ink,
    letterSpacing: 0.2,
  );
  static const titleLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LuxColors.ink,
    letterSpacing: 0.3,
  );
  static const titleMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LuxColors.ink,
    letterSpacing: 0.2,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: LuxColors.ink,
    letterSpacing: 0.1,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LuxColors.inkSecondary,
    letterSpacing: 0.1,
    height: 1.45,
  );
  static const labelLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: LuxColors.sapphire,
    letterSpacing: 1.2,
  );

  /// Etiqueta de botón: frase normal, peso firme. Las mayúsculas espaciadas
  /// quedan para rótulos pequeños (eyebrows), no para acciones.
  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: LuxColors.ink,
    letterSpacing: 0.2,
  );

  /// Rótulo pequeño en mayúsculas espaciadas sobre un título.
  static const eyebrow = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: LuxColors.sapphire,
    letterSpacing: 2.2,
  );

  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: LuxColors.inkTertiary,
    letterSpacing: 0.3,
  );
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

ThemeData get luxTheme {
  // Build base text theme using GoogleFonts — guarantees fonts load on all platforms
  const serif = GoogleFonts.cormorantGaramond;
  const sans = GoogleFonts.montserrat;

  TextStyle gf(
          TextStyle t,
          TextStyle Function({
            Color? color,
            double? fontSize,
            FontWeight? fontWeight,
            double? letterSpacing,
            double? height,
          }) font) =>
      font(
        color: t.color,
        fontSize: t.fontSize,
        fontWeight: t.fontWeight,
        letterSpacing: t.letterSpacing,
        height: t.height,
      );

  final textTheme = TextTheme(
    displayLarge: gf(LuxTypography.displayLarge, serif),
    displayMedium: gf(LuxTypography.displayMedium, serif),
    headlineLarge: gf(LuxTypography.headlineLarge, serif),
    headlineMedium: gf(LuxTypography.headlineMedium, sans),
    titleLarge: gf(LuxTypography.titleLarge, sans),
    titleMedium: gf(LuxTypography.titleMedium, sans),
    bodyLarge: gf(LuxTypography.bodyLarge, sans),
    bodyMedium: gf(LuxTypography.bodyMedium, sans),
    labelLarge: gf(LuxTypography.labelLarge, sans),
    bodySmall: gf(LuxTypography.caption, sans),
  );

  final fieldRadius = BorderRadius.circular(LuxRadius.md);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: LuxColors.bg,
    canvasColor: LuxColors.bg,
    colorScheme: const ColorScheme.light(
      primary: LuxColors.sapphire,
      onPrimary: LuxColors.onAccent,
      primaryContainer: LuxColors.sapphireTint,
      onPrimaryContainer: LuxColors.sapphireDark,
      secondary: LuxColors.sapphireLight,
      onSecondary: LuxColors.onAccent,
      surface: LuxColors.surface,
      onSurface: LuxColors.ink,
      onSurfaceVariant: LuxColors.inkTertiary,
      surfaceContainerLowest: LuxColors.surface,
      surfaceContainerLow: LuxColors.bg,
      surfaceContainer: LuxColors.surface,
      surfaceContainerHigh: LuxColors.surface,
      surfaceContainerHighest: LuxColors.surfaceMuted,
      outline: LuxColors.border,
      outlineVariant: LuxColors.border,
      error: LuxColors.error,
      onError: LuxColors.onAccent,
      shadow: LuxColors.shadow,
      surfaceTint: Colors.transparent,
    ),
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: LuxColors.ink),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: LuxColors.sapphire),
    appBarTheme: const AppBarTheme(
      backgroundColor: LuxColors.bg,
      foregroundColor: LuxColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: LuxColors.ink),
      titleTextStyle: LuxTypography.headlineMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // Painted by backgroundBuilder: the shared, subtle Luxelane relief.
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LuxColors.onAccent,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: LuxColors.onAccent.withValues(alpha: 0.7),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.md)),
        textStyle: LuxTypography.button.copyWith(color: LuxColors.onAccent),
        elevation: 0,
      ).copyWith(
        backgroundBuilder: (context, states, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: luxRaisedDecoration(
            pressed: states.contains(WidgetState.pressed),
            enabled: !states.contains(WidgetState.disabled),
            radius: LuxRadius.md,
          ),
          child: child,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LuxColors.sapphire,
        foregroundColor: LuxColors.onAccent,
        elevation: 0,
        minimumSize: const Size(64, 46),
        textStyle: LuxTypography.button.copyWith(fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: LuxColors.surface,
        foregroundColor: LuxColors.ink,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: LuxColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.md)),
        textStyle: LuxTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LuxColors.sapphire,
        textStyle: LuxTypography.button.copyWith(fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.sm)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: LuxColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LuxColors.surface,
      hintStyle:
          LuxTypography.bodyMedium.copyWith(color: LuxColors.inkTertiary),
      labelStyle: LuxTypography.bodyMedium,
      floatingLabelStyle: LuxTypography.caption
          .copyWith(color: LuxColors.sapphire, letterSpacing: 0.6),
      prefixIconColor: LuxColors.inkTertiary,
      suffixIconColor: LuxColors.inkTertiary,
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: LuxColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: LuxColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: LuxColors.sapphire, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: LuxColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: const BorderSide(color: LuxColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      color: LuxColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxRadius.lg),
        side: const BorderSide(color: LuxColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: LuxColors.border,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: LuxColors.inkTertiary,
      textColor: LuxColors.ink,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LuxColors.surfaceMuted,
      selectedColor: LuxColors.sapphireTint,
      side: const BorderSide(color: LuxColors.border),
      labelStyle: LuxTypography.caption.copyWith(color: LuxColors.ink),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.xl)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LuxColors.surface,
      selectedItemColor: LuxColors.sapphire,
      unselectedItemColor: LuxColors.inkTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LuxColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: LuxColors.sapphireTint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => LuxTypography.caption.copyWith(
          fontSize: 11,
          color: s.contains(WidgetState.selected)
              ? LuxColors.ink
              : LuxColors.inkTertiary,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? LuxColors.sapphire
              : LuxColors.inkTertiary,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: LuxColors.surface,
      selectedIconTheme: IconThemeData(color: LuxColors.sapphire),
      unselectedIconTheme: IconThemeData(color: LuxColors.inkTertiary),
      selectedLabelTextStyle: LuxTypography.labelLarge,
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        color: LuxColors.inkTertiary,
      ),
      indicatorColor: LuxColors.sapphireTint,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.sapphire
            : LuxColors.surface,
      ),
      checkColor: WidgetStateProperty.all(LuxColors.onAccent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: const BorderSide(color: LuxColors.inkTertiary),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.sapphire
            : LuxColors.inkTertiary,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.onAccent
            : LuxColors.inkTertiary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.sapphire
            : LuxColors.surfaceMuted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.sapphire
            : LuxColors.border,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: LuxColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: LuxColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxRadius.md),
        side: const BorderSide(color: LuxColors.border),
      ),
      textStyle: LuxTypography.bodyMedium,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: LuxColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: const Color(0x660D1B2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.xl)),
      titleTextStyle: LuxTypography.headlineLarge,
      contentTextStyle: LuxTypography.bodyMedium,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LuxColors.surface,
      contentTextStyle: LuxTypography.bodyMedium,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    splashFactory: InkSparkle.splashFactory,
    highlightColor: Colors.transparent,
    datePickerTheme: DatePickerThemeData(
      backgroundColor: LuxColors.surface,
      headerBackgroundColor: LuxColors.sapphireTint,
      headerForegroundColor: LuxColors.ink,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg)),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.onAccent
            : s.contains(WidgetState.disabled)
                ? LuxColors.inkTertiary.withOpacity(0.5)
                : LuxColors.ink,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuxColors.sapphire
            : Colors.transparent,
      ),
      todayBorder: const BorderSide(color: LuxColors.sapphire),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: LuxColors.surface,
      dialBackgroundColor: LuxColors.surfaceMuted,
      hourMinuteColor: LuxColors.surfaceMuted,
      hourMinuteTextColor: LuxColors.ink,
      dialHandColor: LuxColors.sapphire,
      dialTextColor: LuxColors.ink,
      entryModeIconColor: LuxColors.inkTertiary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LuxColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: LuxColors.border,
      dragHandleSize: Size(36, 4),
      modalBarrierColor: Color(0x660D1B2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: LuxColors.sapphireDark,
        borderRadius: BorderRadius.circular(LuxRadius.sm),
      ),
      textStyle: LuxTypography.caption.copyWith(color: LuxColors.onAccent),
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

bool isWeb(BuildContext ctx) =>
    MediaQuery.sizeOf(ctx).width >= LuxBreakpoints.mobile;
bool isDesktop(BuildContext ctx) =>
    MediaQuery.sizeOf(ctx).width >= LuxBreakpoints.desktop;
double contentMaxWidth(BuildContext ctx) =>
    isDesktop(ctx) ? 1100 : double.infinity;
