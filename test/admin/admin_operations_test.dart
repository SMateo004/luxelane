import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';

void main() {
  group('AdminOperations', () {
    test('el flujo normal avanza paso a paso hasta completado', () {
      const flow = [
        BookingStatus.confirmed,
        BookingStatus.driverArriving,
        BookingStatus.driverArrived,
        BookingStatus.inProgress,
        BookingStatus.completed,
      ];
      for (var i = 0; i < flow.length - 1; i++) {
        expect(AdminOperations.canTransition(flow[i], flow[i + 1]), isTrue,
            reason: '${flow[i]} → ${flow[i + 1]}');
      }
    });

    test('no se puede reabrir ni retroceder una reserva cerrada', () {
      for (final to in BookingStatus.values) {
        expect(AdminOperations.canTransition(BookingStatus.completed, to),
            isFalse);
        expect(AdminOperations.canTransition(BookingStatus.cancelled, to),
            isFalse);
      }
      expect(
          AdminOperations.canTransition(
              BookingStatus.inProgress, BookingStatus.pending),
          isFalse);
    });

    test('un viaje en curso no se cancela, se completa', () {
      expect(
          AdminOperations.canTransition(
              BookingStatus.inProgress, BookingStatus.cancelled),
          isFalse);
      expect(
          AdminOperations.canTransition(
              BookingStatus.pending, BookingStatus.cancelled),
          isTrue);
    });
  });
}
