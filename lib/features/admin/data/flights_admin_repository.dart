import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../core/enums/enums.dart';
import '../../../core/error/function_errors.dart';
import '../../../core/models/models.dart';
import '../../../l10n/l10n.dart';
import '../domain/admin_flights.dart';

export '../domain/admin_flights.dart';

/// Motivos del servidor (functions/src/flight.ts) en el texto del panel.
/// Nunca el texto técnico.
String flightAdminErrorMessage(String code, Object? details) {
  final common = commonFunctionError(code, details);
  if (common != null) return common;
  final t = L10n.current;
  return switch (functionErrorReason(details)) {
    'flight_config_missing' => t.adminFlightErrConfigMissing,
    'booking_without_flight' => t.adminFlightErrNoFlight,
    'booking_not_found' => t.adminFlightErrNotFound,
    'invalid_transition' => t.adminFlightErrInvalidTransition,
    'no_show_disabled' => t.adminFlightErrNoShowDisabled,
    _ => switch (code) {
        'invalid-argument' => t.adminFlightErrInvalid,
        'permission-denied' => t.adminFlightErrPermission,
        'not-found' => t.adminFlightErrNotFound,
        _ => t.adminFlightErrGeneric,
      },
  };
}

/// adminUpsertAirport: los datos no válidos con su propio texto.
String airportAdminErrorMessage(String code, Object? details) =>
    code == 'invalid-argument' && commonFunctionError(code, details) == null
        ? L10n.current.adminAirportErrInvalid
        : flightAdminErrorMessage(code, details);

DateTime? _date(Object? v) => switch (v) {
      Timestamp() => v.toDate(),
      num() => DateTime.fromMillisecondsSinceEpoch(v.toInt()),
      _ => null,
    };

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

/// Acciones del registro (admin_logs.action) que cambian el vuelo a mano.
const _manualActions = {'set_flight_info', 'clear_flight_lock'};

/// Máximo de entradas del registro que se leen por reserva.
const _logLimit = 50;

FlightBooking? flightBookingFromDoc(String id, Map<String, dynamic>? x) {
  if (x == null) return null;
  final flight = FlightInfo.fromMap(x['flight'], readyAt: x['readyAt']);
  if (flight == null) return null;
  return FlightBooking(
    bookingId: id,
    bookingStatus: BookingStatusX.fromString(
      (x['status'] as String?) ?? 'pending', // i18n-ignore: estado (dato)
    ),
    flight: flight,
    flightActive: x['flightActive'] == true,
    origin: _str((x['origin'] as Map?)?['address']),
    destination: _str((x['destination'] as Map?)?['address']),
  );
}

class FirebaseFlightsAdminRepository implements FlightsAdminRepository {
  FirebaseFlightsAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _dbOverride = firestore,
        _fnOverride = functions;

  final FirebaseFirestore? _dbOverride;
  final FirebaseFunctions? _fnOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instance;

  Future<Either<FlightAdminFailure, T>> _guard<T>(
    Future<T> Function() f, {
    String Function(String code, Object? details) message =
        flightAdminErrorMessage,
  }) async {
    try {
      return Right(await f());
    } on FirebaseFunctionsException catch (e) {
      return Left(FlightAdminFailure(message(e.code, e.details)));
    } catch (e) {
      return Left(FlightAdminFailure(unexpectedErrorMessage(e)));
    }
  }

  Future<Object?> _call(String name, Map<String, dynamic> data) async =>
      (await _fn.httpsCallable(name).call<Object?>(data)).data;

  @override
  Stream<FlightBooking?> watchFlight(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((s) => flightBookingFromDoc(s.id, s.data()));

  @override
  Future<Either<FlightAdminFailure, FlightManualChange?>> lastManualChange(
    String bookingId,
  ) =>
      _guard(() async {
        // Solo igualdad en un campo: sin índice compuesto. Se filtra aquí.
        final snap = await _db
            .collection('admin_logs')
            .where('targetId', isEqualTo: bookingId)
            .limit(_logLimit)
            .get();
        FlightManualChange? last;
        for (final d in snap.docs) {
          final x = d.data();
          final action = x['action'] ?? x['operation'];
          if (!_manualActions.contains(action)) continue;
          final at = _date(x['createdAt']);
          if (last != null &&
              (at == null || (last.at != null && !at.isAfter(last.at!)))) {
            continue;
          }
          last = FlightManualChange(
            clearedLock: action == 'clear_flight_lock',
            adminEmail: _str(x['adminEmail']),
            at: at,
            reason: _str(x['reason']),
          );
        }
        return last;
      });

  @override
  Future<Either<FlightAdminFailure, FlightInbox>> inbox() => _guard(() async {
        final bookings = _db.collection('bookings');
        // Una igualdad o un «in» en un solo campo cada una: sin índices
        // compuestos. Los cancelados o desviados ya no se vigilan
        // (flightActive false): van en la segunda consulta.
        final results = await Future.wait([
          bookings
              .where('flightActive', isEqualTo: true)
              .limit(kFlightInboxLimit)
              .get(),
          bookings
              .where('flight.status', whereIn: ['cancelled', 'diverted'])
              .limit(kFlightInboxLimit)
              .get(),
        ]);
        final byId = <String, FlightBooking>{};
        for (final snap in results) {
          for (final d in snap.docs) {
            final b = flightBookingFromDoc(d.id, d.data());
            if (b != null) byId[d.id] = b;
          }
        }
        return FlightInbox(
          items: byId.values.toList(),
          truncated: results.any((s) => s.docs.length >= kFlightInboxLimit),
        );
      });

  @override
  Future<Either<FlightAdminFailure, void>> setFlightInfo(
    String bookingId,
    FlightManualInput input,
  ) =>
      _guard(() => _call('adminSetFlightInfo', input.toPayload(bookingId)));

  @override
  Future<Either<FlightAdminFailure, void>> clearFlightLock(
    String bookingId,
    String reason,
  ) =>
      _guard(
        () => _call('adminClearFlightLock', {
          'bookingId': bookingId,
          'reason': reason.trim(),
        }),
      );

  @override
  Future<Either<FlightAdminFailure, void>> forceNoShow(
    String bookingId,
    String reason,
  ) =>
      _guard(
        () => _call('adminForceNoShow', {
          'bookingId': bookingId,
          'reason': reason.trim(),
        }),
      );

  @override
  Future<Either<FlightAdminFailure, List<Airport>>> airports() =>
      _guard(() async {
        final snap = await _db.collection('airports').get();
        return [
          for (final d in snap.docs)
            if (Airport.fromMap(d.id, d.data()) case final a?) a,
        ]..sort((a, b) => a.code.compareTo(b.code));
      });

  @override
  Future<Either<FlightAdminFailure, void>> upsertAirport(AirportInput input) =>
      _guard(
        () => _call('adminUpsertAirport', input.toPayload()),
        message: airportAdminErrorMessage,
      );
}
