import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/mfa.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';

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
      setState(() => _error = 'Escribe las 6 cifras del código.');
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
          title: const Text('Verificación en dos pasos'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancelar',
            onPressed: _busy ? null : widget.onCancel,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              Text(
                widget.challenge.hasTotp
                    ? 'Abre tu app autenticadora y escribe el código de '
                        'Luxelane.'
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
                decoration: const InputDecoration(labelText: 'Código'),
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
                label: 'Entrar',
                loading: _busy,
                onPressed: _busy || !widget.challenge.hasTotp ? null : _submit,
              ),
              const SizedBox(height: LuxSpacing.md),
              const Text(
                '¿Perdiste el acceso a tu app autenticadora? Contacta con '
                'central para recuperar la cuenta.',
                style: LuxTypography.caption,
              ),
            ],
          ),
        ),
      );
}
