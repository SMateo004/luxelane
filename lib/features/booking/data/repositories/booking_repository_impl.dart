import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
    Future<String?> Function()? appVersion,
  }) : _db = firestore,
       _functionsOverride = functions,
       _appVersion = appVersion ?? _installedVersion;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;

  /// Versión instalada (x.y.z) que el servidor compara con minAppVersion.
  final Future<String?> Function() _appVersion;

  static Future<String?> _installedVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return null;
    }
  }

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  @override
  Future<Either<Failure, Booking>> createBooking(
    Booking booking, {
    double? quotedPrice,
    required String requestId,
  }) async {
    try {
      final res = await _functions
          .httpsCallable('createBooking')
          .call<Map<String, dynamic>>(
            bookingRequestData(
              booking,
              quotedPrice: quotedPrice,
              requestId: requestId,
              appVersion: await _appVersion(),
            ),
          );
      final id = res.data['bookingId'] as String;
      return getBookingById(id);
    } on FirebaseFunctionsException catch (e) {
      return Left(bookingFailureFor(e.code, e.details));
    } catch (_) {
      return const Left(ServerFailure(_kConnectionError));
    }
  }

  @override
  Future<Either<Failure, BookingQuote>> quoteBooking(Booking trip) async {
    try {
      final res = await _functions
          .httpsCallable('quoteBooking')
          .call<Map<String, dynamic>>(
            bookingRequestData(
              trip,
              quote: true,
              appVersion: await _appVersion(),
            ),
          );
      return Right(BookingQuote.fromJson(res.data));
    } on FirebaseFunctionsException catch (e) {
      return Left(bookingFailureFor(e.code, e.details));
    } catch (_) {
      return const Left(ServerFailure(_kConnectionError));
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
  Stream<List<Booking>> watchBookingsByRider(String riderId) => _col
      .where('riderId', isEqualTo: riderId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs
                .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<Either<Failure, List<Booking>>> getBookingsByRider(
    String riderId,
  ) async {
    try {
      final snap = await _col.where('riderId', isEqualTo: riderId).get();
      final list =
          snap.docs
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
  // El chófer no lee reservas ajenas: las pendientes le llegan por
  // openRequests, que el servidor escribe sin datos personales.
  Stream<List<OpenRequest>> streamOpenRequests() =>
      _db.collection('openRequests').snapshots().map((snap) {
        final list =
            snap.docs.map((d) => OpenRequest.fromJson(d.id, d.data())).toList();
        list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return list;
      });

  @override
  Stream<List<Booking>> watchDriverBookings(String driverId) =>
      _col.where('driverId', isEqualTo: driverId).snapshots().map((snap) {
        final list =
            snap.docs
                .map((d) => Booking.fromJson({'id': d.id, ...d.data()}))
                .toList();
        // Manual sort by updatedAt descending
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      });

  @override
  Stream<GeoPoint?> watchDriverLocation(String bookingId) => _col
      .doc(bookingId)
      .collection('tracking')
      .doc('driver')
      .snapshots()
      .map((s) {
        final d = s.data();
        final lat = d?['lat'], lng = d?['lng'];
        return lat is num && lng is num
            ? GeoPoint(lat.toDouble(), lng.toDouble())
            : null;
      });

  @override
  Stream<String?> watchDriverPhone(String bookingId) => _col
      .doc(bookingId)
      .collection('driverContact')
      .doc('phone')
      .snapshots()
      .map((s) => s.data()?['phone'] as String?);

  @override
  Future<void> publishDriverLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) => _col.doc(bookingId).collection('tracking').doc('driver').set({
    'lat': latitude,
    'lng': longitude,
    'updatedAt': FieldValue.serverTimestamp(),
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
      return const Left(
        ServerFailure('No se pudo guardar tu valoración. Inténtalo de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> assignDriver({
    required String bookingId,
    required String driverId,
  }) async {
    try {
      final docRef = _col.doc(bookingId);
      // Antes de aceptar el chófer no puede leer la reserva: la solicitud
      // abierta existe mientras siga pendiente, y las reglas comprueban de
      // nuevo que lo esté al escribir.
      final requestRef = _db.collection('openRequests').doc(bookingId);
      final driverRef = _db.collection('driverProfiles').doc(driverId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        final driver = await transaction.get(driverRef);
        if (!snapshot.exists) {
          throw const _AcceptError('Otro chófer ya aceptó este viaje.');
        }
        if (driver.data()?['documentsVerified'] != true) {
          throw const _AcceptError(
            'Tus documentos aún no están verificados por Luxelane.',
          );
        }
        if (driver.data()?['isAvailable'] != true) {
          throw const _AcceptError(
            'Conéctate y termina tu viaje actual antes de aceptar otro.',
          );
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
      // Verificación y disponibilidad ya se comprobaron: un rechazo aquí es
      // casi siempre que otro chófer la tomó antes.
      return Left(
        ServerFailure(
          e.code == 'permission-denied'
              ? 'Este viaje ya no está disponible.'
              : 'No se pudo aceptar el viaje. Revisa tu conexión.',
        ),
      );
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
      return Left(
        ServerFailure(
          e.code == 'permission-denied'
              ? 'Esta reserva ya no se puede cancelar: el viaje está en curso o '
                  'terminó.'
              : 'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.',
        ),
      );
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

const _kConnectionError =
    'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.';

/// Solo los datos del viaje que aceptan quoteBooking y createBooking: el
/// precio, el estado y la zona los pone el servidor.
Map<String, dynamic> bookingRequestData(
  Booking b, {
  double? quotedPrice,
  String? requestId,
  String? appVersion,
  bool quote = false,
}) {
  Map<String, dynamic> place(Place p) => {
    'name': p.name,
    'address': p.address,
    'lat': p.lat,
    'lng': p.lng,
  };
  final hourly = b.serviceType == ServiceType.byTheHour;
  return {
    'origin': place(b.origin),
    // Por horas sin destino fijo, el servidor usa la recogida.
    if (!hourly) 'destination': place(b.destination),
    'scheduledAt': b.scheduledAt.millisecondsSinceEpoch,
    'vehicleClass': b.vehicleClass.name,
    'serviceType': b.serviceType.name,
    if (hourly) 'hours': b.hours ?? 2,
    if (appVersion != null) 'appVersion': appVersion,
    if (!quote) ...{
      'passengerCount': b.passengerCount,
      'luggageCount': b.luggageCount,
      if (b.flightNumber?.isNotEmpty == true) 'flightNumber': b.flightNumber,
      if (b.flightType != null) 'flightType': b.flightType,
      if (b.notes?.trim().isNotEmpty == true) 'notes': b.notes!.trim(),
      if (b.guest != null) 'guest': b.guest!.toJson()..remove('email'),
      if (quotedPrice != null) 'quotedPrice': quotedPrice,
      if (requestId != null) 'requestId': requestId,
    },
  };
}

/// Error del servidor (details.reason) convertido en un mensaje para el
/// pasajero, sin texto técnico.
Failure bookingFailureFor(String code, Object? details) {
  final d = details is Map ? details : const {};
  final reason = d['reason'] as String?;
  if (reason == 'price_changed' && d['price'] is num) {
    return PriceChangedFailure((d['price'] as num).toDouble());
  }
  if (reason == 'app_update_required') {
    return AppUpdateRequiredFailure(
      androidStoreUrl: d['androidStoreUrl'] as String?,
      iosStoreUrl: d['iosStoreUrl'] as String?,
    );
  }
  return ServerFailure(switch (reason) {
    'pricing_unavailable' =>
      'No pudimos calcular el precio de este viaje '
          'ahora. Inténtalo de nuevo en unos minutos.',
    'out_of_area' =>
      'Por ahora solo hacemos viajes dentro de la misma '
          'ciudad de la recogida.',
    'class_unavailable' =>
      'Esta clase de vehículo no está disponible en '
          'este momento. Elige otra.',
    'service_unavailable' =>
      'Las reservas están en pausa por '
          'mantenimiento. Vuelve a intentarlo en unos minutos.',
    'invalid_hours' => 'Elige un número entero de horas.',
    'past_pickup' => 'La hora de recogida ya pasó. Elige una nueva hora.',
    'inactive_user' => 'Tu cuenta no puede hacer reservas en este momento.',
    'unauthenticated' => 'Inicia sesión para reservar.',
    _ =>
      code == 'unavailable' || code == 'deadline-exceeded'
          ? _kConnectionError
          : 'No pudimos procesar tu reserva. Revisa los datos del viaje e '
              'inténtalo de nuevo.',
  });
}

class _AcceptError implements Exception {
  const _AcceptError(this.message);
  final String message;
}
