import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/lux_format.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/features/booking/data/airport_repository.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:luxelane/features/booking/presentation/widgets/flight_step_fields.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Pasajero: paso «Tu vuelo» (B4). Vuelos y aeropuertos FICTICIOS.
class _Airports implements AirportRepository {
  _Airports(this.value);
  final Airport? value;
  @override
  Stream<Airport?> watch(String code) => Stream.value(value);
}

Future<void> _pump(WidgetTester t, Widget w,
    {Locale locale = const Locale('es'),
    double scale = 1,
    double width = 390}) {
  L10n.use(locale);
  t.view.physicalSize = Size(width, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  return t.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: LuxLocale.supportedLocales,
    localizationsDelegates: LuxLocale.delegates,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: w)),
  ));
}

final _date = DateTime(2026, 11, 20);

void main() {
  group('número de vuelo (misma regla que el servidor)', () {
    test('normaliza sin ceros a la izquierda; todos ceros no vale', () {
      expect(FlightNumber.normalize('ob 0760'), 'OB760');
      expect(FlightNumber.normalize('Z8-0301'), 'Z8301');
      expect(FlightNumber.isValid('OB0760'), isTrue);
      expect(FlightNumber.isValid('OB0000'), isFalse);
    });
  });

  group('lo que se manda al servidor', () {
    test('FlightDraft → flight completo; si falta algo, nada', () {
      const draft = FlightDraft(airline: ' Aerolínea de prueba ');
      expect(
          draft.toRequest(
              airportCode: 'VVI', type: FlightType.domestic, number: 'zz0123'),
          isNull);
      final r = draft
          .copyWith(date: _date, time: const TimeOfDay(hour: 9, minute: 5))
          .toRequest(
              airportCode: 'VVI', type: FlightType.domestic, number: 'zz0123')!;
      expect(r.toJson(), {
        'airportCode': 'VVI',
        'flightType': 'domestic',
        'airline': 'Aerolínea de prueba',
        'flightNumber': 'ZZ123',
        'flightDate': '2026-11-20',
        'scheduledArrival': '09:05',
        'hasCheckedBag': true,
      });
    });

    test('quoteBooking y createBooking llevan flight; nunca readyAt ni estado',
        () {
      final now = DateTime(2026, 11, 19);
      final b = Booking(
        id: '',
        riderId: '',
        origin: const Place(address: 'Aeropuerto', lat: -17.64, lng: -63.13),
        destination: const Place(address: 'Centro', lat: -17.78, lng: -63.18),
        scheduledAt: now,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        status: BookingStatus.pending,
        estimatedPrice: 0,
        createdAt: now,
        updatedAt: now,
        flightRequest: FlightRequest(
          airportCode: 'VVI',
          flightType: FlightType.international,
          flightNumber: 'ZZ9',
          flightDate: _date,
          scheduledArrival: '23:50',
          hasCheckedBag: false,
        ),
      );
      for (final quote in [true, false]) {
        final data = bookingRequestData(b, quote: quote, requestId: 'r');
        expect((data['flight'] as Map)['scheduledArrival'], '23:50');
        expect((data['flight'] as Map)['hasCheckedBag'], false);
        expect(data.toString(), isNot(contains('readyAt')));
        expect((data['flight'] as Map).containsKey('status'), isFalse);
      }
    });

    test('la cotización trae readyAt y si falta el punto', () {
      final q = BookingQuote.fromJson({
        'price': 120,
        'readyAt': DateTime.utc(2026, 11, 20, 18, 25).millisecondsSinceEpoch,
        'pickupPointMissing': true,
      });
      expect(q.readyAt!.toUtc(), DateTime.utc(2026, 11, 20, 18, 25));
      expect(q.pickupPointMissing, isTrue);
    });

    test('errores del vuelo con texto propio en los tres idiomas', () {
      for (final l in const ['es', 'en', 'pt']) {
        L10n.use(Locale(l));
        final generic = bookingFailureFor('internal', null).message;
        for (final r in [
          'flight_config_missing',
          'airport_unknown',
          'flight_not_airport_pickup'
        ]) {
          final m =
              bookingFailureFor('failed-precondition', {'reason': r}).message;
          expect(m, isNot(generic), reason: '$l $r');
        }
      }
      L10n.use(const Locale('es'));
    });
  });

  testWidgets(
      'equipaje facturado: «con equipaje» por defecto y la ayuda sobria',
      (t) async {
    var draft = const FlightDraft();
    await _pump(
        t,
        StatefulBuilder(
          builder: (c, set) => FlightDetailsFields(
            draft: draft,
            onChanged: (d) => set(() => draft = d),
          ),
        ));
    final l = L10n.current;
    expect(
        t
            .widget<ChoiceChip>(find.byKey(const ValueKey('flight-bag-true')))
            .selected,
        isTrue);
    expect(find.text(l.bookingFlightCheckedBagHelp), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('flight-bag-false')));
    await t.pump();
    expect(draft.hasCheckedBag, isFalse);
  });

  testWidgets('sin fecha ni hora, avisa', (t) async {
    await _pump(
        t,
        FlightDetailsFields(
            draft: const FlightDraft(), onChanged: (_) {}, showErrors: true));
    expect(find.text(L10n.current.bookingFlightDateMissing), findsOneWidget);
    expect(find.text(L10n.current.bookingFlightTimeMissing), findsOneWidget);
  });

  testWidgets('punto del tipo de vuelo y la hora a la que estará el chófer',
      (t) async {
    final ready = DateTime(2026, 11, 20, 14, 25);
    await _pump(
        t,
        FlightPickupInfo(
          airportCode: 'VVI',
          flightType: FlightType.international,
          readyAt: ready,
          repository: _Airports(const Airport(
            code: 'VVI',
            name: 'Aeropuerto (prueba)',
            city: 'x',
            domestic: PickupPoint(
                name: 'Nacional (ficticia)', instructions: '', lat: 1, lng: 1),
            international: PickupPoint(
                name: 'Internacional (ficticia)',
                instructions: 'Puerta 3',
                lat: 1,
                lng: 1),
          )),
        ));
    await t.pumpAndSettle();
    expect(find.text('Internacional (ficticia)'), findsOneWidget);
    expect(find.text('Nacional (ficticia)'), findsNothing);
    expect(find.text(L10n.current.flightDriverWillBeAt(LuxFormat.time(ready))),
        findsOneWidget);
  });

  testWidgets('sin punto definido: por confirmar con central', (t) async {
    await _pump(
        t,
        FlightPickupInfo(
            airportCode: 'VVI',
            flightType: FlightType.domestic,
            readyAt: null,
            repository: _Airports(null)));
    await t.pumpAndSettle();
    expect(find.text(L10n.current.flightPickupPointPending), findsOneWidget);
  });

  group('en el viaje (estados del vuelo)', () {
    FlightInfo f(FlightStatus s, FlightDataQuality q) => FlightInfo(
          airportCode: 'VVI',
          flightType: FlightType.domestic,
          flightNumber: 'ZZ1',
          flightDate: '2026-11-20',
          scheduledArrival: DateTime(2026, 11, 20, 14),
          status: s,
          dataQuality: q,
          readyAt: DateTime(2026, 11, 20, 15, 5),
        );

    testWidgets('retrasado, sin datos y cancelado; según lo previsto, nada',
        (t) async {
      final l = L10n.current;
      await _pump(
          t,
          RiderFlightStatusNote(
              flight: f(FlightStatus.delayed, FlightDataQuality.ok)));
      expect(
          find.text(l.rideFlightDelayed(
              LuxFormat.time(DateTime(2026, 11, 20, 15, 5)))),
          findsOneWidget);
      await _pump(
          t,
          RiderFlightStatusNote(
              flight: f(FlightStatus.scheduled, FlightDataQuality.none)));
      expect(
          find.text(
              l.flightNoLiveData(LuxFormat.time(DateTime(2026, 11, 20, 14)))),
          findsOneWidget);
      await _pump(
          t,
          RiderFlightStatusNote(
              flight: f(FlightStatus.cancelled, FlightDataQuality.ok)));
      expect(find.text(l.rideFlightDisrupted), findsOneWidget);
      await _pump(
          t,
          RiderFlightStatusNote(
              flight: f(FlightStatus.scheduled, FlightDataQuality.ok)));
      expect(find.byKey(const ValueKey('rider-flight-note')), findsNothing);
    });
  });

  for (final w in [390.0, 768.0, 1280.0]) {
    for (final loc in const [Locale('es'), Locale('en'), Locale('pt')]) {
      testWidgets(
          'paso del vuelo sin desbordes a $w px, ${loc.languageCode}, texto al 200 %',
          (t) async {
        await _pump(
          t,
          Column(children: [
            FlightDetailsFields(
                draft: FlightDraft(
                    date: _date, time: const TimeOfDay(hour: 9, minute: 0)),
                onChanged: (_) {}),
            FlightPickupInfo(
                airportCode: 'VVI',
                flightType: FlightType.domestic,
                readyAt: DateTime(2026, 11, 20, 9, 25),
                repository: _Airports(null)),
          ]),
          locale: loc,
          scale: 2,
          width: w,
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('lector de pantalla: botones etiquetados y de 48 px', (t) async {
    final h = t.ensureSemantics();
    await _pump(
        t, FlightDetailsFields(draft: const FlightDraft(), onChanged: (_) {}));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
