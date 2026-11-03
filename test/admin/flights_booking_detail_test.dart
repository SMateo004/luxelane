import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:mocktail/mocktail.dart';

import 'flights_fakes.dart';

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

/// Panel, vuelos (B3): el detalle de la reserva (Operaciones) lleva la
/// tarjeta «Vuelo» cuando la recogida es en un aeropuerto.
void main() {
  late FakeFlightsRepo repo;
  late _Bloc bloc;

  Booking booking(String id, {String? airport}) => Booking.fromJson({
        'id': id,
        'riderId': 'ana',
        'origin': {
          'address': 'Aeropuerto de prueba',
          'coordinates': const GeoPoint(-17.64, -63.13),
        },
        'destination': {
          'address': 'Hotel de prueba',
          'coordinates': const GeoPoint(-17.78, -63.18),
        },
        'status': 'confirmed',
        'estimatedPrice': 100,
        if (airport != null) 'pickupAirport': airport,
        if (airport != null) 'flightNumber': 'OB760',
      });

  setUp(() {
    repo = FakeFlightsRepo();
    sl.registerSingleton<FlightsAdminRepository>(repo);
    bloc = _Bloc();
    whenListen(
      bloc,
      const Stream<AdminState>.empty(),
      initialState: AdminState(
        bookings: [booking('b1', airport: 'VVI'), booking('b2')],
      ),
    );
    when(() => bloc.bookingEvents(any()))
        .thenAnswer((_) => const Stream.empty());
  });
  tearDown(() => sl.unregister<FlightsAdminRepository>());

  Future<void> open(WidgetTester t, String id) async {
    t.view.physicalSize = const Size(1280, 2400);
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
                onPressed: () => showBookingDetail(c, id),
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

  testWidgets('recogida en aeropuerto: tarjeta del vuelo', (t) async {
    repo.initial['b1'] = fakeFlightBooking('b1');
    repo.changeAnswer = const Right(null);
    await open(t, 'b1');
    expect(find.byKey(const ValueKey('flight-card')), findsOneWidget);
    expect(find.text('El chófer debe estar a las 14:35'), findsOneWidget);
  });

  testWidgets('sin aeropuerto: sin tarjeta', (t) async {
    await open(t, 'b2');
    expect(find.text('Reserva #B2'), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-card')), findsNothing);
  });
}
