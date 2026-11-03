import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_flight_card.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_flights_tab.dart';

import 'flights_fakes.dart';

/// Panel, vuelos (B3): a 390 px con texto al 200 % (y a 768 y 1280 px) la
/// sección, la tarjeta y los diálogos se dibujan sin desbordes ni
/// excepciones; los botones miden al menos 48 px.
void main() {
  late FakeFlightsRepo repo;

  setUp(() {
    repo = FakeFlightsRepo();
    repo.inboxAnswer = Right(
      FlightInbox(
        truncated: true,
        items: [
          fakeFlightBooking(
            'verify0001',
            flight: fakeFlight(
              source: FlightSource.passenger,
              quality: FlightDataQuality.none,
              manualLock: true,
            ),
          ),
        ],
      ),
    );
    repo.airportsAnswer = Right([
      fakeAirport(domestic: kFakePoint),
    ]);
    repo.initial['b1'] = fakeFlightBooking(
      'b1',
      bookingStatus: BookingStatus.driverArrived,
      flight: fakeFlight(manualLock: true, source: FlightSource.manual),
    );
    repo.changeAnswer = Right(
      FlightManualChange(
        clearedLock: false,
        adminEmail: 'central-con-un-correo-largo@example.com',
        at: DateTime.utc(2026, 11, 20, 13),
        reason: 'Llamada a la aerolínea para confirmar la hora',
      ),
    );
  });

  void minTap(WidgetTester t, Finder f) {
    for (final e in f.evaluate()) {
      final size = t.getSize(find.byWidget(e.widget));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$e');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$e');
    }
  }

  for (final (width, scale) in [(390.0, 2.0), (768.0, 1.0), (1280.0, 1.0)]) {
    group('$width px, texto ×$scale', () {
      testWidgets('bandeja y aeropuertos', (t) async {
        await pumpPanel(
          t,
          FlightsTab(repository: repo),
          width: width,
          height: 900,
          textScale: scale,
        );
        expect(t.takeException(), isNull);
        expect(find.byKey(const ValueKey('flights-row-verify0001')),
            findsOneWidget);
        minTap(t, find.byKey(const ValueKey('flights-row-verify0001')));

        await t.tap(find.byKey(const ValueKey('flights-view-airports')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const ValueKey('airport-row-VVI')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.byKey(const ValueKey('airport-editor')), findsOneWidget);
        minTap(t, find.byKey(const ValueKey('airport-save')));
        minTap(t, find.byKey(const ValueKey('airport-domestic-remove')));
      });

      testWidgets('tarjeta y diálogos del vuelo', (t) async {
        await pumpPanel(
          t,
          SingleChildScrollView(
            child: AdminFlightCard(bookingId: 'b1', repository: repo),
          ),
          width: width,
          height: 900,
          textScale: scale,
        );
        expect(t.takeException(), isNull);
        for (final k in [
          'flight-set',
          'flight-clear-lock',
          'flight-force-no-show',
        ]) {
          minTap(t, find.byKey(ValueKey(k)));
        }

        final set = find.byKey(const ValueKey('flight-set'));
        await t.ensureVisible(set);
        await t.pumpAndSettle();
        await t.tap(set);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        minTap(t, find.byKey(const ValueKey('flight-set-actual')));
        minTap(t, find.byKey(const ValueKey('flight-set-confirm')));
        await t.tap(find.text('Cancelar'));
        await t.pumpAndSettle();

        final noShow = find.byKey(const ValueKey('flight-force-no-show'));
        await t.ensureVisible(noShow);
        await t.pumpAndSettle();
        await t.tap(noShow);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('flight-reason-dialog')),
          findsOneWidget,
        );
      });
    });
  }
}
