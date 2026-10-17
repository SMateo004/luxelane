import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand fonts (Montserrat, Cormorant Garamond) ship in assets/google_fonts
/// and are declared in pubspec.yaml, so they work offline. Weights not
/// bundled are still fetched by google_fonts when there is a connection.
abstract final class BrandFonts {
  /// Warms up the bundled weights before the first frame. Never blocks
  /// startup for long and never fails it: a missing font only means a
  /// fallback font for a moment.
  static Future<void> preload() async {
    GoogleFonts.config.allowRuntimeFetching = true;
    try {
      await GoogleFonts.pendingFonts([
        for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700])
          GoogleFonts.montserrat(fontWeight: w),
        for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w600])
          GoogleFonts.cormorantGaramond(fontWeight: w),
        GoogleFonts.cormorantGaramond(fontStyle: FontStyle.italic),
        GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
      ]).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[Luxelane] Brand fonts not preloaded: $e');
    }
  }

  /// Both fonts are under the SIL Open Font License, which asks to ship it.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (name, file) in [('Montserrat', 'OFL-Montserrat.txt'), ('Cormorant Garamond', 'OFL-CormorantGaramond.txt')]) {
        yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString('assets/google_fonts/$file'));
      }
    });
  }
}
