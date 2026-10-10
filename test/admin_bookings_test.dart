import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/l10n.dart';

class _MockAdminBloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

final _at = DateTime(2026, 10, 10, 9);

User _u(String id, String name, String phone, UserRole role) => User(
      id: id,
      email: '$id@x.bo',
      phone: phone,
      displayName: name,
      role: role,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
    );

Booking _b(String id, BookingStatus status, {String? driverId, String? passengerPhone}) => Booking(
      id: id,
      riderId: 'r1',
      driverId: driverId,
      origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
      destination: const Place(address: 'Viru Viru', lat: 0, lng: 0),
      scheduledAt: _at,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 180,
      createdAt: _at,
      updatedAt: _at,
      passengerPhone: passengerPhone,
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  late _MockAdminBloc bloc;

  Future<void> pump(WidgetTester tester, List<Booking> bookings, {double width = 1280}) async {
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = _MockAdminBloc();
    final state = AdminState(bookings: bookings, users: [
      _u('r1', 'Ana Rojas', '+591 70000001', UserRole.rider),
      _u('d1', 'Carlos Peña', '+591 70000002', UserRole.driver),
    ]);
    whenListen(bloc, const Stream<AdminState>.empty(), initialState: state);
    await tester.pumpWidget(BlocProvider<AdminBloc>.value(
      value: bloc,
      child: localizedApp(const Scaffold(body: BookingsTab())),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in const [390.0, 1280.0]) {
    testWidgets('shows rider and chauffeur phones (${width.toInt()}px)', (tester) async {
      await pump(tester, [_b('b1', BookingStatus.confirmed, driverId: 'd1')], width: width);
      expect(find.text('Pasajero: +591 70000001'), findsOneWidget);
      expect(find.text('Chófer: +591 70000002'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("a guest booking shows the guest's phone", (tester) async {
    await pump(tester, [_b('b1', BookingStatus.pending, passengerPhone: '+591 79999999')]);
    expect(find.text('Pasajero: +591 79999999'), findsOneWidget);
  });

  testWidgets('reassigns the chauffeur with a reason', (tester) async {
    await pump(tester, [_b('booking1', BookingStatus.driverArriving, driverId: 'd1')]);
    await tester.tap(find.byTooltip('Acciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reasignar chófer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se le quita el viaje a Carlos Peña'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Auto averiado');
    await tester.tap(find.text('Reasignar chófer').last);
    await tester.pumpAndSettle();
    verify(() => bloc.add(const AdminReleaseChauffeurRequested('booking1', reason: 'Auto averiado'))).called(1);
  });

  testWidgets('no reassign once the trip started; cancel sends the reason', (tester) async {
    await pump(tester, [_b('booking2', BookingStatus.inProgress, driverId: 'd1')]);
    await tester.tap(find.byTooltip('Acciones'));
    await tester.pumpAndSettle();
    expect(find.text('Reasignar chófer'), findsNothing);
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar reserva').last);
    await tester.pumpAndSettle();
    verify(() => bloc.add(const AdminCancelBookingRequested('booking2', reason: ''))).called(1);
  });
}
