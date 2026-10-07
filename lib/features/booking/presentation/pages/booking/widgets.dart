part of '../booking_screen.dart';

// ── WEB TOP BAR ───────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({
    required this.formData,
    required this.service,
    required this.hours,
    required this.onBack,
    required this.onServiceChanged,
    required this.onHoursChanged,
    this.showStickySelector = false,
    this.selectedVehicle,
    this.onVehicleChanged,
    this.km = 25.0,
  });

  final BookingFormData? formData;
  final ServiceType service;
  final int hours;
  final VoidCallback onBack;
  final ValueChanged<ServiceType> onServiceChanged;
  final ValueChanged<int> onHoursChanged;
  final bool showStickySelector;
  final VehicleClass? selectedVehicle;
  final ValueChanged<VehicleClass>? onVehicleChanged;
  final double km;

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        decoration: const BoxDecoration(
          color: _kBg,
          border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Row(
          children: [
            // ── Luxelane logo mark ───────────────────────────────────────
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  border: Border.all(color: _kTextPrimary, width: 1.5),
                ),
                child: const Center(
                  child: Text('L', style: TextStyle(
                    fontFamily: kSerif, fontSize: 15,
                    fontWeight: FontWeight.w500, color: _kTextPrimary,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              const Text('LUXELANE', style: TextStyle(
                fontFamily: kSans, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 3.0,
                color: _kTextPrimary,
              )),
            ]),
            const SizedBox(width: 40),
            // ── Back button ──────────────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onBack,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: _kTextSub),
                  const SizedBox(width: 5),
                  Text(context.l10n.commonBack,
                      style: const TextStyle(fontFamily: kSans, fontSize: 11,
                          fontWeight: FontWeight.w400, letterSpacing: 0.8,
                          color: _kTextSub)),
                ]),
              ),
            ),

            // ── Sticky vehicle selector (appears after scrolling past cards) ─
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: showStickySelector && selectedVehicle != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: showStickySelector ? 1.0 : 0.0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _kVehicleClasses.map((vc) {
                              final price = DefaultPricing.estimate(
                                  vc, service, km: km, hours: hours);
                              final isActive = selectedVehicle == vc;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => onVehicleChanged?.call(vc),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFEEF2FC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.zero,
                                        border: Border.all(
                                          color: isActive
                                              ? _kPanelAccent
                                              : _kBorder,
                                          width: isActive ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            vc.localizedLabel(context.l10n),
                                            style: TextStyle(
                                              fontFamily: kSans,
                                              fontSize: 13,
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isActive
                                                  ? _kPanelAccent
                                                  : _kTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: 12,
                                            color: isActive
                                                ? _kPanelAccent
                                                    .withValues(alpha: 0.3)
                                                : _kBorder,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            LuxMoney.format(price.round()),
                                            style: TextStyle(
                                              fontFamily: kSans,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isActive
                                                  ? _kPanelAccent
                                                  : _kTextSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(),

            // ── Route summary pill ───────────────────────────────────────
            if (formData?.origin != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          formData!.origin.displayName,
                          style: const TextStyle(fontFamily: kSans,
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: _kTextPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 14,
                            color: _kTextSub),
                      ),
                      Flexible(
                        child: Text(
                          formData!.destination?.displayName ?? '—',
                          style: const TextStyle(fontFamily: kSans,
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: _kTextPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(width: 16),

            _LightServiceTypeTab(
              selected: service,
              onChanged: onServiceChanged,
              compact: true,
            ),

            if (service == ServiceType.byTheHour) ...[
              const SizedBox(width: 12),
              _CompactHourPicker(hours: hours, onChanged: onHoursChanged),
            ],
          ],
        ),
      );
}

// ── VEHICLE CARD ──────────────────────────────────────────────────────────────

class _VehicleCard extends StatefulWidget {
  const _VehicleCard({
    required this.vehicleClass,
    required this.price,
    required this.selected,
    required this.cardBg,
    required this.cardBgSelected,
    required this.onTap,
    this.serviceType = ServiceType.oneWay,
    this.hours,
    this.width,
  });

  final VehicleClass vehicleClass;
  final double       price;
  final bool         selected;
  final Color        cardBg;
  final Color        cardBgSelected;
  final VoidCallback onTap;
  final ServiceType  serviceType;
  final int?         hours;
  final double?      width;

  // Asset path for transparent-background PNG
  String get _assetPath {
    switch (vehicleClass) {
      case VehicleClass.business:
        return 'assets/images/vehicles/business/car.png';
      case VehicleClass.firstClass:
        return 'assets/images/vehicles/first_class/car.png';
      case VehicleClass.businessVan:
        return 'assets/images/vehicles/van/car.png';
      case VehicleClass.electric:
        return 'assets/images/vehicles/electric/car.png';
    }
  }

  // Network fallback
  String get _fallbackUrl {
    switch (vehicleClass) {
      case VehicleClass.business:
        return 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.firstClass:
        return 'https://images.unsplash.com/photo-1563720223523-e75db7d32e5c?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.businessVan:
        return 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=700&q=90&auto=format&fit=crop';
      case VehicleClass.electric:
        return 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=700&q=90&auto=format&fit=crop';
    }
  }

  // Sapphire-family accent per vehicle (border + pill)
  Color get _accentColor {
    switch (vehicleClass) {
      case VehicleClass.business:    return const Color(0xFF3A7BD5);
      case VehicleClass.firstClass:  return const Color(0xFF7B4DB5);
      case VehicleClass.businessVan: return const Color(0xFF2E6AC8);
      case VehicleClass.electric:    return const Color(0xFF2A9E72);
    }
  }

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late AnimationController _popCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _tiltAnim;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    // Scale: pops up then settles (elastic feel)
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.01), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.01, end: 1.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));
    // Tilt: brief perspective lean on the Y axis (3D feel)
    _tiltAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_VehicleCard old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _popCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Car image is fixed at 480 px wide, anchored to the LEFT edge.
    // Unselected card (210 px) → shows left ~44 % of the car (corner only).
    // Selected card (500 px)   → shows the entire car + 20 px right margin.
    const kCarW    = 480.0;
    const kCarLeft = 0.0;   // car left edge flush with card left edge
    const kSelPad  = 20.0;  // extra breathing room on the right when selected

    final baseW   = widget.width ?? 210.0;
    final targetW = widget.selected ? kCarW + kSelPad : baseW;

    final accent = widget._accentColor;
    final bgColor = widget.selected ? widget.cardBgSelected : widget.cardBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _popCtrl,
          builder: (context, child) {
            final perspective = Matrix4.identity()
              ..setEntry(3, 2, 0.0008) // perspective depth
              ..rotateY(_tiltAnim.value);
            return Transform(
              transform: perspective * (Matrix4.identity()..scale(_scaleAnim.value)),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
            width: targetW,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected ? accent : const Color(0xFFE0DDD8),
                width: widget.selected ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.selected
                      ? accent.withAlpha(55)
                      : Colors.black.withAlpha(18),
                  blurRadius: widget.selected ? 32 : 12,
                  spreadRadius: widget.selected ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // Hover lift (only when not selected)
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                  0, _hover && !widget.selected ? -5 : 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Vehicle image — fills most of the card ───────────────
                  // Car is anchored to the BOTTOM-RIGHT corner at a FIXED
                  // 440 px width.  As the card expands from 210 → 310 px the
                  // ClipRRect reveals an extra 100 px of the car's left side.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [

                          // bg colour
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            color: bgColor,
                          ),

                          // radial spotlight — centred towards bottom-left
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.5, 0.5),
                                    radius: 0.9,
                                    colors: [
                                      accent.withAlpha(
                                          widget.selected ? 65 : 32),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── car — fixed 480 px, pinned to BOTTOM-LEFT ───────
                          // Card clips the right side of the image.
                          // Unselected (210 px): left 44 % visible = corner only.
                          // Selected   (500 px): full car visible + 20 px margin.
                          Positioned(
                            bottom: -14,
                            left:   kCarLeft,
                            child: SizedBox(
                              width: kCarW,
                              child: _CarImage(
                                assetPath: widget._assetPath,
                                fallbackUrl: widget._fallbackUrl,
                              ),
                            ),
                          ),

                          // bottom fade — blends car into info strip
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      bgColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // checkmark badge
                          Positioned(
                            top: 14, right: 14,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: widget.selected ? 1.0 : 0.0,
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withAlpha(90),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Info strip — always at the very bottom ───────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name row + selected pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.vehicleClass.localizedLabel(context.l10n),
                                style: const TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w400,
                                  color: _kTextPrimary,
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: widget.selected ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(22),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: accent.withAlpha(60), width: 1),
                                ),
                                child: Text(
                                  context.l10n.bookingSelectedBadge,
                                  style: TextStyle(
                                    fontFamily: kSans,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.6,
                                    color: accent,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Description
                        Text(
                          widget.vehicleClass.localizedDescription(context.l10n),
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: _kTextTertiary,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Price + capacity
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              LuxMoney.format(widget.price.round()),
                              style: const TextStyle(
                                fontFamily: kSerif,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: _kTextPrimary,
                                height: 1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEBE4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline,
                                      size: 11, color: _kTextSub),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.vehicleClass.capacity}',
                                    style: const TextStyle(
                                      fontFamily: kSans,
                                      fontSize: 10,
                                      color: _kTextSub,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tries local asset first; falls back to a placeholder icon if not found.
class _CarImage extends StatelessWidget {
  const _CarImage({required this.assetPath, required this.fallbackUrl});
  final String assetPath;
  final String fallbackUrl;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.black12,
          ),
        ),
      );
}

/// Capacity section image: tries local asset, falls back to network, then icon.
class _CapacityImage extends StatelessWidget {
  const _CapacityImage({
    super.key,
    required this.assetPath,
    required this.fallbackUrl,
    required this.fallbackIcon,
  });
  final String   assetPath;
  final String   fallbackUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        width: double.infinity,
        height: 290,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(
          fallbackUrl,
          width: double.infinity,
          height: 290,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 290,
            color: const Color(0xFFF0EDE8),
            child: Center(
              child: Icon(fallbackIcon, size: 60, color: _kTextTertiary),
            ),
          ),
        ),
      );
}

// ── BOOK OPTION CARD (Blacklane "Book for myself / guest" style) ───────────────

class _BookOptionCard extends StatelessWidget {
  const _BookOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData  icon;
  final Color     iconBg;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final bool      selected;
  final VoidCallback onTap;
  final Widget?   trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: selected ? _kPanelAccent : _kBorder,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                          fontFamily: kSans,
                          fontSize: 12,
                          color: _kTextSub,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

// ── RESERVE BAR (web, pinned bottom of right panel) ───────────────────────────

class _ReserveBar extends StatelessWidget {
  const _ReserveBar({
    required this.selected,
    required this.loading,
    required this.onReserve,
  });

  final VehicleClass selected;
  final bool         loading;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: GestureDetector(
          onTap: loading ? null : onReserve,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 52,
            color: loading ? LD.cta.withValues(alpha: 0.6) : LD.cta,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: LD.onCta))
                  : Text(
                      context.l10n.bookingReserveCta(
                          selected.localizedLabel(context.l10n).toUpperCase()),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: LD.onCta,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ),
      );
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFEEEBE4) : const Color(0xFFF5F4F1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14,
              color: enabled ? _kTextPrimary : _kTextTertiary),
        ),
      );
}

// ── GUARANTEE ROW ─────────────────────────────────────────────────────────────

Widget _GuaranteeRow(IconData icon, String text) => Row(children: [
      Icon(icon, size: 15, color: _kTextSub),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontFamily: kSans, fontSize: 11, color: _kTextSub)),
      ),
    ]);

// ── MOBILE VEHICLE DETAIL ─────────────────────────────────────────────────────

class _MobileVehicleDetail extends StatelessWidget {
  const _MobileVehicleDetail({super.key, required this.vehicleClass});
  final VehicleClass vehicleClass;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: _kDivider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(vehicleClass.localizedDescription(context.l10n),
                style: const TextStyle(fontFamily: kSans,
                    fontSize: 12, color: _kTextSub))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEBE4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.l10n.bookingSeatsUpTo(vehicleClass.capacity),
                  style: const TextStyle(fontFamily: kSans,
                      fontSize: 10, fontWeight: FontWeight.w600, color: _kTextSub)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(color: _kDivider, height: 1),
          const SizedBox(height: 10),
          _GuaranteeRow(Icons.price_check_outlined, context.l10n.bookingAllFeesIncluded),
          const SizedBox(height: 6),
          _GuaranteeRow(Icons.event_available_outlined, context.l10n.bookingFreeCancellationShort),
        ]),
      );
}

// ── SUMMARY ROW (confirm step) ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isFirst = false});
  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => Column(children: [
        if (!isFirst) const Divider(color: _kDivider, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Flexible(
              child: Text(label,
                  style: const TextStyle(fontFamily: kSans, fontSize: 12, color: _kTextSub)),
            ),
            const SizedBox(width: 16),
            Flexible(child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontFamily: kSans, fontSize: 12,
                    fontWeight: FontWeight.w500, color: _kTextPrimary))),
          ]),
        ),
      ]);
}

// ── SERVICE TYPE TAB ──────────────────────────────────────────────────────────

class _LightServiceTypeTab extends StatelessWidget {
  const _LightServiceTypeTab({
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });
  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 38.0 : 42.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: ServiceType.values.map((t) {
          final active = selected == t;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.all(3),
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 0),
              decoration: BoxDecoration(
                color: active ? _kTextPrimary : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              alignment: Alignment.center,
              child: compact
                  ? Text(t.localizedLabel(context.l10n),
                      style: TextStyle(
                        fontFamily: kSans, fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : _kTextSub,
                      ))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── COMPACT HOUR PICKER (top bar) ─────────────────────────────────────────────

class _CompactHourPicker extends StatelessWidget {
  const _CompactHourPicker({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Btn(icon: Icons.remove, enabled: hours > 2, onTap: () => onChanged(hours - 1)),
          SizedBox(width: 40,
              child: Text(context.l10n.bookingHoursShort(hours), textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: kSans, fontSize: 13,
                      fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: hours < 12, onTap: () => onChanged(hours + 1)),
        ]),
      );
}

// ── LIGHT HOUR ROW (mobile) ───────────────────────────────────────────────────

class _LightHourRow extends StatelessWidget {
  const _LightHourRow({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg, borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Expanded(
            child: Text(context.l10n.bookingSummaryDuration,
                style: const TextStyle(fontFamily: kSans, fontSize: 13,
                    fontWeight: FontWeight.w500, color: _kTextPrimary)),
          ),
          _Btn(icon: Icons.remove, enabled: hours > 2, onTap: () => onChanged(hours - 1)),
          SizedBox(width: 48, child: Text(context.l10n.bookingHoursShort(hours), textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kSans, fontSize: 15,
                  fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: hours < 12, onTap: () => onChanged(hours + 1)),
        ]),
      );
}

// ── LIGHT COUNTER ROW (mobile) ────────────────────────────────────────────────

class _LightCounterRow extends StatelessWidget {
  const _LightCounterRow({
    required this.label, required this.icon,
    required this.value, required this.min, required this.max,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg, borderRadius: BorderRadius.zero,
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: _kTextSub),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w500, color: _kTextPrimary))),
          _Btn(icon: Icons.remove, enabled: value > min, onTap: () => onChanged(value - 1)),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kSans, fontSize: 15,
                  fontWeight: FontWeight.w600, color: _kTextPrimary))),
          _Btn(icon: Icons.add, enabled: value < max, onTap: () => onChanged(value + 1)),
        ]),
      );
}

// ── LIGHT TEXT FIELD ──────────────────────────────────────────────────────────

class _LightTextField extends StatelessWidget {
  const _LightTextField({
    required this.label, this.hint, required this.icon,
    required this.onChanged, this.maxLines = 1,
  });
  final String label;
  final String? hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged, maxLines: maxLines,
        style: const TextStyle(fontFamily: kSans, fontSize: 13,
            color: _kTextPrimary),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: const TextStyle(fontFamily: kSans, fontSize: 13,
              color: _kTextTertiary, fontWeight: FontWeight.w300),
          labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
              color: _kTextSub, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 18, color: _kTextSub),
          filled: true, fillColor: _kCardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: _kTextPrimary, width: 1.5)),
        ),
      );
}

// ── MOBILE PRICE BAR ──────────────────────────────────────────────────────────

class _LightPriceBar extends StatelessWidget {
  const _LightPriceBar({
    required this.price, required this.onConfirm, required this.label,
    this.loading = false,
  });
  final double price;
  final VoidCallback onConfirm;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.bookingFixedPriceLabel,
                    style: const TextStyle(fontFamily: kSans, fontSize: 9,
                        fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 1.5)),
                Text(LuxMoney.format(price.round()),
                    style: const TextStyle(fontFamily: kSans, fontSize: 22,
                        fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.5)),
              ]),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTextPrimary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontFamily: kSans, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
                child: loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                    : Text(label.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ]),
      );
}

// ── MOBILE STEP INDICATOR ─────────────────────────────────────────────────────

class _LightStepIndicator extends StatelessWidget {
  const _LightStepIndicator({required this.steps, required this.currentStep});
  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(child: Container(height: 1,
                color: i ~/ 2 < currentStep ? _kTextPrimary : _kBorder));
          }
          final idx    = i ~/ 2;
          final done   = idx < currentStep;
          final active = idx == currentStep;
          return Column(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: done ? _kTextPrimary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done || active ? _kTextPrimary : _kBorder,
                    width: active ? 1.5 : 1),
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : Text('${idx + 1}',
                      style: TextStyle(fontFamily: kSans, fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: active ? _kTextPrimary : _kTextTertiary))),
            ),
            const SizedBox(height: 3),
            Text(steps[idx], maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: kSans, fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? _kTextPrimary : _kTextTertiary, letterSpacing: 0.3)),
          ]);
        }),
      );
}

// ── PAY ON TRIP NOTICE ────────────────────────────────────────────────────────

/// Shown when the rider has no saved card: the fixed price is paid to the
/// chauffeur at the end of the trip (cash or QR).
class _PayOnTripNotice extends StatelessWidget {
  const _PayOnTripNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LD.accentTint,
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.payments_outlined, size: 20, color: _kPanelAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.bookingPayOnTripTitle,
                      style: const TextStyle(fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w600, color: _kTextPrimary)),
                  const SizedBox(height: 4),
                  Text(context.l10n.bookingPayOnTripBody,
                      style: const TextStyle(fontFamily: kSans, fontSize: 12,
                          height: 1.5, color: _kTextSub)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── CORPORATE BILLING ─────────────────────────────────────────────────────────

/// Lets a member of a corporate account bill the ride to the company
/// (monthly invoice, the chauffeur collects nothing) or pay personally.
class _CorporateBillingPanel extends StatelessWidget {
  const _CorporateBillingPanel({
    required this.company,
    required this.billCompany,
    required this.costCenter,
    required this.onBillCompany,
    required this.onCostCenter,
    required this.onReference,
  });

  final Company company;
  final bool billCompany;
  final String? costCenter;
  final ValueChanged<bool> onBillCompany;
  final ValueChanged<String?> onCostCenter;
  final ValueChanged<String> onReference;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget option(bool corporate, IconData icon, String title, String body) {
      final sel = billCompany == corporate;
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          child: GestureDetector(
            onTap: () => onBillCompany(corporate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? LD.accentTint : _kCardBg,
                border: Border.all(color: sel ? LD.accent : _kBorder, width: sel ? 1.5 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: sel ? _kPanelAccent : _kTextSub),
                  const SizedBox(height: 8),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w600, color: _kTextPrimary)),
                  const SizedBox(height: 2),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: kSans, fontSize: 11,
                          height: 1.4, color: _kTextTertiary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.corpBillTo.toUpperCase(),
            style: const TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              option(true, Icons.business_outlined, company.name, l.corpBillCompanyHint),
              const SizedBox(width: 8),
              option(false, Icons.person_outline, l.corpBillPersonal, l.corpBillPersonalHint),
            ],
          ),
        ),
        if (billCompany) ...[
          if (company.costCenters.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: costCenter,
              isExpanded: true,
              dropdownColor: _kCardBg,
              style: const TextStyle(fontFamily: kSans, fontSize: 13, color: _kTextPrimary),
              decoration: InputDecoration(
                labelText: company.requireCostCenter
                    ? l.corpCostCenterRequired
                    : l.corpCostCenterOptional,
                labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
                    color: _kTextSub, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.account_tree_outlined, size: 18, color: _kTextSub),
                filled: true,
                fillColor: _kCardBg,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _kBorder)),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _kBorder)),
              ),
              items: [
                if (!company.requireCostCenter)
                  DropdownMenuItem<String>(value: null, child: Text(l.corpCostCenterNone)),
                for (final c in company.costCenters)
                  DropdownMenuItem<String>(value: c, child: Text(c)),
              ],
              onChanged: onCostCenter,
            ),
          ],
          const SizedBox(height: 12),
          _LightTextField(
            label: l.corpReference,
            hint: l.corpReferenceHint,
            icon: Icons.tag_rounded,
            onChanged: onReference,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: LD.accentTint, border: Border.all(color: _kBorder)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: _kPanelAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.corpBillCompanyNotice(company.name),
                      style: const TextStyle(fontFamily: kSans, fontSize: 12,
                          height: 1.5, color: _kTextSub)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── PROMO CODE ────────────────────────────────────────────────────────────────

class _PromoCodeField extends StatelessWidget {
  const _PromoCodeField({
    required this.controller,
    required this.applied,
    required this.discount,
    required this.error,
    required this.checking,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? applied;

  /// Previewed discount for the current fare (null while re-checking).
  final double? discount;
  final String? error;
  final bool checking;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: LD.accentTint, border: Border.all(color: LD.accent)),
        child: Row(children: [
          const Icon(Icons.local_offer_outlined, size: 18, color: _kPanelAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              discount == null
                  ? l.promoApplied(applied!)
                  : l.promoAppliedWithDiscount(applied!, LuxMoney.format(discount!.round())),
              style: const TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w600, color: _kTextPrimary),
            ),
          ),
          if (checking)
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPanelAccent))
          else
            IconButton(
              tooltip: l.promoRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18, color: _kTextSub),
              onPressed: onRemove,
            ),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => onApply(),
              style: const TextStyle(fontFamily: kSans, fontSize: 13, color: _kTextPrimary, letterSpacing: 1),
              decoration: InputDecoration(
                labelText: l.promoFieldLabel,
                labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
                    color: _kTextSub, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.local_offer_outlined, size: 18, color: _kTextSub),
                filled: true,
                fillColor: _kCardBg,
                isDense: true,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _kBorder)),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _kBorder)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: _kTextPrimary,
                side: const BorderSide(color: _kTextPrimary),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: checking ? null : onApply,
              child: checking
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kTextPrimary))
                  : Text(l.promoApply),
            ),
          ),
        ]),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(localizedBookingError(l, error!),
              style: const TextStyle(fontFamily: kSans, fontSize: 12, color: LuxPalette.error)),
        ],
      ],
    );
  }
}
