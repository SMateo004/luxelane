import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class RideRepositoryImpl implements RideRepository {
  RideRepositoryImpl({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('rides');

  @override
  Future<Either<Failure, Ride>> createRide(Ride ride) async {
    try {
      final id = _uuid.v4();
      final data = ride.toJson()..['id'] = id;
      await _col.doc(id).set(data);
      return Right(Ride.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> getRideById(String rideId) async {
    try {
      final doc = await _col.doc(rideId).get();
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(Ride.fromJson({'id': doc.id, ...doc.data()!}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> getRideByBooking(String bookingId) async {
    try {
      final snap = await _col
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Left(NotFoundFailure());
      final d = snap.docs.first;
      return Right(Ride.fromJson({'id': d.id, ...d.data()}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ride>>> getRidesByRider(String riderId) async {
    try {
      final snap = await _col
          .where('riderId', isEqualTo: riderId)
          .orderBy('startedAt', descending: true)
          .get();
      return Right(snap.docs
          .map((d) => Ride.fromJson({'id': d.id, ...d.data()}))
          .toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ride>>> getRidesByDriver(String driverId) async {
    try {
      final snap = await _col
          .where('driverId', isEqualTo: driverId)
          .orderBy('startedAt', descending: true)
          .get();
      return Right(snap.docs
          .map((d) => Ride.fromJson({'id': d.id, ...d.data()}))
          .toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> appendRoutePoint({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _col.doc(rideId).update({
        'driverRoute': FieldValue.arrayUnion([GeoPoint(latitude, longitude)]),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeRide({
    required String rideId,
    required double distanceKm,
    required int durationMin,
  }) async {
    try {
      await _col.doc(rideId).update({
        'completedAt': Timestamp.now(),
        'distanceKm': distanceKm,
        'durationMin': durationMin,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitRating({
    required String rideId,
    required double rating,
    required bool isRiderRating,
  }) async {
    try {
      await _col.doc(rideId).update({
        isRiderRating ? 'riderRating' : 'driverRating': rating,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Ride> watchRide(String rideId) => _col
      .doc(rideId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => Ride.fromJson({'id': s.id, ...s.data()!}));
}
