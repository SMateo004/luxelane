import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/repositories/admin_repository.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_alerts_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_finance_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_pricing_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AdminRepository {}

final _now = DateTime.now();
const _place = Place(address: 'Av. Arce 2631, La Paz', lat: 0, lng: 0);

Booking _b(String id, BookingStatus s,
        {String? paymentId, String? review, bool pickupLocked = false}) =>
    Booking.fromJson({
      'pickupLocked': pickupLocked,
      'id': id,
      'riderId': 'u-rider',
      'driverId': s == BookingStatus.pending ? null : 'u-driver',
      'origin': _place.toJson(),
      'destination': _place.toJson(),
      'class': 'business',
      'serviceType': 'oneWay',
      'status': s.label,
      'estimatedPrice': 125.5,
      'paymentId': paymentId,
      if (review != null) 'pricingReview': {'reason': review},
    });

late _MockRepo _last;

AdminRepository _repo() {
  final r = _last = _MockRepo();
  final users = [
    User(
      id: 'u-rider',
      email: 'ana@example.com',
      phone: '',
      displayName: 'Ana Pérez',
      role: UserRole.rider,
      createdAt: _now,
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
    ),
    User(
      id: 'u-driver',
      email: 'luis@example.com',
      phone: '',
      displayName: 'Luis Mamani',
      role: UserRole.driver,
      createdAt: _now,
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
    ),
  ];
  when(() => r.bookingsLimit).thenReturn(1000);
  when(r.watchAllBookings).thenAnswer((_) => Stream.value([
        _b('booking-completed-1', BookingStatus.completed, paymentId: 'p1'),
        _b('booking-completed-2', BookingStatus.completed),
        _b('booking-pending', BookingStatus.pending, review: 'below_fare'),
        _b('booking-progress', BookingStatus.inProgress),
        _b('booking-cancelled', BookingStatus.cancelled),
        _b('booking-arrived', BookingStatus.driverArrived, pickupLocked: true),
      ]));
  when(() => r.watchBookingEvents(any())).thenAnswer((_) => Stream.value([
        BookingEvent.fromJson('e1', {
          'type': 'transition',
          'from': 'driver_arriving',
          'to': 'driver_arrived',
          'actor': {'uid': 'u-driver', 'role': 'driver'},
          'source': 'driver_app',
          'at': Timestamp.fromDate(_now),
          'appVersion': '2.0.0',
          'farFromPickup': true,
          'arrivalCheck': 'compared',
        }, {
          'lat': -17.64481,
          'lng': -63.13532,
          'distanceMeters': 850,
        }),
        BookingEvent.fromJson('e2', {
          'type': 'pickup_locked',
          'from': 'driver_arrived',
          'to': 'driver_arrived',
          'actor': {'uid': 'u-driver', 'role': 'driver'},
          'source': 'driver_app',
          'failedAttempts': 5,
        }),
      ]));
  when(() => r.forceVerify(any(), any()))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  when(r.watchAllPayments).thenAnswer((_) => Stream.value([
        Payment(
          id: 'p1',
          bookingId: 'booking-completed-1',
          riderId: 'u-rider',
          stripePaymentIntentId: 'pi',
          amount: 12550,
          currency: 'bob',
          status: PaymentStatus.captured,
          createdAt: _now,
        ),
      ]));
  when(r.watchAllUsers).thenAnswer((_) => Stream.value(users));
  when(r.watchAllDrivers).thenAnswer((_) => Stream.value([
        DriverProfile(
          userId: 'u-driver',
          licenseNumber: 'LP-1234',
          licenseExpiry: _now.add(const Duration(days: 300)),
          vehicleId: 'v1',
          documentsVerified: false,
          rating: 4.9,
          totalRides: 12,
          isAvailable: true,
        ),
      ]));
  when(r.watchPricingRules).thenAnswer((_) => Stream.value([
        PricingRule.unconfigured(VehicleClass.business, ServiceType.oneWay)
            .copyWith(
                basePriceUsd: 55,
                pricePerKmUsd: 3,
                minimumPriceUsd: 60,
                isActive: false),
      ]));
  when(r.watchAllVehicles).thenAnswer((_) => Stream.value(const []));
  when(r.watchAuditLogs).thenAnswer((_) => Stream.value([
        AuditLog(
          id: 'l1',
          adminId: 'u-admin',
          adminEmail: 'admin@luxelane.com',
          action: 'update_pricing',
          targetId: 'business_oneWay',
          targetType: 'pricing',
          details: 'Business Class · Solo ida',
          createdAt: _now,
        ),
      ]));
  when(r.watchAdminAlerts).thenAnswer((_) => Stream.value([
        AdminAlert(
          id: 'al1',
          type: 'distance_fallback',
          bookingId: 'booking-pending',
          message: 'Precio calculado con línea recta.',
          createdAt: _now,
        ),
        AdminAlert(
          id: 'al2',
          type: 'open_requests_reconciled',
          createdAt: _now.subtract(const Duration(hours: 1)),
          resolved: true,
        ),
      ]));
  when(() => r.resolveAlert(any(), note: any(named: 'note')))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  when(r.watchGlobalSettings)
      .thenAnswer((_) => Stream.value({'isMaintenanceMode': true}));
  when(r.watchFinanceSettings)
      .thenAnswer((_) => Stream.value({'platformCommissionPct': 20}));
  when(r.backfillSettlements)
      .thenAnswer((_) async => const Right<Failure, int>(2));
  when(() => r.updatePricingRule(any()))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  when(() => r.verifyDriver(any(),
          vehicleReviewed: any(named: 'vehicleReviewed'),
          vehicleNote: any(named: 'vehicleNote')))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  return r;
}

late AdminRepository _lastRepo;

Future<void> _pump(WidgetTester tester, Widget tab, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _lastRepo = _repo();
  final bloc = AdminBloc(adminRepository: _lastRepo)..add(AdminDataRequested());
  addTearDown(bloc.close);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: BlocProvider.value(value: bloc, child: tab),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(
      PricingRule.unconfigured(VehicleClass.business, ServiceType.oneWay)));

  const tabs = <String, Widget>{
    'panel': DashboardTab(),
    'operaciones': BookingsTab(),
    'finanzas': FinanceTab(),
    'tarifas': PricingTab(),
    'chóferes': DriversTab(),
    'vehículos': VehiclesTab(),
    'usuarios': UsersTab(),
    'auditoría': AuditTab(),
    'alertas': AlertsTab(),
    'configuración': SettingsTab(),
  };

  for (final size in const [Size(1280, 900), Size(390, 844)]) {
    for (final e in tabs.entries) {
      testWidgets('${e.key} se dibuja sin errores a ${size.width.toInt()}px',
          (tester) async {
        await _pump(tester, e.value, size);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('finanzas muestra cobrado y por cobrar', (tester) async {
    await _pump(tester, const FinanceTab(), const Size(1280, 2400));
    expect(find.text('Cobrado'), findsWidgets);
    expect(find.text('Por cobrar'), findsWidgets);
  });

  testWidgets('tarifas muestra todas las combinaciones', (tester) async {
    await _pump(tester, const PricingTab(), const Size(1280, 4000));
    expect(find.text('Personalizada'), findsOneWidget);
    expect(find.text('Desactivada'), findsOneWidget);
    // Todas las combinaciones salvo la personalizada: sin cifras de fábrica.
    expect(
        find.text('Sin configurar'),
        findsNWidgets(
            VehicleClass.values.length * ServiceType.values.length - 1));
  });

  testWidgets('alertas: lista por fecha, estado y marcar revisada',
      (tester) async {
    await _pump(tester, const AlertsTab(), const Size(1280, 900));
    expect(
        find.text('Precio con distancia aproximada  Reserva #BOOKIN',
            findRichText: true),
        findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Revisada'), findsOneWidget);
    // Solo la pendiente se puede marcar.
    expect(find.text('Marcar revisada'), findsOneWidget);
    await tester.tap(find.text('Marcar revisada'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Revisado con el chófer');
    await tester.tap(find.widgetWithText(FilledButton, 'Marcar revisada'));
    await tester.pumpAndSettle();
    verify(() => _lastRepo.resolveAlert('al1', note: 'Revisado con el chófer'))
        .called(1);
  });

  group('verificar chófer', () {
    Future<void> openDialog(WidgetTester tester) async {
      await _pump(tester, const DriversTab(), const Size(1280, 900));
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      expect(find.text('Vehículo revisado'), findsOneWidget);
    }

    testWidgets('sin la casilla verifica pero no activa el vehículo',
        (tester) async {
      await openDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Verificar'));
      await tester.pumpAndSettle();
      verify(() => _lastRepo.verifyDriver('u-driver',
          vehicleReviewed: false,
          vehicleNote: any(named: 'vehicleNote'))).called(1);
    });

    testWidgets('con la casilla y una nota, verifica y activa', (tester) async {
      await openDialog(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Sin golpes, ITV al día');
      await tester
          .tap(find.widgetWithText(FilledButton, 'Verificar y activar'));
      await tester.pumpAndSettle();
      verify(() => _lastRepo.verifyDriver('u-driver',
          vehicleReviewed: true,
          vehicleNote: 'Sin golpes, ITV al día')).called(1);
    });
  });

  testWidgets('el panel alerta de lo que requiere atención', (tester) async {
    await _pump(tester, const DashboardTab(), const Size(1280, 2400));
    expect(find.textContaining('mantenimiento activo'), findsOneWidget);
    expect(find.textContaining('fuera de tarifa'), findsOneWidget);
    expect(find.textContaining('sin verificar'), findsOneWidget);
  });

  testWidgets('editar y guardar una tarifa en móvil', (tester) async {
    await _pump(tester, const PricingTab(), const Size(390, 6000));
    // Primera tarjeta: Business Class · Solo ida.
    await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final perKm = find.widgetWithText(TextField, '3');
    await tester.enterText(perKm.first, '4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar tarifa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();

    final saved = verify(() => _last.updatePricingRule(captureAny()))
        .captured
        .single as PricingRule;
    expect(saved.pricePerKmUsd, 4);
    expect(saved.basePriceUsd, 55);
    expect(saved.isActive, isFalse);
  });

  testWidgets('asigna los repartos pendientes desde configuración',
      (tester) async {
    await _pump(tester, const SettingsTab(), const Size(1280, 2400));
    // Dos viajes completados de ejemplo, sin reparto del servidor.
    expect(find.textContaining('2 viajes completados sin reparto'),
        findsOneWidget);
    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar').last);
    await tester.pumpAndSettle();
    verify(_last.backfillSettlements).called(1);
    expect(tester.takeException(), isNull);
  });

  group('verificación en recogida (T6)', () {
    Future<void> open(WidgetTester tester, String id) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showBookingDetail(context, id),
            child: const Text('abrir'),
          ),
        ),
        const Size(1280, 2000),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('ficha: bloqueo, registro con ubicación y lejanía',
        (tester) async {
      await open(tester, 'booking-arrived');
      expect(find.text('Bloqueada: 5 códigos incorrectos'), findsOneWidget);
      // El registro va al final de la ficha.
      await tester.scrollUntilVisible(
          find.text('Verificación bloqueada tras 5 códigos incorrectos'), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('Registro del viaje'), findsOneWidget);
      expect(find.text('En camino → Chófer llegó'), findsOneWidget);
      expect(find.text('Lejos del punto de recogida (850 m)'), findsOneWidget);
      expect(find.text('Ubicación del chófer: -17.64481, -63.13532'),
          findsOneWidget);
      expect(find.text('Verificación bloqueada tras 5 códigos incorrectos'),
          findsOneWidget);
      // Desde el panel ya no se marca «En progreso» ni «Verificada».
      expect(find.textContaining('Marcar "En progreso"'), findsNothing);
      expect(find.textContaining('Marcar "Verificada"'), findsNothing);
    });

    testWidgets('«Forzar verificación» exige motivo y llama al servidor',
        (tester) async {
      await open(tester, 'booking-arrived');
      await tester.tap(find.text('Forzar verificación'));
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Forzar verificación');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'abc');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(
          find.byType(TextField).last, 'Pasajero sin batería');
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      verify(() =>
              _lastRepo.forceVerify('booking-arrived', 'Pasajero sin batería'))
          .called(1);
    });

    testWidgets('solo con el chófer en la recogida', (tester) async {
      await open(tester, 'booking-progress');
      expect(find.text('Forzar verificación'), findsNothing);
    });
  });
}
