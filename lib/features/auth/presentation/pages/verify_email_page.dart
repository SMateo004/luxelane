import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';

/// «Verifica tu correo»: tras registrarse con correo y contraseña. Reservar
/// exige el correo verificado; el resto de la app funciona sin él.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
    this.repository,
    this.email,
    this.cooldown = const Duration(seconds: 60),
    this.maxResends = 5,
    this.onDone,
  });

  /// Sustituible en tests.
  final AuthRepository? repository;
  final String? email;

  /// Espera entre reenvíos y reenvíos por visita (Auth además limita).
  final Duration cooldown;
  final int maxResends;

  /// Al terminar (verificado o «más tarde»); por defecto vuelve al inicio.
  final VoidCallback? onDone;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late final AuthRepository _repo = widget.repository ?? sl<AuthRepository>();
  Timer? _timer;
  int _wait = 0;
  int _resends = 0;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    // El registro ya envió el primer enlace.
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
      if (_wait == 0) t.cancel();
    });
  }

  void _done() {
    final cb = widget.onDone;
    if (cb != null) return cb();
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go(from != null && from.startsWith('/') ? from : '/');
  }

  Future<void> _resend() async {
    if (_busy || _wait > 0 || _resends >= widget.maxResends) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final r = await _repo.sendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _busy = false;
      r.fold((f) => _error = f.message, (_) {
        _resends++;
        _info = 'Te enviamos un enlace nuevo.';
      });
    });
    final tooMany = r.fold(
      (f) =>
          f is EmailVerificationFailure &&
          f.issue == EmailVerificationIssue.tooManyRequests,
      (_) => false,
    );
    if (r.isRight() || tooMany) _startCooldown();
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final r = await _repo.refreshEmailVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (f) => setState(() => _error = f.message),
      (verified) {
        if (verified) {
          showLuxSnackbar(context, 'Correo verificado. Ya puedes reservar.');
          _done();
        } else {
          setState(
            () => _error = 'Aún no vemos el correo verificado. Abre el '
                'enlace que te enviamos y vuelve a intentarlo.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exhausted = _resends >= widget.maxResends;
    final resendLabel = exhausted
        ? 'Límite de reenvíos alcanzado'
        : _wait > 0
            ? 'Reenviar enlace ($_wait s)'
            : 'Reenviar enlace';
    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            Text(
              widget.email == null
                  ? 'Te enviamos un enlace a tu correo.'
                  : 'Te enviamos un enlace a ${widget.email}.',
              style: LuxTypography.titleMedium,
            ),
            const SizedBox(height: LuxSpacing.sm),
            const Text(
              'Ábrelo y vuelve aquí. Necesitas el correo verificado para '
              'reservar. Si el enlace venció o no llega, pide uno nuevo '
              '(revisa también la carpeta de correo no deseado).',
              style: LuxTypography.bodyMedium,
            ),
            const SizedBox(height: LuxSpacing.lg),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const ValueKey('verify-error'),
                    style: LuxTypography.bodyMedium
                        .copyWith(color: LuxColors.error),
                  ),
                ),
              ),
            if (_info != null)
              Padding(
                padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                child: Text(_info!, style: LuxTypography.bodyMedium),
              ),
            LuxButton(
              label: 'Ya lo verifiqué',
              loading: _busy,
              onPressed: _busy ? null : _check,
            ),
            const SizedBox(height: LuxSpacing.sm),
            LuxOutlinedButton(
              label: resendLabel,
              onPressed:
                  _busy || _wait > 0 || exhausted ? null : () => _resend(),
            ),
            const SizedBox(height: LuxSpacing.sm),
            LuxButton.ghost(label: 'Más tarde', onPressed: _done),
          ],
        ),
      ),
    );
  }
}
