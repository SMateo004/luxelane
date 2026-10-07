import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/widgets/components.dart';

import 'helpers/l10n.dart';

Widget _themed(Widget child, {Locale locale = const Locale('es')}) =>
    localizedApp(Scaffold(body: child), locale: locale, theme: luxTheme);

void main() {
  // ---------------------------------------------------------------------------
  // LuxButton
  // ---------------------------------------------------------------------------
  group('LuxButton', () {
    testWidgets('renders label uppercased', (tester) async {
      await tester.pumpWidget(_themed(
        LuxButton(label: 'Confirm', onPressed: () {}),
      ));
      expect(find.text('CONFIRM'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_themed(
        LuxButton(label: 'Go', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows spinner when loading=true', (tester) async {
      await tester.pumpWidget(_themed(
        const LuxButton(label: 'Loading', onPressed: null, loading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // LuxOutlinedButton
  // ---------------------------------------------------------------------------
  group('LuxOutlinedButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_themed(
        LuxOutlinedButton(label: 'Cancel', onPressed: () {}),
      ));
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(_themed(
        LuxOutlinedButton(
          label: 'Add',
          onPressed: () {},
          icon: Icons.add,
        ),
      ));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // BookingStatusChip
  // ---------------------------------------------------------------------------
  group('BookingStatusChip', () {
    const spanish = {
      BookingStatus.pending: 'PENDIENTE',
      BookingStatus.confirmed: 'CONFIRMADO',
      BookingStatus.driverArriving: 'EN CAMINO',
      BookingStatus.driverArrived: 'CHÓFER LLEGÓ',
      BookingStatus.inProgress: 'EN PROGRESO',
      BookingStatus.completed: 'COMPLETADO',
      BookingStatus.cancelled: 'CANCELADO',
    };
    for (final status in BookingStatus.values) {
      testWidgets('renders for $status', (tester) async {
        await tester.pumpWidget(_themed(BookingStatusChip(status: status)));
        expect(find.text(spanish[status]!), findsOneWidget);
      });
    }

    testWidgets('follows the app language (en, pt)', (tester) async {
      await tester.pumpWidget(_themed(
        const BookingStatusChip(status: BookingStatus.completed),
        locale: const Locale('en'),
      ));
      expect(find.text('COMPLETED'), findsOneWidget);

      await tester.pumpWidget(_themed(
        const BookingStatusChip(status: BookingStatus.completed),
        locale: const Locale('pt'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('CONCLUÍDO'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // PriceEstimateBar / VehicleCard
  // ---------------------------------------------------------------------------
  group('Booking widgets in English', () {
    testWidgets('PriceEstimateBar uses translated defaults and Bs', (tester) async {
      await tester.pumpWidget(_themed(
        PriceEstimateBar(price: 1250, onConfirm: () {}),
        locale: const Locale('en'),
      ));
      expect(find.text('FIXED PRICE'), findsOneWidget);
      expect(find.text('CONFIRM BOOKING'), findsOneWidget);
      expect(find.text('Bs 1,250'), findsOneWidget);
    });

    testWidgets('VehicleCard shows localized class and capacity', (tester) async {
      await tester.pumpWidget(_themed(
        VehicleCard(
          vehicleClass: VehicleClass.electric,
          price: 300,
          selected: false,
          onTap: () {},
          serviceType: ServiceType.byTheHour,
          hours: 3,
        ),
        locale: const Locale('en'),
      ));
      expect(find.text('Electric'), findsOneWidget);
      expect(find.text('3 h total'), findsOneWidget);
      expect(find.textContaining('Up to'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // LuxCard
  // ---------------------------------------------------------------------------
  group('LuxCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(_themed(
        const LuxCard(child: Text('Card Content')),
      ));
      expect(find.text('Card Content'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // LuxDivider
  // ---------------------------------------------------------------------------
  group('LuxDivider', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_themed(const LuxDivider()));
      expect(find.byType(LuxDivider), findsOneWidget);
    });
  });
}
