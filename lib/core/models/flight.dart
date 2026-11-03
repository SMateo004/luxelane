import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/l10n.dart';
import '../utils/service_area.dart' show FlightType;

/// Vuelo de llegada de una reserva (prompt de vuelos). Lo escribe solo el
/// servidor: bookings/{id}.flight (pasajero y admin) y
/// bookings/{id}/driverView/flight (chófer asignado, con ventana). La app
/// nunca calcula readyAt ni el estado: los lee.

enum FlightStatus {
  scheduled,
  delayed,
  landed,
  cancelled,
  diverted,
  unknown;

  static FlightStatus fromWire(Object? raw) =>
      values.where((s) => s.name == raw).firstOrNull ?? unknown;

  bool get disrupted =>
      this == FlightStatus.cancelled || this == FlightStatus.diverted;

  String get label {
    final t = L10n.current;
    return switch (this) {
      scheduled => t.flightStatusScheduled,
      delayed => t.flightStatusDelayed,
      landed => t.flightStatusLanded,
      cancelled => t.flightStatusCancelled,
      diverted => t.flightStatusDiverted,
      unknown => t.flightStatusUnknown,
    };
  }
}

/// ok: dato reciente de una fuente o de central; stale: viejo; none: solo lo
/// que declaró el pasajero.
enum FlightDataQuality {
  ok,
  stale,
  none;

  static FlightDataQuality fromWire(Object? raw) =>
      values.where((s) => s.name == raw).firstOrNull ?? none;
}

/// Quién dio el último dato (solo lo ve el admin).
enum FlightSource {
  passenger,
  manual,
  auto;

  static FlightSource fromWire(Object? raw) =>
      values.where((s) => s.name == raw).firstOrNull ?? passenger;
}

DateTime? _date(Object? v) => switch (v) {
      Timestamp() => v.toDate(),
      num() => DateTime.fromMillisecondsSinceEpoch(v.toInt()),
      _ => null,
    };

class FlightInfo {
  const FlightInfo({
    required this.airportCode,
    required this.flightType,
    this.airline,
    required this.flightNumber,
    required this.flightDate,
    this.scheduledArrival,
    this.estimatedArrival,
    this.actualArrival,
    required this.status,
    required this.dataQuality,
    this.readyAt,
    this.hasCheckedBag,
    this.source,
    this.manualLock = false,
    this.lastObservedAt,
    this.lastChangeAt,
  });

  final String airportCode;
  final FlightType flightType;
  final String? airline;
  final String flightNumber;

  /// Fecha local del vuelo, AAAA-MM-DD.
  final String flightDate;
  final DateTime? scheduledArrival;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  final FlightStatus status;
  final FlightDataQuality dataQuality;

  /// Hora a la que el chófer debe estar en el punto de recogida.
  final DateTime? readyAt;

  // Solo en la reserva (pasajero y admin), no en la copia del chófer.
  final bool? hasCheckedBag;
  final FlightSource? source;
  final bool manualLock;
  final DateTime? lastObservedAt;
  final DateTime? lastChangeAt;

  /// Sin datos en vivo: solo la hora programada (declarada o vieja).
  bool get noLiveData => dataQuality != FlightDataQuality.ok;

  /// Real si existe, si no estimada, si no programada.
  DateTime? get effectiveArrival =>
      actualArrival ?? estimatedArrival ?? scheduledArrival;

  /// Desde bookings/{id}.flight ([readyAt] va aparte en la reserva) o desde
  /// driverView/flight (lleva su readyAt).
  static FlightInfo? fromMap(Object? raw, {Object? readyAt}) {
    if (raw is! Map) return null;
    final type = FlightType.fromName(raw['flightType'] as String?);
    final number = raw['flightNumber'];
    if (type == null || number is! String) return null;
    final airline = raw['airline'];
    return FlightInfo(
      airportCode: (raw['airportCode'] as String?) ?? '',
      flightType: type,
      airline: airline is String && airline.isNotEmpty ? airline : null,
      flightNumber: number,
      flightDate: (raw['flightDate'] as String?) ?? '',
      scheduledArrival: _date(raw['scheduledArrival']),
      estimatedArrival: _date(raw['estimatedArrival']),
      actualArrival: _date(raw['actualArrival']),
      status: FlightStatus.fromWire(raw['status']),
      dataQuality: FlightDataQuality.fromWire(raw['dataQuality']),
      readyAt: _date(readyAt ?? raw['readyAt']),
      hasCheckedBag:
          raw['hasCheckedBag'] is bool ? raw['hasCheckedBag'] as bool : null,
      source: raw.containsKey('source')
          ? FlightSource.fromWire(raw['source'])
          : null,
      manualLock: raw['manualLock'] == true,
      lastObservedAt: _date(raw['lastObservedAt']),
      lastChangeAt: _date(raw['lastChangeAt']),
    );
  }
}

/// Punto de recogida de un aeropuerto para un tipo de vuelo.
class PickupPoint {
  const PickupPoint({
    required this.name,
    required this.instructions,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String instructions;
  final double lat;
  final double lng;

  static PickupPoint? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final lat = raw['lat'];
    final lng = raw['lng'];
    if (name is! String || lat is! num || lng is! num) return null;
    return PickupPoint(
      name: name,
      instructions: (raw['instructions'] as String?) ?? '',
      lat: lat.toDouble(),
      lng: lng.toDouble(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'instructions': instructions, 'lat': lat, 'lng': lng};
}

/// airports/{código}: sin punto para un tipo, el chófer ve «Punto por
/// confirmar con central».
class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.city,
    this.domestic,
    this.international,
  });

  final String code;
  final String name;
  final String city;
  final PickupPoint? domestic;
  final PickupPoint? international;

  PickupPoint? pointFor(FlightType t) =>
      t == FlightType.domestic ? domestic : international;

  static Airport? fromMap(String id, Object? raw) {
    if (raw is! Map) return null;
    final points = raw['pickupPoints'];
    return Airport(
      code: (raw['code'] as String?) ?? id,
      name: (raw['name'] as String?) ?? id,
      city: (raw['city'] as String?) ?? '',
      domestic: points is Map ? PickupPoint.fromMap(points['domestic']) : null,
      international:
          points is Map ? PickupPoint.fromMap(points['international']) : null,
    );
  }
}
