import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/lux_motion.dart';
import '../enums/enums.dart';
import '../models/models.dart';
import 'lux_feedback.dart';
import 'lux_raised.dart';

export 'lux_feedback.dart';
export 'lux_raised.dart' show LuxRaisedVariant, LuxLoadingDots;

// ---------------------------------------------------------------------------
// LuxButton — acción principal (zafiro sólido). Una por pantalla.
// ---------------------------------------------------------------------------

class LuxButton extends StatelessWidget {
  const LuxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.width = double.infinity,
    this.height = 54,
    this.icon,
    this.trailingIcon,
    this.variant = LuxRaisedVariant.primary,
  });

  /// Acción destructiva (cancelar un viaje, eliminar la cuenta).
  const LuxButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.width = double.infinity,
    this.height = 54,
    this.icon,
    this.trailingIcon,
  }) : variant = LuxRaisedVariant.danger;

  /// Acción discreta, solo texto.
  const LuxButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.width = double.infinity,
    this.height = 48,
    this.icon,
    this.trailingIcon,
  }) : variant = LuxRaisedVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double width;
  final double height;
  final IconData? icon;
  final IconData? trailingIcon;
  final LuxRaisedVariant variant;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: LuxRaisedButton(
          label: label,
          onPressed: onPressed,
          loading: loading,
          icon: icon,
          trailingIcon: trailingIcon,
          variant: variant,
          height: height,
          expand: width == double.infinity,
          radius: LuxRadius.md,
          uppercase: false,
          fontSize: 15,
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxOutlinedButton — acción alternativa (blanco con filete).
// ---------------------------------------------------------------------------

class LuxOutlinedButton extends StatelessWidget {
  const LuxOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 54,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: LuxRaisedButton(
          label: label,
          onPressed: onPressed,
          loading: loading,
          icon: icon,
          variant: LuxRaisedVariant.secondary,
          height: height,
          expand: width == double.infinity,
          radius: LuxRadius.md,
          uppercase: false,
          fontSize: 15,
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxPressable — cualquier superficie tocable: se hunde un poco al presionar
// y responde con una vibración leve. Da a tarjetas y filas el mismo tacto
// que a los botones.
// ---------------------------------------------------------------------------

class LuxPressable extends StatefulWidget {
  const LuxPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = LuxMotion.pressedScale,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<LuxPressable> createState() => _LuxPressableState();
}

class _LuxPressableState extends State<LuxPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapCancel: () => _set(false),
          onTapUp: (_) {
            _set(false);
            if (widget.haptic) LuxHaptics.tap();
            widget.onTap!();
          },
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: LuxMotion.of(context, LuxMotion.fast),
            curve: LuxMotion.emphasized,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LuxTextField
// ---------------------------------------------------------------------------

class LuxTextField extends StatelessWidget {
  const LuxTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.maxLines = 1,
    this.autofocus = false,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        maxLines: maxLines,
        autofocus: autofocus,
        inputFormatters: inputFormatters,
        style: LuxTypography.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: LuxColors.inkTertiary, size: 20)
              : null,
          suffixIcon: suffixIcon,
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxCard
// ---------------------------------------------------------------------------

class LuxCard extends StatelessWidget {
  const LuxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LuxSpacing.md),
    this.onTap,
    this.selected = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: LuxPressable(
          onTap: onTap,
          scale: 0.985,
          child: AnimatedContainer(
            duration: LuxMotion.of(context, LuxMotion.base),
            curve: LuxMotion.emphasized,
            padding: padding,
            decoration: BoxDecoration(
              color: selected ? LuxColors.sapphireTint : LuxColors.surface,
              borderRadius: BorderRadius.circular(LuxRadius.lg),
              border: Border.all(
                color: selected ? LuxColors.sapphire : LuxColors.border,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected ? LuxElevation.mid : LuxElevation.low,
            ),
            child: child,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// VehicleCard
// ---------------------------------------------------------------------------

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicleClass,
    required this.price,
    required this.selected,
    required this.onTap,
    this.serviceType = ServiceType.oneWay,
    this.hours,
  });

  final VehicleClass vehicleClass;
  final double price;
  final bool selected;
  final VoidCallback onTap;
  final ServiceType serviceType;
  final int? hours;

  @override
  Widget build(BuildContext context) => LuxCard(
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            _VehicleIcon(vehicleClass: vehicleClass, selected: selected),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicleClass.label, style: LuxTypography.titleLarge),
                  const SizedBox(height: 2),
                  Text(vehicleClass.description, style: LuxTypography.caption),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: LuxColors.inkTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hasta ${vehicleClass.capacity}',
                        style: LuxTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bs${price.toStringAsFixed(0)}',
                  style: LuxTypography.headlineMedium.copyWith(
                    color: selected ? LuxColors.sapphire : LuxColors.ink,
                  ),
                ),
                Text(
                  serviceType == ServiceType.byTheHour
                      ? '${hours ?? 2}h en total'
                      : 'precio fijo',
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ],
        ),
      );
}

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon({required this.vehicleClass, this.selected = false});
  final VehicleClass vehicleClass;
  final bool selected;

  IconData get _icon {
    switch (vehicleClass) {
      case VehicleClass.business:
        return Icons.directions_car_outlined;
      case VehicleClass.firstClass:
        return Icons.star_outline_rounded;
      case VehicleClass.businessVan:
        return Icons.airport_shuttle_outlined;
      case VehicleClass.businessSuv:
        return Icons.directions_car_filled_outlined;
      case VehicleClass.electric:
        return Icons.electric_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? LuxColors.surface : LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
        child: Icon(_icon, color: LuxColors.sapphire, size: 26),
      );
}

// ---------------------------------------------------------------------------
// ServiceTypeTab
// ---------------------------------------------------------------------------

class ServiceTypeTab extends StatelessWidget {
  const ServiceTypeTab({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;

  @override
  Widget build(BuildContext context) => LuxSegmented<ServiceType>(
        values: ServiceType.values,
        selected: selected,
        labelOf: (t) => t.label,
        onChanged: onChanged,
      );
}

/// Control segmentado: una pastilla blanca se desliza sobre un riel gris
/// muy claro. Elegir no debería gritar; el zafiro queda para la acción.
class LuxSegmented<T> extends StatelessWidget {
  const LuxSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = 44,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    final duration = LuxMotion.of(context, LuxMotion.base);
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuxColors.surfaceMuted,
        borderRadius: BorderRadius.circular(LuxRadius.md),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: LuxMotion.emphasized,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: LuxColors.surface,
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140D1B2E),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: v == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (v == selected) return;
                            LuxHaptics.tap();
                            onChanged(v);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: LuxTypography.titleMedium.copyWith(
                                fontSize: 13,
                                color: v == selected
                                    ? LuxColors.ink
                                    : LuxColors.inkTertiary,
                                fontWeight: v == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              child: Text(labelOf(v)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BookingStatusChip
// ---------------------------------------------------------------------------

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});
  final BookingStatus status;

  Color get _color {
    switch (status) {
      case BookingStatus.pending:
        return LuxColors.inkTertiary;
      case BookingStatus.confirmed:
        return LuxColors.sapphire;
      case BookingStatus.driverArriving:
        return LuxColors.sapphireLight;
      case BookingStatus.driverArrived:
        return LuxColors.sapphireLight;
      case BookingStatus.verified:
        return LuxColors.sapphire;
      case BookingStatus.inProgress:
        return LuxColors.success;
      case BookingStatus.completed:
        return LuxColors.success;
      case BookingStatus.cancelled:
        return LuxColors.error;
      // Pendiente de la decisión de central.
      case BookingStatus.noShow:
        return LuxColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LuxRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              status.displayLabel,
              style: LuxTypography.caption.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// LoadingOverlay
// ---------------------------------------------------------------------------

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: LuxColors.bg.withValues(alpha: 0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LuxLoadingDots(color: LuxColors.sapphire, size: 8),
              if (message != null) ...[
                const SizedBox(height: LuxSpacing.md),
                Text(message!, style: LuxTypography.bodyMedium),
              ],
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// EmptyState
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.hourglass_empty_rounded,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.xl),
          child: LuxFadeIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxColors.border),
                  ),
                  child: Icon(icon, color: LuxColors.sapphire, size: 26),
                ),
                const SizedBox(height: LuxSpacing.lg),
                Text(
                  message,
                  style: LuxTypography.headlineLarge.copyWith(
                    color: LuxColors.ink,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: LuxSpacing.lg),
                  LuxButton(
                      label: actionLabel!, onPressed: onAction, width: 220),
                ],
              ],
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// SectionHeader
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  /// Rótulo de sección discreto: mayúsculas pequeñas y espaciadas en tinta
  /// terciaria. Ordena sin competir con el contenido.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: LuxTypography.eyebrow
                    .copyWith(color: LuxColors.inkTertiary),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxGroup / LuxListRow — listas agrupadas: una tarjeta, filas separadas por
// un filete que no llega al borde. El patrón de los ajustes de iOS.
// ---------------------------------------------------------------------------

class LuxGroup extends StatelessWidget {
  const LuxGroup({super.key, required this.children, this.footer});
  final List<Widget> children;

  /// Nota breve bajo el grupo (qué pasa con estos ajustes).
  final String? footer;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: LuxColors.surface,
              borderRadius: BorderRadius.circular(LuxRadius.lg),
              border: Border.all(color: LuxColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 52),
                      child: LuxDivider(),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(footer!, style: LuxTypography.caption),
            ),
        ],
      );
}

class LuxListRow extends StatelessWidget {
  const LuxListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? LuxColors.error : LuxColors.ink;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: destructive ? LuxColors.error : LuxColors.inkSecondary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LuxTypography.bodyLarge.copyWith(
                    color: color,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: LuxTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: LuxColors.inkTertiary,
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          LuxHaptics.tap();
          onTap!();
        },
        child: row,
      ),
    );
  }
}

/// Fila con interruptor: toda la fila es tocable.
class LuxSwitchRow extends StatelessWidget {
  const LuxSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: LuxListRow(
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: () => onChanged(!value),
          trailing: Switch.adaptive(
            value: value,
            onChanged: (v) {
              LuxHaptics.tap();
              onChanged(v);
            },
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// RiderPreferencesNote — lo que el chófer debe saber del pasajero antes de
// recogerlo, en una nota breve y serena.
// ---------------------------------------------------------------------------

class RiderPreferencesNote extends StatelessWidget {
  const RiderPreferencesNote({super.key, required this.preferences});
  final RidePreferences preferences;

  @override
  Widget build(BuildContext context) {
    final notes = preferences.driverNotes;
    if (notes.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuxSpacing.md - 2),
      decoration: BoxDecoration(
        color: LuxColors.sapphireTint,
        borderRadius: BorderRadius.circular(LuxRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTILO DEL PASAJERO',
            style: LuxTypography.eyebrow.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in notes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: LuxColors.surface,
                    borderRadius: BorderRadius.circular(LuxRadius.xl),
                  ),
                  child: Text(
                    n,
                    style: LuxTypography.caption.copyWith(
                      color: LuxColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DriverCard
// ---------------------------------------------------------------------------

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.name,
    required this.rating,
    required this.vehicle,
    this.plate = '',
    this.photoUrl,
  });

  final String name;
  final double rating;
  final String vehicle;
  final String plate;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: LuxColors.sapphireTint,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: LuxTypography.headlineMedium.copyWith(
                        color: LuxColors.sapphire,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: LuxTypography.titleLarge),
                  const SizedBox(height: 2),
                  Text(vehicle, style: LuxTypography.bodyMedium),
                  if (plate.isNotEmpty)
                    Text(plate, style: LuxTypography.caption),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.star_rounded,
                    color: LuxColors.sapphire, size: 18),
                const SizedBox(height: 2),
                Text(rating.toStringAsFixed(1),
                    style: LuxTypography.titleLarge),
              ],
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// PriceEstimateBar
// ---------------------------------------------------------------------------

class PriceEstimateBar extends StatelessWidget {
  const PriceEstimateBar({
    super.key,
    required this.price,
    required this.onConfirm,
    this.loading = false,
    this.label = 'Confirmar reserva',
  });

  final double price;
  final VoidCallback onConfirm;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(
          LuxSpacing.md,
          LuxSpacing.sm,
          LuxSpacing.md,
          LuxSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: LuxColors.surface,
          border: Border(top: BorderSide(color: LuxColors.border)),
          boxShadow: luxSoftShadow,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PRECIO FIJO', style: LuxTypography.caption),
                Text(
                  'Bs${price.toStringAsFixed(0)}',
                  style: LuxTypography.displayMedium.copyWith(
                    color: LuxColors.sapphire,
                  ),
                ),
              ],
            ),
            const SizedBox(width: LuxSpacing.lg),
            Expanded(
              child: LuxButton(
                label: label,
                onPressed: onConfirm,
                loading: loading,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxSnackbar
// ---------------------------------------------------------------------------

void showLuxSnackbar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (isError) {
    LuxHaptics.warning();
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isError
                  ? LuxColors.error.withValues(alpha: 0.1)
                  : LuxColors.sapphireTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.priority_high_rounded : Icons.check_rounded,
              color: isError ? LuxColors.error : LuxColors.sapphire,
              size: 16,
            ),
          ),
          const SizedBox(width: LuxSpacing.md - 4),
          Expanded(
            child: Text(
              message,
              style: LuxTypography.bodyMedium.copyWith(
                color: LuxColors.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: LuxColors.surface,
      elevation: 8,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 3),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxRadius.lg),
        side: const BorderSide(color: LuxColors.border),
      ),
      margin: const EdgeInsets.fromLTRB(
        LuxSpacing.md,
        0,
        LuxSpacing.md,
        LuxSpacing.md,
      ),
      dismissDirection: DismissDirection.down,
    ),
  );
}

// ---------------------------------------------------------------------------
// LuxDivider
// ---------------------------------------------------------------------------

class LuxDivider extends StatelessWidget {
  const LuxDivider({super.key, this.vertical = false});
  final bool vertical;

  @override
  Widget build(BuildContext context) => vertical
      ? Container(width: 1, color: LuxColors.border)
      : Container(height: 1, color: LuxColors.border);
}

// ---------------------------------------------------------------------------
// StepIndicator
// ---------------------------------------------------------------------------

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color: i ~/ 2 < currentStep
                    ? LuxColors.sapphire
                    : LuxColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < currentStep;
          final active = idx == currentStep;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done
                      ? LuxColors.sapphire
                      : active
                          ? LuxColors.sapphireTint
                          : LuxColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        active || done ? LuxColors.sapphire : LuxColors.border,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: LuxColors.onAccent,
                        )
                      : Text(
                          '${idx + 1}',
                          style: LuxTypography.caption.copyWith(
                            color: active
                                ? LuxColors.sapphire
                                : LuxColors.inkTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: LuxTypography.caption.copyWith(
                  color: active ? LuxColors.sapphire : LuxColors.inkTertiary,
                ),
              ),
            ],
          );
        }),
      );
}

// ---------------------------------------------------------------------------
// LuxelaneWordmark — the single brand mark used across web and app:
// a framed serif "L" monogram followed by the spaced LUXELANE logotype.
// Colour adapts to the surrounding theme unless [color] is given.
// ---------------------------------------------------------------------------

class LuxelaneWordmark extends StatelessWidget {
  const LuxelaneWordmark({
    super.key,
    this.size = 12,
    this.color,
    this.showMonogram = true,
  });

  /// Font size of the logotype; the monogram scales with it.
  final double size;
  final Color? color;
  final bool showMonogram;

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : LuxColors.ink);
    final box = size * 2.15;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMonogram) ...[
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              border: Border.all(color: c.withValues(alpha: 0.85), width: 1.4),
            ),
            child: Center(
              child: Text(
                'L',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: size * 1.25,
                  fontWeight: FontWeight.w500,
                  color: c,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          SizedBox(width: size),
        ],
        Text(
          'LUXELANE',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: size,
            fontWeight: FontWeight.w600,
            letterSpacing: size * 0.25,
            color: c,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
