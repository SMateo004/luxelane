import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Booking>> watchAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Booking.fromJson(data);
            }).toList());
  }

  @override
  Stream<List<User>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return User.fromJson(data);
        }).toList());
  }

  @override
  Stream<List<DriverProfile>> watchAllDrivers() {
    return _db.collection('driverProfiles').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['userId'] = doc.id; // Corrected field mapping for DriverProfile
          return DriverProfile.fromJson(data);
        }).toList());
  }

  @override
  Stream<List<PricingRule>> watchPricingRules() {
    return _db.collection('pricingRules').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return PricingRule.fromJson(data);
        }).toList());
  }

  @override
  Stream<List<Vehicle>> watchAllVehicles() {
    return _db.collection('vehicles').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Vehicle.fromJson(data);
        }).toList());
  }

  @override
  Stream<List<AuditLog>> watchAuditLogs() {
    return _db
        .collection('admin_logs')
        .orderBy('createdAt', descending: true)
        .limit(250)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return AuditLog.fromJson(data);
            }).toList());
  }

  @override
  Stream<Map<String, dynamic>> watchGlobalSettings() {
    return _db
        .collection('config')
        .doc('global')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> _logAction(String action, String targetId, String targetType,
      {String details = ''}) async {
    final ref = _db.collection('admin_logs').doc();
    await ref.set({
      'adminId': 'admin_main', // In a real app, get from AuthState
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Either<Failure, void>> updatePricingRule(PricingRule rule) async {
    try {
      await _db.collection('pricingRules').doc(rule.id).set(rule.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyDriver(String driverId) async {
    try {
      await _db
          .collection('driverProfiles')
          .doc(driverId)
          .update({'documentsVerified': true});
      await _logAction('verify_driver', driverId, 'driver');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active) async {
    try {
      await _db.collection('users').doc(userId).update({'isActive': active});
      await _logAction(active ? 'unblock_user' : 'block_user', userId, 'user');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleVehicleStatus(String vehicleId, bool active) async {
    try {
      await _db.collection('vehicles').doc(vehicleId).update({'isActive': active});
      await _logAction(active ? 'enable_vehicle' : 'disable_vehicle', vehicleId, 'vehicle');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMaintenanceMode(bool active) async {
    try {
      await _db.collection('config').doc('global').set({
        'isMaintenanceMode': active,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAction(active ? 'enable_maintenance' : 'disable_maintenance', 'app', 'global_config');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGlobalSettings(Map<String, dynamic> fields) async {
    try {
      await _db.collection('config').doc('global').set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logAction('update_settings', 'global', 'global_config', details: fields.keys.join(', '));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBooking(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).delete();
      await _logAction('delete_booking', bookingId, 'booking');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role) async {
    try {
      await _db.collection('users').doc(userId).update({'role': role.name});
      await _logAction('update_role', userId, 'user', details: 'role → ${role.name}');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

