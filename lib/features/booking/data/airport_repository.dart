import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/models.dart';

/// airports/{código}: nombre y puntos de recogida (los lee quien tiene
/// sesión; los escribe solo el servidor). Sustituible en pruebas.
abstract class AirportRepository {
  Stream<Airport?> watch(String code);
}

class FirestoreAirportRepository implements AirportRepository {
  FirestoreAirportRepository([FirebaseFirestore? db]) : _db = db;
  final FirebaseFirestore? _db;

  @override
  Stream<Airport?> watch(String code) => (_db ?? FirebaseFirestore.instance)
      .collection('airports')
      .doc(code)
      .snapshots()
      .map((s) => s.exists ? Airport.fromMap(s.id, s.data()) : null)
      // Sin permiso o sin red: como si no hubiera punto (por confirmar).
      .handleError((_) {});
}
