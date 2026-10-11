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

Widget _themed(Widget child) => MaterialApp(
      theme: luxTheme,
      home: Scaffold(body: child),
    );

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
    for (final status in BookingStatus.values) {
      testWidgets('renders for $status', (tester) async {
        await tester.pumpWidget(_themed(BookingStatusChip(status: status)));
        expect(
          find.text(status.displayLabel.toUpperCase()),
          findsOneWidget,
        );
      });
    }
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

  // ---------------------------------------------------------------------------
  // GoogleSignInButton
  // ---------------------------------------------------------------------------
  group('GoogleSignInButton', () {
    testWidgets('dispatches GoogleSignInRequested when tapped', (tester) async {
      final bloc = _MockAuthBloc();
      whenListen(bloc, const Stream<AuthState>.empty(),
          initialState: const AuthUnauthenticated());
      await tester.pumpWidget(_themed(BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const GoogleSignInButton(),
      )));
      expect(find.text('Continuar con Google'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      verify(() => bloc.add(const GoogleSignInRequested())).called(1);
    });

    testWidgets('is disabled while auth is loading', (tester) async {
      final bloc = _MockAuthBloc();
      whenListen(bloc, const Stream<AuthState>.empty(),
          initialState: const AuthLoading());
      await tester.pumpWidget(_themed(BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const GoogleSignInButton(),
      )));
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });
  });
}
