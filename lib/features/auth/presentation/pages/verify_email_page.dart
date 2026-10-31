import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

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
        _info = context.l10n.authVerifyResent;
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
          showLuxSnackbar(context, context.l10n.authVerifyDone);
          _done();
        } else {
          setState(
            () => _error = context.l10n.authVerifyNotYet,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exhausted = _resends >= widget.maxResends;
    final t = context.l10n;
    final resendLabel = exhausted
        ? t.authVerifyResendLimit
        : _wait > 0
            ? t.authVerifyResendIn(_wait)
            : t.authVerifyResend;
    return Scaffold(
      appBar: AppBar(title: Text(t.authVerifyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            Text(
              widget.email == null
                  ? t.authVerifySentGeneric
                  : t.authVerifySentTo(widget.email!),
              style: LuxTypography.titleMedium,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              t.authVerifyBody,
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
              label: t.authVerifyConfirm,
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
            LuxButton.ghost(label: t.authVerifyLater, onPressed: _done),
          ],
        ),
      ),
    );
  }
}
