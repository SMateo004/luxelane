import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_driver_applications.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_driver_applications_tab.dart';

import 'driver_applications_fakes.dart';

/// Panel, solicitudes de chófer (B2): bandeja por estado, vacía y con
/// error; vencimientos próximos y autorizar en línea.
void main() {
  late FakeDriverAppsRepo repo;

  setUp(() => repo = FakeDriverAppsRepo());

  Future<void> pump(WidgetTester t, {double width = 1280}) => pumpPanel(
        t,
        DriverApplicationsTab(repository: repo),
        width: width,
      );

  group('bandeja', () {
    testWidgets('filtra por estado y ordena lo más reciente primero',
        (t) async {
      repo.inboxes[DriverAppStatus.submitted] = Right(
        DriverAppInbox(
          items: [
            fakeSummary(
              'a',
              name: 'Ana Prueba',
              email: 'ana@example.com',
              submittedAt: DateTime(2026, 10, 1, 8),
            ),
          ],
        ),
      );
      repo.inboxes[DriverAppStatus.needsChanges] = Right(
        DriverAppInbox(
          items: [
            fakeSummary(
              'b',
              status: DriverAppStatus.needsChanges,
              email: 'beto@example.com',
              submittedAt: DateTime(2026, 9, 1, 8),
            ),
          ],
        ),
      );
      await pump(t);
      expect(repo.inboxCalls, [DriverAppStatus.submitted]);
      expect(find.text('Ana Prueba'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text('Enviada el 01/10/2026 08:00'), findsOneWidget);
      expect(find.text('beto@example.com'), findsNothing);

      await t.tap(find.byKey(const ValueKey('drvapp-status-needs_changes')));
      await t.pumpAndSettle();
      expect(repo.inboxCalls.last, DriverAppStatus.needsChanges);
      expect(find.text('Ana Prueba'), findsNothing);
      // Sin nombre: el correo hace de título.
      expect(find.text('beto@example.com'), findsOneWidget);
    });

    testWidgets('vacía: lo dice y sugiere cambiar de estado', (t) async {
      await pump(t);
      expect(
        find.byKey(const ValueKey('drvapp-inbox-empty')),
        findsOneWidget,
      );
      expect(find.text('No hay solicitudes en este estado'), findsOneWidget);
    });

    testWidgets('error: mensaje y reintentar vuelve a pedir', (t) async {
      repo.inboxes[DriverAppStatus.submitted] =
          const Left(DriverAppFailure('Sin conexión de prueba'));
      await pump(t);
      expect(
        find.byKey(const ValueKey('drvapp-inbox-error')),
        findsOneWidget,
      );
      expect(
          find.text('No se pudieron cargar las solicitudes.'), findsOneWidget);
      expect(find.text('Sin conexión de prueba'), findsOneWidget);

      repo.inboxes[DriverAppStatus.submitted] = Right(
        DriverAppInbox(items: [fakeSummary('a', name: 'Ana Prueba')]),
      );
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();
      expect(repo.inboxCalls.length, 2);
      expect(find.text('Ana Prueba'), findsOneWidget);
    });

    testWidgets('abrir una fila muestra el detalle y volver, la bandeja',
        (t) async {
      repo.inboxes[DriverAppStatus.submitted] = Right(
        DriverAppInbox(items: [fakeSummary('chofer-1', name: 'Luis Prueba')]),
      );
      await pump(t);
      await t.tap(find.byKey(const ValueKey('drvapp-row-chofer-1')));
      await t.pumpAndSettle();
      expect(repo.detailCalls, ['chofer-1']);
      expect(find.byKey(const ValueKey('drvapp-detail')), findsOneWidget);
      await t.tap(find.text('Volver a la bandeja'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('drvapp-inbox-list')), findsOneWidget);
    });
  });

  group('vencimientos próximos', () {
    final soon = DateTime.now().add(const Duration(days: 10));
    final past = DateTime.now().subtract(const Duration(days: 2));

    testWidgets('lista por periodo; autorizar en línea pide motivo', (t) async {
      repo.expiriesAnswer = Right(
        DocExpiries(
          items: [
            DocExpiryItem(
              driverId: 'd1',
              type: DriverDocType.vehicleSoat,
              status: DriverDocStatus.expired,
              expiresAt: past,
              name: 'Carla Prueba',
              email: 'carla@example.com',
              docsBlocked: true,
            ),
            DocExpiryItem(
              driverId: 'd2',
              type: DriverDocType.licenseFront,
              status: DriverDocStatus.approved,
              expiresAt: soon,
              email: 'dario@example.com',
            ),
          ],
        ),
      );
      await pump(t);
      await t.tap(find.text('Vencimientos próximos'));
      await t.pumpAndSettle();
      expect(repo.expiriesCalls, [30]);
      expect(find.text('Carla Prueba'), findsOneWidget);
      expect(find.text('dario@example.com'), findsOneWidget);
      expect(find.text('Bloqueado para ponerse en línea'), findsOneWidget);
      // Solo el bloqueado se puede autorizar.
      expect(find.byKey(const ValueKey('drvapp-allow-d1')), findsOneWidget);
      expect(find.byKey(const ValueKey('drvapp-allow-d2')), findsNothing);

      await t.tap(find.byKey(const ValueKey('drvapp-days-7')));
      await t.pumpAndSettle();
      expect(repo.expiriesCalls, [30, 7]);

      await t.tap(find.text('Autorizar en línea'));
      await t.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('drvapp-reason-confirm'));
      await t.enterText(
        find.byKey(const ValueKey('drvapp-reason-field')),
        'corto',
      );
      await t.pump();
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      expect(find.text('Escribe al menos 10 caracteres.'), findsOneWidget);
      await t.enterText(
        find.byKey(const ValueKey('drvapp-reason-field')),
        'Renovación en trámite, comprobante visto',
      );
      await t.pump();
      await t.tap(confirm);
      await t.pumpAndSettle();
      expect(repo.allowCalls, [
        {
          'driverId': 'd1',
          'reason': 'Renovación en trámite, comprobante visto'
        },
      ]);
      expect(find.text('Chófer autorizado para ponerse en línea.'),
          findsOneWidget);
    });

    testWidgets('vacía y con error', (t) async {
      await pump(t);
      await t.tap(find.byKey(const ValueKey('drvapp-view-expiries')));
      await t.pumpAndSettle();
      expect(
        find.text('Ningún documento vence en los próximos 30 días.'),
        findsOneWidget,
      );

      repo.expiriesAnswer = const Left(DriverAppFailure('Error de prueba'));
      await t.tap(find.byKey(const ValueKey('drvapp-expiries-reload')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('drvapp-expiries-error')),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('pantallas y texto grande', () {
    for (final w in [390.0, 768.0, 1280.0]) {
      testWidgets('bandeja y vencimientos a $w px con texto ×2', (t) async {
        repo.inboxes[DriverAppStatus.submitted] = Right(
          DriverAppInbox(
            items: [
              fakeSummary(
                'a',
                name: 'Ana Prueba con un nombre bastante largo',
                email: 'ana.prueba.larga@example.com',
                submittedAt: DateTime(2026, 10, 1, 8),
              ),
            ],
            truncated: true,
          ),
        );
        repo.expiriesAnswer = Right(
          DocExpiries(
            truncated: true,
            items: [
              DocExpiryItem(
                driverId: 'd1',
                type: DriverDocType.vehicleInsurance,
                status: DriverDocStatus.expired,
                expiresAt: DateTime(2026, 1, 2),
                name: 'Carla Prueba',
                docsBlocked: true,
              ),
            ],
          ),
        );
        await pumpPanel(
          t,
          DriverApplicationsTab(repository: repo),
          width: w,
          textScale: 2,
        );
        expect(t.takeException(), isNull);
        expect(find.text('Ana Prueba con un nombre bastante largo'),
            findsOneWidget);
        await t.tap(find.byKey(const ValueKey('drvapp-view-expiries')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('drvapp-allow-d1')),
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('drvapp-expiries-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(t.takeException(), isNull);
      });
    }
  });
}
