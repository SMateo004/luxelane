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

class AirportTransferPage extends StatefulWidget {
  const AirportTransferPage({super.key});

  @override
  State<AirportTransferPage> createState() => _AirportTransferPageState();
}

class _AirportTransferPageState extends State<AirportTransferPage> {
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;
  bool _isIda = true;

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
              isMobile
                  ? _MobileLayout(
                      scrollController: _scrollController,
                      isIda: _isIda,
                      onToggle: (val) => setState(() => _isIda = val),
                    )
                  : _DesktopLayout(
                      scrollController: _scrollController,
                      isIda: _isIda,
                      onToggle: (val) => setState(() => _isIda = val),
                    ),
              _NavBar(scrolled: _navScrolled, isMobile: isMobile),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final ScrollController scrollController;
  final bool isIda;
  final ValueChanged<bool> onToggle;

  const _DesktopLayout({
    required this.scrollController,
    required this.isIda,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 2,
          child: _BookingPanel(
            isIda: isIda,
            onToggle: onToggle,
            isMobile: false,
          ),
        ),
        Flexible(
          flex: 3,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72),
                _RightHeroSection(isMobile: false),
                _ThreeFeatureCards(isMobile: false),
                _VehicleClassesSection(isMobile: false),
                _LongTextSection(isMobile: false),
                _FaqSection(isMobile: false),
                _FooterSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final ScrollController scrollController;
  final bool isIda;
  final ValueChanged<bool> onToggle;

  const _MobileLayout({
    required this.scrollController,
    required this.isIda,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 72),
          _BookingPanel(isIda: isIda, onToggle: onToggle, isMobile: true),
          _RightHeroSection(isMobile: true),
          _ThreeFeatureCards(isMobile: true),
          _VehicleClassesSection(isMobile: true),
          _LongTextSection(isMobile: true),
          _FaqSection(isMobile: true),
          _FooterSection(),
        ],
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

class _BookingPanel extends StatelessWidget {
  final bool isIda;
  final ValueChanged<bool> onToggle;
  final bool isMobile;
  const _BookingPanel({
    required this.isIda,
    required this.onToggle,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final hPad = isMobile ? 20.0 : 48.0;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
      children: [
        const SizedBox(height: 8),
        Row(
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          'Traslados al aeropuerto',
          style: TextStyle(
            fontFamily: _kSerif,
            fontSize: isMobile ? 26.0 : 36.0,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ida o Por horas · Sin esperas',
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 13,
            color: Colors.white.withAlpha(130),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isIda ? _kSapphire : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                    child: Text(
                      'Ida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: isIda
                            ? Colors.white
                            : Colors.white.withAlpha(130),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isIda ? _kSapphire : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                    child: Text(
                      'Por horas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: !isIda
                            ? Colors.white
                            : Colors.white.withAlpha(130),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DarkTextField(hint: 'De - Dirección, aeropuerto, hotel...'),
        const SizedBox(height: 12),
        _DarkTextField(hint: 'A - Dirección, aeropuerto, hotel...'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kElevated,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: _kSapphire, size: 16),
              const SizedBox(width: 10),
              Text(
                dateStr,
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 13,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'El chófer esperará 15 minutos sin coste adicional.',
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 11,
            color: Colors.white.withAlpha(80),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _FullWidthCtaButton(
          label: 'SELECCIONAR',
          onTap: () => context.go('/'),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
              '← Volver al inicio',
              style: TextStyle(
                fontFamily: _kSans,
                fontSize: 12,
                color: Colors.white.withAlpha(130),
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          border: Border(
            bottom: BorderSide(color: _kBorder),
          ),
        ),
        padding: EdgeInsets.fromLTRB(hPad, 64, hPad, 32),
        child: content,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(
          right: BorderSide(color: _kBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 64, hPad, 48),
      child: SingleChildScrollView(child: content),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final String hint;
  const _DarkTextField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(
        fontFamily: _kSans,
        fontSize: 13,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: _kSans,
          fontSize: 13,
          color: Colors.white.withAlpha(80),
        ),
        filled: true,
        fillColor: _kElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _kSapphire),
        ),
      ),
    );
  }
}

class _FullWidthCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _FullWidthCtaButton({required this.label, required this.onTap});

  @override
  State<_FullWidthCtaButton> createState() => _FullWidthCtaButtonState();
}

class _FullWidthCtaButtonState extends State<_FullWidthCtaButton> {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? _kSapphireLight : _kSapphire,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kSans,
              fontSize: 12,
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

class _RightHeroSection extends StatelessWidget {
  final bool isMobile;
  const _RightHeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final heroHeight = isMobile ? 260.0 : 400.0;
    final hPad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 36.0 : 52.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/services/aeropuerto/hero.jpg',
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
                colors: [Colors.transparent, Color(0xCC070E18)],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SERVICIO DE TRASLADOS',
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 10,
                    letterSpacing: 3.0,
                    color: _kSapphire,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Al aeropuerto sin\nestrés ni esperas',
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeFeatureCards extends StatelessWidget {
  final bool isMobile;
  const _ThreeFeatureCards({required this.isMobile});

  static const List<_FeatureCardData> _cards = [
    _FeatureCardData(
      icon: Icons.payments_outlined,
      title: 'Precios competitivos',
      description:
          'Acceda a un servicio de primera calidad a precios basados en la distancia.',
    ),
    _FeatureCardData(
      icon: Icons.flight_outlined,
      title: 'Viaje al aeropuerto sin problemas',
      description:
          'Relájese con la hora gratuita de espera y el seguimiento de vuelos.',
    ),
    _FeatureCardData(
      icon: Icons.schedule_outlined,
      title: 'Flexibilidad de viaje',
      description:
          'Manténgase flexible. Es rápido y fácil cancelar o hacer cambios en cualquier viaje.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;

    if (isMobile) {
      return Container(
        color: _kSurface,
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            for (int i = 0; i < _cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SmallFeatureCard(data: _cards[i]),
            ],
          ],
        ),
      );
    }

    return Container(
      color: _kSurface,
      padding: EdgeInsets.all(pad),
      child: Row(
        children: [
          for (int i = 0; i < _cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Expanded(child: _SmallFeatureCard(data: _cards[i])),
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

class _SmallFeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  const _SmallFeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: _kSapphire, size: 26),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: _kSans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 12,
              color: Colors.white.withAlpha(160),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleClassesSection extends StatelessWidget {
  final bool isMobile;
  const _VehicleClassesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 56),
            child: Text(
              'Descubre nuestras clases de servicio',
              style: TextStyle(
                fontFamily: _kSerif,
                fontSize: titleSize,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
          _VehicleCard(
            imagePath: 'assets/images/services/aeropuerto/business.jpg',
            badge: 'BUSINESS CLASS',
            title: 'Mercedes Clase E, BMW Serie 5, o similar',
            bullets: const [
              '👥 Hasta 3 personas',
              '🧳 Hasta 2 maletas grandes',
              '✓ Disponible en la mayoría de ciudades',
            ],
            imageOnLeft: true,
            isMobile: isMobile,
          ),
          _VehicleCard(
            imagePath: 'assets/images/services/aeropuerto/firstclass.jpg',
            badge: 'FIRST CLASS',
            title: 'Mercedes S-Class, BMW Serie 7, o similar',
            bullets: const [
              '👥 Hasta 3 personas',
              '🧳 Hasta 2 maletas grandes',
              '✓ Servicio de lujo premium',
            ],
            imageOnLeft: false,
            isMobile: isMobile,
          ),
          _VehicleCard(
            imagePath: 'assets/images/services/aeropuerto/van.jpg',
            badge: 'BUSINESS VAN',
            title: 'Mercedes V-Class, Toyota Alphard, o similar',
            bullets: const [
              '👥 Hasta 7 personas',
              '🧳 Hasta 5 maletas grandes',
              '✓ Ideal para grupos y familias',
            ],
            imageOnLeft: true,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String imagePath;
  final String badge;
  final String title;
  final List<String> bullets;
  final bool imageOnLeft;
  final bool isMobile;

  const _VehicleCard({
    required this.imagePath,
    required this.badge,
    required this.title,
    required this.bullets,
    required this.imageOnLeft,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = isMobile ? 22.0 : 28.0;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            imagePath,
            height: 220,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: _kElevated,
              height: 220,
              child: const Center(
                child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
              ),
            ),
          ),
          Container(
            color: _kSurface,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSapphire.withAlpha(40),
                    border: Border.all(color: _kSapphire),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontFamily: _kSans,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      color: _kSapphireLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                for (final bullet in bullets) ...[
                  const SizedBox(height: 6),
                  Text(
                    bullet,
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 12,
                      color: Colors.white.withAlpha(160),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final imageWidget = Expanded(
      child: SizedBox(
        height: 280,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: _kElevated,
            height: 280,
            child: const Center(
              child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
            ),
          ),
        ),
      ),
    );

    final textWidget = Expanded(
      child: Container(
        height: 280,
        color: _kSurface,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kSapphire.withAlpha(40),
                border: Border.all(color: _kSapphire),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontFamily: _kSans,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  color: _kSapphireLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: _kSerif,
                fontSize: titleSize,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            for (final bullet in bullets) ...[
              const SizedBox(height: 6),
              Text(
                bullet,
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 12,
                  color: Colors.white.withAlpha(160),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: imageOnLeft
            ? [imageWidget, textWidget]
            : [textWidget, imageWidget],
      ),
    );
  }
}

class _LongTextSection extends StatelessWidget {
  final bool isMobile;
  const _LongTextSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 26.0 : 36.0;
    final imgHeight = isMobile ? 220.0 : 380.0;

    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imgHeight,
            child: Image.asset(
              'assets/images/services/aeropuerto/arrival.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: _kElevated,
                height: imgHeight,
                child: const Center(
                  child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Llegue o salga del aeropuerto',
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Un servicio de chófer de Luxelane busca alcanzar los estándares más altos posibles para todos sus pasajeros. Nuestros conductores profesionales pueden hacer un seguimiento de su vuelo y ajustar la hora de recogida si hay retrasos fuera de su control.',
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 14,
                    color: Colors.white.withAlpha(160),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservas de conexiones entre aeropuertos',
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reservar un servicio de Luxelane es fácil. Simplemente proporcione los datos de recogida y destino y seleccione la clase del vehículo. El precio que ve es el precio que paga, sin cargos ocultos.',
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 14,
                    color: Colors.white.withAlpha(160),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final bool isMobile;
  const _FaqSection({required this.isMobile});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: '¿Qué hace un traslado al aeropuerto?',
      answer:
          'Un traslado al aeropuerto es un servicio de coche privado que lleva a los pasajeros de avión hacia y desde el aeropuerto. Los conductores profesionales pueden recoger a los pasajeros en la terminal después de recoger su equipaje.',
    ),
    _FaqItem(
      question: '¿Merece la pena reservar un traslado desde el aeropuerto?',
      answer:
          'Los traslados al aeropuerto son una forma estupenda de evitar el estrés tanto al inicio como al final de un vuelo. Luxelane ofrece una amplia gama de opciones de traslado que se adaptan a tus necesidades.',
    ),
    _FaqItem(
      question: '¿Qué es un traslado al aeropuerto de pago?',
      answer:
          'Un traslado al aeropuerto de pago es un servicio de transporte con un conductor profesional reservado con antelación. El precio incluye propinas, peajes y cualquier otro gasto adicional.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    return Container(
      color: _kSurface,
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preguntas frecuentes',
            style: TextStyle(
              fontFamily: _kSerif,
              fontSize: titleSize,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 32),
          for (final faq in _faqs) _FaqTile(item: faq),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatelessWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: _kSapphire,
        collapsedIconColor: Colors.white.withAlpha(80),
        title: Text(
          item.question,
          style: const TextStyle(
            fontFamily: _kSans,
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer,
              style: TextStyle(
                fontFamily: _kSans,
                fontSize: 13,
                color: Colors.white.withAlpha(160),
                height: 1.65,
              ),
            ),
          ),
        ],
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
