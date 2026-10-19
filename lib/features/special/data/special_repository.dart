import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/failures.dart';
import '../domain/special_models.dart';

/// Solicitudes de servicios especiales. Las reglas de Firestore validan
/// cada escritura; los avisos los envía el servidor.
class SpecialRepository {
  SpecialRepository({required FirebaseFirestore firestore}) : _db = firestore;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('specialRequests');

  static List<SpecialRequest> _parse(QuerySnapshot<Map<String, dynamic>> s) {
    final out = <SpecialRequest>[];
    for (final d in s.docs) {
      try {
        out.add(SpecialRequest.fromDoc(d.id, d.data()));
      } catch (e) {
        debugPrint('[Especiales] ${d.id} ignorado: $e');
      }
    }
    out.sort(
        (a, b) => (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
    return out;
  }

  Stream<List<SpecialRequest>> watchMine(String uid) =>
      _col.where('riderId', isEqualTo: uid).snapshots().map(_parse);

  Stream<List<SpecialRequest>> watchAll() => _col.snapshots().map(_parse);

  Future<Either<Failure, void>> _run(
      Future<void> Function() f, String error) async {
    try {
      await f();
      return const Right(null);
    } catch (e) {
      debugPrint('[Especiales] $e');
      return Left(ServerFailure(error));
    }
  }

  Future<Either<Failure, void>> create(Map<String, dynamic> data) => _run(
      () => _col.add(data),
      'No pudimos enviar tu solicitud. Revisa los datos e inténtalo de nuevo.');

  Future<Either<Failure, void>> _setStatus(String id, SpecialStatus s,
          [Map<String, dynamic> extra = const {}]) =>
      _run(
          () => _col.doc(id).update({
                'status': s.value,
                'updatedAt': FieldValue.serverTimestamp(),
                ...extra,
              }),
          'No se pudo actualizar la solicitud. Inténtalo de nuevo.');

  Future<Either<Failure, void>> cancel(String id) =>
      _setStatus(id, SpecialStatus.cancelled);

  Future<Either<Failure, void>> acceptQuote(String id) =>
      _setStatus(id, SpecialStatus.confirmed);

  // ── Administración ────────────────────────────────────────────────────────

  Future<Either<Failure, void>> quote(
          String id, double amountBs, String note) =>
      _setStatus(id, SpecialStatus.quoted, {
        'quoteBs': amountBs,
        'adminNote': note.trim(),
        'quotedAt': FieldValue.serverTimestamp(),
      });

  Future<Either<Failure, void>> decline(String id, String note) =>
      _setStatus(id, SpecialStatus.declined, {'adminNote': note.trim()});

  Future<Either<Failure, void>> complete(String id) =>
      _setStatus(id, SpecialStatus.completed);
}
