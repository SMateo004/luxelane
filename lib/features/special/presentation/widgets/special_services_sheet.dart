import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/special_models.dart';

/// Acceso secundario a los servicios especiales. Texto tenue, sin relleno ni
/// insignias: está para quien lo busca, sin competir con "Ver precios".
class MoreServicesLink extends StatefulWidget {
  const MoreServicesLink({super.key, this.onDark = false});

  /// Sobre la foto del hero (web) o sobre fondo claro (app).
  final bool onDark;

  @override
  State<MoreServicesLink> createState() => _MoreServicesLinkState();
}

class _MoreServicesLinkState extends State<MoreServicesLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.onDark ? Colors.white : LuxColors.inkTertiary;
    final color = widget.onDark
        ? base.withAlpha(_hover ? 230 : 140)
        : (_hover ? LuxColors.inkSecondary : base);
    return Semantics(
      button: true,
      label: 'Más servicios',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showSpecialServices(context),
          child: Padding(
            // Área táctil cómoda aunque el texto sea pequeño.
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Más servicios',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                      color: color,
                      decoration: _hover
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja (móvil) o diálogo (escritorio) con los servicios especiales.
Future<void> showSpecialServices(BuildContext context) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (wide) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: LuxColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.lg)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: _SpecialServicesContent(),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: LuxColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
    ),
    builder: (ctx) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: _SpecialServicesContent(showHandle: true),
      ),
    ),
  );
}

class _SpecialServicesContent extends StatelessWidget {
  const _SpecialServicesContent({this.showHandle = false});
  final bool showHandle;

  void _open(BuildContext context, String path) {
    Navigator.of(context, rootNavigator: true).pop();
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.read<AuthBloc>().state is AuthAuthenticated;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: LuxColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Text('SERVICIOS ESPECIALES',
            style: LuxTypography.caption
                .copyWith(letterSpacing: 2, color: LuxColors.inkTertiary)),
        const SizedBox(height: 6),
        const Text('Para ocasiones fuera de lo habitual',
            style: LuxTypography.titleLarge),
        const SizedBox(height: 4),
        Text('Bajo solicitud: te enviamos una cotización sin compromiso.',
            style:
                LuxTypography.caption.copyWith(color: LuxColors.inkSecondary)),
        const SizedBox(height: 16),
        for (final k in SpecialKind.values) ...[
          _SpecialOption(
              kind: k, onTap: () => _open(context, '/especiales/${k.slug}')),
          const SizedBox(height: 8),
        ],
        if (signedIn)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _open(context, '/especiales'),
              style: TextButton.styleFrom(
                  foregroundColor: LuxColors.inkSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: const Text('Mis solicitudes'),
            ),
          ),
      ],
    );
  }
}

class _SpecialOption extends StatelessWidget {
  const _SpecialOption({required this.kind, required this.onTap});
  final SpecialKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuxRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuxRadius.md),
              border: Border.all(color: LuxColors.border),
            ),
            child: Row(children: [
              Icon(kind.icon, size: 22, color: LuxColors.inkSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kind.label, style: LuxTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(kind.tagline, style: LuxTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: LuxColors.inkTertiary),
            ]),
          ),
        ),
      );
}
