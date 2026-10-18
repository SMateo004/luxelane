import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/vehicles/vehicle_catalog.dart';

/// Admin side of the vehicle catalog. Saving goes through the
/// saveVehicleClass callable (validated and audited on the server).
abstract class VehicleClassRepository {
  /// Null on success, else an error key (`vehicle/…`).
  Future<String?> save(VehicleClassInfo v, {required bool create});

  /// Uploads a photo for [classId]; returns its public URL (null on failure).
  Future<String?> uploadImage(String classId, Uint8List bytes, String contentType);
}

class VehicleClassRepositoryImpl implements VehicleClassRepository {
  VehicleClassRepositoryImpl(this._fn, [FirebaseStorage? storage]) : _storageOverride = storage;
  final FirebaseFunctions _fn;
  final FirebaseStorage? _storageOverride;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  @override
  Future<String?> save(VehicleClassInfo v, {required bool create}) async {
    try {
      await _fn.httpsCallable('saveVehicleClass').call({'id': v.id, 'data': v.toJson(), 'create': create});
      return null;
    } on FirebaseFunctionsException catch (e) {
      final m = RegExp(r'vehicle/[a-z-]+').firstMatch(e.message ?? '');
      return m?.group(0) ?? 'vehicle/failed';
    } catch (_) {
      return 'vehicle/failed';
    }
  }

  @override
  Future<String?> uploadImage(String classId, Uint8List bytes, String contentType) async {
    try {
      final ext = contentType.split('/').last.replaceAll('jpeg', 'jpg');
      final ref = _storage.ref('vehicle_classes/$classId/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
