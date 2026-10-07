import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/presentation/pages/home_design.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../design/lux_promise.dart';
import 'components.dart';

// ============================================================
// Public site chrome — the nav bar and footer shared by the landing page
// and every service page, so the brand reads as one product everywhere.
// ============================================================

/// Service catalogue: one list feeds the nav dropdown, mobile menu and footer.
abstract class LuxServiceRoutes {
  static const pickup = '/servicios/recogida-inmediata';
  static const airport = '/servicios/traslado-aeropuerto';
  static const hourly = '/servicios/contratacion-por-horas';

  static const all = <(String, String, IconData)>[
    ('Traslado al aeropuerto', airport, Icons.flight_takeoff_rounded),
    ('Chófer por horas', hourly, Icons.schedule_rounded),
    ('Recogida inmediata', pickup, Icons.bolt_rounded),
  ];
}

const kSiteNavHeight = 72.0;

/// Fixed, auth-aware navigation bar. Transparent over hero imagery and turns
/// into a solid midnight bar once the page scrolls ([solid]).
class LuxSiteNav extends StatelessWidget {
  const LuxSiteNav({
    super.key,
    required this.solid,
    this.onFleet,
    this.onBusiness,
    this.onBook,
  });

  final bool solid;
  final VoidCallback? onFleet;
  final VoidCallback? onBusiness;

  /// Primary CTA. Defaults to the home booking widget.
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final book = onBook ?? () => context.go('/');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: kSiteNavHeight,
      decoration: BoxDecoration(
        color: solid ? const Color(0xF5070E18) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: solid ? Colors.white.withAlpha(25) : Colors.transparent,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 56),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Luxelane, inicio',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: const LuxelaneWordmark(color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
          if (!narrow) ...[
            const LuxServicesMenu(),
            const SizedBox(width: 32),
            LuxNavLink('Flota', onTap: onFleet ?? () => context.go('/')),
            const SizedBox(width: 32),
            LuxNavLink('Para empresas',
                onTap: onBusiness ?? () => context.go('/')),
            const SizedBox(width: 40),
          ],
          BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, auth) {
              if (auth is AuthAuthenticated) {
                return Row(children: [
                  if (!narrow) LuxNavCta(onTap: book),
                  if (!narrow) const SizedBox(width: 16),
                  const NotificationBell(color: Colors.white),
                  const SizedBox(width: 8),
                  _AvatarDot(
                    name: auth.user.displayName,
                    onTap: () => ctx.go('/profile'),
                  ),
                  if (narrow) ...[
                    const SizedBox(width: 4),
                    _MenuButton(
                        onBook: book, onFleet: onFleet, onBusiness: onBusiness),
                  ],
                ]);
              }
              return Row(children: [
                if (!narrow) ...[
                  LuxNavLink('Iniciar sesión', onTap: () => ctx.go('/login')),
                  const SizedBox(width: 24),
                ],
                LuxNavCta(onTap: book, compact: narrow),
                if (narrow) ...[
                  const SizedBox(width: 4),
                  _MenuButton(
                      onBook: book, onFleet: onFleet, onBusiness: onBusiness),
                ],
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class LuxNavLink extends StatefulWidget {
  const LuxNavLink(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<LuxNavLink> createState() => _LuxNavLinkState();
}

class _LuxNavLinkState extends State<LuxNavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          // Underline is overlaid so it never shifts the label's baseline.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: _hover ? Colors.white : Colors.white.withAlpha(170),
                  decoration: TextDecoration.none,
                ),
              ),
              // Hairline underline grows on hover — quiet, precise feedback.
              Positioned(
                left: 0,
                bottom: -6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 1,
                  width: _hover ? 18 : 0,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      );
}

/// "Servicios" link with hover dropdown.
class LuxServicesMenu extends StatefulWidget {
  const LuxServicesMenu({super.key});

  @override
  State<LuxServicesMenu> createState() => _LuxServicesMenuState();
}

class _LuxServicesMenuState extends State<LuxServicesMenu> {
  bool _hover = false;
  bool _dropHover = false;
  final _portal = OverlayPortalController();
  final _key = GlobalKey();

  void _show() {
    setState(() => _hover = true);
    if (!_portal.isShowing) _portal.show();
  }

  void _hide() {
    setState(() => _hover = false);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!_dropHover && !_hover && mounted && _portal.isShowing)
        _portal.hide();
    });
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) {
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return const SizedBox.shrink();
          final offset = box.localToGlobal(Offset.zero);
          return Positioned(
            left: offset.dx - 20,
            top: offset.dy + box.size.height + 10,
            child: MouseRegion(
              onEnter: (_) => setState(() => _dropHover = true),
              onExit: (_) {
                setState(() => _dropHover = false);
                _hide();
              },
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1220),
                  border: Border.all(color: const Color(0xFF1A2B40)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 32,
                        offset: Offset(0, 16)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in LuxServiceRoutes.all)
                      _DropItem(
                        label: s.$1,
                        icon: s.$3,
                        onTap: () {
                          _portal.hide();
                          context.go(s.$2);
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        child: MouseRegion(
          key: _key,
          onEnter: (_) => _show(),
          onExit: (_) => _hide(),
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SERVICIOS',
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: _hover ? Colors.white : Colors.white.withAlpha(170),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _hover ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: _hover ? Colors.white : Colors.white.withAlpha(170)),
              ),
            ],
          ),
        ),
      );
}

class _DropItem extends StatefulWidget {
  const _DropItem(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_DropItem> createState() => _DropItemState();
}

class _DropItemState extends State<_DropItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hover ? LD.sph.withAlpha(40) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(widget.icon,
                    size: 16,
                    color: _hover ? Colors.white : const Color(0xFF8CB2E3)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      color:
                          _hover ? Colors.white : Colors.white.withAlpha(190),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Solid sapphire primary CTA used in the nav.
class LuxNavCta extends StatefulWidget {
  const LuxNavCta({super.key, required this.onTap, this.compact = false});
  final VoidCallback onTap;
  final bool compact;

  @override
  State<LuxNavCta> createState() => _LuxNavCtaState();
}

class _LuxNavCtaState extends State<LuxNavCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 16 : 22, vertical: 11),
            color: _hover ? LD.sphLt : LD.sph,
            child: Text(
              widget.compact ? 'RESERVAR' : 'RESERVAR UN VIAJE',
              style: const TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: Colors.white,
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
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Mi perfil',
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(90)),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'L',
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ── Mobile full-screen menu ─────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onBook, this.onFleet, this.onBusiness});
  final VoidCallback onBook;
  final VoidCallback? onFleet;
  final VoidCallback? onBusiness;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Menú',
        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        onPressed: () => showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Cerrar menú',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (ctx, _, __) => _MobileMenu(
            onBook: onBook,
            onFleet: onFleet,
            onBusiness: onBusiness,
          ),
          transitionBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -0.03), end: Offset.zero)
                  .animate(
                      CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ),
      );
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({required this.onBook, this.onFleet, this.onBusiness});
  final VoidCallback onBook;
  final VoidCallback? onFleet;
  final VoidCallback? onBusiness;

  @override
  Widget build(BuildContext context) {
    void go(VoidCallback f) {
      Navigator.of(context).pop();
      f();
    }

    Widget item(String label, VoidCallback onTap, {IconData? icon}) => InkWell(
          onTap: () => go(onTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF8CB2E3)),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(label,
                    style: displayText(
                            size: 26,
                            color: Colors.white,
                            weight: FontWeight.w400)
                        .copyWith(height: 1.2, letterSpacing: 0)),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white.withAlpha(110)),
            ]),
          ),
        );

    return Material(
      color: const Color(0xFF070E18),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const LuxelaneWordmark(color: Colors.white),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: 32),
              const LuxEyebrow('Servicios', color: Color(0xFF8CB2E3)),
              const SizedBox(height: 8),
              for (final s in LuxServiceRoutes.all)
                item(s.$1, () => context.go(s.$2), icon: s.$3),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withAlpha(25)),
              item('Flota', onFleet ?? () => context.go('/')),
              item('Para empresas', onBusiness ?? () => context.go('/')),
              const Spacer(),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => go(onBook),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LD.sph,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('RESERVAR UN VIAJE',
                      style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${LuxPromise.fixedPrice}  ·  ${LuxPromise.freeCancel}',
                textAlign: TextAlign.center,
                style: uiLabel(
                    size: 10, color: Colors.white.withAlpha(120), spacing: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Footer
// ============================================================

class LuxSiteFooter extends StatelessWidget {
  const LuxSiteFooter({super.key, this.onFleet, this.onBusiness});
  final VoidCallback? onFleet;
  final VoidCallback? onBusiness;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuxelaneWordmark(color: Colors.white.withAlpha(220)),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Servicio de chófer privado para quienes valoran su tiempo, '
            'su privacidad y cada detalle del camino.',
            style: bodyText(size: 13, color: Colors.white.withAlpha(130)),
          ),
        ),
      ],
    );

    final services = _FooterCol('Servicios', [
      for (final s in LuxServiceRoutes.all) (s.$1, () => context.go(s.$2)),
    ]);
    final company = _FooterCol('Luxelane', [
      ('Flota', onFleet ?? () => context.go('/')),
      ('Para empresas', onBusiness ?? () => context.go('/')),
      ('Conduce con nosotros', () => context.go('/driver/login')),
    ]);
    const promises = _FooterCol('Nuestra promesa', [
      (LuxPromise.fixedPrice, null),
      (LuxPromise.freeCancel, null),
      (LuxPromise.chauffeurs, null),
      (LuxPromise.support, null),
    ]);

    return Container(
      color: const Color(0xFF03050A),
      child: Column(children: [
        Container(height: 1, color: LD.sph.withAlpha(102)),
        Padding(
          padding:
              EdgeInsets.fromLTRB(narrow ? 24 : 56, 64, narrow ? 24 : 56, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (narrow) ...[
                    brand,
                    const SizedBox(height: 40),
                    Wrap(
                        spacing: 48,
                        runSpacing: 36,
                        children: [services, company, promises]),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: brand),
                        Expanded(flex: 3, child: services),
                        Expanded(flex: 3, child: company),
                        Expanded(flex: 3, child: promises),
                      ],
                    ),
                  const SizedBox(height: 56),
                  Container(height: 1, color: Colors.white.withAlpha(18)),
                  const SizedBox(height: 22),
                  Text(
                    '© ${DateTime.now().year} Luxelane. Todos los derechos reservados.',
                    style: uiLabel(
                        size: 10,
                        color: Colors.white.withAlpha(70),
                        spacing: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol(this.title, this.links);
  final String title;
  final List<(String, VoidCallback?)> links;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: uiLabel(
                  size: 10, color: Colors.white.withAlpha(110), spacing: 2.4)),
          const SizedBox(height: 18),
          for (final l in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: l.$2 == null
                  ? Text(l.$1,
                      style:
                          bodyText(size: 13, color: Colors.white.withAlpha(150))
                              .copyWith(height: 1.4))
                  : _FooterLink(l.$1, l.$2!),
            ),
        ],
      );
}

class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: bodyText(
                    size: 13,
                    color: _hover ? Colors.white : Colors.white.withAlpha(150))
                .copyWith(height: 1.4),
          ),
        ),
      );
}
