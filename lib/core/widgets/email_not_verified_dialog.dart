import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('Verifica tu correo para reservar'),
        content: const Text(
          'Por seguridad, solo se puede reservar con el correo verificado. '
          'Abre el enlace que te enviamos o pide uno nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/verify-email');
            },
            child: const Text('Verificar mi correo'),
          ),
        ],
      );
}
