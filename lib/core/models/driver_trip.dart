import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/enums.dart';
import 'models.dart';

/// Resumen de un viaje terminado del chófer (ventana del chófer,
/// decisión 2): lo escribe el servidor en driverHistory/{uid}/trips/{id}.
/// Sin datos del pasajero: ni nombre, ni teléfono, ni notas, ni dirección
/// exacta, ni vuelo, ni preferencias. Los importes son los mismos campos que
/// la pantalla de ganancias ya leía de la reserva.
class DriverTripSummary {
  const DriverTripSummary({
    required this.bookingId,
    required this.status,
    this.endedAt,
    this.serviceType,
    this.vehicleClass,
    this.pickupArea,
    this.dropoffArea,
    this.distanceKm,
    this.durationMinutes,
    this.riderRating,
    this.estimatedPrice,
    this.finalPrice,
    this.settlement,
    this.refunded = false,
  });

  final String bookingId;

  /// completed, cancelled o noShow.
  final BookingStatus status;
  final DateTime? endedAt;
  final ServiceType? serviceType;
  final VehicleClass? vehicleClass;
  final String? pickupArea;
  final String? dropoffArea;
  final double? distanceKm;
  final int? durationMinutes;

  /// Estrellas que dio el pasajero (1 a 5), sin comentario.
  final int? riderRating;
  final double? estimatedPrice;
  final double? finalPrice;
  final BookingSettlement? settlement;
  final bool refunded;

  /// Importe cobrado: el final si existe, si no el estimado (como en la
  /// reserva).
  double get chargedAmount => finalPrice ?? estimatedPrice ?? 0;

  /// Reparto vigente: el del servidor si corresponde al importe actual o,
  /// si no, uno provisional con [commissionPct] (igual que la reserva).
  BookingSettlement settlementOr(double commissionPct) {
    final s = settlement;
    if (s != null && (s.amount - chargedAmount).abs() < 0.005) return s;
    return BookingSettlement.estimate(
      chargedAmount,
      commissionPct: s?.commissionPct ?? commissionPct,
    );
  }

  static DriverTripSummary fromMap(String id, Map<String, dynamic> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    final ended = j['endedAt'];
    final service = j['serviceType'] as String?;
    final cls = j['vehicleClass'] as String?;
    return DriverTripSummary(
      bookingId: (j['bookingId'] as String?) ?? id,
      status: BookingStatusX.fromString((j['status'] as String?) ?? ''),
      endedAt: ended is Timestamp ? ended.toDate() : null,
      serviceType: service == null
          ? null
          : ServiceType.values.where((s) => s.name == service).firstOrNull,
      vehicleClass: cls == null
          ? null
          : VehicleClass.values.where((c) => c.name == cls).firstOrNull,
      pickupArea: j['pickupArea'] as String?,
      dropoffArea: j['dropoffArea'] as String?,
      distanceKm: d('distanceKm'),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt(),
      riderRating: (j['riderRating'] as num?)?.toInt(),
      estimatedPrice: d('estimatedPrice'),
      finalPrice: d('finalPrice'),
      settlement: BookingSettlement.fromJson(j['settlement']),
      refunded: j['refunded'] == true,
    );
  }
}
