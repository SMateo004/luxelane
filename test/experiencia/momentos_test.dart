import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/ride/presentation/ride_moments.dart';

/// E31: la llegada no vibraba, el código verificado y el fin del viaje no
/// tenían ninguna confirmación para el pasajero.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('qué momento toca en cada cambio de estado', () {
    expect(
      rideMomentFor(BookingStatus.driverArriving, BookingStatus.driverArrived),
      RideMoment.arrived,
    );
    expect(
      rideMomentFor(BookingStatus.driverArrived, BookingStatus.verified),
      RideMoment.verified,
    );
    expect(
      rideMomentFor(BookingStatus.inProgress, BookingStatus.completed),
      RideMoment.completed,
    );
    // Al abrir la pantalla o sin cambio: nada.
    expect(rideMomentFor(null, BookingStatus.completed), isNull);
    expect(
      rideMomentFor(BookingStatus.verified, BookingStatus.verified),
      isNull,
    );
    expect(
      rideMomentFor(BookingStatus.verified, BookingStatus.inProgress),
      isNull,
    );
  });

  test('cada momento tiene su háptica', () async {
    final calls = <String?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') {
        calls.add(c.arguments as String?);
      }
      return null;
    });
    for (final m in RideMoment.values) {
      playRideMoment(m);
    }
    await pumpEventQueue();
    expect(calls, hasLength(3));
  });
}
