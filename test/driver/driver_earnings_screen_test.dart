import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_earnings_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

final _now = DateTime(2026, 10, 10, 12);

Booking _b(String id, {BookingSettlement? settlement}) => Booking(
      id: id,
      riderId: 'r',
      driverId: 'd',
      origin: const Place(address: 'Aeropuerto El Alto', lat: 0, lng: 0),
      destination:
          const Place(address: 'Av. Ballivián, Calacoto', lat: 0, lng: 0),
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.completed,
      estimatedPrice: 100,
      createdAt: _now,
      updatedAt: _now,
      settlement: settlement,
    );

void main() {
  testWidgets('muestra ganancias netas, comisión y viajes provisionales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = _MockDriverBloc();
    when(() => bloc.state).thenReturn(
      DriverLoaded(
        user: User(
          id: 'd',
          email: 'd@example.com',
          phone: '',
          displayName: 'Luis',
          role: UserRole.driver,
          createdAt: _now,
          isVerified: true,
          isActive: true,
          fcmTokens: const [],
        ),
        profile: DriverProfile(
          userId: 'd',
          licenseNumber: 'LP-1',
          licenseExpiry: _now,
          vehicleId: 'v',
          documentsVerified: true,
          rating: 5,
          totalRides: 2,
          isAvailable: true,
        ),
        isAvailable: true,
        bookings: [
          _b(
            'a',
            settlement: const BookingSettlement(
              amount: 100,
              commissionPct: 10,
              platformCommission: 10,
              driverPayout: 90,
            ),
          ),
          _b('b'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: BlocProvider<DriverBloc>.value(
          value: bloc,
          child: const DriverEarningsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Bs170.00'), findsOneWidget); // 90 + 80
    expect(find.text('Bs200.00'), findsOneWidget); // tarifas
    expect(find.text('− Bs30.00'), findsOneWidget); // 10 + 20
    expect(find.text('Bs90.00'), findsOneWidget);
    expect(find.text('Bs80.00'), findsOneWidget);
    expect(find.text('Provisional'), findsOneWidget);
  });
}
