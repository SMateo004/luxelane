import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/repositories/admin_repository.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_finance_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_pricing_tab.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AdminRepository {}

final _now = DateTime.now();
const _place = Place(address: 'Av. Arce 2631, La Paz', lat: 0, lng: 0);

Booking _b(String id, BookingStatus s, {String? paymentId, String? review}) =>
    Booking.fromJson({
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
      ]));
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
        PricingRule.fallback(VehicleClass.business, ServiceType.oneWay)
            .copyWith(basePriceUsd: 55, isActive: false),
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
  when(r.watchGlobalSettings)
      .thenAnswer((_) => Stream.value({'isMaintenanceMode': true}));
  when(r.watchFinanceSettings)
      .thenAnswer((_) => Stream.value({'platformCommissionPct': 20}));
  when(r.backfillSettlements)
      .thenAnswer((_) async => const Right<Failure, int>(2));
  when(() => r.updatePricingRule(any()))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  when(() => r.verifyDriver(any()))
      .thenAnswer((_) async => const Right<Failure, void>(null));
  return r;
}

Future<void> _pump(WidgetTester tester, Widget tab, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = AdminBloc(adminRepository: _repo())..add(AdminDataRequested());
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
      PricingRule.fallback(VehicleClass.business, ServiceType.oneWay)));

  const tabs = <String, Widget>{
    'panel': DashboardTab(),
    'operaciones': BookingsTab(),
    'finanzas': FinanceTab(),
    'tarifas': PricingTab(),
    'chóferes': DriversTab(),
    'vehículos': VehiclesTab(),
    'usuarios': UsersTab(),
    'auditoría': AuditTab(),
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
    expect(find.text('PERSONALIZADA'), findsOneWidget);
    expect(find.text('DESACTIVADA'), findsOneWidget);
    expect(find.text('DE FÁBRICA'), findsNWidgets(7));
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
}
