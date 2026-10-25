import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_finance_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:mocktail/mocktail.dart';

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<void> {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Auth extends Mock implements fb.FirebaseAuth {}

Booking _b(Map<String, dynamic> extra) => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.64, -63.13),
      },
      'status': 'cancelled',
      'estimatedPrice': 100,
      ...extra,
    });

/// B4–B6 en el panel: «no se presentó», recargo y motivo.
void main() {
  test('la reserva lee no_show y los campos de cancelación del servidor', () {
    final at = DateTime.utc(2026, 10, 25, 12, 15);
    final b = _b({
      'status': 'no_show',
      'noShowAvailableAt': Timestamp.fromDate(at),
      'lastRelease': {'driverId': 'd1', 'reason': 'vehicle_issue'},
    });
    expect(b.status, BookingStatus.noShow);
    expect(b.noShowAvailableAt!.isAtSameMomentAs(at), isTrue);
    expect(b.lastReleaseReason, 'vehicle_issue');
    final c = _b({
      'cancelledBy': 'rider',
      'cancellationReason': 'changed_plans',
      'cancellationFee': 30,
      'cancellationFeeBasis': 'late',
    });
    expect(c.hasCancellationFee, isTrue);
    expect(c.cancellationFee, 30);
    expect(_b({'cancellationFee': 0}).hasCancellationFee, isFalse);
  });

  test('central solo puede cancelar un no_show', () {
    expect(AdminOperations.nextStatuses(BookingStatus.noShow),
        [BookingStatus.cancelled]);
    expect(AdminOperations.isClosed(BookingStatus.noShow), isFalse);
  });

  testWidgets('detalle: recargo solo si es mayor que cero, con motivo y base',
      (t) async {
    Future<void> show(Booking b) => t.pumpWidget(
          MaterialApp(
            theme: luxTheme,
            home: Scaffold(body: Column(children: cancellationRows(b))),
          ),
        );
    await show(_b({
      'cancelledBy': 'rider',
      'cancellationReason': 'changed_plans',
      'cancellationFee': 30,
      'cancellationFeeBasis': 'late',
    }));
    expect(find.text('Pasajero'), findsOneWidget);
    expect(find.text('Cambié de planes'), findsOneWidget);
    expect(find.text('Recargo (anotado, no cobrado)'), findsOneWidget);
    expect(find.text('Tarde (aplica recargo)'), findsOneWidget);

    await show(_b({
      'cancelledBy': 'rider',
      'cancellationFee': 0,
      'cancellationFeeBasis': 'no_policy',
    }));
    expect(find.text('Recargo (anotado, no cobrado)'), findsNothing);
    expect(find.text('Sin política de cancelación'), findsOneWidget);

    await show(_b({'status': 'no_show'}));
    expect(find.textContaining('Pendiente de tu decisión'), findsOneWidget);
  });

  group('decisión tras «no se presentó»', () {
    late _Bloc bloc;
    setUpAll(() => registerFallbackValue(AdminDataRequested()));
    setUp(() {
      bloc = _Bloc();
      whenListen(bloc, const Stream<AdminState>.empty(),
          initialState: const AdminState());
    });

    Future<void> open(WidgetTester t, Booking b) async {
      t.view.physicalSize = const Size(1200, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: luxTheme,
          home: BlocProvider<AdminBloc>.value(
            value: bloc,
            child: Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () => noShowDecisionDialog(c, b),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
    }

    TextButton confirm(WidgetTester t) =>
        t.widget<TextButton>(find.byKey(const Key('no-show-confirm')));

    testWidgets('recargo con tope en el precio y motivo obligatorio',
        (t) async {
      final b = _b({'status': 'no_show'});
      await open(t, b);
      expect(confirm(t).onPressed, isNull);
      await t.enterText(
        find.byKey(const Key('no-show-reason')),
        'El pasajero no contestó llamadas',
      );
      await t.enterText(find.byKey(const Key('no-show-fee')), '150');
      await t.pump();
      expect(find.text('Entre 0 y 100.00'), findsOneWidget);
      expect(confirm(t).onPressed, isNull);
      await t.enterText(find.byKey(const Key('no-show-fee')), '25');
      await t.pump();
      await t.tap(find.byKey(const Key('no-show-confirm')));
      await t.pumpAndSettle();
      verify(
        () => bloc.add(
          AdminNoShowDecided(b, 25, 'El pasajero no contestó llamadas'),
        ),
      ).called(1);
    });
  });

  test('decideNoShow: adminUpdateBooking cancel con el recargo', () async {
    final functions = _Functions();
    final callable = _Callable();
    final repo =
        AdminRepositoryImpl(_Firestore(), auth: _Auth(), functions: functions);
    when(() => functions.httpsCallable(any())).thenReturn(callable);
    when(() => callable.call<void>(any())).thenAnswer((_) async => _Result());
    final r = await repo.decideNoShow(
      _b({'status': 'no_show'}),
      25,
      ' Sin respuesta del pasajero ',
    );
    expect(r.isRight(), isTrue);
    verify(() => functions.httpsCallable('adminUpdateBooking')).called(1);
    verify(
      () => callable.call<void>({
        'bookingId': 'b1',
        'action': 'cancel',
        'cancellationFee': 25.0,
        'reason': 'Sin respuesta del pasajero',
      }),
    ).called(1);
    expect(
      adminErrorMessage('failed-precondition', {
        'reason': 'fee_only_after_no_show',
      }),
      contains('no se presentó'),
    );
  });
}
