import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String _kSans = 'Montserrat';
const String _kSerif = 'Cormorant Garamond';
const Color _kBg = Color(0xFF070E18);
const Color _kSurface = Color(0xFF0A1220);
const Color _kElevated = Color(0xFF0D1928);
const Color _kBorder = Color(0xFF1A2B40);
const Color _kSapphire = Color(0xFF1B4F8A);
const Color _kSapphireLight = Color(0xFF2E6FBF);

class ImmediatePickupPage extends StatefulWidget {
  const ImmediatePickupPage({super.key});

  @override
  State<ImmediatePickupPage> createState() => _ImmediatePickupPageState();
}

class _ImmediatePickupPageState extends State<ImmediatePickupPage> {
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _navScrolled) {
      setState(() => _navScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 72),
                    _HeroSection(isMobile: isMobile),
                    _IntroSection(isMobile: isMobile),
                    _FeatureCardsSection(isMobile: isMobile),
                    _SplitSection(isMobile: isMobile),
                    _FooterSection(),
                  ],
                ),
              ),
              _NavBar(scrolled: _navScrolled, isMobile: isMobile),
            ],
          );
        },
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool scrolled;
  final bool isMobile;
  const _NavBar({required this.scrolled, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 72,
        color: scrolled ? _kBg : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48),
        child: Row(
          children: [
            _WordMark(),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(label: 'INICIO', onTap: () => context.go('/')),
              const SizedBox(width: 32),
              const _NavText(label: 'SERVICIOS'),
              const SizedBox(width: 32),
              const _NavText(label: 'FLOTA'),
              const SizedBox(width: 32),
              const _NavText(label: 'PARA EMPRESAS'),
              const SizedBox(width: 40),
            ],
            _ReserveButton(onTap: () => context.go('/')),
          ],
        ),
      ),
    );
  }
}

class _WordMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _kSapphire,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'LUXELANE',
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 11,
            letterSpacing: 1.0,
            color: _hovered ? Colors.white : Colors.white.withAlpha(160),
          ),
        ),
      ),
    );
  }
}

class _NavText extends StatefulWidget {
  final String label;
  const _NavText({required this.label});

  @override
  State<_NavText> createState() => _NavTextState();
}

class _NavTextState extends State<_NavText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Text(
        widget.label,
        style: TextStyle(
          fontFamily: _kSans,
          fontSize: 11,
          letterSpacing: 1.0,
          color: _hovered ? Colors.white : Colors.white.withAlpha(160),
        ),
      ),
    );
  }
}

class _ReserveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ReserveButton({required this.onTap});

  @override
  State<_ReserveButton> createState() => _ReserveButtonState();
}

class _ReserveButtonState extends State<_ReserveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _kSapphireLight : _kSapphire,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'RESERVAR UN VIAJE',
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 11,
              letterSpacing: 1.0,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  const _HeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final heroHeight = isMobile ? 340.0 : 520.0;
    final titleSize = isMobile ? 42.0 : 64.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/services/recogida/hero.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: _kElevated,
              child: const Center(
                child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC070E18),
                ],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Servicio de\nRecogida Inmediata!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _kSerif,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chóferes profesionales a su alcance',
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 14,
                      letterSpacing: 2.0,
                      color: Color(0xFFA0A0A0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSection extends StatelessWidget {
  final bool isMobile;
  const _IntroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final vPad = isMobile ? 40.0 : 80.0;
    final hPad = isMobile ? 20.0 : 40.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    return Container(
      color: _kBg,
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              const Text(
                'RECOGIDA INMEDIATA',
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 10,
                  letterSpacing: 3.0,
                  color: _kSapphire,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Descubre el servicio de recogida inmediata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kSerif,
                  fontSize: titleSize,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques en la aplicación Luxelane.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 15,
                  color: Colors.white.withAlpha(160),
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCardsSection extends StatelessWidget {
  final bool isMobile;
  const _FeatureCardsSection({required this.isMobile});

  static const List<_FeatureCardData> _cards = [
    _FeatureCardData(
      icon: Icons.touch_app_outlined,
      title: 'Conveniencia',
      description:
          'Consigue un viaje con chófer de puerta a puerta justo cuando lo necesitas con solo unos toques.',
    ),
    _FeatureCardData(
      icon: Icons.airline_seat_recline_extra_outlined,
      title: 'Comodidad',
      description:
          'Un viaje privado en un vehículo de alta gama hace que cada viaje sea un placer.',
    ),
    _FeatureCardData(
      icon: Icons.star_border_outlined,
      title: 'Calidad',
      description:
          'Hacer que su experiencia sea excelente es nuestra máxima prioridad en todos sus viajes.',
    ),
    _FeatureCardData(
      icon: Icons.person_outline,
      title: 'Chóferes profesionales',
      description:
          'Viaje con confianza gracias a los chóferes expertos que le ofrecen la mejor calidad y discreción.',
    ),
    _FeatureCardData(
      icon: Icons.shield_outlined,
      title: 'Fiabilidad',
      description:
          'Reserve con seguridad y manténgase informado con actualizaciones del estado del viaje en tiempo real.',
    ),
    _FeatureCardData(
      icon: Icons.payments_outlined,
      title: 'Precios competitivos',
      description:
          'Acceda a un servicio de primera calidad a precios basados en la distancia, justos para todos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 80.0;
    final vPad = isMobile ? 32.0 : 80.0;

    if (isMobile) {
      return Container(
        color: _kSurface,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          children: [
            for (int i = 0; i < _cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _FeatureCard(data: _cards[i]),
            ],
          ],
        ),
      );
    }

    return Container(
      color: _kSurface,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        children: [
          for (int row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _FeatureCard(data: _cards[row * 2])),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard(data: _cards[row * 2 + 1])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: _kSapphire, size: 28),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: _kSans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 13,
              color: Colors.white.withAlpha(160),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitSection extends StatelessWidget {
  final bool isMobile;
  const _SplitSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 64.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/images/services/recogida/interior.jpg',
            height: 260,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: _kElevated,
              height: 260,
              child: const Center(
                child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
              ),
            ),
          ),
          Container(
            color: _kSurface,
            padding: EdgeInsets.all(hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÓMODO · SEGURO · INMEDIATO',
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 10,
                    letterSpacing: 3.0,
                    color: _kSapphire,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cómodos viajes a la carta en cuestión de minutos',
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cuando necesite una forma segura de desplazarse por la ciudad, piense en el servicio de recogida inmediata de Luxelane. La combinación perfecta entre el servicio tradicional de traslados y el transporte privado.',
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 14,
                    color: Colors.white.withAlpha(160),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 32),
                _CtaButton(
                  label: 'RESERVAR AHORA',
                  onTap: () => context.go('/'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 520,
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              'assets/images/services/recogida/interior.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: _kElevated,
                height: 520,
                child: const Center(
                  child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: _kSurface,
              padding: EdgeInsets.all(hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CÓMODO · SEGURO · INMEDIATO',
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 10,
                      letterSpacing: 3.0,
                      color: _kSapphire,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cómodos viajes a la carta en cuestión de minutos',
                    style: TextStyle(
                      fontFamily: _kSerif,
                      fontSize: titleSize,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cuando necesite una forma segura de desplazarse por la ciudad, piense en el servicio de recogida inmediata de Luxelane. La combinación perfecta entre el servicio tradicional de traslados y el transporte privado.',
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 14,
                      color: Colors.white.withAlpha(160),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _CtaButton(
                    label: 'RESERVAR AHORA',
                    onTap: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? _kSapphireLight : _kSapphire,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: _kSans,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      height: 80,
      child: Center(
        child: Text(
          '© 2025 Luxelane · Todos los derechos reservados',
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 11,
            color: Colors.white.withAlpha(60),
          ),
        ),
      ),
    );
  }
}
