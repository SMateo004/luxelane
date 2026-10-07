import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/driver_document.dart';

/// Chauffeur verification documents: files in Storage
/// (driver_documents/{uid}/…) plus a record per type in
/// driverProfiles/{uid}/verificationDocs/{type}. Mutations return null on
/// success or a [DriverDocErrorCodes] value.
abstract class DriverDocumentsRepository {
  static const maxBytes = 10 * 1024 * 1024;

  Stream<Map<DriverDocType, DriverDocument>> watch(String driverId);

  Future<String?> upload({
    required String driverId,
    required DriverDocType type,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    DateTime? expiresAt,
  });

  /// Short-lived link to open the file (chauffeur or admin).
  Future<String?> downloadUrl(String storagePath);

  /// Admin review through the reviewDriverDocument Cloud Function.
  Future<String?> review({
    required String driverId,
    required DriverDocType type,
    required bool approve,
    String? reason,
    DateTime? expiresAt,
  });
}

class DriverDocumentsRepositoryImpl implements DriverDocumentsRepository {
  DriverDocumentsRepositoryImpl(this._db, this._fn, [FirebaseStorage? storage]) : _storageOverride = storage;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;
  final FirebaseStorage? _storageOverride;

  // Resolved lazily so apps without Storage configured still start.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _col(String driverId) =>
      _db.collection('driverProfiles').doc(driverId).collection('verificationDocs');

  @override
  Stream<Map<DriverDocType, DriverDocument>> watch(String driverId) => _col(driverId).snapshots().map((s) => {
        for (final d in s.docs)
          if (DriverDocType.fromName(d.id) case final t?) t: DriverDocument.fromJson(t, d.data()),
      });

  @override
  Future<String?> upload({
    required String driverId,
    required DriverDocType type,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    DateTime? expiresAt,
  }) async {
    if (bytes.length >= DriverDocumentsRepository.maxBytes) return DriverDocErrorCodes.tooLarge;
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'bin';
      // A new file per upload keeps the previous one until it is reviewed.
      final path = 'driver_documents/$driverId/${type.name}-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _storage.ref(path).putData(bytes, SettableMetadata(contentType: contentType));
      await _col(driverId).doc(type.name).set({
        'type': type.name,
        'status': 'pending',
        'storagePath': path,
        'fileName': fileName,
        'contentType': contentType,
        'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return DriverDocErrorCodes.failed;
    }
  }

  @override
  Future<String?> downloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> review({
    required String driverId,
    required DriverDocType type,
    required bool approve,
    String? reason,
    DateTime? expiresAt,
  }) async {
    try {
      await _fn.httpsCallable('reviewDriverDocument').call({
        'driverId': driverId,
        'type': type.name,
        'approve': approve,
        if (reason != null) 'reason': reason,
        if (expiresAt != null) 'expiresAt': expiresAt.millisecondsSinceEpoch,
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      return DriverDocErrorCodes.fromMessage(e.message);
    } catch (_) {
      return DriverDocErrorCodes.failed;
    }
  }
}
