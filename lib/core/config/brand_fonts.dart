import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lo más que el arranque espera a las fuentes de marca. Sin red (o con
/// una red lenta) la app sigue con la fuente del sistema en vez de quedarse
/// en blanco; google_fonts las aplica cuando lleguen.
const Duration kBrandFontsTimeout = Duration(seconds: 8);

/// Precarga Montserrat y Cormorant Garamond para que todos los
/// TextStyle(fontFamily: …) se resuelvan bien en web y en nativo.
/// Nunca lanza ni espera más de [timeout]. [load] solo se cambia en tests.
Future<void> preloadBrandFonts({
  Duration timeout = kBrandFontsTimeout,
  Future<void> Function()? load,
  void Function(String message)? log,
}) async {
  try {
    await (load ?? _loadBrandFonts)().timeout(timeout);
  } catch (e) {
    (log ?? debugPrint)('[Luxelane] fuentes de marca no disponibles: $e');
  }
}

Future<void> _loadBrandFonts() {
  GoogleFonts.config.allowRuntimeFetching = true;
  return GoogleFonts.pendingFonts([
    GoogleFonts.montserrat(),
    GoogleFonts.montserrat(fontWeight: FontWeight.w300),
    GoogleFonts.montserrat(fontWeight: FontWeight.w500),
    GoogleFonts.montserrat(fontWeight: FontWeight.w600),
    GoogleFonts.montserrat(fontWeight: FontWeight.w700),
    GoogleFonts.cormorantGaramond(),
    GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300),
    GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w500),
    GoogleFonts.cormorantGaramond(fontStyle: FontStyle.italic),
    GoogleFonts.cormorantGaramond(
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.italic,
    ),
  ]);
}
