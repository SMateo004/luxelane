import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../domain/booking_error_codes.dart';

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
    int? days,
    String? promoCode,
  }) async {
    try {
      final result = await _fn.httpsCallable('quoteBooking').call({
        if (promoCode != null) 'promoCode': promoCode,
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'origin': _placeArg(origin),
        if (destination != null) 'destination': _placeArg(destination),
        if (routeDistanceKm != null && routeDistanceKm > 0)
          'routeDistanceKm': routeDistanceKm,
        if (hours != null) 'hours': hours,
        if (days != null && days > 1) 'days': days,
      });
      return Right(
          Quote.fromJson(Map<String, dynamic>.from(result.data as Map)));
    } on FirebaseFunctionsException catch (e) {
      // Server messages are technical English; the UI shows a translated one.
      final message = e.message ?? '';
      return Left(ServerFailure(message.contains('account/suspended')
          ? BookingErrorCodes.accountSuspended
          : message.contains('app/maintenance')
              ? BookingErrorCodes.maintenance
              : BookingErrorCodes.quoteFailed));
    } catch (_) {
      return const Left(ServerFailure(BookingErrorCodes.quoteFailed));
    }
  }

  @override
  Future<({double discount, String? error})> checkPromoCode({
    required String code,
    required double fare,
    required VehicleClass vehicleClass,
  }) async {
    try {
      final r = Map<String, dynamic>.from((await _fn.httpsCallable('checkPromoCode').call({
        'code': code,
        'fare': fare,
        'vehicleClass': vehicleClass.name,
      }))
          .data as Map);
      if (r['ok'] == true) return (discount: (r['discount'] as num).toDouble(), error: null);
      return (discount: 0.0, error: r['error'] as String? ?? PromoErrorCodes.invalid);
    } catch (_) {
      return (discount: 0.0, error: PromoErrorCodes.failed);
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
  Future<Either<Failure, Booking>> createBooking(Booking booking,
      {String? paymentMethodId}) async {
    if (booking.quoteId == null) {
      return const Left(ServerFailure(BookingErrorCodes.quoteMissing));
    }
    try {
      // The chauffeur can't read other users' profiles, so the rider's ride
      // style travels with the booking. If it can't be read, book anyway.
      RidePreferences? prefs;
      try {
        final profile =
            await _db.collection('users').doc(booking.riderId).get();
        prefs = RidePreferences.fromJson(profile.data()?['ridePreferences']);
      } catch (_) {}
      final result = await _fn.httpsCallable('createBooking').call({
        'quoteId': booking.quoteId,
        'scheduledAt': booking.scheduledAt.millisecondsSinceEpoch,
        if (booking.stripePaymentIntentId != null)
          'paymentIntentId': booking.stripePaymentIntentId,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (booking.notes != null) 'notes': booking.notes,
        if (booking.flightNumber != null) 'flightNumber': booking.flightNumber,
        if (booking.flightType != null) 'flightType': booking.flightType,
        if (booking.pickupAirport != null) 'pickupAirport': booking.pickupAirport,
        'passengerCount': booking.passengerCount,
        'luggageCount': booking.luggageCount,
        if (booking.passengerName != null) 'passengerName': booking.passengerName,
        if (booking.passengerPhone != null) 'passengerPhone': booking.passengerPhone,
        if (prefs != null && !prefs.isEmpty) 'riderPreferences': prefs.toJson(),
        if (booking.companyId != null)
          'billing': {
            'type': 'corporate',
            if (booking.costCenter != null) 'costCenter': booking.costCenter,
            if (booking.billingReference != null) 'reference': booking.billingReference,
          },
      });
      final id = (result.data as Map)['bookingId'] as String;
      final doc = await _col.doc(id).get();
      return Right(Booking.fromJson({'id': doc.id, ...doc.data()!}));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(_createErrorCode(e.message ?? '')));
    } catch (_) {
      return const Left(ServerFailure(BookingErrorCodes.createFailed));
    }
  }

  /// Maps createBooking's server errors (functions/src/index.ts) to codes.
  static String _createErrorCode(String message) {
    if (message.contains('account/suspended')) return BookingErrorCodes.accountSuspended;
    if (message.contains('app/maintenance')) return BookingErrorCodes.maintenance;
    if (message.contains('quote/expired')) return BookingErrorCodes.quoteExpired;
    if (message.contains('payment/not-authorised')) return BookingErrorCodes.paymentNotAuthorised;
    if (message.contains('invalid flightNumber')) return BookingErrorCodes.invalidFlight;
    if (message.contains('invalid passengerCount')) return BookingErrorCodes.tooManyPassengers;
    if (message.contains('billing/cost-center-required')) return BookingErrorCodes.costCenterRequired;
    if (message.contains('billing/company-inactive')) return BookingErrorCodes.companyInactive;
    if (message.contains('billing/')) return BookingErrorCodes.corporateNotAllowed;
    if (message.contains('promo/')) return BookingErrorCodes.promoNoLongerValid;
    return BookingErrorCodes.createFailed;
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
  Stream<List<Booking>> watchBookingsByRider(String riderId) => _col
      .where('riderId', isEqualTo: riderId)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

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
    // Server-side so the chauffeur is released and notified, and late
    // cancellations (< 1 h before pickup) are recorded.
    try {
      await _fn.httpsCallable('cancelBooking').call({'bookingId': bookingId});
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      final notCancellable = e.message?.contains('not-cancellable') ?? false;
      return Left(ServerFailure(
          notCancellable ? BookingErrorCodes.notCancellable : BookingErrorCodes.cancelFailed));
    } catch (_) {
      return const Left(ServerFailure(BookingErrorCodes.cancelFailed));
    }
  }

  @override
  Stream<LiveLocation?> watchLiveLocation(String bookingId) => _col
      .doc(bookingId)
      .collection('tracking')
      .doc('live')
      .snapshots()
      .map((s) => s.exists && s.data() != null ? LiveLocation.fromJson(s.data()!) : null);

  @override
  Future<Either<Failure, void>> updateLiveLocation({
    required String bookingId,
    required double lat,
    required double lng,
    double heading = 0,
    double speed = 0,
  }) async {
    try {
      await _col.doc(bookingId).collection('tracking').doc('live').set({
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        'updatedAt': FieldValue.serverTimestamp(),
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
  Future<Either<Failure, void>> declineOffer(String bookingId) async {
    try {
      await _fn.httpsCallable('declineOffer').call({'bookingId': bookingId});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rateBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _fn.httpsCallable('rateBooking').call({
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure(BookingErrorCodes.rateFailed));
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
