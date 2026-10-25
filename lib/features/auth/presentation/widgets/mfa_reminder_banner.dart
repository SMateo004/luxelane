import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/mfa.dart';
import '../../../../core/di/injection.dart';
import '../pages/mfa_enroll_page.dart';

/// Fase 1 (decisión 3): aviso para chóferes y administradores sin app
/// autenticadora registrada. Desaparece al darla de alta.
class MfaReminderBanner extends StatefulWidget {
  const MfaReminderBanner({super.key, required this.accountName, this.service});

  final String accountName;
  final MfaService? service;

  @override
  State<MfaReminderBanner> createState() => _MfaReminderBannerState();
}

class _MfaReminderBannerState extends State<MfaReminderBanner> {
  // Sin servicio registrado (pruebas de otras pantallas), no hay aviso.
  late final MfaService? _mfa = widget.service ??
      (sl.isRegistered<MfaService>() ? sl<MfaService>() : null);
  bool? _enrolled;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final mfa = _mfa;
    if (mfa == null) return;
    try {
      final v = await mfa.hasSecondFactor();
      if (mounted) setState(() => _enrolled = v);
    } catch (_) {
      // Sin red: no se molesta con el aviso.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enrolled != false) return const SizedBox.shrink();
    return Material(
      color: LuxColors.warning.withValues(alpha: 0.12),
      child: ListTile(
        key: const ValueKey('mfa-reminder'),
        leading: const Icon(Icons.shield_outlined, color: LuxColors.warning),
        title: const Text('Activa la verificación en dos pasos'),
        subtitle: const Text(
          'Pronto será obligatoria para entrar. Tarda un minuto.',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MfaEnrollPage(
                accountName: widget.accountName,
                service: _mfa!,
              ),
            ),
          );
          await _check();
        },
      ),
    );
  }
}
