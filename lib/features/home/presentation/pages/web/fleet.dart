part of '../home_web_page.dart';

// ============================================================
// Fleet Section
// ============================================================

class _FleetSection extends StatelessWidget {
  const _FleetSection({required this.sectionKey, required this.onBook});
  final GlobalKey sectionKey;
  final VoidCallback onBook;

  static const _accents = [LuxPalette.champagne, LuxPalette.champagneLight, LuxPalette.champagneDeep];

  /// The bookable vehicle types, as set in the admin catalog.
  static List<_FleetItem> _vehicles(AppLocalizations l) => [
        for (final (i, v) in VehicleCatalog.instance.active.indexed)
          _FleetItem(
            cls: v.nameIn(l.localeName),
            model: v.descriptionIn(l.localeName),
            info: v,
            tags: [
              l.unitPassengers(v.capacity),
              if (v.capacity >= 5) l.homeFleetTagGroups else l.homeFleetTagFixedPrice,
              if (v.extraLarge >= 3) l.homeFleetTagExtraLuggage else if (i.isEven) l.homeFleetTagVerified else l.homeFleetTagTracking,
            ],
            accent: _accents[i % _accents.length],
          ),
      ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: VehicleCatalog.instance,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;
    final hPad = narrow ? 24.0 : 64.0;
    final vPad = narrow ? 56.0 : 100.0;
    final l = context.l10n;
    final vehicles = _vehicles(l);
    return Container(
        key: sectionKey,
        color: LD.dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, narrow ? 28 : 56),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RevealOnScroll(child: LuxEyebrow(l.homeFleetEyebrow)),
                  const SizedBox(height: 20),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 80),
                    child: Text(l.homeFleetTitle,
                        style: displayText(size: narrow ? 36 : 52, color: Colors.white)),
                  ),
                ]),
              ),
              if (!narrow) const SizedBox(width: 24),
              if (!narrow) RevealOnScroll(
                delay: const Duration(milliseconds: 160),
                child: Text(l.homeFleetSwipeHint.toUpperCase(), style: TextStyle(
                  fontFamily: kSans, fontSize: 9, letterSpacing: 2.4,
                  color: Colors.white.withAlpha(60),
                  decoration: TextDecoration.none,
                )),
              ),
            ]),
          ),
          // Horizontal card list
          SizedBox(
            height: narrow ? 360 : 460,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (_, i) => _FleetCard(item: vehicles[i], onBook: onBook),
            ),
          ),
          const SizedBox(height: 72),
        ]),
      );
  }
}

@immutable
class _FleetItem {
  const _FleetItem({
    required this.cls,
    required this.model,
    required this.info,
    required this.tags,
    required this.accent,
  });
  final String cls;
  final String model;
  final VehicleClassInfo info;
  final List<String> tags;
  final Color accent;
}

class _FleetCard extends StatefulWidget {
  const _FleetCard({required this.item, required this.onBook});
  final _FleetItem item;
  final VoidCallback onBook;

  @override
  State<_FleetCard> createState() => _FleetCardState();
}

class _FleetCardState extends State<_FleetCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onBook,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 340,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              border: Border.all(
                color: _hover ? widget.item.accent.withAlpha(180) : Colors.white.withAlpha(18),
              ),
            ),
            child: Stack(children: [
              // Accent gradient wash
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [widget.item.accent.withAlpha(_hover ? 45 : 20), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Car image
              Positioned(
                bottom: 110, left: 0, right: 0, height: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _FleetImage(info: widget.item.info),
                ),
              ),
              // Bottom info bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [const Color(0xFF0B1220).withAlpha(242), Colors.transparent],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Class name — 22px serif
                    Text(widget.item.cls, style: const TextStyle(
                      fontFamily: kSerif, fontSize: 22, fontWeight: FontWeight.w400,
                      color: Colors.white, height: 1.1,
                      decoration: TextDecoration.none,
                    )),
                    const SizedBox(height: 4),
                    // Model — 12px dim
                    Text(widget.item.model, style: TextStyle(
                      fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(115), height: 1.5,
                      decoration: TextDecoration.none,
                    )),
                    const SizedBox(height: 16),
                    // Tags
                    Wrap(spacing: 6, runSpacing: 6,
                      children: widget.item.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(36)),
                        ),
                        child: Text(t, style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white.withAlpha(128),
                          decoration: TextDecoration.none,
                        )),
                      )).toList()),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Uploaded photo, else the bundled one of a built-in type, else its icon.
class _FleetImage extends StatelessWidget {
  const _FleetImage({required this.info});
  final VehicleClassInfo info;

  @override
  Widget build(BuildContext context) {
    Widget icon() => Icon(info.iconData, size: 80, color: Colors.white.withAlpha(16));
    Widget asset() => info.asset == null
        ? icon()
        : Image.asset(info.asset!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => icon());
    return info.imageUrl == null
        ? asset()
        : Image.network(info.imageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => asset());
  }
}
