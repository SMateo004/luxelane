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
      final snap = await _col.where('riderId', isEqualTo: riderId).get();
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
  // El filtro por estado es obligatorio: las reglas solo dejan a un chófer
  // leer reservas pendientes, y Firestore rechaza una consulta que no lo
  // garantice.
  Stream<List<Booking>> streamPendingBookings() => _col
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
  Stream<List<Booking>> watchDriverBookings(String driverId) =>
      _col.where('driverId', isEqualTo: driverId).snapshots().map((snap) {
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
  Future<Either<Failure, void>> rateBooking({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    try {
      await _col.doc(bookingId).update({
        'riderRating': rating.clamp(1, 5),
        if (comment.trim().isNotEmpty) 'riderComment': comment.trim(),
        'updatedAt': Timestamp.now(),
      });
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure(
          'No se pudo guardar tu valoración. Inténtalo de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, void>> assignDriver({
    required String bookingId,
    required String driverId,
  }) async {
    try {
      final docRef = _col.doc(bookingId);
      final driverRef = _db.collection('driverProfiles').doc(driverId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final driver = await transaction.get(driverRef);
        if (!snapshot.exists) {
          throw const _AcceptError('Esta reserva ya no existe.');
        }
        final currentStatus = snapshot.get('status') as String?;
        if (currentStatus != BookingStatus.pending.label) {
          throw const _AcceptError('Otro chófer ya aceptó este viaje.');
        }
        if (driver.data()?['documentsVerified'] != true) {
          throw const _AcceptError(
              'Tus documentos aún no están verificados por Luxelane.');
        }
        if (driver.data()?['isAvailable'] != true) {
          throw const _AcceptError(
              'Conéctate y termina tu viaje actual antes de aceptar otro.');
        }
        transaction.update(docRef, {
          'driverId': driverId,
          'status': BookingStatus.confirmed.label,
          'updatedAt': Timestamp.now(),
        });
        // Ocupado ya solo si la recogida es próxima; si es para más
        // adelante, al salir hacia el pasajero.
        final at = (snapshot.data()?['scheduledAt'] as Timestamp?)?.toDate();
        if (at == null || at.isBefore(DateTime.now().add(kBusyLead))) {
          transaction.update(driverRef, {'isAvailable': false});
        }
      });
      return const Right(null);
    } on _AcceptError catch (e) {
      return Left(ValidationFailure(e.message));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code == 'permission-denied'
          ? 'No se pudo aceptar: tu cuenta de chófer no está habilitada.'
          : 'No se pudo aceptar el viaje. Revisa tu conexión.'));
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
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code == 'permission-denied'
          ? 'Esta reserva ya no se puede cancelar: el viaje está en curso o '
              'terminó.'
          : 'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.'));
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

class _AcceptError implements Exception {
  const _AcceptError(this.message);
  final String message;
}
