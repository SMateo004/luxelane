part of '../home_web_page.dart';

// ============================================================
// Trust Section — the Luxelane promise + how it works.
// Only commitments the product actually enforces are listed here
// (server-fixed prices, free cancellation before the ride, verified
// chauffeurs, live tracking). Never add unverified reviews.
// ============================================================

class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.onBook});
  final VoidCallback onBook;

  static const _promises = [
    (
      icon: Icons.lock_outline,
      title: 'Precio fijo en Bs',
      body:
          'Ves el precio final antes de reservar, sin recargos por tráfico. Incluye 60 min de espera en aeropuerto y 15 en ciudad.',
    ),
    (
      icon: Icons.event_available_outlined,
      title: 'Cancelación gratuita',
      body:
          'Cancela sin costo hasta 1 hora antes de la recogida, desde la app.',
    ),
    (
      icon: Icons.verified_user_outlined,
      title: 'Chóferes verificados',
      body:
          'Licencia y documentos revisados por nuestro equipo antes de su primer viaje.',
    ),
    (
      icon: Icons.near_me_outlined,
      title: 'Seguimiento en vivo',
      body:
          'Sigue a tu chófer en el mapa y recibe avisos cuando está en camino y cuando llega.',
    ),
  ];

  static const _steps = [
    (
      n: '01',
      title: 'Reserva en un minuto',
      body: 'Elige origen, destino, fecha y clase de vehículo.'
    ),
    (
      n: '02',
      title: 'Confirma tu precio fijo',
      body: 'Te mostramos el precio final en bolivianos. Ese es el que pagas.'
    ),
    (
      n: '03',
      title: 'Tu chófer te espera',
      body: 'Recibe los datos de tu chófer y síguelo en tiempo real.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 900;
    final gutter = narrow ? 20.0 : 48.0;

    return Container(
      color: LD.bg,
      padding:
          EdgeInsets.symmetric(vertical: narrow ? 72 : 112, horizontal: gutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealOnScroll(
                  child: Text('LA PROMESA LUXELANE', style: eyebrow())),
              const SizedBox(height: 16),
              RevealOnScroll(
                delay: const Duration(milliseconds: 80),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Viajar con confianza,\nde principio a fin.',
                    style: displayText(
                        size: narrow ? 40 : 60, weight: FontWeight.w400),
                  ),
                ),
              ),
              SizedBox(height: narrow ? 40 : 64),
              _Grid(
                columns: width < 600 ? 1 : (width < 1100 ? 2 : 4),
                children: [
                  for (var i = 0; i < _promises.length; i++)
                    RevealOnScroll(
                      delay: Duration(milliseconds: 60 * i),
                      child: _PromiseCard(
                        icon: _promises[i].icon,
                        title: _promises[i].title,
                        body: _promises[i].body,
                      ),
                    ),
                ],
              ),
              SizedBox(height: narrow ? 72 : 112),
              RevealOnScroll(child: Text('CÓMO FUNCIONA', style: eyebrow())),
              const SizedBox(height: 32),
              _Grid(
                columns: width < 800 ? 1 : 3,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    RevealOnScroll(
                      delay: Duration(milliseconds: 80 * i),
                      child: _StepTile(
                          n: _steps[i].n,
                          title: _steps[i].title,
                          body: _steps[i].body),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              RevealOnScroll(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TrustCta(onTap: onBook),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple responsive grid: equal-width columns, rows sized to content.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 24.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final row = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: gap),
              Expanded(
                  child: j < row.length ? row[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
      if (i + columns < children.length) rows.add(const SizedBox(height: gap));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LD.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: LD.accentTint, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: LD.accent),
            ),
            const SizedBox(height: 24),
            Text(title, style: displayText(size: 24, weight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(body, style: bodyText(size: 14)),
          ],
        ),
      );
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: LD.accent)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n,
                style: displayText(
                    size: 34, color: LD.accent, weight: FontWeight.w400)),
            const SizedBox(height: 12),
            Text(title,
                style: bodyText(size: 16, color: LD.ink)
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(body, style: bodyText(size: 14)),
          ],
        ),
      );
}

class _TrustCta extends StatefulWidget {
  const _TrustCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_TrustCta> createState() => _TrustCtaState();
}

class _TrustCtaState extends State<_TrustCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Reservar un viaje',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: LuxMotion.fast,
              curve: LuxMotion.curve,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              color: _hover ? LuxPalette.champagneLight : LD.cta,
              // widthFactor keeps the button as wide as its label.
              child: const Center(
                widthFactor: 1,
                child: Text(
                  'RESERVAR UN VIAJE',
                  style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: LD.onCta,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
