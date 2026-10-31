// Los StreamController se cierran con addTearDown.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_booking_preferences.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/widgets/trip_preferences_step.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_queue_screen.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_preferences_card.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/features/profile/presentation/pages/preferences_screen.dart';
import 'package:luxelane/features/profile/presentation/widgets/trip_preferences_editor.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Prefs extends Mock implements PreferencesRepository {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

// Personas, lugares y textos de PRUEBA, ficticios.

const _pickupArea = 'El Alto';

/// Una nota de exactamente 200 caracteres (el máximo).
final _note200 = () {
  const base = 'Llevo un carrito de bebé plegado y una maleta grande que no '
      'cabe atrás; por favor espera en la puerta principal del hotel, junto '
      'a la recepción, y avísame al llegar con un mensaje corto. Gracias de '
      'antemano por todo.';
  return base.substring(0, TripPreferences.noteMax);
}();

/// Todas las opciones: todos los idiomas y necesidades, una opción en cada
/// grupo de una sola elección, la nota larga y la lista.
final _full = TripPreferences(
  languages: DriverLanguage.values,
  temperature: CabinTemperaturePref.cool,
  conversation: ConversationPref.quiet,
  music: MusicStyle.instrumental,
  needs: PracticalNeed.values,
  note: _note200,
  playlistUrl: 'https://music.example.com/lista',
);

User _user(TripPreferences prefs, {UserRole role = UserRole.rider}) => User(
      id: 'ana',
      email: 'ana@example.com',
      phone: '+59170000000',
      displayName: 'Ana',
      role: role,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
      tripPreferences: prefs,
    );

/// Textos que el diseño acorta a propósito con «…» y por qué. Ninguno es de
/// las preferencias: son de la tarjeta de la solicitud, que las rodea.
typedef _Ellipsis = ({String why, bool Function(RenderParagraph p) covers});

String _text(RenderParagraph p) => p.text.toPlainText();

final _ellipsisAllowed = <String, List<_Ellipsis>>{
  'solicitud': [
    (
      why: 'Cabecera de la tarjeta de la solicitud («Mañana · hora · desde '
          'zona» y «clase · pasajeros»): una línea a propósito para que la '
          'cola se lea de un vistazo; el detalle completo se ve al aceptar. '
          'No es de las preferencias: la línea de idiomas se lee entera.',
      covers: (p) =>
          p.maxLines == 1 &&
          (_text(p).contains(_pickupArea) ||
              _text(p).startsWith(VehicleClass.business.label)),
    ),
  ],
};

/// El error y el widget que lo causó (la línea del código).
String _describe(FlutterErrorDetails e) {
  final where = RegExp(r'file://\S*/((?:lib|test)/\S+)')
      .firstMatch(e.toString())
      ?.group(1);
  return '${e.exceptionAsString().split('\n').first} ${where ?? ''}'.trim();
}

/// Roboto del SDK de Flutter con los nombres de las fuentes de la app (como
/// test/l10n/texto_grande_idiomas_test.dart): con FlutterTest cada letra
/// mide 1 em y se marcaría como cortado texto que en el teléfono cabe.
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory(
    root != null
        ? '$root/bin/cache/artifacts/material_fonts'
        : '${File(Platform.resolvedExecutable).parent.parent.parent.path}'
            '/material_fonts',
  );
  for (final family in [
    LuxTypography.sansFamily,
    LuxTypography.serifFamily,
    'Roboto', // i18n-ignore: nombre de fuente
  ]) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Bold']) {
      final f = File('${dir.path}/Roboto-$w.ttf');
      expect(f.existsSync(), isTrue, reason: 'falta ${f.path}');
      loader.addFont(f.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }
}

/// Todos los nodos del árbol de accesibilidad, en todas las vistas.
List<SemanticsNode> _nodes(WidgetTester t) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    out.add(n);
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  for (final view in t.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return out;
}

/// Lo que se puede tocar y mide menos de 48 × 48. Como
/// androidTapTargetGuideline, pero se salta lo que un desplazamiento deja a
/// medias (su rectángulo toca el recorte del padre): la regla de
/// flutter_test no siempre lo reconoce dentro de una hoja y no es un
/// defecto del widget.
List<String> _smallTargets(WidgetTester t) {
  bool touches(Rect r, Rect clip) =>
      r.left - clip.left < 0.001 ||
      clip.right - r.right < 0.001 ||
      r.top - clip.top < 0.001 ||
      clip.bottom - r.bottom < 0.001;
  final out = <String>[];
  for (final n in _nodes(t)) {
    if (n.isMergedIntoParent || n.isInvisible) continue;
    final d = n.getSemanticsData();
    if (d.hasFlag(SemanticsFlag.isHidden) ||
        d.hasFlag(SemanticsFlag.isLink) ||
        !(d.hasAction(SemanticsAction.tap) ||
            d.hasAction(SemanticsAction.longPress))) {
      continue;
    }
    if ([n.parentSemanticsClipRect, n.parentPaintClipRect]
        .any((clip) => clip != null && touches(n.rect, clip))) {
      continue;
    }
    if (n.rect.width < 48 - 0.01 || n.rect.height < 48 - 0.01) {
      out.add('«${d.label}» ${n.rect.size}');
    }
  }
  return out;
}

/// B5: las preferencias con la letra al 200 % y con lector de pantalla, en
/// español, inglés y portugués, en un móvil de 390 × 844.
void main() {
  setUpAll(() async {
    await _loadFonts();
    registerFallbackValue(TripPreferences.empty);
  });

  tearDown(() async {
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  /// Monta [home] a 390 × 844 con la letra al 200 % (en el builder, para que
  /// llegue a hojas y diálogos). Devuelve los errores del framework.
  Future<List<FlutterErrorDetails>> mount(
    WidgetTester t,
    Locale locale,
    Widget home, {
    List<BlocProvider> providers = const [],
    Duration? settle,
  }) async {
    L10n.use(locale);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app = MaterialApp(
      theme: luxTheme,
      locale: locale,
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: home,
    );
    return collect(() async {
      await t.pumpWidget(
        providers.isEmpty
            ? app
            : MultiBlocProvider(providers: providers, child: app),
      );
      if (settle != null) {
        await t.pump(settle);
        await t.pump(settle);
      } else {
        await t.pumpAndSettle();
      }
    });
  }

  /// Ningún error de layout y ningún texto en pantalla cortado.
  void expectWhole(
    WidgetTester t,
    List<FlutterErrorDetails> errors, {
    String? screen,
    String where = '',
  }) {
    final allowed = _ellipsisAllowed[screen] ?? const [];
    expect(errors.map(_describe).toList(), isEmpty,
        reason: 'errores de layout $where');
    expect(t.takeException(), isNull);
    final view = Offset.zero & const Size(390, 844);
    final cut = <String>[];
    for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
      if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
      final box = p.localToGlobal(Offset.zero) & p.size;
      if (!box.overlaps(view)) continue;
      if (allowed.any((e) => e.covers(p))) continue;
      final text = _text(p);
      if (p.didExceedMaxLines) {
        cut.add('«$text» (más líneas que maxLines)');
      } else if (!p.softWrap &&
          p.getMaxIntrinsicWidth(double.infinity) > p.size.width + 0.5) {
        cut.add('«$text» (no cabe a lo ancho)');
      }
    }
    expect(cut, isEmpty, reason: 'textos cortados $where');
  }

  /// Objetivos táctiles de 48 px y con etiqueta. [whole]: además la regla
  /// de flutter_test entera (ver [_smallTargets] para los tramos con algo
  /// a medio desplazar).
  Future<void> expectTargets(
    WidgetTester t,
    String where, {
    bool whole = true,
  }) async {
    if (whole) {
      await expectLater(t, meetsGuideline(androidTapTargetGuideline),
          reason: where);
    }
    expect(_smallTargets(t), isEmpty, reason: 'objetivos < 48 px $where');
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline),
        reason: where);
  }

  /// Recorre [scrollable] de arriba abajo y comprueba en cada tramo.
  Future<void> everyScreenful(
    WidgetTester t,
    Finder scrollable,
    Future<void> Function(String where) check,
  ) async {
    final position = t.state<ScrollableState>(scrollable).position;
    var i = 0;
    while (true) {
      await check(i == 0 ? '' : '(tramo $i)');
      if (position.pixels >= position.maxScrollExtent) break;
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.6)
            .clamp(0, position.maxScrollExtent),
      );
      await t.pumpAndSettle();
      i++;
    }
    position.jumpTo(0);
    await t.pumpAndSettle();
  }

  /// Cada opción del editor: etiqueta, estado (seleccionada o no) y que se
  /// puede tocar; cada grupo con su encabezado; el contador y la
  /// advertencia de la nota. Desplaza hasta cada cosa: lo que queda lejos
  /// fuera de la lista no está en el árbol de accesibilidad.
  Future<void> expectEditorSemantics(
    WidgetTester t,
    TripPreferences p,
  ) async {
    final l = L10n.current;
    final seen = <String, int>{};
    Future<void> option(String label, bool selected) async {
      // «Sin preferencia» sale en varios grupos: la n-ésima, en orden.
      final i = seen[label] = (seen[label] ?? -1) + 1;
      final finder = find
          .descendant(
            of: find.byType(TripPreferencesEditor),
            matching: find.text(label),
          )
          .at(i);
      await t.ensureVisible(finder);
      await t.pumpAndSettle();
      final d = t.getSemantics(finder).getSemanticsData();
      expect(d.label, label, reason: 'etiqueta de «$label»');
      expect(d.hasFlag(SemanticsFlag.hasSelectedState), isTrue,
          reason: '«$label» sin estado');
      expect(d.hasFlag(SemanticsFlag.isSelected), selected,
          reason: '«$label» ${selected ? '' : 'no '}seleccionada');
      expect(d.hasFlag(SemanticsFlag.isButton), isTrue, reason: label);
      expect(d.hasAction(SemanticsAction.tap), isTrue, reason: label);
    }

    for (final v in DriverLanguage.values) {
      await option(v.label, p.languages.contains(v));
    }
    for (final v in CabinTemperaturePref.values) {
      await option(v.label, p.temperature == v);
    }
    for (final v in ConversationPref.values) {
      await option(v.label, p.conversation == v);
    }
    for (final v in MusicStyle.values) {
      await option(v.label, p.music == v);
    }
    for (final v in PracticalNeed.values) {
      await option(v.label, p.needs.contains(v));
    }

    Future<bool> reads(Finder near, bool Function(SemanticsData d) test) async {
      await t.ensureVisible(near);
      await t.pumpAndSettle();
      return _nodes(t).map((n) => n.getSemanticsData()).any(test);
    }

    for (final h in [
      l.prefsLanguagesTitle,
      l.prefsTemperatureTitle,
      l.prefsConversationTitle,
      l.prefsMusicTitle,
      l.prefsNeedsTitle,
      l.prefsNoteTitle,
    ]) {
      expect(
        await reads(
          find.text(h.toUpperCase()),
          (d) => d.hasFlag(SemanticsFlag.isHeader) && d.label == h,
        ),
        isTrue,
        reason: 'encabezado «$h»',
      );
    }

    // La nota: lo que queda del contador y la advertencia se leen.
    final note = find.byKey(const ValueKey('prefs-note'));
    final remaining = MaterialLocalizations.of(t.element(note))
        .remainingTextFieldCharacterCount(
            TripPreferences.noteMax - (p.note?.length ?? 0));
    bool has(SemanticsData d, String s) =>
        d.label.contains(s) || d.hint.contains(s) || d.value.contains(s);
    for (final (what, text) in [
      ('contador', remaining),
      ('advertencia', l.prefsNoteWarning),
      ('aviso de privacidad', l.prefsNeedPrivateHint),
      ('quién lo ve', l.prefsDriverWillSee),
    ]) {
      expect(await reads(note, (d) => has(d, text)), isTrue,
          reason: '$what «$text»');
    }
  }

  /// Un botón con esa etiqueta.
  void expectButton(WidgetTester t, String label) {
    final node = t.getSemantics(find.text(label).last);
    final d = node.getSemanticsData();
    expect(d.label, contains(label));
    expect(d.hasFlag(SemanticsFlag.isButton), isTrue, reason: '«$label»');
  }

  for (final locale in const [Locale('es'), Locale('en'), Locale('pt')]) {
    final code = locale.languageCode;
    group('$code, letra al 200 % y lector de pantalla:', () {
      // --- 1. PreferencesScreen ----------------------------------------
      for (final (name, saved, options) in [
        ('vacía', TripPreferences.empty, PreferenceOptions.none),
        ('llena', _full, const PreferenceOptions(playlistEnabled: true)),
      ]) {
        testWidgets('1 perfil: preferencias $name', (t) async {
          final handle = t.ensureSemantics();
          final repo = _Prefs();
          when(() => repo.options()).thenAnswer((_) async => options);
          final bloc = _MockProfileBloc();
          whenListen(bloc, const Stream<ProfileState>.empty(),
              initialState: ProfileLoaded(user: _user(saved)));
          final errors = await mount(
            t,
            locale,
            BlocProvider<ProfileBloc>.value(
              value: bloc,
              child: PreferencesScreen(repository: repo),
            ),
          );
          final l = L10n.current;
          if (saved.isEmpty) {
            expect(find.text(l.prefsEmpty), findsOneWidget);
          } else {
            expect(
                find.byKey(const ValueKey('prefs-playlist')), findsOneWidget);
            expect(find.text('200/200'), findsOneWidget);
          }
          await everyScreenful(
            t,
            find
                .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable))
                .first,
            (where) async {
              expectWhole(t, errors, where: where);
              await expectTargets(t, where, whole: where.isEmpty);
            },
          );
          await expectEditorSemantics(t, saved);
          expectButton(t, l.prefsSave);
          handle.dispose();
        });
      }

      // --- 2. Paso de la reserva ---------------------------------------
      testWidgets('2 reserva: «Preferencias de este viaje»', (t) async {
        final handle = t.ensureSemantics();
        final repo = _Prefs();
        when(() => repo.options()).thenAnswer(
            (_) async => const PreferenceOptions(playlistEnabled: true));
        final errors = await mount(
          t,
          locale,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(LuxSpacing.md),
              child: TripPreferencesStep(
                profile: _full,
                trip: _full.copyWith(music: MusicStyle.jazz),
                repository: repo,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        final l = L10n.current;
        expectWhole(t, errors, where: '(cerrado)');
        await expectTargets(t, '(cerrado)');
        expectButton(t, l.prefsTripEdit);
        expectButton(t, l.prefsTripReset);

        final sheetErrors = await collect(() async {
          await t.tap(find.text(l.prefsTripEdit));
          await t.pumpAndSettle();
        });
        expect(find.byKey(const ValueKey('prefs-playlist')), findsOneWidget);
        await everyScreenful(
          t,
          find
              .descendant(
                  of: find.byType(SingleChildScrollView).last,
                  matching: find.byType(Scrollable))
              .first,
          (where) async {
            expectWhole(t, sheetErrors, where: '(hoja) $where');
            await expectTargets(t, '(hoja) $where', whole: where.isEmpty);
          },
        );
        await expectEditorSemantics(t, _full.copyWith(music: MusicStyle.jazz));
        expectButton(t, l.prefsTripApply);
        expectButton(t, l.prefsTripSkip);
        handle.dispose();
      });

      // --- 3. Tarjeta del chófer ---------------------------------------
      testWidgets('3 chófer: la tarjeta con todo y el aviso', (t) async {
        final handle = t.ensureSemantics();
        final errors = await mount(
          t,
          locale,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(LuxSpacing.md),
              child: DriverPreferencesView(
                preferences: _full,
                launch: (_) async => true,
              ),
            ),
          ),
        );
        final l = L10n.current;
        expect(find.text(_note200), findsOneWidget);
        await everyScreenful(
          t,
          find
              .descendant(
                  of: find.byType(SingleChildScrollView),
                  matching: find.byType(Scrollable))
              .first,
          (where) async {
            expectWhole(t, errors, where: where);
            await expectTargets(t, where, whole: where.isEmpty);
          },
        );
        expectCardSemantics(t);
        await t.scrollUntilVisible(find.text(l.prefsOpenPlaylist), 200);
        expectButton(t, l.prefsOpenPlaylist);

        final dialogErrors = await collect(() async {
          await t.tap(find.text(l.prefsOpenPlaylist));
          await t.pumpAndSettle();
        });
        expect(find.text(l.prefsOpenPlaylistTitle), findsOneWidget);
        expectWhole(t, dialogErrors, where: '(aviso)');
        await expectTargets(t, '(aviso)');
        expectButton(t, l.prefsCancel);
        expectButton(t, l.prefsOpenPlaylistConfirm);
        handle.dispose();
      });

      // --- 4. Panel ----------------------------------------------------
      testWidgets('4 panel: preferencias de la reserva, en español', (t) async {
        final handle = t.ensureSemantics();
        final repo = _Prefs();
        final ctrl = StreamController<TripPreferences?>.broadcast();
        addTearDown(ctrl.close);
        when(() => repo.watchBookingPreferences('b1'))
            .thenAnswer((_) => ctrl.stream);
        final errors = await mount(
          t,
          locale,
          LuxSpanishOnly(
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(LuxSpacing.md),
                child: AdminBookingPreferences(
                  bookingId: 'b1',
                  repository: repo,
                  launch: (_) async => true,
                ),
              ),
            ),
          ),
          // Mientras llega la copia se ve un indicador que no se detiene.
          settle: const Duration(milliseconds: 100),
        );
        errors.addAll(await collect(() async {
          ctrl.add(_full);
          await t.pumpAndSettle();
        }));
        expect(find.text('Preferencias del pasajero'), findsOneWidget);
        await everyScreenful(
          t,
          find
              .descendant(
                  of: find.byType(SingleChildScrollView),
                  matching: find.byType(Scrollable))
              .first,
          (where) async {
            expectWhole(t, errors, where: where);
            await expectTargets(t, where, whole: where.isEmpty);
          },
        );
        await t.scrollUntilVisible(find.text('Abrir lista'), 200);
        expectButton(t, 'Abrir lista');
        handle.dispose();
      });

      // --- 5. Solicitud abierta ----------------------------------------
      testWidgets('5 chófer: idiomas en la solicitud abierta', (t) async {
        final handle = t.ensureSemantics();
        final driver = _MockDriverBloc();
        whenListen(
          driver,
          const Stream<DriverState>.empty(),
          initialState: DriverLoaded(
            user: _user(TripPreferences.empty, role: UserRole.driver),
            profile: DriverProfile(
              userId: 'ana',
              licenseNumber: 'LP-1',
              licenseExpiry: DateTime(2030),
              vehicleId: 'v',
              documentsVerified: true,
              rating: 4.9,
              totalRides: 12,
              isAvailable: true,
            ),
            isAvailable: true,
            bookings: const [],
            pendingRequests: [
              OpenRequest(
                id: 'q1',
                vehicleClass: VehicleClass.business,
                serviceType: ServiceType.oneWay,
                scheduledAt: DateTime.now().add(const Duration(days: 1)),
                estimatedPrice: 150,
                pickupArea: _pickupArea,
                dropoffArea: 'La Paz',
                preferredDriverLanguages: DriverLanguage.values,
              ),
            ],
            vehicleClass: VehicleClass.business,
          ),
        );
        final auth = _MockAuthBloc();
        whenListen(auth, const Stream<AuthState>.empty(),
            initialState: const AuthUnauthenticated());
        final errors = await mount(
          t,
          locale,
          const DriverQueueScreen(),
          providers: [
            BlocProvider<DriverBloc>.value(value: driver),
            BlocProvider<AuthBloc>.value(value: auth),
          ],
          settle: const Duration(milliseconds: 600),
        );
        final langs = L10n.current.prefsLanguagesSummary(
            DriverLanguage.values.map((l) => l.label).join(', '));
        expect(find.text(langs), findsOneWidget);
        expectWhole(t, errors, screen: 'solicitud');
        await expectTargets(t, '');
        final line =
            t.renderObjectList<RenderParagraph>(find.text(langs)).single;
        expect(line.didExceedMaxLines, isFalse);
        // El lector lee la línea entera (el icono no dice nada).
        expect(
          _nodes(t).any((n) => n.getSemanticsData().label.contains(langs)),
          isTrue,
          reason: 'idiomas para el lector',
        );
        handle.dispose();
      });
    });
  }
}

/// Lo que el framework informó mientras corría [body].
Future<List<FlutterErrorDetails>> collect(Future<void> Function() body) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// La tarjeta del chófer: título como encabezado y cada fila leída entera
/// (rótulo y valor juntos).
void expectCardSemantics(WidgetTester t) {
  final l = L10n.current;
  final nodes = _nodes(t).map((n) => n.getSemanticsData()).toList();
  expect(
    nodes.any((d) =>
        d.hasFlag(SemanticsFlag.isHeader) && d.label == l.prefsCardTitle),
    isTrue,
    reason: 'encabezado de la tarjeta',
  );
  for (final (title, value) in [
    (
      l.prefsLanguagesTitle,
      DriverLanguage.values.map((v) => v.label).join(', ')
    ),
    (l.prefsTemperatureTitle, _full.temperature.label),
    (l.prefsConversationTitle, _full.conversation.label),
    (l.prefsMusicTitle, _full.music.label),
    (l.prefsNeedsTitle, PracticalNeed.values.map((v) => v.label).join(', ')),
    (l.prefsNoteTitle, _note200),
  ]) {
    expect(
      nodes.any((d) => d.label.contains(title) && d.label.contains(value)),
      isTrue,
      reason: 'fila «$title»',
    );
  }
}
