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
      return Left(ServerFailure((e.message ?? '').contains('account/suspended')
          ? BookingErrorCodes.accountSuspended
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
  Future<Either<Failure, Booking>> createBooking(Booking booking) async {
    if (booking.quoteId == null) {
      return const Left(ServerFailure(BookingErrorCodes.quoteMissing));
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
        if (booking.passengerName != null) 'passengerName': booking.passengerName,
        if (booking.passengerPhone != null) 'passengerPhone': booking.passengerPhone,
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
