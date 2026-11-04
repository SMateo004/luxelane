import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

/// Ventana del chófer, B2: la X que cierra el detalle de la reserva del
/// panel tiene nombre (tooltip y etiqueta para el lector de pantalla).
/// Datos FICTICIOS.
void main() {
  late _Bloc bloc;

  setUp(() {
    bloc = _Bloc();
    whenListen(
      bloc,
      const Stream<AdminState>.empty(),
      initialState: AdminState(bookings: [
        Booking.fromJson({
          'id': 'b2',
          'riderId': 'ana',
          'origin': {
            'address': 'Origen (prueba)',
            'coordinates': const GeoPoint(-17.78, -63.18),
          },
          'destination': {
            'address': 'Destino (prueba)',
            'coordinates': const GeoPoint(-17.76, -63.19),
          },
          'status': 'confirmed',
          'estimatedPrice': 100,
        }),
      ]),
    );
    when(() => bloc.bookingEvents(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1280, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: luxTheme,
      locale: const Locale('es'),
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      home: BlocProvider<AdminBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showBookingDetail(c, 'b2'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
  }

  testWidgets('la X tiene tooltip y etiqueta «Cerrar», y cierra el detalle',
      (t) async {
    final h = t.ensureSemantics();
    await open(t);
    expect(find.text('Reserva #B2'), findsOneWidget);
    expect(find.byTooltip(L10n.current.commonClose), findsOneWidget);
    final close = find.byKey(const ValueKey('booking-detail-close'));
    expect(
      t.getSemantics(close),
      containsSemantics(
          tooltip: L10n.current.commonClose,
          isButton: true,
          hasTapAction: true),
    );
    await t.tap(close);
    await t.pumpAndSettle();
    expect(find.text('Reserva #B2'), findsNothing);
    h.dispose();
  });

  testWidgets('ningún botón del detalle queda sin nombre', (t) async {
    final h = t.ensureSemantics();
    await open(t);
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
