import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return const Left(NotFoundFailure('User not found'));
      return Right(User.fromJson({'id': doc.id, ...doc.data()!}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(User user) async {
    try {
      await _users.doc(user.id).update(user.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _users.doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverProfile>> getDriverProfile(
    String userId,
  ) async {
    try {
      final doc = await _db.collection('driverProfiles').doc(userId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Profile not found'));
      return Right(DriverProfile.fromJson(doc.data()!));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDriverProfile(
    DriverProfile profile,
  ) async {
    try {
      await _db
          .collection('driverProfiles')
          .doc(profile.userId)
          .set(profile.toJson(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDriverLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.collection('driverProfiles').doc(userId).update({
        'currentLocation': GeoPoint(latitude, longitude),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setDriverAvailability({
    required String userId,
    required bool isAvailable,
  }) async {
    try {
      await _db.collection('driverProfiles').doc(userId).update({
        'isAvailable': isAvailable,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<DriverProfile?> watchDriverProfile(String driverId) => _db
      .collection('driverProfiles')
      .doc(driverId)
      .snapshots()
      .map((s) => s.exists ? DriverProfile.fromJson(s.data()!) : null);
}
