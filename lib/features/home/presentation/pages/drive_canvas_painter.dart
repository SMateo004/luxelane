import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DriveCanvasAnim extends StatefulWidget {
  const DriveCanvasAnim({super.key});
  @override
  State<DriveCanvasAnim> createState() => _DriveCanvasAnimState();
}

class _DriveCanvasAnimState extends State<DriveCanvasAnim> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  double _mouseX = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _ctrl.addListener(_updateParticles);
  }

  void _updateParticles() {
    if (math.Random().nextDouble() > 0.7) {
      final w = MediaQuery.sizeOf(context).width;
      final h = MediaQuery.sizeOf(context).height;
      _particles.add(_Particle(
        x: w * 0.55 + math.Random().nextDouble() * w * 0.35,
        y: h * 0.42 + math.Random().nextDouble() * h * 0.08,
        vx: -math.Random().nextDouble() * 2 - 1,
        vy: math.Random().nextDouble() * 0.5 - 0.25,
        life: 1.0,
        size: math.Random().nextDouble() * 1.5 + 0.5,
      ));
    }
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].x += _particles[i].vx;
      _particles[i].y += _particles[i].vy;
      _particles[i].life -= 0.015;
      if (_particles[i].life <= 0) _particles.removeAt(i);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => setState(() => _mouseX = e.localPosition.dx),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: DrivePainter(
            progress: _ctrl.value * 10,
            mx: _mouseX - (MediaQuery.sizeOf(context).width / 2),
            particles: _particles,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, life, size;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.size});
}

class DrivePainter extends CustomPainter {
  final double progress;
  final double mx;
  final List<_Particle> particles;

  DrivePainter({required this.progress, required this.mx, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Background Sky
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, H * 0.5), [
        const Color(0xFFF2ECE0),
        const Color(0xFFEDE6D8),
        const Color(0xFFE8E0D0),
      ]);
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H * 0.5), skyPaint);

    final hgPaint = Paint()
      ..shader = ui.Gradient.radial(Offset(W * 0.5, H * 0.44), W * 0.5, [
        const Color(0x33C8AA64),
        const Color(0x0FC8AA64),
        const Color(0x00C8AA64),
      ]);
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H * 0.7), hgPaint);

    // City
    _drawCity(canvas, W, H);
    // Road
    _drawRoad(canvas, W, H);
    // Particles
    for (var p in particles) {
      canvas.drawCircle(Offset(p.x, p.y), p.size, Paint()..color = const Color(0xFFB4965A).withValues(alpha: p.life * 0.3));
    }
    // Car
    _drawCar(canvas, W, H);
  }

  void _drawCity(Canvas canvas, double W, double H) {
    final hor = H * 0.44;
    final buildings = [
      [0.04, 0.02, 0.07], [0.07, 0.015, 0.11], [0.09, 0.025, 0.085],
      [0.13, 0.018, 0.13], [0.155, 0.01, 0.09], [0.17, 0.03, 0.07],
      [0.22, 0.015, 0.15], [0.24, 0.02, 0.1], [0.27, 0.04, 0.08],
      [0.32, 0.012, 0.12], [0.34, 0.018, 0.07], [0.36, 0.025, 0.09],
      [0.62, 0.02, 0.09], [0.65, 0.012, 0.13], [0.68, 0.03, 0.075],
      [0.73, 0.018, 0.11], [0.76, 0.025, 0.085], [0.8, 0.02, 0.14],
      [0.84, 0.015, 0.09], [0.87, 0.035, 0.07], [0.93, 0.018, 0.1], [0.96, 0.022, 0.08],
    ];

    canvas.save();
    canvas.drawRect(Rect.fromLTWH(0, hor - H * 0.2, W, H * 0.2), Paint()
      ..shader = ui.Gradient.linear(Offset(0, hor - H * 0.18), Offset(0, hor), [
        const Color(0x00C8AF82), const Color(0x0DC8AF82)
      ]));

    final rng = math.Random(42);
    for (var b in buildings) {
      final bx = b[0] * W, bw = b[1] * W, bh = b[2] * H;
      for (int i = 0; i < bh ~/ 14; i++) {
        for (int j = 0; j < bw ~/ 10; j++) {
          if (rng.nextDouble() > 0.4) {
            canvas.drawRect(Rect.fromLTWH(bx + j * 10 + 2, hor - bh + i * 14 + 2, 5, 8), Paint()..color = const Color(0x14B4965A));
          }
        }
      }
      canvas.drawRect(Rect.fromLTWH(bx, hor - bh, bw, bh), Paint()..color = const Color(0x2E19140C));
    }
    canvas.restore();
  }

  void _drawRoad(Canvas canvas, double W, double H) {
    final vpX = W * 0.5 + mx * 0.02;
    final vpY = H * 0.44;
    final rW = W * 2.2;

    final rPath = Path()..moveTo(vpX, vpY)..lineTo(vpX - rW / 2, H + 100)..lineTo(vpX + rW / 2, H + 100)..close();
    canvas.drawPath(rPath, Paint()..shader = ui.Gradient.linear(Offset(0, vpY), Offset(0, H), [
      const Color(0xF2BEAF9B), const Color(0xF7AFA28E), const Color(0xFC9B8E7A)
    ]));

    for (var side in [-0.38, 0.38]) {
      canvas.drawLine(Offset(vpX, vpY), Offset(vpX + side * rW * 0.55, H + 100), Paint()..color = const Color(0x80A08246)..strokeWidth = 1.5);
    }

    const dashCount = 16;
    final baseScroll = progress * 0.4;
    for (int i = 0; i < dashCount; i++) {
      final t = ((i / dashCount) + baseScroll) % 1;
      final y = vpY + (H + 100 - vpY) * t;
      final w = (rW * 0.015) * t;
      final len = 50 * t;
      canvas.drawRect(Rect.fromLTWH(vpX - w / 2, y - len / 2, w, len), Paint()..color = const Color(0xFFC8B99B).withValues(alpha: 0.7 * t));
    }
  }

  void _drawCar(Canvas canvas, double W, double H) {
    final vpX = W * 0.5 + mx * 0.015;
    final vpY = H * 0.44;
    final s = math.min(W, H) * 0.001 * (60 + (progress % 1) * 10);
    final carW = s * 3.8, carH = s * 1.4;
    final cx = vpX + (math.sin((progress % 1) * math.pi * 4) * s * 0.5) + mx * 0.008;
    final cy = vpY + (H + 100 - vpY) * 0.62 - carH * 0.5;
    final scaleX = (1 + 0.62 * 2.5) * s * 0.038;

    canvas.save();
    canvas.translate(cx, cy);

    canvas.save();
    canvas.scale(1, 0.15);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, carH * 3.5), width: carW * 1.1, height: carH * 2.4), Paint()..color = const Color(0x33140F05));
    canvas.restore();

    canvas.scale(scaleX, scaleX);
    const bw = 100.0, bh = 28.0;

    final body = Path()..moveTo(-bw, 12)..lineTo(-bw, 0)..quadraticBezierTo(-bw * 0.92, -8, -bw * 0.7, -18)
      ..lineTo(-bw * 0.18, -26)..lineTo(bw * 0.28, -24)..quadraticBezierTo(bw * 0.82, -22, bw, -8)
      ..lineTo(bw, 12)..close();
    canvas.drawPath(body, Paint()..shader = ui.Gradient.linear(const Offset(0, -26), const Offset(0, 12), [const Color(0xFF2A2520), const Color(0xFF1A1510)]));

    for (var wx in [-bw * 0.62, bw * 0.6]) {
      canvas.drawCircle(Offset(wx, 14), 16, Paint()..color = const Color(0xFF181410));
      canvas.drawCircle(Offset(wx, 14), 10, Paint()..color = const Color(0xD9AA8C50));
      for (int a = 0; a < 5; a++) {
        final ang = (a / 5) * math.pi * 2 + progress * math.pi * 2;
        canvas.drawLine(Offset(wx + math.cos(ang) * 2, 14 + math.sin(ang) * 2), Offset(wx + math.cos(ang) * 9, 14 + math.sin(ang) * 9), Paint()..color = const Color(0x801E160A)..strokeWidth = 1.5);
      }
      canvas.drawCircle(Offset(wx, 14), 3, Paint()..color = const Color(0xFF1A1510));
    }
    
    // Headlight
    canvas.drawRect(const Rect.fromLTWH(bw - 2, -6, 6, 4), Paint()..color = const Color(0xF2F0E1BE));
    canvas.drawRect(const Rect.fromLTWH(bw - 5, -14, 30, 20), Paint()..shader = ui.Gradient.radial(const Offset(bw + 8, -4), 20, [const Color(0x40F0E1BE), const Color(0x00F0E1BE)]));
    // Taillight
    canvas.drawRect(const Rect.fromLTWH(-bw - 4, -6, 5, 4), Paint()..color = const Color(0xE6B41E14));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
