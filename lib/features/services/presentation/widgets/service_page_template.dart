import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../../../../core/widgets/lux_site_chrome.dart';
import '../../../home/presentation/pages/home_design.dart';

// ============================================================
// Service page template
//
// Every service page follows the same narrative, mirroring how a
// high-value traveller decides:
//   1. Desire     — immersive hero + the booking card, right away
//   2. Certainty  — the promises that remove risk (price, waiting, cancel)
//   3. Clarity    — three steps: nothing to figure out
//   4. Story      — what the experience feels like
//   5. Choice     — three classes, never more (avoids choice overload)
//   6. Objections — FAQ
//   7. Close      — a calm, single call to action
// ============================================================

@immutable
class ServiceStep {
  const ServiceStep(this.title, this.body);
  final String title;
  final String body;
}

@immutable
class ServiceFaq {
  const ServiceFaq(this.question, this.answer);
  final String question;
  final String answer;
}

@immutable
class ServicePageContent {
  const ServicePageContent({
    required this.mode,
    required this.eyebrow,
    required this.title,
    required this.lead,
    required this.heroImage,
    required this.heroFallback,
    required this.assurances,
    required this.steps,
    required this.storyEyebrow,
    required this.storyTitle,
    required this.storyBody,
    required this.storyPoints,
    required this.storyImage,
    required this.storyFallback,
    required this.faqs,
    required this.closingTitle,
    required this.closingBody,
  });

  final LuxBookingMode mode;
  final String eyebrow;
  final String title;
  final String lead;
  final String heroImage;
  final String heroFallback;
  final List<LuxAssurance> assurances;
  final List<ServiceStep> steps;
  final String storyEyebrow;
  final String storyTitle;
  final String storyBody;
  final List<String> storyPoints;
  final String storyImage;
  final String storyFallback;
  final List<ServiceFaq> faqs;
  final String closingTitle;
  final String closingBody;

  ServiceType get serviceType => mode == LuxBookingMode.hourly
      ? ServiceType.byTheHour
      : ServiceType.oneWay;
}

class ServicePageTemplate extends StatefulWidget {
  const ServicePageTemplate({super.key, required this.content});
  final ServicePageContent content;

  @override
  State<ServicePageTemplate> createState() => _ServicePageTemplateState();
}

class _ServicePageTemplateState extends State<ServicePageTemplate> {
  final _scroll = ScrollController();
  final _luxScroll = LuxScrollNotifier();
  final _fleetKey = GlobalKey();
  bool _solidNav = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      _luxScroll.update(_scroll.offset);
      final solid = _scroll.offset > 40;
      if (solid != _solidNav) setState(() => _solidNav = solid);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _luxScroll.dispose();
    super.dispose();
  }

  void _toTop() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 900),
      curve: const Cubic(0.16, 1, 0.3, 1));

  void _toFleet() {
    final ctx = _fleetKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 800),
        curve: const Cubic(0.16, 1, 0.3, 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    return Scaffold(
      backgroundColor: LD.dark,
      body: LuxScrollProvider(
        notifier: _luxScroll,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(content: c),
                  _AssuranceBand(items: c.assurances),
                  _StepsSection(steps: c.steps),
                  _StorySection(content: c),
                  _ClassesSection(
                      key: _fleetKey, service: c.serviceType, onChoose: _toTop),
                  _FaqSection(faqs: c.faqs),
                  _ClosingSection(
                      title: c.closingTitle,
                      body: c.closingBody,
                      onBook: _toTop),
                  LuxSiteFooter(onFleet: _toFleet),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LuxSiteNav(
                  solid: _solidNav, onBook: _toTop, onFleet: _toFleet),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

double _hPad(BuildContext c) => MediaQuery.sizeOf(c).width < 900 ? 24 : 56;
bool _narrow(BuildContext c) => MediaQuery.sizeOf(c).width < 900;

class _Photo extends StatelessWidget {
  const _Photo(this.path, this.fallback);
  final String path;
  final String fallback;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Image.asset(
          fallback,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF0D1928)),
        ),
      );
}

class _Bounded extends StatelessWidget {
  const _Bounded({required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

// ── 1. Hero ─────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.content});
  final ServicePageContent content;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    final screenH = MediaQuery.sizeOf(context).height;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LuxEyebrow(content.eyebrow, color: const Color(0xFF8CB2E3)),
        const SizedBox(height: 20),
        Text(content.title,
            style: displayText(size: narrow ? 46 : 72, color: Colors.white)
                .copyWith(height: 1.0)),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(content.lead,
              style: bodyText(
                  size: narrow ? 14 : 16, color: Colors.white.withAlpha(190))),
        ),
      ],
    );

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: LuxServiceBookingCard(mode: content.mode),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 520,
            child: Stack(fit: StackFit.expand, children: [
              _Photo(content.heroImage, content.heroFallback),
              const _HeroScrim(),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, kSiteNavHeight + 24, pad, 72),
                child: Align(alignment: Alignment.bottomLeft, child: copy),
              ),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad - 8),
              child: card,
            ),
          ),
        ],
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: (screenH).clamp(720, 980)),
      child: Stack(children: [
        Positioned.fill(child: _Photo(content.heroImage, content.heroFallback)),
        const Positioned.fill(child: _HeroScrim(horizontal: true)),
        Padding(
          padding: EdgeInsets.fromLTRB(pad, kSiteNavHeight + 64, pad, 80),
          child: _Bounded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: RevealOnScroll(dy: 40, child: copy)),
                const SizedBox(width: 64),
                RevealOnScroll(
                    delay: const Duration(milliseconds: 150),
                    dy: 40,
                    child: card),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim({this.horizontal = false});
  final bool horizontal;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: horizontal
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xEB070E18),
                    Color(0x99070E18),
                    Color(0x66070E18)
                  ],
                  stops: [0.0, 0.55, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xA6070E18),
                    Color(0x8C070E18),
                    Color(0xF5070E18)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
        ),
      );
}

// ── 2. Assurances ───────────────────────────────────────────────────────────

class _AssuranceBand extends StatelessWidget {
  const _AssuranceBand({required this.items});
  final List<LuxAssurance> items;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    final tiles = [
      for (var i = 0; i < items.length; i++)
        RevealOnScroll(
          delay: Duration(milliseconds: 80 * i),
          dy: 32,
          child: _AssuranceTile(item: items[i]),
        ),
    ];
    return Container(
      color: LD.bg,
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 56 : 88),
      child: _Bounded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LuxEyebrow('Nuestra promesa'),
            const SizedBox(height: 14),
            Text('Tranquilidad, por escrito.',
                style:
                    displayText(size: narrow ? 36 : 52).copyWith(height: 1.05)),
            SizedBox(height: narrow ? 36 : 56),
            if (narrow)
              Column(children: [
                for (final t in tiles)
                  Padding(padding: const EdgeInsets.only(bottom: 28), child: t),
              ])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 40),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssuranceTile extends StatelessWidget {
  const _AssuranceTile({required this.item});
  final LuxAssurance item;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(border: Border.all(color: LD.border)),
            child: Icon(item.icon, size: 20, color: LD.sph),
          ),
          const SizedBox(height: 20),
          Text(item.title,
              style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LD.ink,
                  height: 1.4)),
          if (item.detail != null) ...[
            const SizedBox(height: 8),
            Text(item.detail!,
                style:
                    bodyText(size: 13, color: LD.ink3).copyWith(height: 1.6)),
          ],
        ],
      );
}

// ── 3. Steps ────────────────────────────────────────────────────────────────

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.steps});
  final List<ServiceStep> steps;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    Widget step(int i) => RevealOnScroll(
          delay: Duration(milliseconds: 100 * i),
          dy: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('0${i + 1}',
                  style: displayText(
                      size: 56, color: LD.sph, weight: FontWeight.w300)),
              const SizedBox(height: 16),
              Container(width: 32, height: 1, color: LD.ink.withAlpha(60)),
              const SizedBox(height: 20),
              Text(steps[i].title,
                  style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: LD.ink)),
              const SizedBox(height: 10),
              Text(steps[i].body, style: bodyText(size: 14, color: LD.ink3)),
            ],
          ),
        );

    return Container(
      color: LD.bg2,
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 64 : 104),
      child: _Bounded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LuxEyebrow('Cómo funciona'),
            const SizedBox(height: 14),
            Text('Tres pasos.\nNada más.',
                style:
                    displayText(size: narrow ? 36 : 52).copyWith(height: 1.05)),
            SizedBox(height: narrow ? 40 : 64),
            if (narrow)
              Column(children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: step(i)),
              ])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 56),
                    Expanded(child: step(i)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── 4. Story ────────────────────────────────────────────────────────────────

class _StorySection extends StatelessWidget {
  const _StorySection({required this.content});
  final ServicePageContent content;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);

    final text = Padding(
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 56 : 96),
      child: RevealOnScroll(
        dy: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LuxEyebrow(content.storyEyebrow, color: const Color(0xFF8CB2E3)),
            const SizedBox(height: 16),
            Text(content.storyTitle,
                style: displayText(size: narrow ? 38 : 54, color: Colors.white)
                    .copyWith(height: 1.05)),
            const SizedBox(height: 24),
            Text(content.storyBody,
                style: bodyText(size: 15, color: Colors.white.withAlpha(180))),
            const SizedBox(height: 28),
            for (final p in content.storyPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Container(
                          width: 14, height: 1, color: const Color(0xFF8CB2E3)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(p,
                          style: bodyText(
                                  size: 14, color: Colors.white.withAlpha(210))
                              .copyWith(height: 1.6)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    final photo = _Photo(content.storyImage, content.storyFallback);

    if (narrow) {
      return ColoredBox(
        color: LD.dark,
        child: Column(children: [SizedBox(height: 300, child: photo), text]),
      );
    }
    // Photo fills the left half; the text column decides the height.
    // (No IntrinsicHeight: an expanding image has no finite intrinsic size.)
    return ColoredBox(
      color: LD.dark,
      child: LayoutBuilder(
        builder: (context, cons) => Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: cons.maxWidth / 2,
              child: photo,
            ),
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 600),
                    child: Align(alignment: Alignment.centerLeft, child: text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 5. Classes ──────────────────────────────────────────────────────────────

class _ClassesSection extends StatelessWidget {
  const _ClassesSection(
      {super.key, required this.service, required this.onChoose});
  final ServiceType service;
  final VoidCallback onChoose;

  static const _classes = [
    (VehicleClass.business, 'assets/images/vehicles/business/car.png'),
    (VehicleClass.firstClass, 'assets/images/vehicles/first_class/car.png'),
    (VehicleClass.businessVan, 'assets/images/vehicles/van/car.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    final cards = [
      for (var i = 0; i < _classes.length; i++)
        RevealOnScroll(
          delay: Duration(milliseconds: 90 * i),
          dy: 40,
          child: _ClassCard(
            vc: _classes[i].$1,
            image: _classes[i].$2,
            from: DefaultPricing.rules[_classes[i].$1]![service]!['min']!,
            perHour: service == ServiceType.byTheHour,
            featured: _classes[i].$1 == VehicleClass.firstClass,
            onChoose: onChoose,
          ),
        ),
    ];

    return Container(
      color: LD.bg,
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 64 : 104),
      child: _Bounded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LuxEyebrow('La flota'),
            const SizedBox(height: 14),
            Text('Elige cómo llegar.',
                style:
                    displayText(size: narrow ? 36 : 52).copyWith(height: 1.05)),
            const SizedBox(height: 12),
            Text(
                'Vehículos de gama alta, impecables y preparados antes de cada servicio.',
                style: bodyText(size: 14, color: LD.ink3)),
            SizedBox(height: narrow ? 36 : 56),
            if (narrow)
              Column(children: [
                for (final c in cards)
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
              ])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 20),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({
    required this.vc,
    required this.image,
    required this.from,
    required this.perHour,
    required this.featured,
    required this.onChoose,
  });
  final VehicleClass vc;
  final String image;
  final double from;
  final bool perHour;
  final bool featured;
  final VoidCallback onChoose;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onChoose,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: _hover || widget.featured
                      ? LD.sph.withAlpha(120)
                      : LD.border),
              boxShadow: [
                BoxShadow(
                  color: LD.ink.withAlpha(_hover ? 22 : 8),
                  blurRadius: _hover ? 40 : 16,
                  offset: Offset(0, _hover ? 20 : 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(widget.vc.label.toUpperCase(),
                      style: uiLabel(size: 10.5, color: LD.ink, spacing: 2.4)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (widget.featured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: LD.sphTint,
                      child: Text('LA MÁS ELEGIDA',
                          style:
                              uiLabel(size: 8.5, color: LD.sph, spacing: 1.4)),
                    ),
                ]),
                const SizedBox(height: 6),
                Text(widget.vc.description,
                    style: bodyText(size: 13, color: LD.ink3)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Image.asset(widget.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_outlined,
                            size: 56,
                            color: LD.border)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 15, color: LD.ink3),
                  const SizedBox(width: 6),
                  Text('Hasta ${widget.vc.capacity} pasajeros',
                      style: uiLabel(size: 12, color: LD.ink2, spacing: 0.4)),
                ]),
                const SizedBox(height: 18),
                Container(height: 1, color: LD.border),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESDE',
                            style:
                                uiLabel(size: 9, color: LD.ink3, spacing: 1.8)),
                        const SizedBox(height: 2),
                        Text(
                          widget.perHour
                              ? 'Bs ${widget.from.toStringAsFixed(0)} · 2 h'
                              : 'Bs ${widget.from.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontFamily: kSans,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: LD.ink),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 250),
                      offset: Offset(_hover ? 0.1 : 0, 0),
                      child: const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: LD.sph),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

// ── 6. FAQ ──────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.faqs});
  final List<ServiceFaq> faqs;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LuxEyebrow('Preguntas frecuentes'),
        const SizedBox(height: 14),
        Text('Todo lo que\nquieres saber.',
            style: displayText(size: narrow ? 36 : 48).copyWith(height: 1.05)),
        const SizedBox(height: 16),
        Text('¿Algo más? Nuestro equipo responde 24/7.',
            style: bodyText(size: 14, color: LD.ink3)),
      ],
    );
    final list = Column(
      children: [
        Container(height: 1, color: LD.border),
        for (final f in faqs) _FaqTile(faq: f),
      ],
    );
    return Container(
      color: LD.bg2,
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 64 : 104),
      child: _Bounded(
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 32), list])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: heading),
                  const SizedBox(width: 64),
                  Expanded(flex: 3, child: list),
                ],
              ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});
  final ServiceFaq faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LD.border))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Row(children: [
                    Expanded(
                      child: Text(widget.faq.question,
                          style: const TextStyle(
                              fontFamily: kSans,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: LD.ink,
                              height: 1.4)),
                    ),
                    const SizedBox(width: 16),
                    AnimatedRotation(
                      turns: _open ? 0.125 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.add_rounded,
                          size: 20, color: LD.sph),
                    ),
                  ]),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 24, right: 36),
                      child: Text(widget.faq.answer,
                          style: bodyText(size: 14, color: LD.ink2)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
}

// ── 7. Closing CTA ──────────────────────────────────────────────────────────

class _ClosingSection extends StatelessWidget {
  const _ClosingSection(
      {required this.title, required this.body, required this.onBook});
  final String title;
  final String body;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final narrow = _narrow(context);
    final pad = _hPad(context);
    return Container(
      color: LD.dark,
      padding:
          EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 80 : 128),
      child: _Bounded(
        maxWidth: 760,
        child: RevealOnScroll(
          dy: 40,
          child: Column(
            children: [
              const LuxEyebrow('Luxelane', color: Color(0xFF8CB2E3)),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style:
                      displayText(size: narrow ? 40 : 60, color: Colors.white)
                          .copyWith(height: 1.05)),
              const SizedBox(height: 20),
              Text(body,
                  textAlign: TextAlign.center,
                  style:
                      bodyText(size: 15, color: Colors.white.withAlpha(170))),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LD.ink,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    minimumSize: const Size(0, 56),
                  ),
                  child: const Text('RESERVAR AHORA',
                      style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 18),
              Text('${LuxPromise.fixedPrice}  ·  ${LuxPromise.freeCancel}',
                  textAlign: TextAlign.center,
                  style: uiLabel(
                      size: 10.5,
                      color: Colors.white.withAlpha(110),
                      spacing: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
