import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/mfa.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Alta de la app autenticadora (TOTP) para chóferes y administradores.
///
/// El secreto solo vive en memoria mientras dura la pantalla: no se guarda,
/// no se registra en logs y la clave escrita se oculta salvo que se pida
/// verla. El código QR contiene el mismo secreto: no hagas capturas.
class MfaEnrollPage extends StatefulWidget {
  const MfaEnrollPage({
    super.key,
    required this.accountName,
    this.service,
    this.onDone,
  });

  final String accountName;
  final MfaService? service;
  final VoidCallback? onDone;

  @override
  State<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends State<MfaEnrollPage> {
  late final MfaService _mfa = widget.service ?? sl<MfaService>();
  final _code = TextEditingController();
  TotpEnrollment? _enrollment;
  bool _busy = false;
  bool _showKey = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _enrollment = null;
    super.dispose();
  }

  String _errorFor(Object e) =>
      mfaErrorMessage(e is PlatformException ? e.code : _codeOf(e));

  String _codeOf(Object e) {
    try {
      return (e as dynamic).code as String;
    } catch (_) {
      return '';
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final e = await _mfa.startTotpEnrollment(accountName: widget.accountName);
      if (!mounted) return;
      setState(() => _enrollment = e);
    } catch (e) {
      if (mounted) setState(() => _error = _errorFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final e = _enrollment;
    final code = _code.text.trim();
    if (e == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = context.l10n.authMfaCodeDigits);
      return;
    }
    if (e.deadline != null && DateTime.now().isAfter(e.deadline!)) {
      setState(() {
        _enrollment = null;
        _error = mfaErrorMessage('code-expired');
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _mfa.finishTotpEnrollment(e, code);
      if (!mounted) return;
      setState(() {
        _done = true;
        _enrollment = null;
      });
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = _errorFor(err);
          _code.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _enrollment;
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.authMfaTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            if (_done) ...[
              Text(
                t.authMfaEnrollDone,
                style: LuxTypography.bodyLarge,
              ),
              const SizedBox(height: LuxSpacing.lg),
              LuxButton(
                label: t.authMfaBack,
                onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
              ),
            ] else if (e == null) ...[
              Text(
                t.authMfaEnrollIntro,
                style: LuxTypography.bodyLarge,
              ),
              const SizedBox(height: LuxSpacing.lg),
              LuxButton(
                label: t.authMfaStart,
                loading: _busy,
                onPressed: _busy ? null : _start,
              ),
            ] else ...[
              Text(
                t.authMfaScanStep,
                style: LuxTypography.bodyLarge,
              ),
              const SizedBox(height: LuxSpacing.md),
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(LuxSpacing.sm),
                  child: QrImageView(
                    key: const ValueKey('mfa-qr'),
                    data: e.qrCodeUrl,
                    size: 200,
                    semanticsLabel: t.authMfaQrSemantics,
                  ),
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              if (_mfa.canOpenInAuthenticator)
                LuxButton.ghost(
                  label: t.authMfaOpenInApp,
                  onPressed: () => _mfa.openInAuthenticator(e),
                ),
              const SizedBox(height: LuxSpacing.sm),
              Text(
                t.authMfaManualKey(_showKey ? e.secretKey : '••••••••••••'),
                key: const ValueKey('mfa-key'),
                style: LuxTypography.bodyMedium,
              ),
              TextButton(
                onPressed: () => setState(() => _showKey = !_showKey),
                child: Text(_showKey ? t.authMfaHideKey : t.authMfaShowKey),
              ),
              Text(
                t.authMfaNoShare,
                style: LuxTypography.caption,
              ),
              const SizedBox(height: LuxSpacing.lg),
              Text(
                t.authMfaCodeStep,
                style: LuxTypography.bodyLarge,
              ),
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                key: const ValueKey('mfa-enroll-code'),
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(labelText: t.authMfaCodeLabel),
                onSubmitted: (_) => _finish(),
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxButton(
                label: t.authMfaActivate,
                loading: _busy,
                onPressed: _busy ? null : _finish,
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: LuxSpacing.md),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const ValueKey('mfa-error'),
                    style: LuxTypography.bodyMedium
                        .copyWith(color: LuxColors.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
