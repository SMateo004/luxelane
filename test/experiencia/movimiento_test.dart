// Experiencia, A5 y Parte B: «reducir movimiento» y animaciones
// interrumpidas. Antes estaban en tools/experiencia/pruebas (fallaban: E1,
// E3, E10); pasan al corregirse.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/widgets/lux_feedback.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_step_action.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

final _now = DateTime(2026, 10, 25, 12);
final _driver = User(
  id: 'd1',
  email: 'd@example.com',
  phone: '',
  displayName: 'Luis',
  role: UserRole.driver,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);
DriverLoaded _loaded(int noticeSeq) => DriverLoaded(
      user: _driver,
      profile: DriverProfile(
        userId: 'd1',
        licenseNumber: 'L',
        licenseExpiry: DateTime(2030),
        vehicleId: 'v1',
        documentsVerified: true,
        rating: 5,
        totalRides: 0,
        isAvailable: false,
      ),
      isAvailable: false,
      bookings: const [],
      notice: noticeSeq == 0 ? null : 'Sin conexión: no se guardó el paso.',
      noticeSeq: noticeSeq,
    );

Widget _app(Widget child, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('SOS (E1): 2 s de pulsación siempre', () {
    Future<int> hold(
      WidgetTester t,
      Duration d, {
      bool platform = false,
      double dilation = 1,
    }) async {
      var n = 0;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: platform);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      timeDilation = dilation;
      await t.pumpWidget(
        _app(SosButton(onActivated: () => n++), reduce: platform),
      );
      final g = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('sos-button'))),
      );
      await t.pump();
      await t.pump(d);
      await g.up();
      await t.pump();
      // El arnés exige restaurarla dentro del cuerpo del test.
      timeDilation = 1;
      return n;
    }

    testWidgets('normal: 1 s no envía, 2,1 s sí', (t) async {
      expect(await hold(t, const Duration(seconds: 1)), 0);
      expect(await hold(t, const Duration(milliseconds: 2100)), 1);
    });

    testWidgets('con «quitar animaciones» del sistema: 200 ms ni 1,9 s envían',
        (t) async {
      expect(
        await hold(t, const Duration(milliseconds: 200), platform: true),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 1900), platform: true),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 2100), platform: true),
        1,
      );
    });

    testWidgets('con timeDilation 5: envía a los 2 s, no a los 10', (t) async {
      expect(
        await hold(t, const Duration(milliseconds: 1900), dilation: 5),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 2100), dilation: 5),
        1,
      );
    });
  });

  group('deslizar para confirmar (E3): si el paso falla, se puede repetir', () {
    Future<void> slide(WidgetTester t) async {
      // El gesto lo recoge el botón redondo; se arrastra por pasos, como un
      // dedo (un único salto no supera el reconocedor).
      final knob = find.descendant(
        of: find.byType(LuxSlideToConfirm),
        matching: find.byType(Icon),
      );
      final g = await t.startGesture(t.getCenter(knob.first));
      for (var i = 0; i < 40; i++) {
        await g.moveBy(const Offset(10, 0));
        await t.pump();
      }
      await g.up();
      await t.pumpAndSettle();
    }

    testWidgets('el control vuelve a empezar al cambiar resetToken', (t) async {
      var calls = 0;
      Widget w(int token) => _app(
            SizedBox(
              width: 320,
              child: LuxSlideToConfirm(
                label: 'He llegado',
                resetToken: token,
                onConfirmed: () => calls++,
              ),
            ),
          );
      await t.pumpWidget(w(0));
      await slide(t);
      await slide(t);
      expect(calls, 1, reason: 'ya confirmado: no repite sin señal');
      await t.pumpWidget(w(1));
      await slide(t);
      expect(calls, 2);
    });

    testWidgets('chófer: tras el aviso de fallo del bloc vuelve a deslizar',
        (t) async {
      final bloc = _MockDriverBloc();
      registerFallbackValue(const DriverArrivedAtPickup(bookingId: 'x'));
      whenListen(bloc, const Stream<DriverState>.empty(),
          initialState: _loaded(0));
      final booking = Booking(
        id: 'b1',
        riderId: 'ana',
        driverId: 'd1',
        origin: const Place(address: 'A', lat: 0, lng: 0),
        destination: const Place(address: 'B', lat: 0, lng: 0),
        scheduledAt: _now,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        status: BookingStatus.driverArriving,
        estimatedPrice: 100,
        createdAt: _now,
        updatedAt: _now,
      );
      Widget w() => MaterialApp(
            home: Scaffold(
              body: BlocProvider<DriverBloc>.value(
                value: bloc,
                child: SizedBox(
                  width: 360,
                  child: DriverStepAction(booking: booking),
                ),
              ),
            ),
          );
      await t.pumpWidget(w());
      await slide(t);
      verify(() => bloc.add(const DriverArrivedAtPickup(bookingId: 'b1')))
          .called(1);
      // El paso no se aplicó: el bloc avisa (noticeSeq sube) y la reserva
      // sigue en driver_arriving.
      when(() => bloc.state).thenReturn(_loaded(1));
      await t.pumpWidget(w());
      await t.pump();
      await slide(t);
      verify(() => bloc.add(const DriverArrivedAtPickup(bookingId: 'b1')))
          .called(1);
    });
  });
}
