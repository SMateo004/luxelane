import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../enums/enums.dart';

// ---------------------------------------------------------------------------
// LuxButton
// ---------------------------------------------------------------------------

class LuxButton extends StatelessWidget {
  const LuxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.width = double.infinity,
    this.height = 52,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double width;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LuxColors.black,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: LuxSpacing.sm),
                    ],
                    Text(label.toUpperCase()),
                  ],
                ),
        ),
      );
}

// ---------------------------------------------------------------------------
// LuxOutlinedButton
// ---------------------------------------------------------------------------

class LuxOutlinedButton extends StatelessWidget {
  const LuxOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 52,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: LuxSpacing.sm),
              ],
              Text(label.toUpperCase()),
            ],
          ),
        ),
      );
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
        style: LuxTypography.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: LuxColors.whiteTertiary, size: 20)
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
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: margin,
        decoration: BoxDecoration(
          color: LuxColors.blackSurface,
          borderRadius: BorderRadius.circular(LuxRadius.md),
          border: Border.all(
            color: selected ? LuxColors.sapphire : LuxColors.blackBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(LuxRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(LuxRadius.md),
            child: Padding(padding: padding, child: child),
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
            _VehicleIcon(vehicleClass: vehicleClass),
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
                      const Icon(Icons.person_outline, size: 14, color: LuxColors.whiteTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Up to ${vehicleClass.capacity}',
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
                    color: selected ? LuxColors.sapphire : LuxColors.white,
                  ),
                ),
                Text(
                  serviceType == ServiceType.byTheHour
                      ? '${hours ?? 2}h total'
                      : 'fixed price',
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ],
        ),
      );
}

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon({required this.vehicleClass});
  final VehicleClass vehicleClass;

  IconData get _icon {
    switch (vehicleClass) {
      case VehicleClass.business:    return Icons.directions_car_outlined;
      case VehicleClass.firstClass:  return Icons.star_outline_rounded;
      case VehicleClass.businessVan: return Icons.airport_shuttle_outlined;
      case VehicleClass.electric:    return Icons.electric_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: LuxColors.blackElevated,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: LuxColors.blackElevated,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
        ),
        child: Row(
          children: ServiceType.values
              .map(
                (t) => Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected == t ? LuxColors.sapphire : Colors.transparent,
                        borderRadius: BorderRadius.circular(LuxRadius.sm),
                      ),
                      child: Text(
                        t.label.toUpperCase(),
                        style: LuxTypography.caption.copyWith(
                          color: selected == t ? LuxColors.black : LuxColors.whiteTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

// ---------------------------------------------------------------------------
// BookingStatusChip
// ---------------------------------------------------------------------------

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});
  final BookingStatus status;

  Color get _color {
    switch (status) {
      case BookingStatus.pending:        return LuxColors.whiteTertiary;
      case BookingStatus.confirmed:      return LuxColors.sapphire;
      case BookingStatus.driverArriving: return LuxColors.sapphireLight;
      case BookingStatus.driverArrived:  return LuxColors.sapphireLight;
      case BookingStatus.inProgress:     return LuxColors.success;
      case BookingStatus.completed:      return LuxColors.success;
      case BookingStatus.cancelled:      return LuxColors.error;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(color: _color.withOpacity(0.4)),
        ),
        child: Text(
          status.displayLabel.toUpperCase(),
          style: LuxTypography.caption.copyWith(
            color: _color,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
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
        color: LuxColors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: LuxColors.sapphire,
                ),
              ),
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
          padding: const EdgeInsets.all(LuxSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: LuxColors.whiteTertiary, size: 40),
              const SizedBox(height: LuxSpacing.md),
              Text(
                message,
                style: LuxTypography.headlineLarge.copyWith(
                  fontStyle: FontStyle.italic,
                  color: LuxColors.whiteSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: LuxSpacing.lg),
                LuxOutlinedButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  width: 200,
                ),
              ],
            ],
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

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LuxTypography.headlineLarge),
                const SizedBox(height: LuxSpacing.xs),
                Container(width: LuxSpacing.lg, height: 1, color: LuxColors.sapphire),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
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
    required this.plate,
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
              backgroundColor: LuxColors.blackElevated,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: LuxTypography.headlineMedium,
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
                  Text(plate, style: LuxTypography.caption),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.star_rounded, color: LuxColors.sapphire, size: 18),
                const SizedBox(height: 2),
                Text(rating.toStringAsFixed(1), style: LuxTypography.titleLarge),
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
    this.label = 'Confirm Booking',
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
          color: LuxColors.blackSurface,
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FIXED PRICE', style: LuxTypography.caption),
                Text(
                  'Bs${price.toStringAsFixed(0)}',
                  style: LuxTypography.displayMedium.copyWith(color: LuxColors.sapphire),
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

void showLuxSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? LuxColors.error : LuxColors.success,
            size: 18,
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(child: Text(message, style: LuxTypography.bodyMedium)),
        ],
      ),
      backgroundColor: LuxColors.blackElevated,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        side: BorderSide(
          color: isError ? LuxColors.error.withOpacity(0.4) : LuxColors.sapphire.withOpacity(0.4),
        ),
      ),
      margin: const EdgeInsets.all(LuxSpacing.md),
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
      ? Container(width: 1, color: LuxColors.blackBorder)
      : Container(height: 1, color: LuxColors.blackBorder);
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
                color: i ~/ 2 < currentStep ? LuxColors.sapphire : LuxColors.blackBorder,
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
                          ? LuxColors.sapphireSubtle
                          : LuxColors.blackElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active || done ? LuxColors.sapphire : LuxColors.blackBorder,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: LuxColors.black)
                      : Text(
                          '${idx + 1}',
                          style: LuxTypography.caption.copyWith(
                            color: active ? LuxColors.sapphire : LuxColors.whiteTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: LuxTypography.caption.copyWith(
                  color: active ? LuxColors.sapphire : LuxColors.whiteTertiary,
                ),
              ),
            ],
          );
        }),
      );
}

// ---------------------------------------------------------------------------
// LuxelaneWordmark
// ---------------------------------------------------------------------------

class LuxelaneWordmark extends StatelessWidget {
  const LuxelaneWordmark({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: const BoxDecoration(
              color: LuxColors.sapphire,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: size * 0.35),
          Text(
            'LUXELANE',
            style: LuxTypography.labelLarge.copyWith(
              fontSize: size,
              letterSpacing: size * 0.2,
            ),
          ),
        ],
      );
}
