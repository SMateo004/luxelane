import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/widgets/components.dart';
import '../../domain/repositories/admin_repository.dart'
    show kAdminReasonMinLength;

// ─────────────────────────────────────────────────────────────────────────────
// Formato
// ─────────────────────────────────────────────────────────────────────────────

final _money = NumberFormat('#,##0.00', 'es');
final _moneyShort = NumberFormat('#,##0', 'es');

/// Importe en bolivianos con el mismo formato en todo el panel: "Bs 1.234,50".
String bs(double v, {bool short = false}) =>
    'Bs ${(short ? _moneyShort : _money).format(v)}';

String adminDate(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

String shortId(String id) =>
    (id.length > 6 ? id.substring(0, 6) : id).toUpperCase();

InputDecoration adminInputDecoration({
  String? hint,
  String? prefixText,
  String? suffixText,
  Widget? prefixIcon,
}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(LuxRadius.md),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: LuxTypography.caption,
    prefixText: prefixText,
    prefixStyle: LuxTypography.caption.copyWith(color: LuxColors.sapphire),
    suffixText: suffixText,
    suffixStyle: LuxTypography.caption,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: LuxColors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    border: border(LuxColors.border),
    enabledBorder: border(LuxColors.border),
    focusedBorder: border(LuxColors.sapphire),
    errorBorder: border(LuxColors.error),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Navegación
// ─────────────────────────────────────────────────────────────────────────────

class SectionChip extends StatelessWidget {
  const SectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LuxPressable(
        onTap: onTap,
        semanticLabel: label,
        child: LuxTapArea(
            child: AnimatedContainer(
          duration: LuxMotion.of(context, LuxMotion.base),
          curve: LuxMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? LuxColors.ink : LuxColors.surface,
            borderRadius: BorderRadius.circular(100),
            border:
                Border.all(color: selected ? LuxColors.ink : LuxColors.border),
          ),
          child: Text(
            label,
            style: LuxTypography.caption.copyWith(
              fontSize: 13,
              color: selected ? LuxColors.onAccent : LuxColors.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        )),
      );
}

class AdminNavItem extends StatelessWidget {
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Contador de elementos que requieren atención (oculto si es 0 o null).
  final int? badge;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(LuxRadius.md),
            child: AnimatedContainer(
              duration: LuxMotion.of(context, LuxMotion.base),
              curve: LuxMotion.emphasized,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? LuxColors.sapphireTint : Colors.transparent,
                borderRadius: BorderRadius.circular(LuxRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color:
                        selected ? LuxColors.sapphire : LuxColors.inkTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: LuxTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        color:
                            selected ? LuxColors.ink : LuxColors.inkSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if ((badge ?? 0) > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: LuxColors.warning,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: LuxTypography.caption.copyWith(
                          color: LuxColors.onAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Rótulo de un grupo de la barra lateral.
class AdminNavGroup extends StatelessWidget {
  const AdminNavGroup(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
        child: Text(
          label.toUpperCase(),
          style: LuxTypography.eyebrow.copyWith(
            fontSize: 9,
            color: LuxColors.inkTertiary,
          ),
        ),
      );
}

/// Cabecera de cada sección del panel: título grande y una línea de
/// contexto, como una portada.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LuxTypography.displayMedium.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: LuxTypography.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) => LuxPressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: LuxMotion.of(context, LuxMotion.base),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? LuxColors.sapphireTint : LuxColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? LuxColors.sapphire : LuxColors.border,
            ),
          ),
          child: Text(
            count == null ? label : '$label · $count',
            style: LuxTypography.caption.copyWith(
              fontSize: 12,
              color: selected ? LuxColors.sapphire : LuxColors.inkSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicadores
// ─────────────────────────────────────────────────────────────────────────────

class AdminKpiTile extends StatelessWidget {
  const AdminKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.sub,
    this.color = LuxColors.sapphire,
    this.width = 220,
  });
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 15),
                  ),
                  const SizedBox(width: LuxSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption.copyWith(
                        fontSize: 12,
                        color: LuxColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: LuxTypography.headlineLarge.copyWith(
                    color: LuxColors.ink,
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 34,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 2),
              Text(sub, style: LuxTypography.caption),
            ],
          ),
        ),
      );
}

/// Botón compacto de acción del panel; se ajusta a su texto (sin ancho fijo).
class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = LuxColors.sapphire,
    this.filled = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final destructive = color == LuxColors.error;
    final fg = !enabled
        ? LuxColors.inkTertiary
        : filled
            ? LuxColors.onAccent
            : destructive
                ? LuxColors.error
                : LuxColors.ink;
    return OutlinedButton(
      onPressed: onTap == null
          ? null
          : () {
              LuxHaptics.tap();
              onTap!();
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: filled && enabled
            ? (destructive ? LuxColors.error : LuxColors.sapphire)
            : LuxColors.surface,
        side: BorderSide(
          color: !enabled
              ? LuxColors.border
              : filled
                  ? Colors.transparent
                  : destructive
                      ? LuxColors.error.withValues(alpha: 0.4)
                      : LuxColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: LuxTypography.caption.copyWith(
                fontSize: 13,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTag extends StatelessWidget {
  const AdminTag(this.label, {super.key, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: LuxTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: LuxTypography.bodyMedium.copyWith(
                  color: LuxColors.inkTertiary,
                ),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: LuxTypography.bodyMedium.copyWith(
                  color: valueColor ?? LuxColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.xl),
          child: LuxFadeIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxColors.border),
                  ),
                  child: Icon(icon, size: 24, color: LuxColors.sapphire),
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  title,
                  style: LuxTypography.headlineLarge.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: LuxSpacing.sm),
                  Text(
                    subtitle!,
                    style: LuxTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogos
// ─────────────────────────────────────────────────────────────────────────────

/// Confirmación para acciones sensibles. Si [reasonLabel] no es null pide un
/// motivo obligatorio, que queda en la auditoría. Devuelve el motivo ('' si
/// no se pidió) o null si se canceló.
Future<String?> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? reasonLabel,
  bool destructive = false,
  int minReasonLength = kAdminReasonMinLength,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _ConfirmAdminDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        reasonLabel: reasonLabel,
        destructive: destructive,
        minReasonLength: minReasonLength,
      ),
    );

/// Pide el motivo de una escritura de admin (queda en la auditoría del
/// servidor). null si se canceló.
Future<String?> askAdminReason(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) =>
    confirmAdminAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      reasonLabel: 'Motivo',
      destructive: destructive,
    );

/// El diálogo es dueño de su campo de texto: se libera al desmontarse, no
/// al cerrarse (la animación de salida aún lo usa).
class _ConfirmAdminDialog extends StatefulWidget {
  const _ConfirmAdminDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.reasonLabel,
    required this.destructive,
    required this.minReasonLength,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? reasonLabel;
  final bool destructive;
  final int minReasonLength;

  @override
  State<_ConfirmAdminDialog> createState() => _ConfirmAdminDialogState();
}

class _ConfirmAdminDialogState extends State<_ConfirmAdminDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reasonLabel = widget.reasonLabel;
    final canConfirm = reasonLabel == null ||
        _ctrl.text.trim().length >= widget.minReasonLength;
    return AlertDialog(
      title: Text(
        widget.title,
        style: LuxTypography.headlineLarge.copyWith(fontSize: 24),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message, style: LuxTypography.bodyMedium),
            if (reasonLabel != null) ...[
              const SizedBox(height: LuxSpacing.md),
              Text(reasonLabel, style: LuxTypography.caption),
              const SizedBox(height: 4),
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 2,
                style: LuxTypography.bodyMedium,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  hint: 'Obligatorio, mínimo ${widget.minReasonLength} '
                      'caracteres (queda en la auditoría)',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.pop(context, _ctrl.text.trim())
              : null,
          style: FilledButton.styleFrom(
            backgroundColor:
                widget.destructive ? LuxColors.error : LuxColors.sapphire,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
