import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/admin_share_repository.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_trip_share.dart';
import 'package:luxelane/l10n/l10n.dart';

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

class _Repo implements AdminShareRepository {
  _Repo({this.active = true, this.fail = false}) {
    addTearDown(() => alerts.close());
  }
  bool active;
  bool fail;
  final revoked = <(String, String)>[];
  final alerts = StreamController<List<UnassignedAlert>>.broadcast();
  @override
  Future<Either<Failure, bool>> isShareActive(String bookingId) async =>
      fail ? const Left(ServerFailure('fallo (prueba)')) : Right(active);
  @override
  Future<Either<Failure, void>> revokeShare(
      String bookingId, String reason) async {
    revoked.add((bookingId, reason));
    active = false;
    return const Right(null);
  }

  @override
  Stream<List<UnassignedAlert>> watchUnassigned() => alerts.stream;
}

/// Prompt 18, C3: el panel ve y revoca el enlace de una reserva y tiene la
/// bandeja de reservas pagadas sin chófer cerca de la hora. Datos FICTICIOS.
void main() {
  Future<void> pump(WidgetTester t, Widget child, {AdminState? state}) async {
    L10n.use(const Locale('es'));
    final bloc = _Bloc();
    whenListen(bloc, const Stream<AdminState>.empty(),
        initialState: state ?? const AdminState());
    t.view.physicalSize = const Size(1280, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: luxTheme,
      locale: const Locale('es'),
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      home: BlocProvider<AdminBloc>.value(
          value: bloc,
          child: Scaffold(body: SingleChildScrollView(child: child))),
    ));
    await t.pumpAndSettle();
  }

  group('AdminTripShareCard', () {
    testWidgets(
        'activo: revocar exige motivo (10+), revoca y pasa a «Sin enlace activo»',
        (t) async {
      final repo = _Repo();
      await pump(t, AdminTripShareCard(bookingId: 'b1', repository: repo));
      expect(find.text(L10n.current.adminShareActive), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('admin-trip-share-revoke')));
      await t.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('admin-share-confirm'));
      await t.enterText(
          find.byKey(const ValueKey('admin-share-reason')), 'corto');
      await t.pump();
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      await t.enterText(find.byKey(const ValueKey('admin-share-reason')),
          'Pedido por el pasajero (prueba)');
      await t.pump();
      await t.tap(confirm);
      await t.pumpAndSettle();
      expect(repo.revoked, [('b1', 'Pedido por el pasajero (prueba)')]);
      expect(find.text(L10n.current.adminShareNone), findsOneWidget);
    });

    testWidgets('sin enlace: nada que revocar', (t) async {
      await pump(
          t,
          AdminTripShareCard(
              bookingId: 'b1', repository: _Repo(active: false)));
      expect(find.text(L10n.current.adminShareNone), findsOneWidget);
      expect(
          find.byKey(const ValueKey('admin-trip-share-revoke')), findsNothing);
    });

    testWidgets('error: aviso y reintento', (t) async {
      final repo = _Repo(fail: true);
      await pump(t, AdminTripShareCard(bookingId: 'b1', repository: repo));
      expect(find.text(L10n.current.adminShareLoadFailed), findsOneWidget);
      repo.fail = false;
      await t.tap(find.text(L10n.current.adminShareRetry));
      await t.pumpAndSettle();
      expect(find.text(L10n.current.adminShareActive), findsOneWidget);
    });

    testWidgets('botones de 48 px y etiquetados', (t) async {
      final h = t.ensureSemantics();
      await pump(t, AdminTripShareCard(bookingId: 'b1', repository: _Repo()));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });

  group('AdminUnassignedInbox', () {
    final booking = Booking.fromJson({
      'id': 'b9xyzabc',
      'riderId': 'ana',
      'status': 'pending',
      'estimatedPrice': 100,
      'scheduledAt': Timestamp.fromDate(DateTime(2026, 11, 20, 14)),
      'origin': {
        'address': 'Origen (prueba)',
        'coordinates': const GeoPoint(-17.7, -63.1)
      },
      'destination': {
        'address': 'Destino (prueba)',
        'coordinates': const GeoPoint(-17.8, -63.2)
      },
    });

    testWidgets('vacía: no ocupa sitio', (t) async {
      final repo = _Repo();
      await pump(t, AdminUnassignedInbox(repository: repo));
      repo.alerts.add(const []);
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('admin-unassigned-inbox')), findsNothing);
    });

    testWidgets('con alertas: código y hora; tocar abre la reserva', (t) async {
      final repo = _Repo();
      final opened = <String>[];
      await pump(t, AdminUnassignedInbox(repository: repo, onOpen: opened.add),
          state: AdminState(bookings: [booking]));
      repo.alerts.add(const [
        UnassignedAlert(alertId: 'unassigned_b9xyzabc', bookingId: 'b9xyzabc')
      ]);
      await t.pumpAndSettle();
      expect(find.textContaining(L10n.current.adminUnassignedTitle),
          findsOneWidget);
      await t.tap(
          find
              .bySemanticsLabel(L10n.current.adminUnassignedOpen('B9XYZA'))
              .first,
          warnIfMissed: false);
      await t.tap(find.byIcon(Icons.person_search_outlined));
      await t.pumpAndSettle();
      expect(opened.last, 'b9xyzabc');
    });
  });
}
