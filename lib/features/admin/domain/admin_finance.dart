import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

enum FinancePeriod { today, last7, last30, thisMonth, all }

extension FinancePeriodX on FinancePeriod {
  String get label {
    switch (this) {
      case FinancePeriod.today:
        return 'Hoy';
      case FinancePeriod.last7:
        return '7 días';
      case FinancePeriod.last30:
        return '30 días';
      case FinancePeriod.thisMonth:
        return 'Este mes';
      case FinancePeriod.all:
        return 'Todo';
    }
  }

  /// Inicio (inclusive) del periodo, o null si no tiene límite.
  DateTime? start(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case FinancePeriod.today:
        return today;
      case FinancePeriod.last7:
        return today.subtract(const Duration(days: 6));
      case FinancePeriod.last30:
        return today.subtract(const Duration(days: 29));
      case FinancePeriod.thisMonth:
        return DateTime(now.year, now.month);
      case FinancePeriod.all:
        return null;
    }
  }

  /// Días que muestra el gráfico diario.
  int chartDays(DateTime now) {
    switch (this) {
      case FinancePeriod.today:
      case FinancePeriod.last7:
        return 7;
      case FinancePeriod.thisMonth:
        return now.day < 7 ? 7 : now.day;
      case FinancePeriod.last30:
      case FinancePeriod.all:
        return 30;
    }
  }
}

/// Estado de cobro de un viaje completado.
enum ChargeStatus { collected, pendingCollection, refunded, failed }

extension ChargeStatusX on ChargeStatus {
  String get label {
    switch (this) {
      case ChargeStatus.collected:
        return 'Cobrado';
      case ChargeStatus.pendingCollection:
        return 'Por cobrar';
      case ChargeStatus.refunded:
        return 'Reembolsado';
      case ChargeStatus.failed:
        return 'Cobro fallido';
    }
  }
}

/// Una línea del libro: un viaje completado con su cobro y su reparto.
class LedgerEntry {
  const LedgerEntry({
    required this.booking,
    required this.payment,
    required this.amount,
    required this.status,
    required this.commission,
    required this.driverPayout,
  });

  final Booking booking;
  final Payment? payment;

  /// Importe facturado (precio final o, si no hay, el estimado).
  final double amount;
  final ChargeStatus status;

  /// Parte de la plataforma (0 si el viaje se reembolsó).
  final double commission;

  /// Parte del chófer (0 si el viaje se reembolsó).
  final double driverPayout;

  /// Fecha contable: cuando se cerró el viaje.
  DateTime get date => booking.updatedAt;
}

class DriverFinance {
  DriverFinance(this.driverId);
  final String driverId;
  int rides = 0;
  double billed = 0;
  double payout = 0;
  double commission = 0;

  /// Lo que la plataforma ya cobró de sus viajes (lo que se le debe liquidar).
  double collectedPayout = 0;
}

class SegmentFinance {
  int rides = 0;
  double billed = 0;
}

/// Resumen financiero calculado a partir de reservas y pagos.
///
/// Todos los totales del panel (inicio, finanzas, configuración) salen de
/// aquí para que las cifras sean idénticas en cada pantalla.
class FinancialSummary {
  FinancialSummary._({
    required this.period,
    required this.commissionPct,
    required this.entries,
    required this.cancelledCount,
    required this.cancelledValue,
    required this.pipelineCount,
    required this.pipelineValue,
    required this.pendingCount,
    required this.daily,
    required this.byDriver,
    required this.byClass,
    required this.byService,
  });

  factory FinancialSummary.compute({
    required List<Booking> bookings,
    required List<Payment> payments,
    double commissionPct = kDefaultCommissionPct,
    FinancePeriod period = FinancePeriod.all,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final from = period.start(n);
    bool inPeriod(DateTime d) => from == null || !d.isBefore(from);

    final paymentFor = paymentIndex(payments);

    final entries = <LedgerEntry>[];
    var cancelledCount = 0, pipelineCount = 0, pendingCount = 0;
    var cancelledValue = 0.0, pipelineValue = 0.0;
    final byDriver = <String, DriverFinance>{};
    final byClass = <VehicleClass, SegmentFinance>{};
    final byService = <ServiceType, SegmentFinance>{};

    for (final b in bookings) {
      switch (b.status) {
        case BookingStatus.completed:
          if (!inPeriod(b.updatedAt)) continue;
          final p = paymentFor(b);
          final status = chargeStatusOf(p);
          final amount = b.chargedAmount;
          final refunded = status == ChargeStatus.refunded;
          // Mismo reparto que ve el chófer: el fijado por el servidor o, si
          // aún no existe, uno provisional con la comisión vigente.
          final split = b.settlementOr(commissionPct);
          final commission = refunded ? 0.0 : split.platformCommission;
          final payout = refunded ? 0.0 : split.driverPayout;
          entries.add(LedgerEntry(
            booking: b,
            payment: p,
            amount: amount,
            status: status,
            commission: commission,
            driverPayout: payout,
          ));
          if (!refunded) {
            if (b.driverId != null) {
              final d = byDriver.putIfAbsent(
                  b.driverId!, () => DriverFinance(b.driverId!));
              d.rides++;
              d.billed += amount;
              d.payout += payout;
              d.commission += commission;
              if (status == ChargeStatus.collected) {
                d.collectedPayout += payout;
              }
            }
            (byClass[b.vehicleClass] ??= SegmentFinance())
              ..rides += 1
              ..billed += amount;
            (byService[b.serviceType] ??= SegmentFinance())
              ..rides += 1
              ..billed += amount;
          }
        case BookingStatus.cancelled:
          if (!inPeriod(b.updatedAt)) continue;
          cancelledCount++;
          cancelledValue += b.estimatedPrice;
        case BookingStatus.pending:
          if (!inPeriod(b.createdAt)) continue;
          pendingCount++;
          pipelineValue += b.estimatedPrice;
        case BookingStatus.confirmed:
        case BookingStatus.driverArriving:
        case BookingStatus.driverArrived:
        case BookingStatus.inProgress:
          if (!inPeriod(b.createdAt)) continue;
          pipelineCount++;
          pipelineValue += b.estimatedPrice;
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    final days = period.chartDays(n);
    final today = DateTime(n.year, n.month, n.day);
    final daily = <DateTime, double>{
      for (var i = days - 1; i >= 0; i--)
        today.subtract(Duration(days: i)): 0.0,
    };
    for (final e in entries) {
      if (e.status == ChargeStatus.refunded) continue;
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      if (daily.containsKey(key)) daily[key] = daily[key]! + e.amount;
    }

    return FinancialSummary._(
      period: period,
      commissionPct: commissionPct,
      entries: entries,
      cancelledCount: cancelledCount,
      cancelledValue: cancelledValue,
      pipelineCount: pipelineCount,
      pipelineValue: pipelineValue,
      pendingCount: pendingCount,
      daily: daily,
      byDriver: byDriver,
      byClass: byClass,
      byService: byService,
    );
  }

  final FinancePeriod period;
  final double commissionPct;
  final List<LedgerEntry> entries;
  final int cancelledCount;
  final double cancelledValue;

  /// Reservas confirmadas o en curso: ingresos esperados, aún no facturados.
  final int pipelineCount;
  final int pendingCount;
  final double pipelineValue;
  final Map<DateTime, double> daily;
  final Map<String, DriverFinance> byDriver;
  final Map<VehicleClass, SegmentFinance> byClass;
  final Map<ServiceType, SegmentFinance> byService;

  double _sum(Iterable<LedgerEntry> es, double Function(LedgerEntry) f) =>
      _round(es.fold(0.0, (s, e) => s + f(e)));

  Iterable<LedgerEntry> _where(ChargeStatus s) =>
      entries.where((e) => e.status == s);

  int get completedCount => entries.length;

  /// Facturación bruta: todos los viajes completados del periodo.
  double get grossBilled => _sum(entries, (e) => e.amount);

  double get collected => _sum(_where(ChargeStatus.collected), (e) => e.amount);

  /// Completados sin cobro capturado (pendiente o fallido): cuentas por cobrar.
  double get receivables => _sum(
      entries.where((e) =>
          e.status == ChargeStatus.pendingCollection ||
          e.status == ChargeStatus.failed),
      (e) => e.amount);

  int get receivablesCount => entries
      .where((e) =>
          e.status == ChargeStatus.pendingCollection ||
          e.status == ChargeStatus.failed)
      .length;

  double get failed => _sum(_where(ChargeStatus.failed), (e) => e.amount);

  double get refunded => _sum(_where(ChargeStatus.refunded), (e) => e.amount);

  int get refundedCount => _where(ChargeStatus.refunded).length;

  /// Ingresos netos: facturado menos reembolsado.
  double get netRevenue => _round(grossBilled - refunded);

  double get platformRevenue => _sum(entries, (e) => e.commission);

  double get driverPayouts => _sum(entries, (e) => e.driverPayout);

  double get averageTicket {
    final n = entries.length - refundedCount;
    return n == 0 ? 0 : _round(netRevenue / n);
  }

  /// Porcentaje de lo neto que ya está cobrado.
  double get collectionRate =>
      netRevenue == 0 ? 0 : (collected / netRevenue * 100).clamp(0, 100);

  /// CSV del libro, para exportar a contabilidad.
  String toCsv(String Function(String userId) nameOf) {
    String esc(String v) =>
        v.contains(RegExp('[",\n;]')) ? '"${v.replaceAll('"', '""')}"' : v;
    String money(double v) => v.toStringAsFixed(2);
    final buf = StringBuffer(
        'fecha,reserva,pasajero,chofer,clase,servicio,importe_bs,estado_cobro,'
        'comision_bs,pago_chofer_bs,id_pago\n');
    for (final e in entries) {
      final b = e.booking;
      buf.writeln([
        e.date.toIso8601String(),
        b.id,
        esc(nameOf(b.riderId)),
        esc(b.driverId == null ? '' : nameOf(b.driverId!)),
        b.vehicleClass.label,
        b.serviceType.label,
        money(e.amount),
        e.status.label,
        money(e.commission),
        money(e.driverPayout),
        e.payment?.id ?? '',
      ].join(','));
    }
    return buf.toString();
  }

  /// Busca el pago de una reserva: primero por `booking.paymentId` y, si no,
  /// el más reciente con ese `bookingId`.
  static Payment? Function(Booking) paymentIndex(List<Payment> payments) {
    final byId = {for (final p in payments) p.id: p};
    final byBooking = <String, Payment>{};
    for (final p in payments) {
      final prev = byBooking[p.bookingId];
      if (prev == null || p.createdAt.isAfter(prev.createdAt)) {
        byBooking[p.bookingId] = p;
      }
    }
    return (b) =>
        (b.paymentId != null ? byId[b.paymentId] : null) ?? byBooking[b.id];
  }

  static ChargeStatus chargeStatusOf(Payment? p) {
    switch (p?.status) {
      case PaymentStatus.captured:
        return ChargeStatus.collected;
      case PaymentStatus.refunded:
        return ChargeStatus.refunded;
      case PaymentStatus.failed:
        return ChargeStatus.failed;
      case PaymentStatus.pending:
      case null:
        return ChargeStatus.pendingCollection;
    }
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
