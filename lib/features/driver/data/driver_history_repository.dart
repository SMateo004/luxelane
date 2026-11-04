import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/driver_trip.dart';

/// Historial del chófer (ventana del chófer, decisión 2): los resúmenes que
/// escribe el servidor en driverHistory/{uid}/trips. El chófer ya no lee
/// las reservas terminadas.
abstract class DriverHistoryRepository {
  /// El resumen de un viaje, o null si no existe (todavía, o porque el
  /// viaje no se cerró a su cargo).
  Future<DriverTripSummary?> getTrip(String driverId, String bookingId);
}

class FirestoreDriverHistoryRepository implements DriverHistoryRepository {
  FirestoreDriverHistoryRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _trips(String driverId) =>
      _db.collection('driverHistory').doc(driverId).collection('trips');

  @override
  Future<DriverTripSummary?> getTrip(String driverId, String bookingId) async {
    final snap = await _trips(driverId).doc(bookingId).get();
    final data = snap.data();
    return data == null ? null : DriverTripSummary.fromMap(snap.id, data);
  }
}
