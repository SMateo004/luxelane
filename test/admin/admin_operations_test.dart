import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';

void main() {
  group('AdminOperations', () {
    test(
      'el panel avanza confirmada → en camino → llegó, pero no verifica',
      () {
        expect(
          AdminOperations.canTransition(
            BookingStatus.confirmed,
            BookingStatus.driverArriving,
          ),
          isTrue,
        );
        expect(
          AdminOperations.canTransition(
            BookingStatus.driverArriving,
            BookingStatus.driverArrived,
          ),
          isTrue,
        );
        expect(
          AdminOperations.canTransition(
            BookingStatus.inProgress,
            BookingStatus.completed,
          ),
          isTrue,
        );
      },
    );

    test('verificada y en curso nunca se fijan desde el panel', () {
      for (final from in BookingStatus.values) {
        expect(
          AdminOperations.canTransition(from, BookingStatus.verified),
          isFalse,
          reason: '$from → verified',
        );
        expect(
          AdminOperations.canTransition(from, BookingStatus.inProgress),
          isFalse,
          reason: '$from → inProgress',
        );
      }
    });

    test('forzar verificación solo con el chófer en la recogida', () {
      for (final s in BookingStatus.values) {
        final b = _booking(s);
        expect(
          AdminOperations.canForceVerify(b),
          s == BookingStatus.driverArrived,
          reason: '$s',
        );
      }
    });

    test('una reserva verificada ocupa al chófer y se puede cancelar', () {
      expect(AdminOperations.isActive(BookingStatus.verified), isTrue);
      expect(
        AdminOperations.canTransition(
          BookingStatus.verified,
          BookingStatus.cancelled,
        ),
        isTrue,
      );
      expect(_booking(BookingStatus.verified).occupiesDriver(), isTrue);
    });

    test('no se puede reabrir ni retroceder una reserva cerrada', () {
      for (final to in BookingStatus.values) {
        expect(
          AdminOperations.canTransition(BookingStatus.completed, to),
          isFalse,
        );
        expect(
          AdminOperations.canTransition(BookingStatus.cancelled, to),
          isFalse,
        );
      }
      expect(
        AdminOperations.canTransition(
          BookingStatus.inProgress,
          BookingStatus.pending,
        ),
        isFalse,
      );
    });

    test('un viaje en curso no se cancela, se completa', () {
      expect(
        AdminOperations.canTransition(
          BookingStatus.inProgress,
          BookingStatus.cancelled,
        ),
        isFalse,
      );
      expect(
        AdminOperations.canTransition(
          BookingStatus.pending,
          BookingStatus.cancelled,
        ),
        isTrue,
      );
    });
  });
}

Booking _booking(BookingStatus status) => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.64, -63.13),
      },
      'status': status.label,
    });
