import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/company/data/company_invite_service.dart';
import 'package:luxelane/features/company/presentation/widgets/company_invite_card.dart';

import 'helpers/l10n.dart';

class _FakeService implements CompanyInviteService {
  _FakeService(this._status, {this.joinError});
  CompanyInviteStatus _status;
  String? joinError;
  int verificationsSent = 0;
  int joins = 0;

  @override
  Future<CompanyInviteStatus> status() async => _status;
  @override
  Future<String?> join() async {
    joins++;
    if (joinError == null) _status = CompanyInviteStatus.none;
    return joinError;
  }

  int declines = 0;
  @override
  Future<String?> decline() async {
    declines++;
    _status = CompanyInviteStatus.none;
    return null;
  }

  @override
  Future<void> sendVerificationEmail() async => verificationsSent++;
}

void main() {
  testWidgets('hidden without an invite', (tester) async {
    await tester.pumpWidget(localizedApp(Scaffold(body: CompanyInviteCard(service: _FakeService(CompanyInviteStatus.none)))));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    expect(find.textContaining('te invitó'), findsNothing);
  });

  for (final width in const [360.0, 1280.0]) {
    testWidgets('unverified e-mail: verify first, then join (${width.toInt()}px)', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final svc = _FakeService(const CompanyInviteStatus(company: 'Acme'), joinError: 'company/email-not-verified');
      await tester.pumpWidget(localizedApp(Scaffold(body: SingleChildScrollView(child: CompanyInviteCard(service: svc)))));
      await tester.pumpAndSettle();
      expect(find.text('Acme te invitó a su cuenta de empresa'), findsOneWidget);
      expect(find.textContaining('primero confirma que este correo es tuyo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('ENVIAR CORREO DE VERIFICACIÓN'));
      await tester.pumpAndSettle();
      expect(svc.verificationsSent, 1);
      expect(find.textContaining('Te enviamos el correo'), findsOneWidget);

      await tester.tap(find.text('YA LO VERIFIQUÉ, UNIRME'));
      await tester.pumpAndSettle();
      expect(find.text('Tu correo aún no está verificado. Abre el enlace que te enviamos.'), findsOneWidget);
    });
  }

  testWidgets('verified e-mail joins (en)', (tester) async {
    final svc = _FakeService(const CompanyInviteStatus(company: 'Acme', verified: true));
    await tester.pumpWidget(localizedApp(Scaffold(body: CompanyInviteCard(service: svc)), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('SEND VERIFICATION E-MAIL'), findsNothing);
    await tester.tap(find.text('JOIN'));
    await tester.pumpAndSettle();
    expect(svc.joins, 1);
    expect(find.text('You joined Acme'), findsOneWidget);
    expect(find.text('Acme invited you to its company account'), findsNothing);
  });

  testWidgets('declining removes the invite', (tester) async {
    final svc = _FakeService(const CompanyInviteStatus(company: 'Acme', verified: true));
    await tester.pumpWidget(localizedApp(Scaffold(body: CompanyInviteCard(service: svc))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tus viajes personales siguen siendo tuyos'), findsOneWidget);
    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(svc.declines, 1);
    expect(find.text('Rechazaste la invitación'), findsOneWidget);
    expect(find.text('Acme te invitó a su cuenta de empresa'), findsNothing);
  });
}
