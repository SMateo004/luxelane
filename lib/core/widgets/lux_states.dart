import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../enums/enums.dart';
import '../models/models.dart';

// ============================================================
// Loading, empty and error states + price breakdown.
// Each widget works on dark (app) and light (editorial) surfaces via
// [light]. Animations are skipped when the OS asks for reduced motion.
// ============================================================

/// Shimmering placeholder block.
class LuxSkeleton extends StatefulWidget {
  const LuxSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 4,
    this.light = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool light;

  @override
  State<LuxSkeleton> createState() => _LuxSkeletonState();
}

class _LuxSkeletonState extends State<LuxSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.light ? LuxPalette.paper3 : LuxPalette.elevated;
    final glow = widget.light ? LuxPalette.paper : LuxPalette.line;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 2 - 0.5;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(t * 2, 0),
                colors: [base, glow, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton list mimicking trip/booking cards while data loads.
class LuxSkeletonList extends StatelessWidget {
  const LuxSkeletonList({super.key, this.count = 4, this.light = false});
  final int count;
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando',
        child: ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(height: LuxSpacing.sm),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(LuxSpacing.md),
            decoration: BoxDecoration(
              color: light ? Colors.white : LuxColors.blackSurface,
              border: Border.all(color: light ? LuxPalette.hairline : LuxColors.blackBorder),
              borderRadius: BorderRadius.circular(LuxRadius.md),
            ),
            child: Row(
              children: [
                LuxSkeleton(width: 48, height: 48, light: light),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LuxSkeleton(light: light),
                      const SizedBox(height: 8),
                      LuxSkeleton(width: 120, height: 12, light: light),
                      const SizedBox(height: 8),
                      LuxSkeleton(width: 80, height: 10, light: light),
                    ],
                  ),
                ),
                const SizedBox(width: LuxSpacing.md),
                LuxSkeleton(width: 64, height: 18, light: light),
              ],
            ),
          ),
        ),
      );
}

/// Friendly error with a retry action.
class LuxErrorState extends StatelessWidget {
  const LuxErrorState({
    super.key,
    this.title = 'Algo no salió bien',
    required this.message,
    this.onRetry,
    this.light = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final primary = light ? LuxPalette.ink : LuxColors.white;
    final secondary = light ? LuxPalette.slate : LuxColors.whiteSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuxSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering_error_rounded, size: 40,
                color: light ? LuxPalette.champagneDeep : LuxColors.accent),
            const SizedBox(height: LuxSpacing.md),
            Text(title,
                textAlign: TextAlign.center,
                style: LuxTypography.headlineLarge.copyWith(color: primary)),
            const SizedBox(height: LuxSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: LuxTypography.bodyMedium.copyWith(color: secondary)),
            if (onRetry != null) ...[
              const SizedBox(height: LuxSpacing.lg),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(180, 48),
                    foregroundColor: light ? LuxPalette.champagneDeep : LuxColors.accent,
                    side: BorderSide(color: light ? LuxPalette.champagneDeep : LuxColors.accent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Line items behind a price, e.g. in the confirm step.
///
/// The amounts shown are the client estimate; the final, fixed price comes
/// from the server quote at confirmation time.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.vehicleClass,
    required this.serviceType,
    this.km = 0,
    this.hours = 2,
    this.light = true,
  });

  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final double km;
  final int hours;
  final bool light;

  List<(String, double)> get lines {
    final r = DefaultPricing.rules[vehicleClass]![serviceType]!;
    if (serviceType == ServiceType.byTheHour) {
      return [('$hours h × ${LuxMoney.format(r['perHour']!)}', r['perHour']! * hours)];
    }
    return [
      ('Tarifa base', r['base']!),
      ('${km.toStringAsFixed(1)} km × ${LuxMoney.format(r['perKm']!, cents: true)}', km * r['perKm']!),
    ];
  }

  double get total => DefaultPricing.estimate(vehicleClass, serviceType, km: km, hours: hours);

  @override
  Widget build(BuildContext context) {
    final ink = light ? LuxPalette.ink : LuxColors.white;
    final muted = light ? LuxPalette.slate : LuxColors.whiteSecondary;
    final line = light ? LuxPalette.hairline : LuxColors.blackBorder;
    final subtotal = lines.fold<double>(0, (a, l) => a + l.$2);
    final minimumApplied = total > subtotal + 0.01;

    TextStyle style(Color c, {double size = 13, FontWeight w = FontWeight.w400}) =>
        TextStyle(fontFamily: 'Montserrat', fontSize: size, fontWeight: w, color: c);

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: style(strong ? ink : muted, w: strong ? FontWeight.w600 : FontWeight.w400))),
              Text(value, style: style(ink, size: strong ? 16 : 13, w: strong ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        );

    return Semantics(
      container: true,
      label: 'Desglose del precio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final l in lines) row(l.$1, LuxMoney.format(l.$2, cents: true)),
          if (minimumApplied) row('Ajuste a tarifa mínima', LuxMoney.format(total - subtotal, cents: true)),
          Divider(height: 20, color: line),
          row('Total estimado', LuxMoney.format(total.ceil()), strong: true),
          const SizedBox(height: 4),
          Text(
            'El precio fijo final se confirma antes de reservar.',
            style: style(muted, size: 11),
          ),
        ],
      ),
    );
  }
}
