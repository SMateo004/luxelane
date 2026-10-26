import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/design/vehicle_catalog.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/lux_raised.dart';
import '../../../home/presentation/pages/home_design.dart';
import 'vehicle_visuals.dart';

// ── Detalles: a quiet carousel of the class ──────────────────────────────────

/// Asset paths bundled with the app, loaded once, so the carousel shows only
/// the gallery photos that really exist.
final Future<Set<String>> _bundledAssets = AssetManifest.loadFromAssetBundle(
  rootBundle,
).then((m) => m.listAssets().toSet()).catchError((Object _) => <String>{});

class VehicleDetailsGallery extends StatefulWidget {
  const VehicleDetailsGallery({
    super.key,
    required this.vehicleClass,
    this.compact = false,
  });
  final VehicleClass vehicleClass;
  final bool compact;

  @override
  State<VehicleDetailsGallery> createState() => _VehicleDetailsGalleryState();
}

class _VehicleDetailsGalleryState extends State<VehicleDetailsGallery> {
  int _page = 0;

  @override
  void didUpdateWidget(VehicleDetailsGallery old) {
    super.didUpdateWidget(old);
    if (old.vehicleClass != widget.vehicleClass) _page = 0;
  }

  /// The class's gallery photos; until they are uploaded, the car itself and
  /// its cabin and trunk photos.
  List<_SlideBuilder> _slides(Set<String> assets) {
    final vc = widget.vehicleClass;
    final gallery = VehicleCatalog.galleryPhotos(vc).where(assets.contains);
    if (gallery.isNotEmpty) {
      return [
        for (final a in gallery) (arrow) => _RoundedPhoto(a, arrow: arrow),
      ];
    }
    return [
      (arrow) => _RoundedStage(
            arrow: arrow,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: VehicleImage(vc, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
      (arrow) => _RoundedPhoto(
            VehicleCatalog.seatingPhoto(vc, 0),
            arrow: arrow,
            fallback: CabinSchematic(
              vehicleClass: vc,
              option: VehicleCatalog.seating(vc).first,
            ),
          ),
      (arrow) => _RoundedPhoto(
            VehicleCatalog.luggagePhoto(vc, 1),
            arrow: arrow,
            fallback: TrunkSchematic(
              vehicleClass: vc,
              option: VehicleCatalog.luggage(vc)[1],
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vehicleClass;
    final tone = VehicleCatalog.tone(vc);
    final highlights = VehicleCatalog.highlights(vc);

    final stage = FutureBuilder<Set<String>>(
      future: _bundledAssets,
      // Show the class straight away; uploaded gallery photos join in as
      // soon as the asset list is known.
      initialData: const <String>{},
      builder: (context, snap) {
        final slides = _slides(snap.data ?? const <String>{});
        final page = _page.clamp(0, slides.length - 1);
        return _Carousel(
          aspectRatio: widget.compact ? 4 / 3 : 16 / 10,
          slideKey: '$vc-$page',
          count: slides.length,
          index: page,
          onIndex: (i) => setState(() => _page = i),
          slide: slides[page],
        );
      },
    );

    final facts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: tone.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 14,
                      height: 1.5,
                      color: LD.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: LuxSpacing.xs),
        Row(
          children: [
            _Spec(Icons.person_outline_rounded, '${vc.capacity} pasajeros'),
            const SizedBox(width: 20),
            _Spec(Icons.luggage_outlined, '${vc.luggageCapacity} maletas'),
          ],
        ),
      ],
    );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DETALLES', style: eyebrow()),
        const SizedBox(height: 10),
        Text(
          vc.label,
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: widget.compact ? 30 : 32,
            fontWeight: FontWeight.w500,
            color: LD.ink,
            height: 1.05,
          ),
        ),
        const SizedBox(height: LuxSpacing.xs),
        Text(
          vc.description,
          style: const TextStyle(
            fontFamily: kSans,
            fontSize: 14,
            color: LD.ink3,
          ),
        ),
      ],
    );

    return _Tone(
      tone: tone,
      child: widget.compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 18),
                stage,
                const SizedBox(height: 18),
                facts,
              ],
            )
          // Photo and story side by side: the heading sits with the facts
          // so the section reads as one block.
          : Row(
              children: [
                Expanded(flex: 3, child: stage),
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 22), facts],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Capacidad ────────────────────────────────────────────────────────────────

class CapacitySection extends StatelessWidget {
  const CapacitySection({
    super.key,
    required this.vehicleClass,
    required this.tab,
    required this.luggageIndex,
    required this.seatingIndex,
    required this.onTab,
    required this.onLuggage,
    required this.onSeating,
    this.compact = false,
  });

  final VehicleClass vehicleClass;
  final int tab; // 0 = equipaje, 1 = asientos
  final int luggageIndex;
  final int seatingIndex;
  final ValueChanged<int> onTab;
  final ValueChanged<int> onLuggage;
  final ValueChanged<int> onSeating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vc = vehicleClass;
    final luggage = VehicleCatalog.luggage(vc);
    final seating = VehicleCatalog.seating(vc);
    final li = luggageIndex.clamp(0, luggage.length - 1);
    final si = seatingIndex.clamp(0, seating.length - 1);

    final isLuggage = tab == 0;
    final count = isLuggage ? luggage.length : seating.length;
    final index = isLuggage ? li : si;
    final title = isLuggage ? luggage[li].title : seating[si].title;
    final detail = isLuggage ? luggage[li].size.dimensions : seating[si].detail;

    final carousel = _Carousel(
      aspectRatio: compact ? 4 / 3 : 16 / 10,
      slideKey: '$vc-$tab-$index',
      count: count,
      index: index,
      onIndex: isLuggage ? onLuggage : onSeating,
      slide: (arrow) => _RoundedPhoto(
        isLuggage
            ? VehicleCatalog.luggagePhoto(vc, li)
            : VehicleCatalog.seatingPhoto(vc, si),
        arrow: arrow,
        fallback: isLuggage
            ? TrunkSchematic(vehicleClass: vc, option: luggage[li])
            : CabinSchematic(vehicleClass: vc, option: seating[si]),
      ),
    );

    // The caption follows the photo: it changes with it.
    final caption = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey('$vc-$tab-$index'),
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LD.ink,
            ),
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            detail,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 13,
              color: LD.ink3,
            ),
          ),
        ],
      ),
    );

    final note = Text(
      isLuggage
          ? 'Medidas estándar de referencia. Si llevas equipaje especial '
              '(palos de golf, cochecito, instrumentos), indícalo en las notas '
              'de recogida.'
          : 'El asiento infantil se solicita con antelación y está sujeto a '
              'disponibilidad. Indica la edad del niño en las notas de '
              'recogida.',
      textAlign: compact ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontFamily: kSans,
        fontSize: 12.5,
        height: 1.6,
        color: LD.ink3,
      ),
    );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAPACIDAD', style: eyebrow()),
        const SizedBox(height: 10),
        Text(
          '¿Cuánto cabe?',
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: compact ? 30 : 32,
            fontWeight: FontWeight.w500,
            color: LD.ink,
            height: 1.05,
          ),
        ),
        const SizedBox(height: LuxSpacing.xs),
        Text(
          'Hasta ${vc.capacity} pasajeros y ${vc.luggageCapacity} maletas facturadas',
          style: const TextStyle(
            fontFamily: kSans,
            fontSize: 14,
            color: LD.ink3,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _UnderlineTab(
              label: 'Equipaje',
              active: isLuggage,
              onTap: () => onTab(0),
            ),
            const SizedBox(width: 28),
            _UnderlineTab(
              label: 'Asientos',
              active: !isLuggage,
              onTap: () => onTab(1),
            ),
          ],
        ),
        const Divider(color: LD.border, height: 1),
      ],
    );

    return _Tone(
      tone: VehicleCatalog.tone(vc),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: 18),
                carousel,
                const SizedBox(height: 14),
                caption,
                const SizedBox(height: 12),
                note,
              ],
            )
          // Same rhythm as Detalles: the photo on one side, what it shows
          // on the other.
          : Row(
              children: [
                Expanded(flex: 3, child: carousel),
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 20),
                      caption,
                      const SizedBox(height: 14),
                      note,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Building blocks ──────────────────────────────────────────────────────────

const _photoRadius = 18.0;

/// Builds a slide; [arrow] is the "next" button the slide pins to its right
/// edge, or null when there is a single slide.
typedef _SlideBuilder = Widget Function(Widget? arrow);

/// One photo at a time with a round "next" arrow on its right edge and page
/// dots below. Swiping works too.
class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.aspectRatio,
    required this.slideKey,
    required this.count,
    required this.index,
    required this.onIndex,
    required this.slide,
  });
  final double aspectRatio;
  final String slideKey;
  final int count;
  final int index;
  final ValueChanged<int> onIndex;
  final _SlideBuilder slide;

  void _go(int delta) => onIndex((index + delta + count) % count);

  @override
  Widget build(BuildContext context) {
    final arrow = count < 2
        ? null
        : _RoundNav(
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Siguiente',
            onTap: () => _go(1),
          );
    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: count < 2
              ? null
              : (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() > 200) _go(v < 0 ? 1 : -1);
                },
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: KeyedSubtree(key: ValueKey(slideKey), child: slide(arrow)),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                GestureDetector(
                  onTap: () => onIndex(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == index ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == index
                          ? (_Tone.of(context)?.accent ?? LD.sph)
                          : LD.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Half the arrow's width: how far it sits past the photo's right edge.
const _arrowOverhang = 24.0;

/// Pins [arrow] half over the right edge of [child], vertically centred. The
/// extra right padding keeps the whole arrow inside the hit-testable area.
Widget _withArrow(Widget child, Widget? arrow) => arrow == null
    ? child
    : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: _arrowOverhang),
            child: child,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: arrow),
          ),
        ],
      );

/// Every photo in the same rounded frame: the whole image, never cropped,
/// over a soft blurred copy of itself that fills the rest of the frame, so
/// photos of any proportion look like one set. Shows the class illustration
/// when the photo is missing.
class _RoundedPhoto extends StatelessWidget {
  const _RoundedPhoto(this.asset, {this.fallback, this.arrow});
  final String asset;
  final Widget? fallback;
  final Widget? arrow;

  @override
  Widget build(BuildContext context) => _withArrow(
        ClipRRect(
          borderRadius: BorderRadius.circular(_photoRadius),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: (_, image, frame, sync) {
              if (frame == null && !sync) {
                return const _RoundedStage(child: SizedBox());
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Image.asset(asset, fit: BoxFit.cover),
                  ),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
                  image,
                ],
              );
            },
            errorBuilder: (_, __, ___) => _RoundedStage(
              child: fallback == null
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.all(18),
                      child: fallback,
                    ),
            ),
          ),
        ),
        arrow,
      );
}

/// Soft rounded backdrop for cut-out cars and illustrations; fills its slot.
class _RoundedStage extends StatelessWidget {
  const _RoundedStage({required this.child, this.arrow});
  final Widget child;
  final Widget? arrow;

  @override
  Widget build(BuildContext context) => _withArrow(
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_photoRadius),
            gradient: _Tone.of(context)?.stageGradient ??
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, LD.bg2],
                ),
          ),
          child: SizedBox.expand(child: child),
        ),
        arrow,
      );
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? LD.ink : LD.ink3,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: active ? 40 : 0,
                  color: _Tone.of(context)?.accent ?? LD.sph,
                ),
              ],
            ),
          ),
        ),
      );
}

class _RoundNav extends StatefulWidget {
  const _RoundNav({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  @override
  State<_RoundNav> createState() => _RoundNavState();
}

/// Round "balloon" arrow with the same soft relief as the buttons.
class _RoundNavState extends State<_RoundNav> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
        child: Semantics(
          button: true,
          label: widget.tooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _down = true),
              onTapCancel: () => setState(() => _down = false),
              onTapUp: (_) {
                setState(() => _down = false);
                widget.onTap();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 48,
                height: 48,
                decoration: luxRaisedDecoration(
                  variant: LuxRaisedVariant.secondary,
                  pressed: _down,
                  radius: 24,
                ),
                child: Icon(widget.icon, size: 20, color: LD.ink),
              ),
            ),
          ),
        ),
      );
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: LD.ink3),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: LD.ink2,
            ),
          ),
        ],
      );
}

/// The selected class colours, for the pieces deep inside a section.
class _Tone extends InheritedWidget {
  const _Tone({required this.tone, required super.child});
  final VehicleTone tone;

  static VehicleTone? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Tone>()?.tone;

  @override
  bool updateShouldNotify(_Tone old) => old.tone != tone;
}
