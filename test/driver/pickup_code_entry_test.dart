import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/remote_flags.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_step_action.dart';
import 'package:luxelane/features/driver/presentation/widgets/pickup_code_entry.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

Future<void> _type(WidgetTester tester, String code) async {
  for (final d in code.split('')) {
    await tester.tap(find.byKey(ValueKey('key-$d')));
    await tester.pump();
  }
}

Booking _booking(BookingStatus status, {bool locked = false}) =>
    Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'driverId': 'chofer',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.6, -63.1)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.7, -63.2),
      },
      'status': status.label,
      'pickupLocked': locked,
    });

void main() {
  group('PickupCodeEntry', () {
    testWidgets('teclado numérico: 4 dígitos se envían y verifican', (
      tester,
    ) async {
      String? sent;
      var verified = false;
      await _pump(
        tester,
        PickupCodeEntry(
          onVerify: (c) async {
            sent = c;
            return const Right(null);
          },
          onVerified: () => verified = true,
        ),
      );
      await _type(tester, '4290');
      await tester.tap(find.byKey(const ValueKey('key-⌫')));
      await tester.pump();
      expect(sent, '4290');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pasajero verificado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(verified, isTrue);
    });

    testWidgets('«Borrar» corrige antes de completar', (tester) async {
      String? sent;
      await _pump(
        tester,
        PickupCodeEntry(
          onVerify: (c) async {
            sent = c;
            return const Right(null);
          },
        ),
      );
      await _type(tester, '12');
      await tester.tap(find.byKey(const ValueKey('key-⌫')));
      await tester.pump();
      await _type(tester, '345');
      expect(sent, '1345');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('incorrecto: aviso con intentos y vuelve a pedir el código', (
      tester,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        PickupCodeEntry(
          onVerify: (c) async {
            calls.add(c);
            return Left(
              tripFailureFor('failed-precondition', {
                'reason': 'wrong_code',
                'attemptsLeft': 3,
              }),
            );
          },
        ),
      );
      await _type(tester, '1111');
      await tester.pumpAndSettle();
      expect(
        find.text('Código incorrecto. Te quedan 3 intentos.'),
        findsOneWidget,
      );
      expect(find.text('1'), findsOneWidget); // solo la tecla, no los cuadros
      await _type(tester, '2222');
      await tester.pumpAndSettle();
      expect(calls, ['1111', '2222']);
    });

    testWidgets(
      'bloqueado: «Contacta con central» y sin teclado; sin número no hay botón',
      (tester) async {
        await _pump(
          tester,
          PickupCodeEntry(
            onVerify:
                (_) async => Left(
                  tripFailureFor('failed-precondition', {
                    'reason': 'pickup_locked',
                  }),
                ),
          ),
        );
        await _type(tester, '1111');
        await tester.pumpAndSettle();
        expect(find.text('Contacta con central'), findsOneWidget);
        expect(find.byKey(const ValueKey('key-1')), findsNothing);
        expect(find.text('Llamar a central'), findsNothing);
      },
    );

    testWidgets('con dispatchPhone configurado se ofrece llamar a central', (
      tester,
    ) async {
      String? called;
      await _pump(
        tester,
        PickupCodeEntry(
          locked: true,
          dispatchPhone: '+00000000',
          onCallDispatch: (p) => called = p,
          onVerify: (_) async => const Right(null),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Llamar a central'));
      expect(called, '+00000000');
    });

    testWidgets('vencido: también pide contactar con central', (tester) async {
      await _pump(
        tester,
        PickupCodeEntry(
          onVerify:
              (_) async => Left(
                tripFailureFor('failed-precondition', {
                  'reason': 'code_expired',
                }),
              ),
        ),
      );
      await _type(tester, '1234');
      await tester.pumpAndSettle();
      expect(find.text('Contacta con central'), findsOneWidget);
      expect(find.textContaining('venció'), findsOneWidget);
    });

    testWidgets('sin red: conserva el código y «Reintentar» lo reenvía', (
      tester,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        PickupCodeEntry(
          onVerify: (c) async {
            calls.add(c);
            return calls.length == 1
                ? const Left(TripFailure(TripIssue.network, 'Sin conexión.'))
                : const Right(null);
          },
        ),
      );
      await _type(tester, '5678');
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['5678', '5678']);
      expect(find.text('Pasajero verificado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('DriverStepAction', () {
    testWidgets('llegó: se pide el código; no hay deslizar para iniciar', (
      tester,
    ) async {
      Booking? opened;
      await _pump(
        tester,
        DriverStepAction(
          booking: _booking(BookingStatus.driverArrived),
          openCodeEntry: (_, b) async => opened = b,
        ),
      );
      expect(find.text('Iniciar viaje'), findsNothing);
      await tester.tap(find.text('Ingresar código del pasajero'));
      expect(opened?.id, 'b1');
    });

    testWidgets('verificada: aparece «Iniciar viaje» para deslizar', (
      tester,
    ) async {
      await _pump(
        tester,
        DriverStepAction(booking: _booking(BookingStatus.verified)),
      );
      expect(find.text('Iniciar viaje'), findsOneWidget);
      expect(find.text('Ingresar código del pasajero'), findsNothing);
    });

    testWidgets('bloqueada: sin código ni inicio; central solo con número', (
      tester,
    ) async {
      RemoteFlags.instance.dispatchPhone.value = null;
      await _pump(
        tester,
        DriverStepAction(
          booking: _booking(BookingStatus.driverArrived, locked: true),
        ),
      );
      expect(find.text('Ingresar código del pasajero'), findsNothing);
      expect(find.text('Llamar a central'), findsNothing);
      RemoteFlags.instance.dispatchPhone.value = '+00000000';
      await tester.pump();
      expect(find.text('Llamar a central'), findsOneWidget);
      RemoteFlags.instance.dispatchPhone.value = null;
    });

    test('los pasos y sus textos', () {
      expect(DriverStepAction.slideLabel(BookingStatus.driverArrived), isNull);
      expect(
        DriverStepAction.slideLabel(BookingStatus.verified),
        'Iniciar viaje',
      );
      expect(
        DriverStepAction.slideLabel(BookingStatus.inProgress),
        'Completar viaje',
      );
      expect(
        DriverStepAction.message(_booking(BookingStatus.inProgress)),
        contains('Viaje en curso'),
      );
    });
  });

  test('dispatchPhone solo si hay un texto no vacío', () {
    expect(dispatchPhoneFrom({}), isNull);
    expect(dispatchPhoneFrom({'dispatchPhone': '  '}), isNull);
    expect(dispatchPhoneFrom({'dispatchPhone': 7}), isNull);
    expect(dispatchPhoneFrom({'dispatchPhone': ' +000 '}), '+000');
  });

  test('app_update_required del servidor: aviso de la app del chófer', () {
    final f = tripFailureFor('failed-precondition', {
      'reason': 'app_update_required',
      'androidStoreUrl': 'https://example.com/app',
      'iosStoreUrl': 'http://inseguro',
    });
    expect(f, isA<AppUpdateRequiredFailure>());
    f as AppUpdateRequiredFailure;
    expect(f.forDriver, isTrue);
    expect(f.androidStoreUrl, 'https://example.com/app');
    expect(f.iosStoreUrl, isNull);
  });
}
