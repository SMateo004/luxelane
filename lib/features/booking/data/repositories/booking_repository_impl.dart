import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  @override
  Future<Either<Failure, Booking>> createBooking(Booking booking) async {
    try {
      final id = _uuid.v4();
      final data = booking.toJson()..['id'] = id;
      await _col.doc(id).set(data);
      return Right(Booking.fromJson(data));
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
      .snapshots()
      .map((snap) {
        final list = snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .where((b) => b.status == BookingStatus.pending)
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
