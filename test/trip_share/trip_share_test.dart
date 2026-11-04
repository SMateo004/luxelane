import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/features/trip_share/data/trip_share_repository.dart';
import 'package:luxelane/features/trip_share/presentation/trip_share_card.dart';
import 'package:luxelane/features/trip_share/presentation/trip_share_cubit.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Repositorio falso: estado inicial, fallo opcional y registro de llamadas.
class _Repo implements TripShareRepository {
  _Repo({this.active = false, this.fail = false});
  bool active;
  bool fail;
  final calls = <String>[];
  Either<Failure, T> _r<T>(T v) =>
      fail ? const Left(ServerFailure('No se pudo (prueba)')) : Right(v);
  @override
  Future<Either<Failure, bool>> isActive(String id) async {
    calls.add('isActive');
    return _r(active);
  }

  @override
  Future<Either<Failure, String>> create(String id) async {
    calls.add('create');
    active = true;
    return _r('/t#TOKENDEPRUEBA0000000A');
  }

  @override
  Future<Either<Failure, void>> revoke(String id) async {
    calls.add('revoke');
    active = false;
    return _r(null);
  }
}

/// Prompt 18, C1: compartir el viaje desde la app del pasajero.
void main() {
  group('TripShareCubit', () {
    blocTest<TripShareCubit, TripShareState>(
      'sin enlace: comprobar y quedar inactivo',
      build: () => TripShareCubit(_Repo(), 'b1'),
      act: (c) => c.load(),
      expect: () => [
        const TripShareState(),
        const TripShareState(status: TripShareStatus.inactive)
      ],
    );

    blocTest<TripShareCubit, TripShareState>(
      'compartir: crea el enlace, queda activo y pide abrir la hoja una vez',
      build: () => TripShareCubit(_Repo(), 'b1'),
      act: (c) => c.share(),
      expect: () => [
        const TripShareState(status: TripShareStatus.working),
        const TripShareState(
            status: TripShareStatus.active,
            sharePath: '/t#TOKENDEPRUEBA0000000A',
            shareSeq: 1),
      ],
    );

    blocTest<TripShareCubit, TripShareState>(
      'dejar de compartir: revoca y queda inactivo',
      build: () => TripShareCubit(_Repo(active: true), 'b1'),
      act: (c) => c.stop(),
      expect: () => [
        const TripShareState(status: TripShareStatus.working),
        const TripShareState(status: TripShareStatus.inactive),
      ],
    );

    blocTest<TripShareCubit, TripShareState>(
      'error: con el mensaje para la persona',
      build: () => TripShareCubit(_Repo(fail: true), 'b1'),
      act: (c) => c.load(),
      expect: () => [
        const TripShareState(),
        const TripShareState(
            status: TripShareStatus.error, message: 'No se pudo (prueba)')
      ],
    );
  });

  group('TripShareCard', () {
    late List<String> shared;
    Future<_Repo> pump(WidgetTester t,
        {_Repo? repo,
        String base = 'https://app.prueba.test',
        Locale locale = const Locale('es'),
        String bookingId = 'b1'}) async {
      L10n.use(locale);
      shared = [];
      final r = repo ?? _Repo();
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TripShareCard(
                bookingId: bookingId,
                repository: r,
                baseUrl: base,
                onShare: (s) async => shared.add(s)),
          ),
        ),
      ));
      await t.pumpAndSettle();
      return r;
    }

    tearDown(() => L10n.use(const Locale('es')));

    testWidgets(
        'inactivo: explica qué verá quien reciba el enlace; «Compartir viaje» abre la hoja con el enlace',
        (t) async {
      final r = await pump(t);
      expect(find.text(L10n.current.tripShareExplain), findsOneWidget);
      await t.tap(find.text('Compartir viaje'));
      await t.pumpAndSettle();
      expect(r.calls, ['isActive', 'create']);
      expect(shared, [
        'Puedes seguir mi viaje aquí: https://app.prueba.test/t#TOKENDEPRUEBA0000000A'
      ]);
      expect(find.text('Enlace activo'), findsOneWidget);
      expect(find.text('Dejar de compartir'), findsOneWidget);
    });

    testWidgets(
        'activo: «Dejar de compartir» revoca y vuelve a ofrecer compartir',
        (t) async {
      final r = await pump(t, repo: _Repo(active: true));
      expect(find.text('Enlace activo'), findsOneWidget);
      await t.tap(find.text('Dejar de compartir'));
      await t.pumpAndSettle();
      expect(r.calls.last, 'revoke');
      expect(find.text('Compartir viaje'), findsOneWidget);
      expect(shared, isEmpty);
    });

    testWidgets('error: mensaje y «Reintentar»', (t) async {
      final r = await pump(t, repo: _Repo(fail: true));
      expect(find.text('No se pudo (prueba)'), findsOneWidget);
      r.fail = false;
      await t.tap(find.text(L10n.current.rideRetry));
      await t.pumpAndSettle();
      expect(find.text('Compartir viaje'), findsOneWidget);
    });

    testWidgets(
        'sin dirección pública (móvil sin PUBLIC_WEB_BASE_URL): no se ofrece ni se llama al servidor',
        (t) async {
      final r = await pump(t, base: '');
      expect(find.text(L10n.current.tripShareUnavailable), findsOneWidget);
      expect(find.text('Compartir viaje'), findsNothing);
      expect(r.calls, ['isActive']);
    });

    for (final (locale, button, text) in [
      (const Locale('en'), 'Share trip', 'You can follow my trip here: '),
      (
        const Locale('pt'),
        'Compartilhar viagem',
        'Você pode acompanhar minha viagem aqui: '
      ),
    ]) {
      testWidgets(
          '${locale.languageCode}: el texto de la hoja en el idioma del pasajero',
          (t) async {
        await pump(t, locale: locale);
        await t.tap(find.text(button));
        await t.pumpAndSettle();
        expect(shared.single, startsWith(text));
      });
    }

    testWidgets('botones de 48 px y etiquetados, en los dos estados',
        (t) async {
      final h = t.ensureSemantics();
      await pump(t);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await pump(t, repo: _Repo(active: true), bookingId: 'b2');
      expect(find.text('Enlace activo'), findsOneWidget);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('texto al 200 %: sin desbordes', (t) async {
      L10n.use(const Locale('es'));
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: luxTheme,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(390, 2400), textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: TripShareCard(
                  bookingId: 'b1',
                  repository: _Repo(active: true),
                  baseUrl: 'https://x.test',
                  onShare: (_) async {}),
            ),
          ),
        ),
      ));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}
