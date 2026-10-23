import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/ride/presentation/pages/ride_screen.dart';

void main() {
  group('«Llamar a tu chófer» (D16)', () {
    test(
      'solo aparece de driver_arriving a in_progress (verified incluido)',
      () {
        for (final s in BookingStatus.values) {
          expect(
            showCallDriver(s, '+59170000555'),
            kDriverLiveStatuses.contains(s),
            reason: s.name,
          );
        }
        expect(kDriverLiveStatuses, {
          BookingStatus.driverArriving,
          BookingStatus.driverArrived,
          BookingStatus.verified,
          BookingStatus.inProgress,
        });
      },
    );

    test('nunca en el historial ni al valorar, ni sin teléfono', () {
      expect(showCallDriver(BookingStatus.completed, '+59170000555'), isFalse);
      expect(showCallDriver(BookingStatus.cancelled, '+59170000555'), isFalse);
      expect(showCallDriver(BookingStatus.inProgress, null), isFalse);
      expect(showCallDriver(BookingStatus.inProgress, ''), isFalse);
    });
  });
}
