import 'package:flutter/material.dart';

import '../../../../core/design/vehicle_catalog.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/lux_raised.dart';
import '../../../home/presentation/pages/home_design.dart';
import 'vehicle_visuals.dart';

// ── Detalles: what the selected class really is ─────────────────────────────

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

class _Slide {
  const _Slide(this.label, this.builder);
  final String label;
  final Widget Function() builder;
}

class _VehicleDetailsGalleryState extends State<VehicleDetailsGallery> {
  int _page = 0;

  @override
  void didUpdateWidget(VehicleDetailsGallery old) {
    super.didUpdateWidget(old);
    if (old.vehicleClass != widget.vehicleClass) _page = 0;
  }

  List<_Slide> get _slides {
    final vc = widget.vehicleClass;
    return [
      // Car PNGs have generous transparent margins: cover fills the stage
      // without ever cutting the car itself.
      _Slide('Exterior', () => VehicleImage(vc, fit: BoxFit.cover)),
      _Slide(
        'Cabina',
        () => _Photo(
          VehicleCatalog.seatingPhoto(vc, 0),
          fallback: CabinSchematic(
              vehicleClass: vc, option: VehicleCatalog.seating(vc).first),
        ),
      ),
      _Slide(
        'Maletero',
        () => _Photo(
          VehicleCatalog.luggagePhoto(vc, 1),
          fallback: TrunkSchematic(
              vehicleClass: vc, option: VehicleCatalog.luggage(vc)[1]),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vehicleClass;
    final slides = _slides;
    final page = _page.clamp(0, slides.length - 1);
    final highlights = VehicleCatalog.highlights(vc);

    final stage = AspectRatio(
      aspectRatio: widget.compact ? 4 / 3 : 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, LD.bg2],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: KeyedSubtree(
                  key: ValueKey('$vc-$page'),
                  child: slides[page].builder(),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Row(children: [
                  _RoundNav(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => setState(() =>
                        _page = (page - 1 + slides.length) % slides.length),
                  ),
                  const SizedBox(width: 8),
                  _RoundNav(
                    icon: Icons.arrow_forward_rounded,
                    onTap: () =>
                        setState(() => _page = (page + 1) % slides.length),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );

    final tabs = Row(
      children: [
        for (var i = 0; i < slides.length; i++) ...[
          _UnderlineTab(
            label: slides[i].label,
            active: i == page,
            onTap: () => setState(() => _page = i),
          ),
          const SizedBox(width: 28),
        ],
      ],
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
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_rounded, size: 16, color: LD.sph),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(h,
                      style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 14,
                          height: 1.5,
                          color: LD.ink2)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(children: [
          _Spec(Icons.person_outline_rounded, '${vc.capacity} pasajeros'),
          const SizedBox(width: 20),
          _Spec(Icons.luggage_outlined, '${vc.luggageCapacity} maletas'),
        ]),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DETALLES', style: eyebrow()),
        const SizedBox(height: 10),
        Text(
          vc.label,
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: widget.compact ? 30 : 40,
            fontWeight: FontWeight.w500,
            color: LD.ink,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(vc.description,
            style: const TextStyle(
                fontFamily: kSans, fontSize: 14, color: LD.ink3)),
        const SizedBox(height: 22),
        tabs,
        const Divider(color: LD.border, height: 1),
        const SizedBox(height: 18),
        if (widget.compact) ...[
          stage,
          const SizedBox(height: 22),
          facts,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: stage),
              const SizedBox(width: 36),
              Expanded(flex: 4, child: facts),
            ],
          ),
      ],
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

    final tiles = tab == 0
        ? [
            for (var i = 0; i < luggage.length; i++)
              _OptionTile(
                selected: i == li,
                onTap: () => onLuggage(i),
                glyphs: (c) => LuggageGlyphs(option: luggage[i], color: c),
                title: luggage[i].title,
                detail: luggage[i].size.dimensions,
                compact: compact,
              ),
          ]
        : [
            for (var i = 0; i < seating.length; i++)
              _OptionTile(
                selected: i == si,
                onTap: () => onSeating(i),
                glyphs: (c) => SeatGlyphs(option: seating[i], color: c),
                title: seating[i].title,
                detail: seating[i].detail,
                compact: compact,
              ),
          ];

    final photo = tab == 0
        ? VehicleCatalog.luggagePhoto(vc, li)
        : VehicleCatalog.seatingPhoto(vc, si);
    // Photos are 754 × 694; illustrations share the frame for a calm layout.
    final stage = AspectRatio(
      aspectRatio: 754 / 694,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ColoredBox(
          color: LD.bg2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey('$vc-$tab-$li-$si'),
              child: _Photo(
                photo,
                fallback: tab == 0
                    ? TrunkSchematic(vehicleClass: vc, option: luggage[li])
                    : CabinSchematic(vehicleClass: vc, option: seating[si]),
              ),
            ),
          ),
        ),
      ),
    );

    final note = Text(
      tab == 0
          ? 'Medidas estándar de referencia. Si llevas equipaje especial '
              '(palos de golf, cochecito, instrumentos), indícalo en las notas '
              'de recogida.'
          : 'El asiento infantil se solicita con antelación y está sujeto a '
              'disponibilidad. Indica la edad del niño en las notas de '
              'recogida.',
      style: const TextStyle(
          fontFamily: kSans, fontSize: 12.5, height: 1.6, color: LD.ink3),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAPACIDAD', style: eyebrow()),
        const SizedBox(height: 10),
        Text(
          '¿Cuánto cabe?',
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: compact ? 30 : 40,
            fontWeight: FontWeight.w500,
            color: LD.ink,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hasta ${vc.capacity} pasajeros y ${vc.luggageCapacity} maletas facturadas',
          style:
              const TextStyle(fontFamily: kSans, fontSize: 14, color: LD.ink3),
        ),
        const SizedBox(height: 22),
        Row(children: [
          _UnderlineTab(
              label: 'Equipaje', active: tab == 0, onTap: () => onTab(0)),
          const SizedBox(width: 28),
          _UnderlineTab(
              label: 'Asientos', active: tab == 1, onTap: () => onTab(1)),
        ]),
        const Divider(color: LD.border, height: 1),
        const SizedBox(height: 20),
        if (compact) ...[
          for (final t in tiles)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: t),
          const SizedBox(height: 8),
          stage,
          const SizedBox(height: 14),
          note,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in tiles)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12), child: t),
                    const SizedBox(height: 6),
                    note,
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(child: stage),
            ],
          ),
      ],
    );
  }
}

// ── Building blocks ──────────────────────────────────────────────────────────

/// Full, uncropped photo; the class illustration when the photo is missing.
class _Photo extends StatelessWidget {
  const _Photo(this.asset, {required this.fallback});
  final String asset;
  final Widget fallback;
  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            Padding(padding: const EdgeInsets.all(18), child: fallback),
      );
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.glyphs,
    required this.title,
    required this.detail,
    this.compact = false,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget Function(Color) glyphs;
  final String title;
  final String detail;
  final bool compact;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final accent = sel ? LD.sph : LD.ink3;
    return Semantics(
      button: true,
      selected: sel,
      label: widget.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            transform: Matrix4.translationValues(0, _hover && !sel ? -1 : 0, 0),
            decoration: BoxDecoration(
              color: sel ? Colors.white : const Color(0xFFFDFEFF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: sel ? LD.sph : LD.border, width: sel ? 1.5 : 1),
              boxShadow: sel || _hover
                  ? [
                      BoxShadow(
                          color: LD.ink.withValues(alpha: 0.06),
                          blurRadius: 2,
                          offset: const Offset(0, 1)),
                      BoxShadow(
                          color: (sel ? LD.sph : LD.ink)
                              .withValues(alpha: sel ? 0.14 : 0.06),
                          blurRadius: 16,
                          spreadRadius: -6,
                          offset: const Offset(0, 8)),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                SizedBox(width: 76, child: widget.glyphs(accent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: TextStyle(
                              fontFamily: kSans,
                              fontSize: 14,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w500,
                              color: LD.ink)),
                      const SizedBox(height: 2),
                      Text(widget.detail,
                          style: const TextStyle(
                              fontFamily: kSans,
                              fontSize: 11.5,
                              color: LD.ink3)),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: sel ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded,
                      size: 18, color: LD.sph),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
                  child: Text(label,
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? LD.ink : LD.ink3,
                      )),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: active ? 40 : 0,
                  color: LD.sph,
                ),
              ],
            ),
          ),
        ),
      );
}

class _RoundNav extends StatefulWidget {
  const _RoundNav({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_RoundNav> createState() => _RoundNavState();
}

class _RoundNavState extends State<_RoundNav> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
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
            width: 40,
            height: 40,
            decoration: luxRaisedDecoration(
              variant: LuxRaisedVariant.secondary,
              pressed: _down,
              radius: 20,
            ),
            child: Icon(widget.icon, size: 18, color: LD.ink),
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
          Text(text,
              style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: LD.ink2)),
        ],
      );
}
