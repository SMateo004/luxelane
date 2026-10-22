import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';

void main() {
  group('BookingStatus.verified', () {
    test('va entre «llegó» e «en curso»', () {
      const order = BookingStatus.values;
      expect(order.indexOf(BookingStatus.verified),
          order.indexOf(BookingStatus.driverArrived) + 1);
      expect(order.indexOf(BookingStatus.inProgress),
          order.indexOf(BookingStatus.verified) + 1);
    });

    test('se guarda como "verified" y se lee igual', () {
      expect(BookingStatus.verified.label, 'verified');
      expect(BookingStatusX.fromString('verified'), BookingStatus.verified);
    });

    test('se muestra como «Verificada»', () {
      expect(BookingStatus.verified.displayLabel, 'Verificada');
    });

    test('cada estado tiene un nombre único y vuelve a sí mismo', () {
      final labels = BookingStatus.values.map((s) => s.label).toSet();
      expect(labels, hasLength(BookingStatus.values.length));
      for (final s in BookingStatus.values) {
        expect(BookingStatusX.fromString(s.label), s);
      }
    });
  });
}
