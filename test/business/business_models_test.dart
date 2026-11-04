import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/business/domain/business_models.dart';

void main() {
  test('periodos en hora de Bolivia', () {
    expect(periodName('2026-10'), 'octubre 2026');
    expect(previousPeriodOf('2027-01'), '2026-12');
    // 23:30 del 31 en La Paz = 03:30 UTC del día 1: sigue siendo octubre.
    expect(currentPeriod(DateTime.utc(2026, 11, 1, 3, 30)), '2026-10');
    final (start, end) = periodRange('2026-10');
    expect(start, DateTime.utc(2026, 10, 1, 4));
    expect(end, DateTime.utc(2026, 11, 1, 4));
  });

  test('extracto: estado vencido y CSV con totales', () {
    final s = CompanyStatement.fromDoc('acme_2026-10', {
      'companyId': 'acme',
      'companyName': 'Acme',
      'taxId': '123',
      'period': '2026-10',
      'status': 'issued',
      'lines': [
        {
          'bookingId': 'b1',
          'dateMs': DateTime.utc(2026, 10, 5, 15).millisecondsSinceEpoch,
          'riderName': 'Luis "Lucho" Rojas',
          'origin': 'Equipetrol',
          'destination': 'VVI',
          'vehicleClass': 'business',
          'costCenter': 'Ventas',
          'amountBs': 108,
        },
      ],
      'adjustments': [
        {'id': 'a', 'concept': 'Peaje', 'amountBs': 30},
      ],
      'tripCount': 1,
      'subtotalBs': 108,
      'discountPct': 10,
      'discountBs': 10.8,
      'adjustmentsBs': 30,
      'totalBs': 127.2,
    });
    expect(s.periodLabel, 'octubre 2026');
    expect(s.isOverdue, isFalse); // sin fecha de vencimiento
    final csv = s.toCsv().split('\n');
    expect(csv.first, startsWith('Fecha;Pasajero'));
    expect(csv[1], contains('"Luis ""Lucho"" Rojas"'));
    expect(csv[1], endsWith('108.00'));
    expect(s.toCsv(), contains('Total;127.20'));
  });
}
