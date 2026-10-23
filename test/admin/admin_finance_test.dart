import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_finance.dart';

final _now = DateTime(2026, 10, 10, 12);
const _place = Place(address: 'X', lat: 0, lng: 0);

Booking _b(
  String id, {
  BookingStatus status = BookingStatus.completed,
  double price = 100,
  double? finalPrice,
  String? driverId = 'driver-1',
  DateTime? at,
  String? paymentId,
  VehicleClass vc = VehicleClass.business,
  BookingSettlement? settlement,
}) => Booking(
  id: id,
  riderId: 'rider-1',
  driverId: driverId,
  origin: _place,
  destination: _place,
  scheduledAt: at ?? _now,
  vehicleClass: vc,
  serviceType: ServiceType.oneWay,
  status: status,
  estimatedPrice: price,
  finalPrice: finalPrice,
  paymentId: paymentId,
  createdAt: at ?? _now,
  updatedAt: at ?? _now,
  settlement: settlement,
);

Payment _p(String id, String bookingId, PaymentStatus status, {DateTime? at}) =>
    Payment(
      id: id,
      bookingId: bookingId,
      riderId: 'rider-1',
      stripePaymentIntentId: 'pi',
      amount: 10000,
      currency: 'bob',
      status: status,
      createdAt: at ?? _now,
    );

void main() {
  group('FinancialSummary', () {
    test('separa cobrado, por cobrar, fallido y reembolsado', () {
      final s = FinancialSummary.compute(
        bookings: [
          _b('a', price: 100),
          _b('b', price: 200),
          _b('c', price: 50),
          _b('d', price: 80),
        ],
        payments: [
          _p('pa', 'a', PaymentStatus.captured),
          _p('pc', 'c', PaymentStatus.refunded),
          _p('pd', 'd', PaymentStatus.failed),
        ],
        commissionPct: 20,
        now: _now,
      );

      expect(s.completedCount, 4);
      expect(s.grossBilled, 430);
      expect(s.collected, 100);
      expect(s.receivables, 280); // b (sin pago) + d (fallido)
      expect(s.receivablesCount, 2);
      expect(s.refunded, 50);
      expect(s.netRevenue, 380);
      // Comisión y pago al chófer solo sobre lo no reembolsado.
      expect(s.platformRevenue, 76);
      expect(s.driverPayouts, 304);
      expect(s.platformRevenue + s.driverPayouts, s.netRevenue);
      expect(s.averageTicket, closeTo(126.67, 0.01));
    });

    test('usa el reparto fijado por el servidor (mismo que ve el chófer)', () {
      const locked = BookingSettlement(
        amount: 100,
        commissionPct: 10,
        platformCommission: 10,
        driverPayout: 90,
      );
      final s = FinancialSummary.compute(
        bookings: [
          _b('a', price: 100, settlement: locked),
          // Reparto de otro importe (precio ajustado después): se recalcula
          // con el porcentaje fijado, no con el vigente.
          _b('b', price: 100, finalPrice: 200, settlement: locked),
          _b('c', price: 100), // sin reparto: comisión vigente
        ],
        payments: const [],
        commissionPct: 30,
        now: _now,
      );
      expect(s.byDriver['driver-1']!.payout, 90 + 180 + 70);
      expect(s.platformRevenue, 10 + 20 + 30);
    });

    test('usa el precio final si existe', () {
      final s = FinancialSummary.compute(
        bookings: [_b('a', price: 100, finalPrice: 130)],
        payments: const [],
        now: _now,
      );
      expect(s.grossBilled, 130);
    });

    test('prefiere el pago enlazado en booking.paymentId', () {
      final s = FinancialSummary.compute(
        bookings: [_b('a', paymentId: 'p1')],
        payments: [
          _p(
            'p1',
            'a',
            PaymentStatus.captured,
            at: _now.subtract(const Duration(days: 1)),
          ),
          _p('p2', 'a', PaymentStatus.failed),
        ],
        now: _now,
      );
      expect(s.entries.single.status, ChargeStatus.collected);
    });

    test('filtra por periodo según la fecha de cierre', () {
      final old = _now.subtract(const Duration(days: 40));
      final bookings = [_b('a'), _b('b', at: old)];
      expect(
        FinancialSummary.compute(
          bookings: bookings,
          payments: const [],
          period: FinancePeriod.last30,
          now: _now,
        ).completedCount,
        1,
      );
      expect(
        FinancialSummary.compute(
          bookings: bookings,
          payments: const [],
          period: FinancePeriod.all,
          now: _now,
        ).completedCount,
        2,
      );
    });

    test('cuenta canceladas y reservas en curso aparte de la facturación', () {
      final s = FinancialSummary.compute(
        bookings: [
          _b('a', status: BookingStatus.cancelled, price: 70),
          _b('b', status: BookingStatus.inProgress, price: 90),
          _b('c', status: BookingStatus.pending, price: 60, driverId: null),
        ],
        payments: const [],
        now: _now,
      );
      expect(s.completedCount, 0);
      expect(s.grossBilled, 0);
      expect(s.cancelledCount, 1);
      expect(s.cancelledValue, 70);
      expect(s.pipelineCount, 1);
      expect(s.pendingCount, 1);
      expect(s.pipelineValue, 150);
    });

    test('liquidación por chófer y serie diaria', () {
      final s = FinancialSummary.compute(
        bookings: [
          _b('a', price: 100),
          _b('b', price: 100, driverId: 'driver-2'),
          _b('c', price: 100, at: _now.subtract(const Duration(days: 2))),
        ],
        payments: [_p('pa', 'a', PaymentStatus.captured)],
        commissionPct: 25,
        period: FinancePeriod.last7,
        now: _now,
      );
      final d1 = s.byDriver['driver-1']!;
      expect(d1.rides, 2);
      expect(d1.payout, 150);
      expect(d1.collectedPayout, 75);
      expect(s.byDriver['driver-2']!.rides, 1);

      expect(s.daily.length, 7);
      expect(s.daily[DateTime(2026, 10, 10)], 200);
      expect(s.daily[DateTime(2026, 10, 8)], 100);
    });

    test('exporta CSV con una línea por viaje', () {
      final s = FinancialSummary.compute(
        bookings: [_b('a', price: 100)],
        payments: const [],
        now: _now,
      );
      final lines = s.toCsv((id) => 'Nombre, $id').trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines[1], contains('"Nombre, rider-1"'));
      expect(lines[1], contains('100.00'));
      expect(lines[1], contains('Por cobrar'));
    });
  });
}
