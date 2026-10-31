import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';

/// Reservar exige el correo verificado: explica por qué y lleva a
/// «Verifica tu correo».
class EmailNotVerifiedDialog extends StatelessWidget {
  const EmailNotVerifiedDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const EmailNotVerifiedDialog(),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.commonEmailNotVerifiedTitle),
        content: Text(context.l10n.commonEmailNotVerifiedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonNotNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/verify-email');
            },
            child: Text(context.l10n.commonVerifyMyEmail),
          ),
        ],
      );
}
