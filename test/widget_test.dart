import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Widget _themed(Widget child) =>
    MaterialApp(theme: luxTheme, home: Scaffold(body: child));

void main() {
  // ---------------------------------------------------------------------------
  // LuxButton
  // ---------------------------------------------------------------------------
  group('LuxButton', () {
    testWidgets('renders label in sentence case', (tester) async {
      await tester.pumpWidget(
        _themed(LuxButton(label: 'Confirmar reserva', onPressed: () {})),
      );
      expect(find.text('Confirmar reserva'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _themed(LuxButton(label: 'Go', onPressed: () => tapped = true)),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('does nothing while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _themed(
          LuxButton(
            label: 'Loading',
            onPressed: () => tapped = true,
            loading: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LuxLoadingDots), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
      await tester.tap(find.byType(LuxLoadingDots));
      expect(tapped, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // LuxOutlinedButton
  // ---------------------------------------------------------------------------
  group('LuxOutlinedButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        _themed(LuxOutlinedButton(label: 'Cancel', onPressed: () {})),
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _themed(
          LuxOutlinedButton(label: 'Add', onPressed: () {}, icon: Icons.add),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // BookingStatusChip
  // ---------------------------------------------------------------------------
  group('BookingStatusChip', () {
    for (final status in BookingStatus.values) {
      testWidgets('renders for $status', (tester) async {
        await tester.pumpWidget(_themed(BookingStatusChip(status: status)));
        expect(find.text(status.displayLabel), findsOneWidget);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // LuxCard
  // ---------------------------------------------------------------------------
  group('LuxCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        _themed(const LuxCard(child: Text('Card Content'))),
      );
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

  // ---------------------------------------------------------------------------
  // GoogleSignInButton
  // ---------------------------------------------------------------------------
  group('GoogleSignInButton', () {
    testWidgets('dispatches GoogleSignInRequested when tapped', (tester) async {
      final bloc = _MockAuthBloc();
      whenListen(
        bloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated(),
      );
      await tester.pumpWidget(
        _themed(
          BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const GoogleSignInButton(),
          ),
        ),
      );
      expect(find.text('Continuar con Google'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      verify(() => bloc.add(const GoogleSignInRequested())).called(1);
    });

    testWidgets('is disabled while auth is loading', (tester) async {
      final bloc = _MockAuthBloc();
      whenListen(
        bloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthLoading(),
      );
      await tester.pumpWidget(
        _themed(
          BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const GoogleSignInButton(),
          ),
        ),
      );
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });
  });
}
