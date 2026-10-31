import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/widgets/email_not_verified_dialog.dart';
import 'package:luxelane/core/widgets/error_boundary.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Bloque «comunes»: componentes de lib/core/widgets, etiquetas de los enums
/// y mensajes de error del cliente en inglés y portugués.
void main() {
  Widget app(Locale locale, Widget home) => MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: home,
      );

  for (final (code, texts) in [
    (
      'en',
      (
        errorTitle: 'Something went wrong',
        retry: 'Try again',
        dialogTitle: 'Verify your email to book',
        notNow: 'Not now',
        completed: 'Completed',
        electric: 'Electric',
        byTheHour: 'By the hour',
        permission: 'You do not have permission to do this.',
        noConnection:
            'No connection to the server. Check your network and try again.',
      ),
    ),
    (
      'pt',
      (
        errorTitle: 'Algo deu errado',
        retry: 'Tentar novamente',
        dialogTitle: 'Verifique seu e-mail para reservar',
        notNow: 'Agora não',
        completed: 'Concluída',
        electric: 'Elétrico',
        byTheHour: 'Por hora',
        permission: 'Você não tem permissão para fazer isso.',
        noConnection:
            'Sem conexão com o servidor. Verifique sua rede e tente novamente.',
      ),
    ),
  ]) {
    group('idioma $code', () {
      final locale = Locale(code);
      setUp(() => L10n.use(locale));
      tearDown(() => L10n.use(const Locale('es')));

      testWidgets('pantalla de error y aviso de correo sin verificar',
          (t) async {
        await t.pumpWidget(app(locale, LuxErrorScreen(onRetry: () {})));
        expect(find.text(texts.errorTitle), findsOneWidget);
        expect(find.text(texts.retry), findsOneWidget);
        expect(find.text('Algo salió mal'), findsNothing);

        await t.pumpWidget(app(locale, const EmailNotVerifiedDialog()));
        expect(find.text(texts.dialogTitle), findsOneWidget);
        expect(find.text(texts.notNow), findsOneWidget);
        expect(find.text('Verifica tu correo para reservar'), findsNothing);
      });

      test('etiquetas de los enums', () {
        expect(BookingStatus.completed.displayLabel, texts.completed);
        expect(VehicleClass.electric.label, texts.electric);
        expect(ServiceType.byTheHour.label, texts.byTheHour);
        // Los nombres de producto no se traducen.
        expect(VehicleClass.business.label, 'Business Class');
      });

      test('mensajes de function_errors y de los fallos', () {
        expect(
          functionErrorMessage('permission-denied', null),
          texts.permission,
        );
        expect(functionErrorMessage('unavailable', null), texts.noConnection);
        // Los const en español que usan otros bloques se muestran traducidos.
        expect(
          const ServerFailure(kNoConnectionMessage).message,
          texts.noConnection,
        );
      });
    });
  }
}
