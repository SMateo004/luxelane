import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_driver_applications.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_driver_applications_tab.dart';

import 'driver_applications_fakes.dart';

/// Panel, solicitudes de chófer (B2): detalle, visor, revisión por
/// documento, decisión final y bitácora de accesos.
void main() {
  late FakeDriverAppsRepo repo;
  final launched = <Uri>[];

  setUp(() {
    repo = FakeDriverAppsRepo();
    launched.clear();
  });

  Future<void> pump(
    WidgetTester t, {
    double width = 1280,
    double textScale = 1,
  }) =>
      pumpPanel(
        t,
        DriverApplicationDetailView(
          repository: repo,
          driverId: 'chofer-1',
          onBack: () {},
          launcher: (u) async {
            launched.add(u);
            return true;
          },
        ),
        width: width,
        textScale: textScale,
      );

  Future<void> scrollTo(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(
      f,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('drvapp-detail')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.pumpAndSettle();
  }

  group('detalle', () {
    testWidgets('datos personales, vehículo y requisitos con su estado',
        (t) async {
      await pump(t);
      expect(find.text('Luis Prueba'), findsOneWidget);
      expect(find.text('Luis Prueba Ficticio'), findsOneWidget);
      expect(find.text('0000000 LP'), findsOneWidget);
      expect(find.text('LIC-PRUEBA-1'), findsOneWidget);
      expect(find.text('31/05/2028'), findsOneWidget);
      expect(find.text('MarcaX'), findsOneWidget);
      expect(find.text('0000-ZZZ'), findsOneWidget);
      expect(find.text('Negro'), findsOneWidget);
      expect(find.text('Sedán'), findsOneWidget);
      expect(find.text('Business Class'), findsOneWidget);
      expect(find.text('Requisitos sin configurar'), findsNothing);

      await scrollTo(t, find.byKey(const ValueKey('drvapp-doc-vehicle_soat')));
      expect(find.text('Motivo del rechazo: No se lee bien'), findsOneWidget);
      expect(find.text('Nota: Se ve borroso'), findsOneWidget);
      expect(find.textContaining('Versión 2'), findsOneWidget);
      expect(find.textContaining('Vence el 31/05/2028'), findsOneWidget);
      // El SOAT es opcional y no está subido: no se revisa.
      final approveSoat = t.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('drvapp-approve-vehicle_soat')),
      );
      expect(approveSoat.onPressed, isNull);
    });

    testWidgets('sin config/ops.driverRequirements: banner y lo subido',
        (t) async {
      repo.detailAnswer = Right(fakeDetail(requirementsConfigured: false));
      await pump(t);
      expect(
        find.byKey(const ValueKey('drvapp-requirements-missing')),
        findsOneWidget,
      );
      expect(find.text('Requisitos sin configurar'), findsOneWidget);
      await scrollTo(
        t,
        find.byKey(const ValueKey('drvapp-doc-criminal_record')),
      );
      expect(find.textContaining('Fuera de los requisitos'), findsWidgets);
    });

    testWidgets('error al cargar: mensaje y reintentar', (t) async {
      repo.detailAnswer = const Left(DriverAppFailure('Error de prueba'));
      await pump(t);
      expect(find.byKey(const ValueKey('drvapp-detail-error')), findsOneWidget);
      repo.detailAnswer = null;
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('drvapp-detail')), findsOneWidget);
    });
  });

  group('visor', () {
    testWidgets('imagen: pide la URL firmada y no la muestra como texto',
        (t) async {
      await pump(t);
      await scrollTo(
          t, find.byKey(const ValueKey('drvapp-view-license_front')));
      await t.tap(find.byKey(const ValueKey('drvapp-view-license_front')));
      await t.pumpAndSettle();
      expect(repo.urlCalls, [('chofer-1', DriverDocType.licenseFront)]);
      expect(find.byKey(const ValueKey('drvapp-viewer')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(
        (t.widget<Image>(find.byType(Image)).image as NetworkImage).url,
        kFakeSignedUrl,
      );
      expect(find.textContaining('caduca en 5 minutos'), findsOneWidget);
      expect(find.textContaining('https://'), findsNothing);
      expect(find.textContaining('Signature'), findsNothing);

      await t.tap(find.byKey(const ValueKey('drvapp-viewer-close')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('drvapp-viewer')), findsNothing);
    });

    testWidgets('PDF: botón que lo abre en otra pestaña', (t) async {
      repo.linkAnswer = Right(
        DocumentLink(
          url: kFakeSignedUrl,
          expiresAt: DateTime(2030),
          contentType: 'application/pdf',
        ),
      );
      await pump(t);
      await scrollTo(
        t,
        find.byKey(const ValueKey('drvapp-view-criminal_record')),
      );
      await t.tap(find.byKey(const ValueKey('drvapp-view-criminal_record')));
      await t.pumpAndSettle();
      expect(repo.urlCalls.single.$2, DriverDocType.criminalRecord);
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('https://'), findsNothing);
      await t.tap(find.text('Abrir PDF en otra pestaña'));
      await t.pumpAndSettle();
      expect(launched, [Uri.parse(kFakeSignedUrl)]);
    });

    testWidgets('error al pedir la URL: se dice en el visor', (t) async {
      repo.linkAnswer = const Left(DriverAppFailure('Sin permiso de prueba'));
      await pump(t);
      await scrollTo(
          t, find.byKey(const ValueKey('drvapp-view-license_front')));
      await t.tap(find.byKey(const ValueKey('drvapp-view-license_front')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('drvapp-viewer-error')), findsOneWidget);
      expect(find.text('Sin permiso de prueba'), findsOneWidget);
    });
  });

  group('revisión por documento', () {
    testWidgets('rechazar exige un motivo de la lista', (t) async {
      await pump(t);
      await scrollTo(
        t,
        find.byKey(const ValueKey('drvapp-reject-license_front')),
      );
      await t.tap(find.byKey(const ValueKey('drvapp-reject-license_front')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('drvapp-reject-dialog')), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('drvapp-reject-confirm')));
      await t.pumpAndSettle();
      expect(find.text('Elige un motivo para rechazar.'), findsOneWidget);
      expect(repo.reviewCalls, isEmpty);

      await t.tap(find.byKey(const ValueKey('drvapp-reject-reason')));
      await t.pumpAndSettle();
      await t.tap(
          find.text('Los datos no coinciden con los de la solicitud').last);
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('drvapp-reject-note')),
        '  El número no coincide  ',
      );
      await t.tap(find.byKey(const ValueKey('drvapp-reject-confirm')));
      await t.pumpAndSettle();
      expect(repo.reviewCalls, [
        {
          'driverId': 'chofer-1',
          'type': DriverDocType.licenseFront,
          'version': 2,
          'approve': false,
          'rejectReason': DocRejectReason.dataMismatch,
          'note': 'El número no coincide',
        },
      ]);
      expect(find.byKey(const ValueKey('drvapp-reject-dialog')), findsNothing);
      // Se recarga el detalle.
      expect(repo.detailCalls.length, 2);
    });

    testWidgets('un fallo del servidor se muestra en el diálogo', (t) async {
      repo.reviewAnswer = const Left(
        DriverAppFailure(
          'El chófer subió una versión nueva; recarga la solicitud.',
        ),
      );
      await pump(t);
      await scrollTo(
        t,
        find.byKey(const ValueKey('drvapp-reject-license_front')),
      );
      await t.tap(find.byKey(const ValueKey('drvapp-reject-license_front')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('drvapp-reject-reason')));
      await t.pumpAndSettle();
      await t.tap(find.text('No se lee bien').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('drvapp-reject-confirm')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('drvapp-reject-error')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('drvapp-reject-dialog')), findsOneWidget);
    });

    testWidgets('aprobar confirma y llama con la versión', (t) async {
      await pump(t);
      await scrollTo(
        t,
        find.byKey(const ValueKey('drvapp-approve-license_front')),
      );
      await t.tap(find.byKey(const ValueKey('drvapp-approve-license_front')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('drvapp-approve-confirm')));
      await t.pumpAndSettle();
      expect(repo.reviewCalls.single['approve'], true);
      expect(repo.reviewCalls.single['version'], 2);
      expect(find.text('Documento aprobado.'), findsOneWidget);
    });
  });

  group('decisión final', () {
    testWidgets('motivo de 10+ caracteres y la carga correcta', (t) async {
      await pump(t);
      await t.tap(find.text('Decisión final'));
      await t.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('drvapp-reason-confirm'));
      final field = find.byKey(const ValueKey('drvapp-reason-field'));

      await t.tap(find.text('Pedir cambios'));
      await t.enterText(field, 'Muy corto');
      await t.pump();
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      expect(find.text('Escribe al menos 10 caracteres.'), findsOneWidget);

      await t.enterText(field, '  Falta la foto del interior trasero  ');
      await t.pump();
      expect(t.widget<FilledButton>(confirm).onPressed, isNotNull);
      await t.tap(confirm);
      await t.pumpAndSettle();
      expect(repo.decideCalls, [
        {
          'driverId': 'chofer-1',
          'decision': DriverAppDecision.needsChanges,
          'reason': 'Falta la foto del interior trasero',
        },
      ]);
      expect(find.text('Decisión guardada: Necesita cambios.'), findsOneWidget);
    });

    testWidgets('documents_not_approved: se explica sin perder el motivo',
        (t) async {
      repo.decideAnswers = [
        const Left(
          DriverAppFailure(
            'No se puede aprobar: estos documentos obligatorios no están '
            'aprobados o vigentes: Certificado de antecedentes.',
          ),
        ),
      ];
      await pump(t);
      await t.tap(find.byKey(const ValueKey('drvapp-decide')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('drvapp-choice-approve')));
      await t.enterText(
        find.byKey(const ValueKey('drvapp-reason-field')),
        'Todo revisado y en orden',
      );
      await t.pump();
      await t.tap(find.byKey(const ValueKey('drvapp-reason-confirm')));
      await t.pumpAndSettle();
      expect(repo.decideCalls.single['decision'], DriverAppDecision.approve);
      expect(find.byKey(const ValueKey('drvapp-reason-error')), findsOneWidget);
      expect(find.textContaining('No se puede aprobar'), findsOneWidget);
      expect(find.text('Todo revisado y en orden'), findsOneWidget);
    });

    testWidgets('una solicitud aprobada ya no admite decisión', (t) async {
      repo.detailAnswer = Right(fakeDetail(status: DriverAppStatus.approved));
      await pump(t);
      final b = t.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('drvapp-decide')),
      );
      expect(b.onPressed, isNull);
    });
  });

  group('bitácora de accesos', () {
    testWidgets('quién y cuándo, sin URL', (t) async {
      repo.logAnswer = Right([
        DocAccessEntry(
          adminId: 'admin-1',
          adminEmail: 'central@example.com',
          type: DriverDocType.licenseFront,
          version: 2,
          at: DateTime(2026, 10, 21, 10, 5),
        ),
        DocAccessEntry(
          adminId: 'abcdef123',
          type: DriverDocType.criminalRecord,
          version: 1,
          at: DateTime(2026, 10, 20, 18),
        ),
      ]);
      await pump(t);
      await t.tap(find.text('Bitácora de accesos'));
      await t.pumpAndSettle();
      expect(repo.logCalls, ['chofer-1']);
      expect(find.byKey(const ValueKey('drvapp-access-log')), findsOneWidget);
      expect(
        find.text('Licencia de conducir (anverso) · versión 2'),
        findsOneWidget,
      );
      expect(
        find.text('central@example.com · 21/10/2026 10:05'),
        findsOneWidget,
      );
      expect(
          find.text('Administrador ABCDEF · 20/10/2026 18:00'), findsOneWidget);
      expect(find.textContaining('https://'), findsNothing);
    });

    testWidgets('vacía', (t) async {
      await pump(t);
      await t.tap(find.byKey(const ValueKey('drvapp-access-log-open')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('drvapp-access-log-empty')),
        findsOneWidget,
      );
    });
  });

  group('pantallas y texto grande', () {
    for (final w in [390.0, 768.0, 1280.0]) {
      testWidgets('detalle a $w px con texto ×2 sin desbordes', (t) async {
        await pump(t, width: w, textScale: 2);
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const ValueKey('drvapp-decide')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('botones de al menos 48 px', (t) async {
      await pump(t, width: 390);
      for (final k in [
        'drvapp-back',
        'drvapp-decide',
        'drvapp-access-log-open',
      ]) {
        final s = t.getSize(find.byKey(ValueKey(k)));
        expect(s.height >= 48 && s.width >= 48, isTrue, reason: '$k: $s');
      }
    });
  });
}
