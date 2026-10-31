import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Reservar exige los términos vigentes (createBooking: terms_required):
/// enlaces a los textos y «Aceptar», que lo anota en el servidor.
class TermsRequiredDialog extends StatefulWidget {
  const TermsRequiredDialog({super.key, required this.repository});

  final AuthRepository repository;

  /// true si quedó aceptado.
  static Future<bool> show(
    BuildContext context, {
    AuthRepository? repository,
  }) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => TermsRequiredDialog(
            repository: repository ?? sl<AuthRepository>(),
          ),
        ) ??
        false;
    if (ok && context.mounted) {
      showLuxSnackbar(context, context.l10n.authTermsAcceptedSnack);
    }
    return ok;
  }

  @override
  State<TermsRequiredDialog> createState() => _TermsRequiredDialogState();
}

class _TermsRequiredDialogState extends State<TermsRequiredDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.repository.acceptTerms();
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _busy = false;
        _error = f.message;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.authTermsDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.authTermsDialogBody),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => context.push('/legal/terminos'),
                  child: Text(context.l10n.authTermsRead),
                ),
                TextButton(
                  onPressed: () => context.push('/legal/privacidad'),
                  child: Text(context.l10n.authPrivacyRead),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(context.l10n.authNotNow),
          ),
          FilledButton(
            onPressed: _busy ? null : _accept,
            child: Text(context.l10n.authAccept),
          ),
        ],
      );
}
