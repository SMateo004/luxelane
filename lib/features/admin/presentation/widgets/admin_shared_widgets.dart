import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';

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
        borderRadius: BorderRadius.circular(LuxRadius.sm),
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
    fillColor: LuxColors.surfaceMuted,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? LuxColors.sapphire : LuxColors.surfaceMuted,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? LuxColors.sapphire
                  : LuxColors.ink.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: LuxTypography.bodyMedium.copyWith(
              color: selected ? LuxColors.onAccent : LuxColors.ink,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
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
  Widget build(BuildContext context) => ListTile(
        selected: selected,
        onTap: onTap,
        leading: Icon(icon,
            color: selected ? LuxColors.sapphire : LuxColors.inkTertiary),
        title: Text(label,
            style: LuxTypography.bodyLarge.copyWith(
              color: selected ? LuxColors.sapphire : LuxColors.ink,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
        trailing: (badge ?? 0) > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: LuxColors.warning.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('$badge',
                    style: LuxTypography.caption.copyWith(
                        color: LuxColors.warning, fontWeight: FontWeight.w700)),
              )
            : null,
        dense: true,
      );
}

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.count});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? LuxColors.sapphire : LuxColors.surfaceMuted,
            borderRadius: BorderRadius.circular(LuxRadius.sm),
            border: Border.all(
                color: selected ? LuxColors.sapphire : LuxColors.border),
          ),
          child: Text(count == null ? label : '$label · $count',
              style: LuxTypography.caption.copyWith(
                  color: selected ? LuxColors.ink : LuxColors.inkTertiary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
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
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.caption
                            .copyWith(color: LuxColors.inkSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: LuxTypography.headlineLarge.copyWith(
                        color: color,
                        fontFamily: 'Cormorant Garamond',
                        fontSize: 32)),
              ),
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
    final fg = !enabled
        ? LuxColors.inkTertiary
        : filled
            ? LuxColors.onAccent
            : color;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: filled && enabled ? LuxColors.sapphire : null,
        side: BorderSide(
            color: enabled
                ? (filled ? LuxColors.sapphire : color.withOpacity(0.5))
                : LuxColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxRadius.sm)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: LuxTypography.caption
                  .copyWith(color: fg, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label.toUpperCase(),
            style: LuxTypography.caption.copyWith(
                color: color, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      );
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow(
      {super.key, required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: LuxTypography.bodyMedium
                      .copyWith(color: LuxColors.inkTertiary)),
            ),
            const SizedBox(width: LuxSpacing.md),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: LuxTypography.bodyMedium.copyWith(
                      color: valueColor ?? LuxColors.ink,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty(
      {super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: LuxColors.inkTertiary),
              const SizedBox(height: LuxSpacing.md),
              Text(title,
                  style: LuxTypography.titleMedium,
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: LuxSpacing.sm),
                Text(subtitle!,
                    style: LuxTypography.caption, textAlign: TextAlign.center),
              ],
            ],
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
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final canConfirm = reasonLabel == null || ctrl.text.trim().length >= 3;
        return AlertDialog(
          backgroundColor: LuxColors.surfaceMuted,
          title: Text(title, style: LuxTypography.titleLarge),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: LuxTypography.bodyMedium),
                if (reasonLabel != null) ...[
                  const SizedBox(height: LuxSpacing.md),
                  Text(reasonLabel, style: LuxTypography.caption),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLines: 2,
                    style: LuxTypography.bodyMedium,
                    onChanged: (_) => setState(() {}),
                    decoration:
                        adminInputDecoration(hint: 'Obligatorio (auditoría)'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: canConfirm
                  ? () => Navigator.pop(ctx, ctrl.text.trim())
                  : null,
              child: Text(confirmLabel,
                  style: TextStyle(
                      color: !canConfirm
                          ? LuxColors.inkTertiary
                          : destructive
                              ? LuxColors.error
                              : LuxColors.sapphire,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    ),
  ).whenComplete(ctrl.dispose);
}
