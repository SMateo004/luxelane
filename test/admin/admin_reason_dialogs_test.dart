import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_finance_tab.dart';
import 'package:mocktail/mocktail.dart';

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

Booking _completed() => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.64, -63.13),
      },
      'status': 'completed',
      'estimatedPrice': 100,
    });

/// Parte A: cobrar y corregir piden un motivo de al menos 10 caracteres,
/// que viaja al servidor y queda en la auditoría.
void main() {
  late _Bloc bloc;

  setUpAll(() => registerFallbackValue(AdminDataRequested()));
  setUp(() {
    bloc = _Bloc();
    whenListen(bloc, const Stream<AdminState>.empty(),
        initialState: const AdminState());
  });

  Future<void> open(
      WidgetTester t, Future<void> Function(BuildContext) f) async {
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
                onPressed: () => f(c),
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

  testWidgets(
      'registrar cobro: sin motivo no se puede; con motivo, al servidor',
      (t) async {
    await open(t, (c) => recordPaymentDialog(c, _completed()));
    final button = find.widgetWithText(TextButton, 'Registrar cobro');
    expect(t.widget<TextButton>(button).onPressed, isNull);
    await t.tap(find.text('QR'));
    await t.enterText(find.byKey(const Key('record-reason')), 'corto');
    await t.pumpAndSettle();
    expect(t.widget<TextButton>(button).onPressed, isNull);
    await t.enterText(
      find.byKey(const Key('record-reason')),
      'Pagó con QR al llegar',
    );
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    final e = verify(() => bloc.add(captureAny())).captured.single
        as AdminRecordPaymentRequested;
    expect(e.method, 'qr');
    expect(e.reason, 'Pagó con QR al llegar');
  });

  testWidgets('corregir cobro: importe y motivo', (t) async {
    final p = Payment.fromJson({
      'id': 'p1',
      'bookingId': 'b1',
      'amount': 10000,
      'status': 'captured',
    });
    await open(t, (c) => correctPaymentDialog(c, p));
    await t.enterText(find.byKey(const Key('correct-amount')), '90');
    await t.enterText(
      find.byKey(const Key('correct-reason')),
      'Importe mal anotado al cerrar',
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar corrección'));
    await t.pumpAndSettle();
    final e = verify(() => bloc.add(captureAny())).captured.single
        as AdminCorrectPaymentRequested;
    expect(e.payment.id, 'p1');
    expect(e.amountBs, 90);
    expect(e.method, isNull);
    expect(e.reason, 'Importe mal anotado al cerrar');
  });
}
