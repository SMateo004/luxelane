part of '../home_web_page.dart';

// ============================================================
// Business Section
// ============================================================

class _BusinessSection extends StatelessWidget {
  const _BusinessSection({required this.sectionKey, required this.onLearnMore});
  final GlobalKey sectionKey;
  final VoidCallback onLearnMore;

  // 🎬 Place video at: assets/videos/business_bg.mp4
  static const _videoAsset = 'assets/videos/business_bg.mp4';

  static const _perks = [
    'Facturación y cobros centralizados',
    'Gerente de cuenta dedicado',
    'Herramientas de cumplimiento de política de viajes',
    'Reservas prioritarias para ejecutivos',
    'Monitoreo de viajes en tiempo real',
    'Reservas para invitados y equipos',
  ];

  Widget _perksPanel(double hPad, double vPad) => Stack(
        children: [
          Positioned.fill(child: _VideoBackground(assetPath: _videoAsset)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: const [Color(0xCC0B1220), Color(0xE8070E18)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _perks.asMap().entries.map((e) {
                final i = e.key;
                return RevealOnScroll(
                  delay: Duration(milliseconds: i * 70), dy: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20))),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: Text('0${i + 1}', style: TextStyle(
                          fontFamily: kSerif, fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: LD.accent.withAlpha(180),
                          decoration: TextDecoration.none,
                        )),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(
                          fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xE6FFFFFF),
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        )),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final hPad = narrow ? 24.0 : 64.0;
    final vPad = narrow ? 48.0 : 100.0;

    final headlinePanel = Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RevealOnScroll(dx: -160, child: const LuxEyebrow('Para Empresas')),
        const SizedBox(height: 28),
        RevealOnScroll(
          delay: const Duration(milliseconds: 80), dx: -160,
          child: Text('Viajes corporativos,\nredefinidos.',
              style: displayText(size: narrow ? 36 : 52, color: Colors.white)),
        ),
        const SizedBox(height: 28),
        RevealOnScroll(
          delay: const Duration(milliseconds: 160), dx: -120,
          child: Text(
            'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.',
            style: bodyText(size: 14, color: const Color(0xCCFFFFFF)),
          ),
        ),
        const SizedBox(height: 44),
        RevealOnScroll(
          delay: const Duration(milliseconds: 220), dx: -120,
          child: _GhostBtn(label: 'Más información', light: true, onTap: onLearnMore),
        ),
      ]),
    );

    return Container(
      key: sectionKey,
      color: LD.dark,
      child: narrow
          ? Column(children: [
              headlinePanel,
              SizedBox(height: 320, child: _perksPanel(hPad, 32)),
            ])
          : IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: headlinePanel),
                Expanded(child: _perksPanel(hPad, vPad)),
              ]),
            ),
    );
  }
}

// ============================================================
// CTA Section
// ============================================================

class _CtaSection extends StatelessWidget {
  const _CtaSection({required this.onBook, required this.onViewFleet});
  final VoidCallback onBook;
  final VoidCallback onViewFleet;

  // 🎬 Place your video file at: assets/videos/cta_bg.mp4
  static const _videoAsset = 'assets/videos/cta_bg.mp4';

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Video background (looping, muted, full-bleed)
          Positioned.fill(
            child: _VideoBackground(assetPath: _videoAsset),
          ),
          // Dark overlay — video stays cinematic, text is bright
          const Positioned.fill(
            child: ColoredBox(color: Color(0x85050A12)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 80, 64, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RevealOnScroll(
                      dx: -100, threshold: 0.9,
                      child: const Text('CUANDO QUIERAS. DONDE QUIERAS.',
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w600,
                          letterSpacing: 4.0,
                          color: Color(0xE0FFFFFF),
                          decoration: TextDecoration.none,
                        )),
                    ),
                    const SizedBox(height: 24),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 80),
                      dx: -100, threshold: 0.9,
                      child: Text('Tu próximo viaje,',
                          style: displayText(size: 96, color: Colors.white)),
                    ),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 120),
                      dx: -100, threshold: 0.9,
                      child: Text('en tus términos.',
                          style: displayText(size: 96, color: Colors.white,
                              style: FontStyle.italic)),
                    ),
                    const SizedBox(height: 48),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 160),
                      dx: -80, threshold: 0.9,
                      child: const Text(
                        'Precio fijo  ·  Chóferes verificados  ·  Reserva anticipada',
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
                          letterSpacing: 2.8,
                          color: Color(0xCCFFFFFF),
                          decoration: TextDecoration.none,
                        )),
                    ),
                    const SizedBox(height: 52),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 220),
                      dx: -80, threshold: 0.9,
                      child: Row(children: [
                        _SolidBtn(
                          label: 'Reservar un viaje', white: true,
                          onTap: onBook,
                        ),
                        const SizedBox(width: 20),
                        _GhostBtn(label: 'Ver flota', light: true, onTap: onViewFleet),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ============================================================
// Shared looping video background
// ============================================================

// 🎬 VIDEO ASSET LOCATIONS:
//   Business section  →  assets/videos/business_bg.mp4
//   CTA section       →  assets/videos/cta_bg.mp4
// Both are already registered in pubspec.yaml under flutter > assets.
// Drop the .mp4 files in place and hot-restart to see them.

class _VideoBackground extends StatefulWidget {
  const _VideoBackground({required this.assetPath});
  final String assetPath;

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ctrl = VideoPlayerController.asset(widget.assetPath);
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      await ctrl.setVolume(0);
      await ctrl.setLooping(true);
      await ctrl.play();
      setState(() { _ctrl = ctrl; _ready = true; });
    } catch (_) {
      // Asset not present yet — section shows solid dark colour as fallback
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      // Fallback: dark colour while video loads / file not placed yet
      return const ColoredBox(color: Color(0xFF0B1220));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width:  _ctrl!.value.size.width,
        height: _ctrl!.value.size.height,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}
