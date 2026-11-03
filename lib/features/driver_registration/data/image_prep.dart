import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/config/emulator_setup.dart' show kUseEmulators;

/// Lado corto mínimo de una foto de documento, en píxeles. Es un valor
/// técnico (legibilidad), no un requisito de negocio: se puede ajustar.
const kMinShortSidePx = 720;

/// Al recomprimir, la foto se reduce en proporción hasta que el lado corto
/// quede en torno a este valor (muy por debajo de los 10 MB del servidor).
const kTargetSidePx = 2048;
const kJpegQuality = 85;

/// Subir documentos solo desde la app del teléfono: en la web la
/// compresión necesita un script externo que la CSP no permite y la cámara
/// no se puede garantizar (decisión 3).
bool get uploadsSupported =>
    debugUploadsSupported ?? (!kIsWeb || kCaptureWebUploads);

/// Solo para las capturas contra los emuladores (entorno de revisión): la web
/// sube SIN recomprimir para poder ver los pasos de la cámara. Exige
/// USE_EMULATORS además de CAPTURE_WEB_UPLOADS: la build de producción nunca
/// lo activa (build_config_test.dart).
const kCaptureWebUploads =
    kUseEmulators && bool.fromEnvironment('CAPTURE_WEB_UPLOADS');

/// Solo pruebas: simula la web (false) o el teléfono (true).
bool? debugUploadsSupported;

enum ImageIssue { unreadable, tooSmall }

class PreparedImage {
  const PreparedImage(this.bytes, {required this.width, required this.height});
  final Uint8List bytes;
  final int width;
  final int height;
  static const contentType = 'image/jpeg';
}

/// Comprueba y prepara una foto antes de subirla (sustituible en pruebas).
abstract class ImagePrep {
  /// Tamaño de la imagen original; null si no se puede leer.
  Future<({int width, int height})?> size(Uint8List bytes);

  /// JPEG recomprimido SIN metadatos (EXIF, ubicación incluida).
  Future<Uint8List> compressWithoutMetadata(Uint8List bytes);

  /// Lee el tamaño, rechaza lo ilegible o pequeño y recomprime.
  Future<({PreparedImage? image, ImageIssue? issue})> prepare(
    Uint8List bytes,
  ) async {
    final s = await size(bytes);
    if (s == null) return (image: null, issue: ImageIssue.unreadable);
    final short = s.width < s.height ? s.width : s.height;
    if (short < kMinShortSidePx) {
      return (image: null, issue: ImageIssue.tooSmall);
    }
    final out = await compressWithoutMetadata(bytes);
    if (out.isEmpty) return (image: null, issue: ImageIssue.unreadable);
    return (
      image: PreparedImage(out, width: s.width, height: s.height),
      issue: null,
    );
  }
}

class DeviceImagePrep extends ImagePrep {
  @override
  Future<({int width, int height})?> size(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final r = (width: frame.image.width, height: frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return r;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List> compressWithoutMetadata(Uint8List bytes) async =>
      // Solo en el modo de capturas (web contra emuladores): sin compresión.
      kIsWeb && kCaptureWebUploads
          ? bytes
          : await FlutterImageCompress.compressWithList(
              bytes,
              minWidth: kTargetSidePx,
              minHeight: kTargetSidePx,
              quality: kJpegQuality,
              // Explícitos aunque sean los valores por defecto: JPEG, orientación
              // aplicada a los píxeles y SIN EXIF (ubicación incluida).
              // ignore: avoid_redundant_argument_values
              format: CompressFormat.jpeg,
              // ignore: avoid_redundant_argument_values
              keepExif: false,
              // ignore: avoid_redundant_argument_values
              autoCorrectionAngle: true,
            );
}
