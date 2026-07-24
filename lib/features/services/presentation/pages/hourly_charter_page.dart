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

class HourlyCharterPage extends StatefulWidget {
  const HourlyCharterPage({super.key});

  @override
  State<HourlyCharterPage> createState() => _HourlyCharterPageState();
}

class _HourlyCharterPageState extends State<HourlyCharterPage> {
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;
  bool _isIda = false;

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
          child: _BookingPanel(isIda: isIda, onToggle: onToggle, isMobile: false),
        ),
        Flexible(
          flex: 3,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72),
                _HeroSection(isMobile: false),
                _ServiceDescriptionSection(isMobile: false),
                _UseCasesSection(isMobile: false),
                _WorldReachSection(),
                _ReviewsSection(isMobile: false),
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
          _HeroSection(isMobile: true),
          _ServiceDescriptionSection(isMobile: true),
          _UseCasesSection(isMobile: true),
          _WorldReachSection(),
          _ReviewsSection(isMobile: true),
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
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final hPad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 26.0 : 36.0;

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
          'Chófer por horas',
          style: TextStyle(
            fontFamily: _kSerif,
            fontSize: titleSize,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu itinerario · Tu ritmo',
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
              const Icon(Icons.access_time_outlined,
                  color: _kSapphire, size: 16),
              const SizedBox(width: 10),
              Text(
                'Duración - 2 horas',
                style: TextStyle(
                  fontFamily: _kSans,
                  fontSize: 13,
                  color: Colors.white.withAlpha(80),
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down,
                  color: Colors.white.withAlpha(80), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _kElevated,
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: _kSapphire, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _kElevated,
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        color: _kSapphire, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  const _HeroSection({required this.isMobile});

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
            'assets/images/services/por-horas/hero.jpg',
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
                  'CONTRATACIÓN POR HORAS',
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
                  'Alquiler de chófer\npor horas y días',
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

class _ServiceDescriptionSection extends StatelessWidget {
  final bool isMobile;
  const _ServiceDescriptionSection({required this.isMobile});

  static const List<String> _bullets = [
    'Define tu itinerario: Tú decides dónde y cuándo ir',
    'Ahorra tiempo: Te dejaremos y recogeremos en la puerta de cada parada',
    'Disfruta con tranquilidad: Viaja en un vehículo premium',
    'Tarifas competitivas: Incluye 40 km de recorrido por hora',
    'Fiabilidad: Chóferes formados en los más altos estándares',
    'Sostenibilidad: Cada viaje se compensa con emisiones de carbono',
    'Wifi disponible en la mayoría de los vehículos',
    'Diseñado para la ciudad: Comienza y termina en la misma ciudad',
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 26.0 : 36.0;

    return Container(
      color: _kSurface,
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Servicio de chófer por horas',
            style: TextStyle(
              fontFamily: _kSerif,
              fontSize: titleSize,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Olvídate de cambiar de medio de transporte cuando tengas que hacer viajes con múltiples paradas. Con Luxelane, defines tu itinerario: tú decides dónde y cuándo ir.',
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 14,
              color: Colors.white.withAlpha(160),
              height: 1.7,
            ),
          ),
          const SizedBox(height: 28),
          for (final bullet in _bullets) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: _kSapphire,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontFamily: _kSans,
                      fontSize: 13,
                      color: Colors.white.withAlpha(160),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UseCasesSection extends StatelessWidget {
  final bool isMobile;
  const _UseCasesSection({required this.isMobile});

  static const List<_UseCaseData> _cases = [
    _UseCaseData(
      icon: Icons.business_center_outlined,
      title: 'Viajes de negocios',
      description:
          'Concéntrate en lo importante. Desplázate fácilmente entre reuniones sin preocuparte por la logística.',
    ),
    _UseCaseData(
      icon: Icons.music_note_outlined,
      title: 'Conciertos y eventos',
      description:
          'Disfruta de una llegada triunfal y una salida sin contratiempos de cualquier evento.',
    ),
    _UseCaseData(
      icon: Icons.camera_alt_outlined,
      title: 'Visitas turísticas',
      description:
          'Descubre la ciudad a tu manera, a tu ritmo, con un chófer local siempre a tu disposición.',
    ),
    _UseCaseData(
      icon: Icons.restaurant_outlined,
      title: 'Actividades de ocio',
      description:
          'Ya sea un almuerzo, compras o tu lista de tareas, tu chófer estará listo cuando lo necesites.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    if (isMobile) {
      return Container(
        color: _kBg,
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diseñado para cada ocasión',
              style: TextStyle(
                fontFamily: _kSerif,
                fontSize: titleSize,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 32),
            for (int i = 0; i < _cases.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _UseCaseCard(data: _cases[i]),
            ],
          ],
        ),
      );
    }

    return Container(
      color: _kBg,
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diseñado para cada ocasión',
            style: TextStyle(
              fontFamily: _kSerif,
              fontSize: titleSize,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _UseCaseCard(data: _cases[0])),
              const SizedBox(width: 20),
              Expanded(child: _UseCaseCard(data: _cases[1])),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _UseCaseCard(data: _cases[2])),
              const SizedBox(width: 20),
              Expanded(child: _UseCaseCard(data: _cases[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _UseCaseData {
  final IconData icon;
  final String title;
  final String description;
  const _UseCaseData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _UseCaseCard extends StatelessWidget {
  final _UseCaseData data;
  const _UseCaseCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: _kSapphire, size: 28),
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

class _WorldReachSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/services/por-horas/mapa.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: _kElevated,
              height: 320,
              child: const Center(
                child: Icon(Icons.image_outlined, color: _kBorder, size: 48),
              ),
            ),
          ),
          Container(
            color: const Color(0x99070E18),
          ),
          const Center(
            child: Text(
              'Disponible en más de 60 países · Cientos de ciudades',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kSans,
                fontSize: 16,
                letterSpacing: 2.0,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final bool isMobile;
  const _ReviewsSection({required this.isMobile});

  static const List<_ReviewData> _reviews = [
    _ReviewData(
      quote:
          'El chófer fue increíble, me ayudó con mis maletas y se detuvo en todos los lugares que quería ver.',
      location: 'Estados Unidos',
    ),
    _ReviewData(
      quote:
          'Los chóferes no son simples conductores sino profesionales altamente capacitados.',
      location: 'Portugal',
    ),
    _ReviewData(
      quote:
          'La aplicación que todos los viajeros necesitan conocer. No he encontrado un lugar donde no funcione.',
      location: 'Canadá',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 26.0 : 36.0;

    if (isMobile) {
      return Container(
        color: _kSurface,
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lo que dicen nuestros clientes',
              style: TextStyle(
                fontFamily: _kSerif,
                fontSize: titleSize,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 32),
            for (int i = 0; i < _reviews.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _ReviewCard(review: _reviews[i]),
            ],
          ],
        ),
      );
    }

    return Container(
      color: _kSurface,
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lo que dicen nuestros clientes',
            style: TextStyle(
              fontFamily: _kSerif,
              fontSize: titleSize,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _reviews.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                Expanded(child: _ReviewCard(review: _reviews[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewData {
  final String quote;
  final String location;
  const _ReviewData({required this.quote, required this.location});
}

class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kElevated,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: _kSapphire, size: 16),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"${review.quote}"',
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 12,
              color: Colors.white.withAlpha(160),
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            review.location,
            style: TextStyle(
              fontFamily: _kSans,
              fontSize: 11,
              color: Colors.white.withAlpha(80),
              letterSpacing: 0.5,
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
      question: '¿Cómo reservo un chófer por horas?',
      answer:
          'Selecciona el lugar de recogida, elige la duración, el día y la hora, elige una clase de vehículo y completa tu reserva.',
    ),
    _FaqItem(
      question: '¿Puedo modificar mi itinerario durante el viaje?',
      answer:
          'Sí. El conductor y el vehículo están a tu disposición en todo momento durante las horas de la reserva.',
    ),
    _FaqItem(
      question: '¿Cuándo recibiré los datos del chófer?',
      answer:
          'Una hora antes de la recogida se te enviarán un SMS y un correo electrónico con el nombre y número del conductor.',
    ),
    _FaqItem(
      question: '¿La reserva puede empezar en un aeropuerto?',
      answer:
          'Sí, la reserva puede empezar o terminar en un aeropuerto. El lugar de inicio y finalización deben estar en la misma ciudad.',
    ),
    _FaqItem(
      question: '¿Puedo aumentar el número de horas?',
      answer:
          'Sí, puedes editar la reserva antes de la hora de inicio. La duración mínima es 2 horas, máximo 24 horas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final titleSize = isMobile ? 30.0 : 42.0;

    return Container(
      color: _kElevated,
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
