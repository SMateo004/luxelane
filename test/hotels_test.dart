import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/hotels/data/hotel_repository.dart';
import 'package:luxelane/features/hotels/domain/partner_hotel.dart';
import 'package:luxelane/features/hotels/presentation/hotel_transfers_page.dart';
import 'package:luxelane/features/hotels/presentation/hotels_admin_tab.dart';
import 'package:luxelane/l10n/l10n.dart';

import 'helpers/l10n.dart';

const _tajibos = PartnerHotel(
  id: 'tajibos',
  name: 'Los Tajibos',
  address: 'Av. San Martín 455, Santa Cruz',
  lat: -17.7600,
  lng: -63.1960,
  meetingPoint: 'Lobby principal',
);
const _marriott = PartnerHotel(
  id: 'marriott',
  name: 'Marriott',
  address: 'Av. Busch, Santa Cruz',
  lat: -17.77,
  lng: -63.18,
  active: false,
);

class _FakeRepo implements HotelRepository {
  _FakeRepo(this.hotels);
  final List<PartnerHotel> hotels;
  final calls = <String>[];

  @override
  Stream<List<PartnerHotel>> watchActive() => Stream.value(hotels.where((h) => h.active).toList());
  @override
  Stream<List<PartnerHotel>> watchAll() => Stream.value(hotels);
  @override
  Future<void> save(PartnerHotel hotel) async => calls.add('save:${hotel.id}:${hotel.name}:${hotel.meetingPoint}');
  @override
  Future<void> setActive(String id, bool active) async => calls.add('active:$id:$active');
}

/// Router app so the form can navigate to /booking; captures the extra.
Widget _routerApp(Widget page, void Function(BookingFormData) onBooking) => MaterialApp.router(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => page),
        GoRoute(
          path: '/booking',
          builder: (_, s) {
            onBooking(s.extra! as BookingFormData);
            return const Scaffold(body: Text('booking'));
          },
        ),
      ]),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!sl.isRegistered<MapsService>()) sl.registerLazySingleton(MapsService.new);
  });

  group('HotelTransfers', () {
    test('link opens the page with the hotel chosen', () {
      expect(HotelTransfers.link('https://luxelane.bo/', 'tajibos'), 'https://luxelane.bo/servicios/hoteles?h=tajibos');
    });

    test('validation mirrors the rules', () {
      const p = Place(address: 'x', lat: -17.7, lng: -63.1);
      expect(HotelTransfers.validate(name: 'Los Tajibos', place: p), isNull);
      expect(HotelTransfers.validate(name: ' ', place: p), 'hotel/name');
      expect(HotelTransfers.validate(name: 'A' * 81, place: p), 'hotel/name');
      expect(HotelTransfers.validate(name: 'Hotel', place: null), 'hotel/place');
      expect(HotelTransfers.validate(name: 'Hotel', place: p, meetingPoint: 'x' * 121), 'hotel/meeting-point');
    });

    test('route by direction', () {
      final (o1, d1) = HotelTransfers.route(_tajibos, HotelTransferDirection.toAirport);
      expect((o1.name, d1.name), ('Los Tajibos', HotelTransfers.airport.name));
      final (o2, d2) = HotelTransfers.route(_tajibos, HotelTransferDirection.fromAirport);
      expect((o2.name, d2.name), (HotelTransfers.airport.name, 'Los Tajibos'));
    });

    test('json round trip', () {
      final h = PartnerHotel.fromJson('tajibos', _tajibos.toJson());
      expect((h.name, h.meetingPoint, h.active, h.lat), ('Los Tajibos', 'Lobby principal', true, -17.76));
    });
  });

  group('HotelTransfersPage', () {
    testWidgets('says partner hotels are coming when there are none', (tester) async {
      await tester.pumpWidget(localizedApp(HotelTransfersPage(repository: _FakeRepo(const []))));
      await tester.pumpAndSettle();
      expect(find.text('Pronto anunciaremos nuestros hoteles aliados'), findsOneWidget);
      expect(find.text('Seguimiento de vuelo'), findsOneWidget);
    });

    for (final size in const [Size(360, 2000), Size(1280, 1400)]) {
      testWidgets('lists active hotels and books to the airport (${size.width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        BookingFormData? booked;
        await tester.pumpWidget(_routerApp(
          HotelTransfersPage(repository: _FakeRepo(const [_tajibos, _marriott]), routeLookup: (_, __) async => null),
          (d) => booked = d,
        ));
        await tester.pumpAndSettle();
        expect(find.text('Los Tajibos'), findsOneWidget);
        expect(find.text('Marriott'), findsNothing); // hidden
        expect(find.text('Punto de encuentro: Lobby principal'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Al aeropuerto'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Recogida:'), findsOneWidget);
        await tester.tap(find.text('VER VEHÍCULOS Y PRECIO'));
        await tester.pumpAndSettle();
        expect(booked!.origin.name, 'Los Tajibos');
        expect(booked!.destination!.name, HotelTransfers.airport.name);
        expect(booked!.pickupNote, 'Lobby principal');
      });
    }

    testWidgets('a hotel link opens its form; from the airport has no meeting note', (tester) async {
      BookingFormData? booked;
      await tester.pumpWidget(_routerApp(
        HotelTransfersPage(
          initialHotelId: 'tajibos',
          repository: _FakeRepo(const [_tajibos]),
          routeLookup: (_, __) async => null,
        ),
        (d) => booked = d,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(HotelTransferForm), findsOneWidget);
      await tester.tap(find.text('Desde el aeropuerto').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Llegada del vuelo:'), findsOneWidget);
      expect(find.textContaining('60 min'), findsWidgets);
      await tester.tap(find.text('VER VEHÍCULOS Y PRECIO'));
      await tester.pumpAndSettle();
      expect(booked!.origin.name, HotelTransfers.airport.name);
      expect(booked!.pickupNote, isEmpty);
    });

    testWidgets('English copy', (tester) async {
      await tester.pumpWidget(
          localizedApp(HotelTransfersPage(repository: _FakeRepo(const [_tajibos])), locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('From hotel to airport, without a second thought'), findsOneWidget);
      expect(find.text('To the airport'), findsOneWidget);
    });
  });

  group('HotelsAdminTab', () {
    for (final width in const [390.0, 1280.0]) {
      testWidgets('lists hotels with their link and toggles visibility (${width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = Size(width, 1200)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _FakeRepo(const [_tajibos, _marriott]);
        await tester.pumpWidget(
            localizedApp(Scaffold(body: HotelsAdminTab(repository: repo, baseUrl: 'https://luxelane.bo'))));
        await tester.pumpAndSettle();
        expect(find.text('https://luxelane.bo/servicios/hoteles?h=tajibos'), findsOneWidget);
        expect(find.text('Visible'), findsOneWidget);
        expect(find.text('Oculto'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(Switch).last);
        await tester.pumpAndSettle();
        expect(repo.calls, ['active:marriott:true']);
      });
    }

    testWidgets('edit dialog validates and saves', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(const [_tajibos]);
      await tester.pumpWidget(localizedApp(Scaffold(body: HotelsAdminTab(repository: repo, baseUrl: 'x'))));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextField, 'Nombre del hotel');
      await tester.enterText(name, '');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa el nombre del hotel (hasta 80 caracteres).'), findsOneWidget);
      await tester.enterText(name, 'Los Tajibos Hotel');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['save:tajibos:Los Tajibos Hotel:Lobby principal']);
    });
  });
}
