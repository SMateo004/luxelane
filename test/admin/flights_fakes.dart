import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/service_area.dart' show FlightType;
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';

export 'driver_applications_fakes.dart' show pumpPanel;

/// Datos de PRUEBA, ficticios. Repositorio falso de la sección «Vuelos»:
/// responde lo que se le fija y anota cada llamada.
class FakeFlightsRepo implements FlightsAdminRepository {
  final flights = <String, StreamController<FlightBooking?>>{};
  final initial = <String, FlightBooking?>{};
  Either<FlightAdminFailure, FlightManualChange?> changeAnswer =
      const Right(null);
  Either<FlightAdminFailure, FlightInbox> inboxAnswer =
      const Right(FlightInbox(items: []));
  Either<FlightAdminFailure, List<Airport>> airportsAnswer = const Right([]);
  Either<FlightAdminFailure, void> writeAnswer = const Right(null);

  final setCalls = <(String, FlightManualInput)>[];
  final clearCalls = <(String, String)>[];
  final noShowCalls = <(String, String)>[];
  final upsertCalls = <AirportInput>[];
  int inboxCalls = 0;
  int changeCalls = 0;

  @override
  Stream<FlightBooking?> watchFlight(String bookingId) async* {
    yield initial[bookingId];
    // Broadcast y de prueba: no queda nada esperando al terminar.
    // ignore: close_sinks
    final c = flights.putIfAbsent(bookingId, StreamController.broadcast);
    yield* c.stream;
  }

  @override
  Future<Either<FlightAdminFailure, FlightManualChange?>> lastManualChange(
    String bookingId,
  ) async {
    changeCalls++;
    return changeAnswer;
  }

  @override
  Future<Either<FlightAdminFailure, FlightInbox>> inbox() async {
    inboxCalls++;
    return inboxAnswer;
  }

  @override
  Future<Either<FlightAdminFailure, void>> setFlightInfo(
    String bookingId,
    FlightManualInput input,
  ) async {
    setCalls.add((bookingId, input));
    return writeAnswer;
  }

  @override
  Future<Either<FlightAdminFailure, void>> clearFlightLock(
    String bookingId,
    String reason,
  ) async {
    clearCalls.add((bookingId, reason));
    return writeAnswer;
  }

  @override
  Future<Either<FlightAdminFailure, void>> forceNoShow(
    String bookingId,
    String reason,
  ) async {
    noShowCalls.add((bookingId, reason));
    return writeAnswer;
  }

  @override
  Future<Either<FlightAdminFailure, List<Airport>>> airports() async =>
      airportsAnswer;

  @override
  Future<Either<FlightAdminFailure, void>> upsertAirport(
    AirportInput input,
  ) async {
    upsertCalls.add(input);
    return writeAnswer;
  }
}

/// 2026-11-20 14:35 en La Paz (18:35 UTC).
final kReadyAt = DateTime.utc(2026, 11, 20, 18, 35);

FlightInfo fakeFlight({
  FlightStatus status = FlightStatus.scheduled,
  FlightDataQuality quality = FlightDataQuality.ok,
  FlightSource source = FlightSource.auto,
  bool manualLock = false,
  DateTime? readyAt,
  DateTime? estimated,
  DateTime? actual,
  String number = 'OB760',
}) =>
    FlightInfo(
      airportCode: 'VVI',
      flightType: FlightType.international,
      airline: 'Aerolínea Prueba',
      flightNumber: number,
      flightDate: '2026-11-20',
      scheduledArrival: DateTime.utc(2026, 11, 20, 18),
      estimatedArrival: estimated,
      actualArrival: actual,
      status: status,
      dataQuality: quality,
      readyAt: readyAt ?? kReadyAt,
      hasCheckedBag: true,
      source: source,
      manualLock: manualLock,
      lastChangeAt: DateTime.utc(2026, 11, 20, 12),
    );

FlightBooking fakeFlightBooking(
  String id, {
  BookingStatus bookingStatus = BookingStatus.confirmed,
  bool active = true,
  FlightInfo? flight,
}) =>
    FlightBooking(
      bookingId: id,
      bookingStatus: bookingStatus,
      flight: flight ?? fakeFlight(),
      flightActive: active,
      origin: 'Aeropuerto de prueba',
      destination: 'Hotel de prueba',
    );

Airport fakeAirport({PickupPoint? domestic, PickupPoint? international}) =>
    Airport(
      code: 'VVI',
      name: 'Aeropuerto Prueba',
      city: 'Ciudad Prueba',
      domestic: domestic,
      international: international,
    );

const kFakePoint = PickupPoint(
  name: 'Salida 1',
  instructions: 'Frente a la puerta',
  lat: -17.64,
  lng: -63.13,
);
