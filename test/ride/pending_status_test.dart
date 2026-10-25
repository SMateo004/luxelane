import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/ride/presentation/widgets/pending_status.dart';

final _pickup = DateTime.utc(2026, 10, 25, 12, 45);

Booking _b({bool released = false}) => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'status': 'pending',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.7, -63.1)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.6, -63.1),
      },
      'estimatedPrice': 100,
      'scheduledAt': Timestamp.fromDate(_pickup),
      if (released) 'lastRelease': {'driverId': 'd1', 'reason': 'other'},
    });

/// 0.5: lo que lee el pasajero mientras su reserva busca chófer.
void main() {
  final before = _pickup.subtract(const Duration(minutes: 45));

  test('búsqueda normal: el mensaje de siempre, sin llamar a central', () {
    final s = pendingSituation(_b(), before);
    expect(s, PendingSituation.searching);
    expect(pendingMessage(s), startsWith('Estamos asignando a tu chófer'));
    expect(pendingNeedsDispatch(s), isFalse);
  });

  test('liberada a 45 min: explica que se busca otro y ofrece central', () {
    final s = pendingSituation(_b(released: true), before);
    expect(s, PendingSituation.driverReleased);
    expect(pendingMessage(s), contains('no pudo hacer el viaje'));
    expect(pendingNeedsDispatch(s), isTrue);
  });

  test('pasada la hora sin chófer: lo dice, aunque no la hayan liberado', () {
    for (final b in [_b(), _b(released: true)]) {
      final s = pendingSituation(b, _pickup.add(const Duration(minutes: 1)));
      expect(s, PendingSituation.pickupPassed);
      expect(pendingMessage(s), contains('Ya pasó la hora de recogida'));
      expect(pendingNeedsDispatch(s), isTrue);
    }
  });
}
