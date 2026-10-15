import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _fn => _functionsOverride ?? FirebaseFunctions.instance;

  /// Convierte documentos en reservas saltando los mal formados: una reserva
  /// corrupta no debe dejar sin lista al chófer ni al pasajero.
  static List<Booking> _parse(
      Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final out = <Booking>[];
    for (final d in docs) {
      try {
        out.add(Booking.fromJson({...d.data(), 'id': d.id}));
      } catch (e) {
        debugPrint('[Bookings] documento ${d.id} ignorado: $e');
      }
    }
    return out;
  }

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
    } on FirebaseException catch (e) {
      debugPrint('[Bookings] crear: ${e.code} ${e.message}');
      return Left(ServerFailure(e.code == 'permission-denied'
          ? 'No pudimos crear tu reserva: revisa la hora de recogida o si '
              'las reservas están en pausa.'
          : 'No pudimos crear tu reserva. Revisa tu conexión e inténtalo de '
              'nuevo.'));
    } catch (e) {
      debugPrint('[Bookings] crear: $e');
      return const Left(
          ServerFailure('No pudimos crear tu reserva. Inténtalo de nuevo.'));
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
      final list = _parse(snap.docs);

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
      final bookings = _parse(snap.docs);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Booking>> streamPendingBookings() => _col
          // Filtrado en la consulta: las reglas solo dejan leer pendientes al
          // chófer, y Firestore rechaza una consulta que pida más.
          .where('status', isEqualTo: BookingStatus.pending.label)
          .snapshots()
          .map((snap) {
        final list = _parse(snap.docs);
        list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return list;
      });

  @override
  Stream<List<Booking>> watchRiderBookings(String riderId) =>
      _col.where('riderId', isEqualTo: riderId).snapshots().map((snap) {
        final list = _parse(snap.docs);
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  @override
  Stream<List<Booking>> watchDriverBookings(String driverId) =>
      _col.where('driverId', isEqualTo: driverId).snapshots().map((snap) {
        final list = _parse(snap.docs);
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
          throw Exception(
              'Booking is no longer pending. It may have been accepted by another driver.');
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
        'cancelledBy': 'rider',
        'updatedAt': Timestamp.now(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code == 'permission-denied'
          ? 'Esta reserva ya no se puede cancelar: el viaje ya empezó o terminó.'
          : 'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.'));
    } catch (_) {
      return const Left(ServerFailure(
          'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, AcceptOutcome>> acceptBooking(String bookingId) async {
    try {
      final res = await _fn
          .httpsCallable('acceptBooking')
          .call<dynamic>({'bookingId': bookingId});
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['accepted'] == true) return const Right(AcceptOutcome.accepted);
      return Right(switch (data['reason']) {
        'driver_busy' => AcceptOutcome.driverBusy,
        'not_verified' => AcceptOutcome.notVerified,
        'not_allowed' => AcceptOutcome.notAllowed,
        'wrong_class' => AcceptOutcome.wrongClass,
        _ => AcceptOutcome.alreadyTaken,
      });
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.code == 'not-found'
          ? 'Esta solicitud ya no existe.'
          : 'No se pudo aceptar el viaje. Revisa tu conexión.'));
    } catch (_) {
      return const Left(
          ServerFailure('No se pudo aceptar el viaje. Revisa tu conexión.'));
    }
  }

  @override
  Future<Either<Failure, void>> rateBooking(
      String bookingId, int rating) async {
    if (rating < 1 || rating > 5) {
      return const Left(ValidationFailure('Elige de 1 a 5 estrellas.'));
    }
    try {
      await _col.doc(bookingId).update({
        'riderRating': rating,
        'ratedAt': Timestamp.now(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code == 'permission-denied'
          ? 'Este viaje ya fue valorado.'
          : 'No se pudo enviar tu valoración. Inténtalo de nuevo.'));
    } catch (_) {
      return const Left(ServerFailure(
          'No se pudo enviar tu valoración. Inténtalo de nuevo.'));
    }
  }

  @override
  Stream<Booking> watchBooking(String bookingId) => _col
      .doc(bookingId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => Booking.fromJson({...s.data()!, 'id': s.id}));
}
