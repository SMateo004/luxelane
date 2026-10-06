import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _fn = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  @override
  Future<Either<Failure, Quote>> requestQuote({
    required VehicleClass vehicleClass,
    required ServiceType serviceType,
    required Place origin,
    Place? destination,
    double? routeDistanceKm,
    int? hours,
  }) async {
    try {
      final result = await _fn.httpsCallable('quoteBooking').call({
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'origin': _placeArg(origin),
        if (destination != null) 'destination': _placeArg(destination),
        if (routeDistanceKm != null && routeDistanceKm > 0)
          'routeDistanceKm': routeDistanceKm,
        if (hours != null) 'hours': hours,
      });
      return Right(
          Quote.fromJson(Map<String, dynamic>.from(result.data as Map)));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'No se pudo cotizar el viaje'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Callable payloads must be plain JSON (no GeoPoint).
  static Map<String, dynamic> _placeArg(Place p) => {
        'name': p.name,
        'address': p.address,
        'lat': p.lat,
        'lng': p.lng,
      };

  @override
  Future<Either<Failure, Booking>> createBooking(Booking booking) async {
    if (booking.quoteId == null) {
      return const Left(ServerFailure('Falta la cotización del viaje'));
    }
    try {
      final result = await _fn.httpsCallable('createBooking').call({
        'quoteId': booking.quoteId,
        'scheduledAt': booking.scheduledAt.millisecondsSinceEpoch,
        if (booking.stripePaymentIntentId != null)
          'paymentIntentId': booking.stripePaymentIntentId,
        if (booking.notes != null) 'notes': booking.notes,
        if (booking.flightNumber != null) 'flightNumber': booking.flightNumber,
        'passengerCount': booking.passengerCount,
        'luggageCount': booking.luggageCount,
      });
      final id = (result.data as Map)['bookingId'] as String;
      final doc = await _col.doc(id).get();
      return Right(Booking.fromJson({'id': doc.id, ...doc.data()!}));
    } on FirebaseFunctionsException catch (e) {
      final expired = e.message?.contains('quote/expired') ?? false;
      return Left(ServerFailure(expired
          ? 'La cotización venció. Vuelve a confirmar para ver el precio actualizado.'
          : e.message ?? 'No se pudo crear la reserva'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBookingById(String bookingId) async {
    try {
      final doc = await _col.doc(bookingId).get();
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(Booking.fromJson({'id': doc.id, ...doc.data()!}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsByRider(
    String riderId,
  ) async {
    try {
      final snap = await _col
          .where('riderId', isEqualTo: riderId)
          .get();
      final list = snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .toList();

      // Manual sort to avoid index requirement
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getPendingBookings() async {
    try {
      final snap = await _col
          .where('status', isEqualTo: BookingStatus.pending.label)
          .orderBy('scheduledAt')
          .get();
      final bookings = snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .toList();
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Booking>> streamPendingBookings() => _col
      // The status filter is required: security rules only let drivers read
      // pending bookings, so an unfiltered query is rejected.
      .where('status', isEqualTo: BookingStatus.pending.label)
      .snapshots()
      .map((snap) {
        final list = snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .toList();
        // Manual sort to avoid needing a composite index
        list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return list;
      });

  @override
  Stream<List<Booking>> watchDriverBookings(String driverId) => _col
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .map((snap) {
        final list = snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .toList();
        // Manual sort by updatedAt descending
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      });

  @override
  Future<Either<Failure, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    try {
      await _col.doc(bookingId).update({
        'status': status.label,
        'updatedAt': Timestamp.now(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignDriver({
    required String bookingId,
    required String driverId,
  }) async {
    try {
      final docRef = _col.doc(bookingId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Booking does not exist');
        }
        final currentStatus = snapshot.get('status') as String?;
        if (currentStatus != BookingStatus.pending.label) {
          throw Exception('Booking is no longer pending. It may have been accepted by another driver.');
        }
        transaction.update(docRef, {
          'driverId': driverId,
          'status': BookingStatus.confirmed.label,
          'updatedAt': Timestamp.now(),
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String bookingId) async {
    try {
      await _col.doc(bookingId).update({
        'status': BookingStatus.cancelled.label,
        'updatedAt': Timestamp.now(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Booking> watchBooking(String bookingId) => _col
      .doc(bookingId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => Booking.fromJson({'id': s.id, ...s.data()!}));
}
