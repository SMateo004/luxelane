import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('vehicles');

  @override
  Future<Either<Failure, Vehicle>> getVehicleById(String vehicleId) async {
    try {
      final doc = await _col.doc(vehicleId).get();
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(Vehicle.fromJson({'id': doc.id, ...doc.data()!}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vehicle>> getVehicleByDriver(String driverId) async {
    try {
      final snap = await _col
          .where('driverId', isEqualTo: driverId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Left(NotFoundFailure());
      final d = snap.docs.first;
      return Right(Vehicle.fromJson({'id': d.id, ...d.data()}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getAvailableVehicles(
    VehicleClass vehicleClass,
  ) async {
    try {
      final snap = await _col
          .where('vehicleClass', isEqualTo: vehicleClass.name)
          .where('isAvailable', isEqualTo: true)
          .get();
      return Right(
        snap.docs
            .map((d) => Vehicle.fromJson({'id': d.id, ...d.data()}))
            .toList(),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createVehicle(Vehicle vehicle) async {
    try {
      await _col.doc(vehicle.id).set(vehicle.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicle(Vehicle vehicle) async {
    try {
      await _col.doc(vehicle.id).update(vehicle.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
