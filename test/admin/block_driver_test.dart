import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';

Booking _b(String id, BookingStatus status,
        {String? driverId, int hour = 10}) =>
    Booking.fromJson({
      'id': id,
      'riderId': 'ana',
      if (driverId != null) 'driverId': driverId,
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.64, -63.13),
      },
      'scheduledAt': Timestamp.fromDate(DateTime(2026, 11, 1, hour)),
      'status': status.label,
    });

void main() {
  final bookings = [
    _b('tarde', BookingStatus.confirmed, driverId: 'asig', hour: 18),
    _b('encamino', BookingStatus.driverArriving, driverId: 'asig', hour: 9),
    _b('hecho', BookingStatus.completed, driverId: 'asig'),
    _b('pend', BookingStatus.pending),
    _b('otro', BookingStatus.inProgress, driverId: 'libre'),
  ];

  test('viajes activos del chófer, por hora de recogida', () {
    expect(
      AdminOperations.activeTripsOf(bookings, 'asig').map((b) => b.id),
      ['encamino', 'tarde'],
    );
    expect(AdminOperations.activeTripsOf(bookings, 'nadie'), isEmpty);
  });

  Future<BlockDriverChoice?> open(WidgetTester tester, String tap) async {
    BlockDriverChoice? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<BlockDriverChoice>(
            context: context,
            builder: (_) => BlockDriverWarningDialog(
              driverName: 'Carlos',
              trips: AdminOperations.activeTripsOf(bookings, 'asig'),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Este chófer tiene viajes activos'), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-encamino')), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-tarde')), findsOneWidget);
    await tester.tap(find.text(tap).first);
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('reasignar abre el viaje sin bloquear', (tester) async {
    final r = await open(tester, 'Reasignar');
    expect(r, isA<ReassignTrip>());
    expect((r! as ReassignTrip).bookingId, 'encamino');
  });

  testWidgets('bloquear igualmente', (tester) async {
    expect(await open(tester, 'Bloquear igualmente'), isA<ConfirmBlock>());
  });

  testWidgets('cancelar no hace nada', (tester) async {
    expect(await open(tester, 'Cancelar'), isNull);
  });
}
