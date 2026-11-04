import 'package:cloud_firestore/cloud_firestore.dart';

/// Programa para empresas: modelos de solo lectura (todo lo escribe el
/// servidor; ver functions/src/corporate_functions.ts).

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
double? _num(Object? v) => (v as num?)?.toDouble();

enum CompanyStatus { pending, active, suspended, rejected }

extension CompanyStatusX on CompanyStatus {
  static CompanyStatus parse(Object? v) => CompanyStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => CompanyStatus.pending,
      );

  String get label => switch (this) {
        CompanyStatus.pending => 'Pendiente de aprobación',
        CompanyStatus.active => 'Activa',
        CompanyStatus.suspended => 'Suspendida',
        CompanyStatus.rejected => 'Rechazada',
      };
}

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.taxId,
    required this.billingEmail,
    required this.contactName,
    required this.phone,
    required this.address,
    required this.status,
    required this.ownerId,
    this.monthlyBudgetBs,
    this.discountPct = 0,
    this.paymentTermsDays = 15,
    this.statusReason,
    this.createdAt,
  });

  final String id;
  final String name;
  final String taxId;
  final String billingEmail;
  final String contactName;
  final String phone;
  final String address;
  final CompanyStatus status;
  final String ownerId;
  final double? monthlyBudgetBs;
  final double discountPct;
  final int paymentTermsDays;
  final String? statusReason;
  final DateTime? createdAt;

  bool get isActive => status == CompanyStatus.active;

  factory Company.fromDoc(String id, Map<String, dynamic> j) => Company(
        id: id,
        name: j['name'] as String? ?? '',
        taxId: j['taxId'] as String? ?? '',
        billingEmail: j['billingEmail'] as String? ?? '',
        contactName: j['contactName'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        status: CompanyStatusX.parse(j['status']),
        ownerId: j['ownerId'] as String? ?? '',
        monthlyBudgetBs: _num(j['monthlyBudgetBs']),
        discountPct: _num(j['discountPct']) ?? 0,
        paymentTermsDays: (j['paymentTermsDays'] as num?)?.toInt() ?? 15,
        statusReason: j['statusReason'] as String?,
        createdAt: _date(j['createdAt']),
      );
}

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isAdmin,
    required this.active,
    this.monthlyLimitBs,
  });

  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;
  final bool active;
  final double? monthlyLimitBs;

  factory CompanyMember.fromDoc(String id, Map<String, dynamic> j) =>
      CompanyMember(
        uid: id,
        email: j['email'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        isAdmin: j['role'] == 'admin',
        active: j['active'] as bool? ?? true,
        monthlyLimitBs: _num(j['monthlyLimitBs']),
      );
}

class CompanyInvite {
  const CompanyInvite({
    required this.companyId,
    required this.companyName,
    required this.email,
    required this.isAdmin,
    this.monthlyLimitBs,
    this.createdAt,
  });

  final String companyId;
  final String companyName;
  final String email;
  final bool isAdmin;
  final double? monthlyLimitBs;
  final DateTime? createdAt;

  factory CompanyInvite.fromDoc(Map<String, dynamic> j) => CompanyInvite(
        companyId: j['companyId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        email: j['email'] as String? ?? '',
        isAdmin: j['role'] == 'admin',
        monthlyLimitBs: _num(j['monthlyLimitBs']),
        createdAt: _date(j['createdAt']),
      );
}

enum StatementStatus { draft, issued, paid }

extension StatementStatusX on StatementStatus {
  static StatementStatus parse(Object? v) => StatementStatus.values
      .firstWhere((e) => e.name == v, orElse: () => StatementStatus.draft);

  String get label => switch (this) {
        StatementStatus.draft => 'Borrador',
        StatementStatus.issued => 'Emitido · por pagar',
        StatementStatus.paid => 'Pagado',
      };
}

class StatementLine {
  const StatementLine({
    required this.bookingId,
    required this.date,
    required this.riderName,
    required this.origin,
    required this.destination,
    required this.vehicleClass,
    required this.costCenter,
    required this.amountBs,
  });

  final String bookingId;
  final DateTime date;
  final String riderName;
  final String origin;
  final String destination;
  final String vehicleClass;
  final String costCenter;
  final double amountBs;

  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
        bookingId: j['bookingId'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['dateMs'] as num?)?.toInt() ?? 0),
        riderName: j['riderName'] as String? ?? '',
        origin: j['origin'] as String? ?? '',
        destination: j['destination'] as String? ?? '',
        vehicleClass: j['vehicleClass'] as String? ?? '',
        costCenter: j['costCenter'] as String? ?? '',
        amountBs: _num(j['amountBs']) ?? 0,
      );
}

class StatementAdjustment {
  const StatementAdjustment(
      {required this.id, required this.concept, required this.amountBs});
  final String id;
  final String concept;
  final double amountBs;

  factory StatementAdjustment.fromJson(Map<String, dynamic> j) =>
      StatementAdjustment(
        id: j['id'] as String? ?? '',
        concept: j['concept'] as String? ?? '',
        amountBs: _num(j['amountBs']) ?? 0,
      );
}

class CompanyStatement {
  const CompanyStatement({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.taxId,
    required this.period,
    required this.status,
    required this.lines,
    required this.adjustments,
    required this.tripCount,
    required this.subtotalBs,
    required this.discountPct,
    required this.discountBs,
    required this.adjustmentsBs,
    required this.totalBs,
    this.issuedAt,
    this.dueAt,
    this.paidAt,
    this.paymentReference,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String taxId;

  /// "2026-10"
  final String period;
  final StatementStatus status;
  final List<StatementLine> lines;
  final List<StatementAdjustment> adjustments;
  final int tripCount;
  final double subtotalBs;
  final double discountPct;
  final double discountBs;
  final double adjustmentsBs;
  final double totalBs;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final String? paymentReference;

  bool get isOverdue =>
      status == StatementStatus.issued &&
      dueAt != null &&
      dueAt!.isBefore(DateTime.now());

  /// "octubre 2026"
  String get periodLabel => periodName(period);

  factory CompanyStatement.fromDoc(String id, Map<String, dynamic> j) =>
      CompanyStatement(
        id: id,
        companyId: j['companyId'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        taxId: j['taxId'] as String? ?? '',
        period: j['period'] as String? ?? '',
        status: StatementStatusX.parse(j['status']),
        lines: (j['lines'] as List? ?? const [])
            .map((e) => StatementLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        adjustments: (j['adjustments'] as List? ?? const [])
            .map((e) =>
                StatementAdjustment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        tripCount: (j['tripCount'] as num?)?.toInt() ?? 0,
        subtotalBs: _num(j['subtotalBs']) ?? 0,
        discountPct: _num(j['discountPct']) ?? 0,
        discountBs: _num(j['discountBs']) ?? 0,
        adjustmentsBs: _num(j['adjustmentsBs']) ?? 0,
        totalBs: _num(j['totalBs']) ?? 0,
        issuedAt: _date(j['issuedAt']),
        dueAt: _date(j['dueAt']),
        paidAt: _date(j['paidAt']),
        paymentReference: j['paymentReference'] as String?,
      );

  /// Extracto en CSV (separador ";", como lo abre Excel en español).
  String toCsv() {
    String q(String v) => '"${v.replaceAll('"', '""')}"';
    final b = StringBuffer()
      ..writeln(
          'Fecha;Pasajero;Origen;Destino;Clase;Centro de coste;Importe Bs');
    for (final l in lines) {
      final d = l.date.toLocal();
      b.writeln([
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
        q(l.riderName),
        q(l.origin),
        q(l.destination),
        l.vehicleClass,
        q(l.costCenter),
        l.amountBs.toStringAsFixed(2),
      ].join(';'));
    }
    b
      ..writeln(';;;;;Subtotal;${subtotalBs.toStringAsFixed(2)}')
      ..writeln(';;;;;Descuento ${discountPct.toStringAsFixed(0)} %;'
          '-${discountBs.toStringAsFixed(2)}');
    for (final a in adjustments) {
      b.writeln(';;;;;${q(a.concept)};${a.amountBs.toStringAsFixed(2)}');
    }
    b.writeln(';;;;;Total;${totalBs.toStringAsFixed(2)}');
    return b.toString();
  }
}

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', //
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "2026-10" → "octubre 2026".
String periodName(String period) {
  final parts = period.split('-');
  if (parts.length != 2) return period;
  final m = int.tryParse(parts[1]) ?? 0;
  if (m < 1 || m > 12) return period;
  return '${_months[m - 1]} ${parts[0]}';
}

/// Mes en curso en Bolivia (UTC-4), formato "2026-10".
String currentPeriod([DateTime? now]) {
  final d = (now ?? DateTime.now()).toUtc().subtract(const Duration(hours: 4));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

/// Mes anterior a [period].
String previousPeriodOf(String period) {
  final y = int.parse(period.substring(0, 4));
  final m = int.parse(period.substring(5));
  return m == 1 ? '${y - 1}-12' : '$y-${(m - 1).toString().padLeft(2, '0')}';
}

/// Inicio y fin (excluido) de un mes en hora de Bolivia.
(DateTime, DateTime) periodRange(String period) {
  final y = int.parse(period.substring(0, 4));
  final m = int.parse(period.substring(5));
  final start = DateTime.utc(y, m).add(const Duration(hours: 4));
  final end = DateTime.utc(y, m + 1).add(const Duration(hours: 4));
  return (start, end);
}
