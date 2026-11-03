import 'package:dartz/dartz.dart';

import '../../../core/enums/enums.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/function_errors.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/service_area.dart' show FlightType;

/// Panel, vuelos (B3): lo que el panel lee y escribe de los vuelos de
/// llegada y de los aeropuertos. El servidor calcula readyAt y el estado;
/// el panel solo los muestra o los fija a mano (adminSetFlightInfo).

/// Motivo de las acciones del panel sobre vuelos y aeropuertos.
const kFlightReasonMin = 10;
const kFlightReasonMax = 500;

/// Máximo de reservas con vuelo que lee la bandeja por consulta.
const kFlightInboxLimit = 200;

/// Las horas de los vuelos se muestran y se eligen en hora de Bolivia
/// (America/La_Paz, UTC−4 fijo, sin horario de verano), como el servidor.
const kLaPazOffset = Duration(hours: -4);

/// [instant] como hora de pared de La Paz (DateTime en UTC con esos campos:
/// DateFormat los imprime tal cual, sin la zona de la máquina).
DateTime laPazWall(DateTime instant) => instant.toUtc().add(kLaPazOffset);

/// Hora de pared de La Paz (solo se leen sus campos) al instante real.
DateTime fromLaPazWall(DateTime wall) => DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    ).subtract(kLaPazOffset);

class FlightAdminFailure extends Failure {
  const FlightAdminFailure(super.message);

  /// El servidor pidió volver a identificarse (reauth_required).
  bool get needsReauth => message == kReauthRequiredMessage;
}

/// Estados de la reserva que ya terminaron: no van a la bandeja.
const _finished = {
  BookingStatus.completed,
  BookingStatus.cancelled,
  BookingStatus.noShow,
};

/// Una reserva con vuelo, tal como la lee el panel.
class FlightBooking {
  const FlightBooking({
    required this.bookingId,
    required this.bookingStatus,
    required this.flight,
    this.flightActive = false,
    this.origin,
    this.destination,
  });

  final String bookingId;
  final BookingStatus bookingStatus;

  /// Con su readyAt (bookings/{id}.readyAt).
  final FlightInfo flight;

  /// El vuelo todavía se vigila (bookings/{id}.flightActive).
  final bool flightActive;
  final String? origin;
  final String? destination;

  bool get bookingFinished => _finished.contains(bookingStatus);
}

/// Las tres bandejas de la sección.
enum FlightInboxKind { toVerify, noData, disrupted }

extension FlightInboxFilter on FlightInboxKind {
  /// Si [b] va en esta bandeja.
  bool matches(FlightBooking b) => switch (this) {
        FlightInboxKind.toVerify =>
          b.flightActive && b.flight.source == FlightSource.passenger,
        FlightInboxKind.noData => b.flightActive &&
            (b.flight.dataQuality == FlightDataQuality.none ||
                b.flight.dataQuality == FlightDataQuality.stale),
        FlightInboxKind.disrupted =>
          b.flight.status.disrupted && !b.bookingFinished,
      };

  /// Las de esta bandeja, primero la que el chófer necesita antes.
  List<FlightBooking> pick(Iterable<FlightBooking> all) {
    final far = DateTime.utc(9999);
    return all.where(matches).toList()
      ..sort(
        (a, b) => (a.flight.readyAt ?? a.flight.scheduledArrival ?? far)
            .compareTo(b.flight.readyAt ?? b.flight.scheduledArrival ?? far),
      );
  }
}

class FlightInbox {
  const FlightInbox({required this.items, this.truncated = false});

  final List<FlightBooking> items;

  /// Alguna consulta llegó al límite: puede haber más.
  final bool truncated;
}

/// El último cambio manual del vuelo (admin_logs): quién y cuándo.
class FlightManualChange {
  const FlightManualChange({
    required this.clearedLock,
    this.adminEmail,
    this.at,
    this.reason,
  });

  /// true: adminClearFlightLock; false: adminSetFlightInfo.
  final bool clearedLock;
  final String? adminEmail;
  final DateTime? at;
  final String? reason;
}

/// Lo que manda el formulario de adminSetFlightInfo. Las horas, como
/// instantes reales; null las borra.
class FlightManualInput {
  const FlightManualInput({
    required this.status,
    required this.estimatedArrival,
    required this.actualArrival,
    required this.reason,
  });

  final FlightStatus status;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  final String reason;

  Map<String, dynamic> toPayload(String bookingId) => {
        'bookingId': bookingId,
        'status': status.name,
        'estimatedArrival': estimatedArrival?.millisecondsSinceEpoch,
        'actualArrival': actualArrival?.millisecondsSinceEpoch,
        'reason': reason.trim(),
      };
}

/// Cambio de un punto de recogida al guardar un aeropuerto.
sealed class PickupPointChange {
  const PickupPointChange();
}

/// Se deja el que hay (la clave no se manda).
class KeepPickupPoint extends PickupPointChange {
  const KeepPickupPoint();
}

/// Se quita (se manda null).
class RemovePickupPoint extends PickupPointChange {
  const RemovePickupPoint();
}

class SetPickupPoint extends PickupPointChange {
  const SetPickupPoint(this.point);
  final PickupPoint point;
}

class AirportInput {
  const AirportInput({
    required this.code,
    required this.name,
    required this.city,
    required this.points,
    required this.reason,
  });

  final String code;
  final String name;
  final String city;
  final Map<FlightType, PickupPointChange> points;
  final String reason;

  Map<String, dynamic> toPayload() => {
        'code': code,
        'name': name.trim(),
        'city': city.trim(),
        'timeZone': 'America/La_Paz', // i18n-ignore: zona horaria (dato)
        'pickupPoints': {
          for (final t in FlightType.values)
            if (points[t] case final SetPickupPoint p)
              t.name: {
                ...p.point.toJson(),
                'name': p.point.name.trim(),
                'instructions': p.point.instructions.trim(),
              }
            else if (points[t] is RemovePickupPoint)
              t.name: null,
        },
        'reason': reason.trim(),
      };
}

/// Validación de un punto (la misma que el servidor).
abstract final class PickupPointRules {
  static bool latOk(double? v) => v != null && v.isFinite && v.abs() <= 90;
  static bool lngOk(double? v) => v != null && v.isFinite && v.abs() <= 180;
  static bool notZero(double? lat, double? lng) => !(lat == 0 && lng == 0);

  /// Acepta coma o punto decimal.
  static double? parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));
}

final kAirportCodePattern = RegExp(r'^[A-Z]{3}$');

/// Lectura directa de Firestore (solo admin) y escrituras por callables.
abstract class FlightsAdminRepository {
  /// bookings/{id}: el vuelo con su readyAt; null si la reserva no tiene.
  Stream<FlightBooking?> watchFlight(String bookingId);

  /// El último cambio manual del vuelo (adminSetFlightInfo o quitar el
  /// bloqueo); null si no hubo.
  Future<Either<FlightAdminFailure, FlightManualChange?>> lastManualChange(
    String bookingId,
  );

  /// Reservas con vuelo vigilado y las de vuelo cancelado o desviado.
  Future<Either<FlightAdminFailure, FlightInbox>> inbox();

  Future<Either<FlightAdminFailure, void>> setFlightInfo(
    String bookingId,
    FlightManualInput input,
  );

  Future<Either<FlightAdminFailure, void>> clearFlightLock(
    String bookingId,
    String reason,
  );

  Future<Either<FlightAdminFailure, void>> forceNoShow(
    String bookingId,
    String reason,
  );

  Future<Either<FlightAdminFailure, List<Airport>>> airports();

  Future<Either<FlightAdminFailure, void>> upsertAirport(AirportInput input);
}
