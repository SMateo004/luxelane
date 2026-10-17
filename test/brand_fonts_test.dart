import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luxelane/core/config/brand_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every preloaded weight is bundled where google_fonts looks for it (works offline)', () async {
    // With fetching off, a weight missing from assets/google_fonts throws.
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
    await GoogleFonts.pendingFonts([
      for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700])
        GoogleFonts.montserrat(fontWeight: w),
      for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w600])
        GoogleFonts.cormorantGaramond(fontWeight: w),
      GoogleFonts.cormorantGaramond(fontStyle: FontStyle.italic),
      GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    ]);
  });

  test('the fonts\' licenses are registered', () async {
    BrandFonts.registerLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, containsAll(['Montserrat', 'Cormorant Garamond']));
  });
}
