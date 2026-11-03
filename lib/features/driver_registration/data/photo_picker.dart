import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Resultado de pedir una foto: los bytes, cancelado o sin acceso.
sealed class PickResult {
  const PickResult();
}

class Picked extends PickResult {
  const Picked(this.bytes);
  final Uint8List bytes;
}

class PickCancelled extends PickResult {
  const PickCancelled();
}

class PickUnavailable extends PickResult {
  const PickUnavailable();
}

/// Cámara o galería del sistema (sustituible en pruebas). Sin cámara
/// propia: las guías de encuadre se muestran antes de abrirla.
abstract class PhotoPicker {
  Future<PickResult> pick(PhotoSource source, {bool frontCamera = false});
}

class SystemPhotoPicker implements PhotoPicker {
  SystemPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<PickResult> pick(PhotoSource source,
      {bool frontCamera = false}) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        preferredCameraDevice:
            frontCamera ? CameraDevice.front : CameraDevice.rear,
        // Sin pedir los metadatos completos (en iOS evita el permiso de
        // fotos con ubicación); la app además los quita al recomprimir.
        requestFullMetadata: false,
      );
      if (file == null) return const PickCancelled();
      return Picked(await file.readAsBytes());
    } catch (_) {
      return const PickUnavailable();
    }
  }
}
