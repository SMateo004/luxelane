part of '../home_web_page.dart';

// ============================================================
// Fixed Nav
// ============================================================

class _LuxNav extends StatelessWidget {
  const _LuxNav({
    required this.scrollY,
    required this.onFleet,
    required this.onServices,
    required this.onBusiness,
  });

  final double scrollY;
  final VoidCallback onFleet;
  final VoidCallback onServices;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    final scrolled = scrollY > 60;
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 72,
      decoration: BoxDecoration(
        color: scrolled ? const Color(0xF50B1220) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? Colors.white.withAlpha(25) : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 56),
        child: Row(
          children: [
            // Logo → always goes home
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: const _LuxLogo(light: true),
              ),
            ),
            const Spacer(),
            // Hide nav links on narrow screens — keep only CTA
            if (!narrow) ...[
              const _ServicesDropdownLink(),
              const SizedBox(width: 32),
              _NavLink('Flota',        light: true, onTap: onFleet),
              const SizedBox(width: 32),
              _NavLink('Para empresas',light: true, onTap: onBusiness),
              const SizedBox(width: 40),
            ],
            // Auth-aware right side
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, auth) {
                if (auth is AuthAuthenticated) {
                  return Row(children: [
                    if (!narrow) _NavCta(onTap: () => ctx.go('/')),
                    if (!narrow) const SizedBox(width: 12),
                    const NotificationBell(color: Colors.white),
                    const SizedBox(width: 8),
                    _AvatarDot(
                      name:  auth.user.displayName,
                      onTap: () => ctx.go('/profile'),
                    ),
                  ]);
                }
                return _NavCta(onTap: () => ctx.go('/'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxLogo extends StatelessWidget {
  const _LuxLogo({this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              border: Border.all(
                color: light ? Colors.white.withAlpha(200) : LD.ink,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'L',
                style: TextStyle(
                  fontFamily: kSerif, fontSize: 15, fontWeight: FontWeight.w500,
                  color: light ? Colors.white : LD.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LUXELANE',
            style: TextStyle(
              fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600,
              letterSpacing: 3.0,
              color: light ? Colors.white : LD.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      );
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, {required this.onTap, this.light = false});
  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
              color: _hover
                  ? (widget.light ? Colors.white : LD.ink)
                  : (widget.light ? Colors.white.withAlpha(160) : LD.ink3),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
}

// ── Services dropdown nav link ────────────────────────────────────────────────

class _ServicesDropdownLink extends StatefulWidget {
  const _ServicesDropdownLink();

  @override
  State<_ServicesDropdownLink> createState() => _ServicesDropdownLinkState();
}

class _ServicesDropdownLinkState extends State<_ServicesDropdownLink> {
  bool _hover = false;
  bool _dropHover = false;
  final _portalController = OverlayPortalController();
  final _key = GlobalKey();

  void _show() {
    setState(() => _hover = true);
    if (!_portalController.isShowing) _portalController.show();
  }

  void _hide() {
    setState(() => _hover = false);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_dropHover && mounted) {
        _portalController.hide();
      }
    });
  }

  static const _items = [
    ('Recogida inmediata',       '/servicios/recogida-inmediata'),
    ('Traslado al aeropuerto',   '/servicios/traslado-aeropuerto'),
    ('Contratación por horas',   '/servicios/contratacion-por-horas'),
  ];

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (_) {
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return const SizedBox.shrink();
          final offset = box.localToGlobal(Offset.zero);
          final size   = box.size;
          return Positioned(
            left: offset.dx - 12,
            top:  offset.dy + size.height + 4,
            child: MouseRegion(
              onEnter: (_) => setState(() => _dropHover = true),
              onExit:  (_) {
                setState(() => _dropHover = false);
                _hide();
              },
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF111A2B),
                  border: Border.all(color: const Color(0xFF24314A)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _items.map((item) => _DropItem(
                    label: item.$1,
                    onTap: () {
                      _portalController.hide();
                      context.go(item.$2);
                    },
                  )).toList(),
                ),
              ),
            ),
          );
        },
        child: MouseRegion(
          key: _key,
          onEnter: (_) => _show(),
          onExit:  (_) => _hide(),
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SERVICIOS',
                style: TextStyle(
                  fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                  color: _hover ? Colors.white : Colors.white.withAlpha(160),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: _hover ? Colors.white : Colors.white.withAlpha(160),
              ),
            ],
          ),
        ),
      );
}

class _DropItem extends StatefulWidget {
  const _DropItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_DropItem> createState() => _DropItemState();
}

class _DropItemState extends State<_DropItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hover ? LD.accent.withAlpha(30) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 3, height: 3,
                  decoration: const BoxDecoration(
                    color: LD.accent, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                    color: _hover ? Colors.white : Colors.white.withAlpha(180),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavCta extends StatefulWidget {
  const _NavCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_NavCta> createState() => _NavCtaState();
}

class _NavCtaState extends State<_NavCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            color: _hover ? LuxPalette.champagneLight : LD.cta,
            child: const Text(
              'RESERVAR UN VIAJE',
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 1.8, color: LD.onCta,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: LD.accentTint),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontFamily: kSans, fontSize: 13, fontWeight: FontWeight.w500,
                color: LD.accent, decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}
