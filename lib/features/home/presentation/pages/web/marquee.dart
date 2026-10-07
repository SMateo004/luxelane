part of '../home_web_page.dart';

// ============================================================
// Marquee Bar
// ============================================================

class _MarqueeBar extends StatefulWidget {
  const _MarqueeBar();

  @override
  State<_MarqueeBar> createState() => _MarqueeBarState();
}

class _MarqueeBarState extends State<_MarqueeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _items = [
    'Precios Fijos en Bs','Chóferes Verificados','Cancelación Gratuita',
    'Reserva en minutos','Flota Premium','Seguimiento en Vivo',
    'Traslados Aeroportuarios','Viajes Corporativos','Privacidad y Discreción','Chófer por Horas',
  ];
  static const _oneSetPx = 2200.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
        height: 40, color: LD.dark,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-_ctrl.value * _oneSetPx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int r = 0; r < 3; r++)
                    for (int i = 0; i < _items.length; i++) ...[
                      Text(
                        _items[i].toUpperCase(),
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                          color: Colors.white.withAlpha(70),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(color: LD.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
