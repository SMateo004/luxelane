import 'package:flutter/material.dart';

import '../../../../core/auth/mfa.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../pages/mfa_sign_in_page.dart';

/// Para las acciones que no se repiten solas (tarjetas, panel admin): tras
/// confirmar la identidad, se pide repetirla.
Future<void> confirmIdentityThenRetry(
  BuildContext context, {
  AuthRepository? repository,
}) async {
  if (await ReauthDialog.show(context, repository: repository) &&
      context.mounted) {
    showLuxSnackbar(context, context.l10n.authReauthConfirmed);
  }
}

/// El servidor respondió reauth_required (decisión 6): borrar la cuenta,
/// cambiar la tarjeta o el panel admin con una sesión antigua. Pide volver a
/// identificarse sin salir de la pantalla; true si se logró.
class ReauthDialog extends StatefulWidget {
  const ReauthDialog({super.key, required this.repository});

  final AuthRepository repository;

  static Future<bool> show(BuildContext context,
          {AuthRepository? repository}) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            ReauthDialog(repository: repository ?? sl<AuthRepository>()),
      ) ??
      false;

  @override
  State<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<ReauthDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm({String? password}) async {
    if (password != null && password.isEmpty) {
      setState(() => _error = context.l10n.authReauthPasswordEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.repository.reauthenticate(password: password);
    if (!mounted) return;
    final failure = r.fold((f) => f, (_) => null);
    if (failure == null) return Navigator.of(context).pop(true);
    if (failure is MfaRequiredFailure) {
      final ok = await _secondFactor(failure.challenge);
      if (!mounted) return;
      if (ok) return Navigator.of(context).pop(true);
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _busy = false;
      _error = failure is AuthCancelledFailure ? null : failure.message;
      _password.clear();
    });
  }

  Future<bool> _secondFactor(MfaChallenge challenge) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (page) => MfaSignInPage(
            challenge: challenge,
            onSignedIn: (_) => Navigator.of(page).pop(true),
            onCancel: () => Navigator.of(page).pop(false),
          ),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final method = widget.repository.reauthMethod;
    final t = context.l10n;
    return AlertDialog(
      title: Text(t.authReauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (method) {
              ReauthMethod.password => t.authReauthPassword,
              ReauthMethod.google => t.authReauthGoogle,
              ReauthMethod.none => t.authReauthNone,
            },
          ),
          if (method == ReauthMethod.password) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('reauth-password'),
              controller: _password,
              obscureText: true,
              autofocus: true,
              enabled: !_busy,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: t.authPasswordLabel),
              onSubmitted: (v) => _confirm(password: v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.authCancel),
        ),
        if (method == ReauthMethod.password)
          FilledButton(
            onPressed: _busy ? null : () => _confirm(password: _password.text),
            child: Text(t.authConfirm),
          ),
        if (method == ReauthMethod.google)
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: Text(t.authGoogleContinue),
          ),
      ],
    );
  }
}
