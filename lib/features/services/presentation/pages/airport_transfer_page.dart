import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/lux_tokens.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/utils/waiting_policy.dart';
import '../../../../l10n/l10n.dart';

const String _kSans = 'Montserrat';
const String _kSerif = 'Cormorant Garamond';
const Color _kBg = LuxPalette.ink;
const Color _kSurface = LuxPalette.surface;
const Color _kElevated = LuxPalette.elevated;
const Color _kBorder = LuxPalette.line;
// Brand accent (champagne). Text placed on top of it uses _kInk.
const Color _kSapphire = LuxPalette.champagne;
const Color _kSapphireLight = LuxPalette.champagneLight;
const Color _kInk = LuxPalette.ink;

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
    final l = context.l10n;
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
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isMobile) ...[
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavLink(label: l.servicesNavHome, onTap: () => context.go('/')),
                            const SizedBox(width: 32),
                            _NavLink(label: l.servicesNavServices, onTap: () => context.go('/')),
                            const SizedBox(width: 32),
                            _NavLink(label: l.servicesNavFleet, onTap: () => context.go('/')),
                            const SizedBox(width: 32),
                            _NavLink(label: l.servicesNavBusiness, onTap: () => context.push('/contacto')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                  Flexible(child: _ReserveButton(onTap: () => context.go('/'))),
                ],
              ),
            ),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              context.l10n.servicesBookRide,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: _kSans,
                fontSize: 11,
                letterSpacing: 1.0,
                color: _kInk,
                fontWeight: FontWeight.w600,
              ),
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
    final l = context.l10n;
    final dateStr = DateFormat.yMd(context.localeTag).format(DateTime.now());

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
          l.servicesAirportPanelTitle,
          style: TextStyle(
            fontFamily: _kSerif,
            fontSize: isMobile ? 26.0 : 36.0,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.servicesAirportPanelSubtitle,
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
                      context.l10n.servicesToggleOneWay,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: isIda
                            ? _kInk
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
                      context.l10n.serviceByTheHour,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kSans,
                        fontSize: 12,
                        color: !isIda
                            ? _kInk
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
        _DarkTextField(hint: context.l10n.servicesFromHint),
        const SizedBox(height: 12),
        _DarkTextField(hint: context.l10n.servicesToHint),
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
              Flexible(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: _kSans,
                    fontSize: 13,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.servicesAirportFreeWait(WaitingPolicy.airportFreeMinutes),
          style: TextStyle(
            fontFamily: _kSans,
            fontSize: 11,
            color: Colors.white.withAlpha(80),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _FullWidthCtaButton(
          label: context.l10n.servicesSelect,
          onTap: () => context.go('/'),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
              context.l10n.servicesBackHome,
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
              color: _kInk,
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

    final l = context.l10n;
    // Min height (not fixed) so longer translations grow the hero instead
    // of overflowing it.
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
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
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC070E18)],
                stops: [0.3, 1.0],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: heroHeight),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.servicesAirportHeroEyebrow,
                  style: const TextStyle(
                    fontFamily: _kSans,
                    fontSize: 10,
                    letterSpacing: 3.0,
                    color: _kSapphire,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.servicesAirportHeroTitle,
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
          ),
        ),
      ],
    );
  }
}

class _ThreeFeatureCards extends StatelessWidget {
  final bool isMobile;
  const _ThreeFeatureCards({required this.isMobile});

  static List<_FeatureCardData> _cardsFor(AppLocalizations l) => [
        _FeatureCardData(
          icon: Icons.payments_outlined,
          title: l.servicesFeaturePriceTitle,
          description: l.servicesAirportFeaturePriceBody,
        ),
        _FeatureCardData(
          icon: Icons.flight_outlined,
          title: l.servicesAirportFeatureFlightTitle,
          description: l.servicesAirportFeatureFlightBody,
        ),
        _FeatureCardData(
          icon: Icons.schedule_outlined,
          title: l.servicesAirportFeatureFlexTitle,
          description: l.servicesAirportFeatureFlexBody,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 48.0;
    final cards = _cardsFor(context.l10n);

    if (isMobile) {
      return Container(
        color: _kSurface,
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SmallFeatureCard(data: cards[i]),
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
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Expanded(child: _SmallFeatureCard(data: cards[i])),
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
    final l = context.l10n;

    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 56),
            child: Text(
              l.servicesAirportClassesTitle,
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
            badge: VehicleClass.business.localizedLabel(l).toUpperCase(),
            title: l.servicesVehicleBusinessModels,
            bullets: [
              '👥 ${l.servicesUpToPeople(3)}',
              '🧳 ${l.servicesUpToLargeBags(2)}',
              '✓ ${l.servicesVehicleMostCities}',
            ],
            imageOnLeft: true,
            isMobile: isMobile,
          ),
          _VehicleCard(
            imagePath: 'assets/images/services/aeropuerto/firstclass.jpg',
            badge: VehicleClass.firstClass.localizedLabel(l).toUpperCase(),
            title: l.servicesVehicleFirstModels,
            bullets: [
              '👥 ${l.servicesUpToPeople(3)}',
              '🧳 ${l.servicesUpToLargeBags(2)}',
              '✓ ${l.servicesVehiclePremiumLuxury}',
            ],
            imageOnLeft: false,
            isMobile: isMobile,
          ),
          _VehicleCard(
            imagePath: 'assets/images/services/aeropuerto/van.jpg',
            badge: VehicleClass.businessVan.localizedLabel(l).toUpperCase(),
            title: l.servicesVehicleVanModels,
            bullets: [
              '👥 ${l.servicesUpToPeople(7)}',
              '🧳 ${l.servicesUpToLargeBags(5)}',
              '✓ ${l.servicesVehicleGroups}',
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
        constraints: const BoxConstraints(minHeight: 280),
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
                  context.l10n.servicesAirportArriveTitle,
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.servicesAirportArriveBody,
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
                  context.l10n.servicesAirportConnectionsTitle,
                  style: TextStyle(
                    fontFamily: _kSerif,
                    fontSize: titleSize,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.servicesAirportConnectionsBody,
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

  static List<_FaqItem> _faqsFor(AppLocalizations l) => [
        _FaqItem(question: l.servicesAirportFaq1Q, answer: l.servicesAirportFaq1A),
        _FaqItem(question: l.servicesAirportFaq2Q, answer: l.servicesAirportFaq2A),
        _FaqItem(question: l.servicesAirportFaq3Q, answer: l.servicesAirportFaq3A),
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
            context.l10n.servicesFaqTitle,
            style: TextStyle(
              fontFamily: _kSerif,
              fontSize: titleSize,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 32),
          for (final faq in _faqsFor(context.l10n)) _FaqTile(item: faq),
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
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Text(
          context.l10n.servicesFooterRights(DateTime.now().year.toString()),
          textAlign: TextAlign.center,
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
