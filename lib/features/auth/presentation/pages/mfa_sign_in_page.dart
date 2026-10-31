import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/mfa.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Segundo paso del inicio de sesión: el código de 6 cifras de la app
/// autenticadora (chóferes y administradores).
class MfaSignInPage extends StatefulWidget {
  const MfaSignInPage({
    super.key,
    required this.challenge,
    required this.onSignedIn,
    required this.onCancel,
  });

  final MfaChallenge challenge;
  final ValueChanged<User> onSignedIn;
  final VoidCallback onCancel;

  @override
  State<MfaSignInPage> createState() => _MfaSignInPageState();
}

class _MfaSignInPageState extends State<MfaSignInPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = context.l10n.authMfaCodeDigits);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.challenge.resolve(code);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _busy = false;
        _error = f.message;
        _code.clear();
      }),
      widget.onSignedIn,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.authMfaTitle),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: context.l10n.authCancel,
            onPressed: _busy ? null : widget.onCancel,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              Text(
                widget.challenge.hasTotp
                    ? context.l10n.authMfaSignInPrompt
                    : mfaErrorMessage('no-totp'),
                style: LuxTypography.bodyLarge,
              ),
              const SizedBox(height: LuxSpacing.lg),
              TextField(
                key: const ValueKey('mfa-code'),
                controller: _code,
                enabled: !_busy && widget.challenge.hasTotp,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration:
                    InputDecoration(labelText: context.l10n.authMfaCodeLabel),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: LuxSpacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: LuxTypography.bodyMedium
                          .copyWith(color: LuxColors.error),
                    ),
                  ),
                ),
              const SizedBox(height: LuxSpacing.lg),
              LuxButton(
                label: context.l10n.authMfaSignInButton,
                loading: _busy,
                onPressed: _busy || !widget.challenge.hasTotp ? null : _submit,
              ),
              const SizedBox(height: LuxSpacing.md),
              Text(
                context.l10n.authMfaLostAccess,
                style: LuxTypography.caption,
              ),
            ],
          ),
        ),
      );
}
