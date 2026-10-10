import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/vehicle_catalog.dart';
import '../../../../core/enums/enums.dart';
import '../../../home/presentation/pages/home_design.dart';

// Vector illustrations used wherever we don't (yet) have a real photo of the
// class. Drawn, not stretched: they stay sharp at any size and are specific to
// each vehicle type — never a photo of a different car.

const _ink = LD.ink;
const _ink2 = Color(0xFF1E3350);
const _seatFree = Color(0xFFE6ECF6);
const _seatLine = Color(0xFFB9C6DA);

// ── Vehicle image: real photo when we have one, illustration otherwise ───────

class VehicleImage extends StatelessWidget {
  const VehicleImage(this.vehicleClass, {super.key, this.fit = BoxFit.contain});
  final VehicleClass vehicleClass;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
        VehicleCatalog.carImage(vehicleClass),
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(painter: _SuvSidePainter()),
        ),
      );
}

/// Side profile of an executive SUV.
class _SuvSidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Design space 1000 × 440, centred and scaled to fit.
    const w = 1000.0, h = 440.0;
    final s = math.min(size.width / w, size.height / h);
    canvas.save();
    // Mirrored so the nose points left, like every vehicle photo.
    canvas.translate(
        (size.width + w * s) / 2, (size.height - h * s) / 2 + 6 * s);
    canvas.scale(-s, s);

    // Ground shadow
    canvas.drawOval(
      const Rect.fromLTWH(70, 352, 860, 34),
      Paint()
        ..color = _ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    const rearX = 230.0, frontX = 770.0, axleY = 330.0, archR = 70.0;

    final body = Path()
      ..moveTo(62, 318)
      ..lineTo(58, 236)
      ..quadraticBezierTo(60, 196, 96, 180)
      ..lineTo(150, 102)
      ..quadraticBezierTo(162, 86, 190, 84)
      ..lineTo(600, 82)
      ..quadraticBezierTo(632, 82, 652, 100)
      ..lineTo(742, 182)
      ..lineTo(900, 204)
      ..quadraticBezierTo(944, 212, 950, 246)
      ..lineTo(954, 300)
      ..quadraticBezierTo(954, 322, 932, 324)
      ..lineTo(frontX + archR + 8, 324)
      ..arcToPoint(Offset(frontX - archR - 8, 324),
          radius: const Radius.circular(archR + 8), clockwise: false)
      ..lineTo(rearX + archR + 8, 324)
      ..arcToPoint(Offset(rearX - archR - 8, 324),
          radius: const Radius.circular(archR + 8), clockwise: false)
      ..lineTo(80, 324)
      ..quadraticBezierTo(62, 324, 62, 318)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B4466), _ink2, _ink],
          stops: [0, 0.45, 1],
        ).createShader(const Rect.fromLTWH(0, 80, 1000, 250)),
    );

    // Shoulder highlight
    canvas.drawPath(
      Path()
        ..moveTo(100, 196)
        ..lineTo(740, 196)
        ..quadraticBezierTo(840, 204, 930, 226),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    // Glasshouse
    final glass = Path()
      ..moveTo(170, 110)
      ..quadraticBezierTo(178, 98, 198, 98)
      ..lineTo(594, 96)
      ..quadraticBezierTo(618, 96, 634, 110)
      ..lineTo(714, 182)
      ..lineTo(150, 184)
      ..close();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8CA4C4).withValues(alpha: 0.85),
            const Color(0xFF34506F),
          ],
        ).createShader(const Rect.fromLTWH(150, 96, 570, 90)),
    );
    // Pillars
    final pillar = Paint()..color = _ink2;
    canvas.drawRect(const Rect.fromLTWH(352, 96, 12, 90), pillar);
    canvas.drawRect(const Rect.fromLTWH(540, 96, 12, 90), pillar);

    // Door lines + handles
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawLine(const Offset(358, 188), const Offset(362, 312), line);
    canvas.drawLine(const Offset(546, 188), const Offset(552, 312), line);
    final handle = Paint()..color = Colors.white.withValues(alpha: 0.30);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(300, 214, 40, 6), const Radius.circular(3)),
        handle);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(488, 214, 40, 6), const Radius.circular(3)),
        handle);

    // Lights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(888, 214, 54, 12), const Radius.circular(6)),
      Paint()..color = const Color(0xFFE8F0FB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(60, 204, 26, 30), const Radius.circular(5)),
      Paint()..color = const Color(0xFFB4504F),
    );

    // Wheels
    for (final x in [rearX, frontX]) {
      _wheel(canvas, Offset(x, axleY), archR - 4);
    }
    canvas.restore();
  }

  void _wheel(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = const Color(0xFF0B1422));
    c.drawCircle(
      o,
      r * 0.62,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFDCE3EE), Color(0xFF8D9AAE)],
        ).createShader(Rect.fromCircle(center: o, radius: r * 0.62)),
    );
    final spoke = Paint()
      ..color = const Color(0xFF55657C)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * r * 0.16,
          o + Offset(math.cos(a), math.sin(a)) * r * 0.56, spoke);
    }
    c.drawCircle(o, r * 0.12, Paint()..color = const Color(0xFF3B4A60));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Cabin seat map (top-down) ────────────────────────────────────────────────

/// Top-down seat map for a class, highlighting the seats a seating option
/// uses. Rows are true to each body: sedan 2+3, SUV 2+3 (wider), van 2+2+3.
class CabinSchematic extends StatelessWidget {
  const CabinSchematic({
    super.key,
    required this.vehicleClass,
    required this.option,
  });
  final VehicleClass vehicleClass;
  final SeatingOption option;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _CabinPainter(vehicleClass, option),
        child: const SizedBox.expand(),
      );
}

class _CabinPainter extends CustomPainter {
  _CabinPainter(this.vc, this.option);
  final VehicleClass vc;
  final SeatingOption option;

  List<int> get _rows => switch (vc) {
        VehicleClass.businessVan => const [2, 2, 3],
        _ => const [2, 3],
      };

  @override
  void paint(Canvas canvas, Size size) {
    final rows = _rows;
    final isVan = vc == VehicleClass.businessVan;
    final isSuv = vc == VehicleClass.businessSuv;
    // Car body: horizontal, front to the right.
    final bodyLen = size.width * 0.86;
    final bodyW = math.min(size.height * 0.62, bodyLen * (isVan ? 0.44 : 0.4));
    final body = Rect.fromCenter(
        center: size.center(Offset.zero), width: bodyLen, height: bodyW);

    // Shadow + body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          body.shift(const Offset(0, 10)), Radius.circular(bodyW * 0.32)),
      Paint()
        ..color = _ink.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    final bodyR = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(bodyW * (isVan ? 0.16 : 0.24)),
      bottomLeft: Radius.circular(bodyW * (isVan ? 0.16 : 0.24)),
      topRight: Radius.circular(bodyW * (isVan ? 0.30 : 0.42)),
      bottomRight: Radius.circular(bodyW * (isVan ? 0.30 : 0.42)),
    );
    canvas.drawRRect(bodyR, Paint()..color = Colors.white);
    canvas.drawRRect(
      bodyR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _seatLine,
    );

    // Cabin area between hood and trunk
    final hood = body.width * (isVan ? 0.14 : 0.22);
    final trunk = body.width * (isVan ? 0.06 : (isSuv ? 0.10 : 0.16));
    final cabin = Rect.fromLTRB(body.left + trunk, body.top + bodyW * 0.1,
        body.right - hood, body.bottom - bodyW * 0.1);
    // Windshield hint
    final ws = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _seatLine;
    canvas.drawLine(Offset(cabin.right + 4, cabin.top + 6),
        Offset(cabin.right + 4, cabin.bottom - 6), ws);

    // Seat assignment: rear rows first (outer seats before the middle one),
    // front passenger last; the driver's seat is never offered.
    final order = <(int, int)>[
      for (var r = rows.length - 1; r >= 0; r--)
        ...(r == 0
            ? [(0, 1)]
            : rows[r] == 3
                ? [(r, 0), (r, 2), (r, 1)]
                : [(r, 0), (r, 1)]),
    ];
    final occupied = order.take(option.passengers).toSet();
    // The child seat goes on an outer rear seat.
    final childSeat = option.childSeat ? order.first : null;

    final rowGap = cabin.width / rows.length;
    for (var r = 0; r < rows.length; r++) {
      final seats = rows[r];
      // Front row on the right.
      final cx = cabin.right - rowGap * (r + 0.5);
      final seatH = cabin.height / 3.2;
      final seatW = math.min(rowGap * 0.62, seatH * 1.05);
      for (var i = 0; i < seats; i++) {
        final cy = seats == 2
            ? cabin.top + cabin.height * (i == 0 ? 0.27 : 0.73)
            : cabin.top + cabin.height * (0.18 + i * 0.32);
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: seatW, height: seatH);
        final isDriver = r == 0 && i == 0;
        final isChild = childSeat == (r, i);
        final isOn = occupied.contains((r, i)) || isChild;
        _seat(canvas, rect, isDriver: isDriver, on: isOn, child: isChild);
      }
    }
  }

  void _seat(Canvas c, Rect r,
      {required bool isDriver, required bool on, required bool child}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.22));
    final fill = isDriver
        ? const Color(0xFFCFD8E6)
        : on
            ? LD.sph
            : _seatFree;
    if (on && !isDriver) {
      c.drawRRect(
        rr.shift(const Offset(0, 3)),
        Paint()
          ..color = LD.sph.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    c.drawRRect(rr, Paint()..color = fill);
    // Backrest (towards the rear = left)
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left, r.top + 2, r.width * 0.26, r.height - 4),
      Radius.circular(r.width * 0.12),
    );
    c.drawRRect(
        back,
        Paint()
          ..color = isDriver
              ? const Color(0xFFB7C3D5)
              : on
                  ? const Color(0xFF123C6B)
                  : _seatLine.withValues(alpha: 0.7));
    if (isDriver) {
      // Steering wheel
      c.drawCircle(
        Offset(r.right + r.width * 0.18, r.center.dy),
        r.height * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF8C9BB2),
      );
    }
    if (child) {
      // Child seat: a smaller shell inside the seat.
      final inner = Rect.fromCenter(
          center: r.center.translate(r.width * 0.06, 0),
          width: r.width * 0.5,
          height: r.height * 0.62);
      c.drawRRect(
          RRect.fromRectAndRadius(inner, Radius.circular(inner.width * 0.4)),
          Paint()..color = Colors.white);
      c.drawCircle(inner.center, inner.width * 0.16, Paint()..color = LD.sph);
    }
  }

  @override
  bool shouldRepaint(covariant _CabinPainter old) =>
      old.vc != vc ||
      old.option.passengers != option.passengers ||
      old.option.childSeat != option.childSeat;
}

// ── Trunk (rear view, open) ──────────────────────────────────────────────────

class TrunkSchematic extends StatelessWidget {
  const TrunkSchematic({
    super.key,
    required this.vehicleClass,
    required this.option,
  });
  final VehicleClass vehicleClass;
  final LuggageOption option;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _TrunkPainter(vehicleClass, option),
        child: const SizedBox.expand(),
      );
}

class _TrunkPainter extends CustomPainter {
  _TrunkPainter(this.vc, this.option);
  final VehicleClass vc;
  final LuggageOption option;

  @override
  void paint(Canvas canvas, Size size) {
    final isVan = vc == VehicleClass.businessVan;
    final isSuv = vc == VehicleClass.businessSuv;
    final w = size.width * (isVan ? 0.66 : 0.72);
    final h = math.min(
        size.height * 0.8,
        w *
            (isVan
                ? 0.86
                : isSuv
                    ? 0.7
                    : 0.5));
    final frame = Rect.fromCenter(
        center: size.center(Offset.zero).translate(0, h * 0.04),
        width: w,
        height: h);

    // Body around the opening
    final outer = RRect.fromRectAndCorners(
      frame.inflate(w * 0.06),
      topLeft: Radius.circular(w * 0.12),
      topRight: Radius.circular(w * 0.12),
      bottomLeft: Radius.circular(w * 0.05),
      bottomRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      outer.shift(const Offset(0, 12)),
      Paint()
        ..color = _ink.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B4466), _ink],
        ).createShader(outer.outerRect),
    );
    // Opening
    final opening = RRect.fromRectAndCorners(
      frame,
      topLeft: Radius.circular(w * 0.08),
      topRight: Radius.circular(w * 0.08),
      bottomLeft: Radius.circular(w * 0.02),
      bottomRight: Radius.circular(w * 0.02),
    );
    canvas.drawRRect(
      opening,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1424), Color(0xFF1A2A40)],
        ).createShader(frame),
    );
    // Interior light strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(frame.center.dx, frame.top + h * 0.05),
            width: w * 0.5,
            height: 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE9F0FA).withValues(alpha: 0.8),
    );

    _drawBags(canvas, frame.deflate(w * 0.05));
  }

  void _drawBags(Canvas c, Rect area) {
    final n = option.count;
    final (cols, rows) = switch (n) {
      1 => (1, 1),
      2 => (2, 1),
      3 => (3, 1),
      4 => (2, 2),
      5 => (3, 2),
      6 => (3, 2),
      _ => (4, 2),
    };
    // Relative footprint per size class.
    final aspect = switch (option.size) {
      LuggageSize.cabin => 0.62,
      LuggageSize.checked => 0.72,
      LuggageSize.oversize => 0.9,
    };
    final cellW = area.width / cols;
    final cellH = area.height * 0.92 / rows;
    final bagH = math.min(cellH * 0.9, cellW * 0.92 / aspect);
    final bagW = bagH * aspect;
    var drawn = 0;
    for (var r = rows - 1; r >= 0 && drawn < n; r--) {
      final inRow = (r == rows - 1) ? math.min(cols, n - drawn) : n - drawn;
      final rowW = inRow * cellW;
      final startX = area.center.dx - rowW / 2;
      for (var i = 0; i < inRow && drawn < n; i++) {
        final cx = startX + cellW * (i + 0.5);
        final bottom = area.bottom - (rows - 1 - r) * cellH;
        _bag(c, Rect.fromLTWH(cx - bagW / 2, bottom - bagH, bagW, bagH));
        drawn++;
      }
    }
  }

  void _bag(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.12));
    c.drawRRect(
      rr.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFB7C2D2)],
        ).createShader(r),
    );
    final rib = Paint()
      ..color = const Color(0xFF8E9BB0).withValues(alpha: 0.7)
      ..strokeWidth = math.max(1, r.width * 0.025);
    for (final f in [0.3, 0.5, 0.7]) {
      final x = r.left + r.width * f;
      c.drawLine(Offset(x, r.top + r.height * 0.08),
          Offset(x, r.bottom - r.height * 0.08), rib);
    }
    // Handle
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(r.center.dx, r.top - r.height * 0.03),
            width: r.width * 0.36,
            height: r.height * 0.06),
        Radius.circular(r.height * 0.03),
      ),
      Paint()..color = const Color(0xFF9AA7BA),
    );
  }

  @override
  bool shouldRepaint(covariant _TrunkPainter old) =>
      old.vc != vc ||
      old.option.count != option.count ||
      old.option.size != option.size;
}

// ── Small glyphs for the option selectors ────────────────────────────────────

class LuggageGlyphs extends StatelessWidget {
  const LuggageGlyphs({super.key, required this.option, required this.color});
  final LuggageOption option;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final h = switch (option.size) {
      LuggageSize.cabin => 18.0,
      LuggageSize.checked => 24.0,
      LuggageSize.oversize => 30.0,
    };
    final shown = math.min(option.count, 4);
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < shown; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CustomPaint(
                size: Size(h * 0.66, h),
                painter: _BagGlyphPainter(color),
              ),
            ),
          if (option.count > shown)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text('+${option.count - shown}',
                  style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
        ],
      ),
    );
  }
}

class _BagGlyphPainter extends CustomPainter {
  _BagGlyphPainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final body = Rect.fromLTWH(0, s.height * 0.14, s.width, s.height * 0.86);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    c.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(s.width * 0.16)), p);
    c.drawLine(Offset(s.width * 0.5, body.top + 3),
        Offset(s.width * 0.5, body.bottom - 3), p..strokeWidth = 1);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * 0.3, 0, s.width * 0.4, s.height * 0.16),
          const Radius.circular(2)),
      p..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BagGlyphPainter old) => old.color != color;
}

class SeatGlyphs extends StatelessWidget {
  const SeatGlyphs({super.key, required this.option, required this.color});
  final SeatingOption option;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(option.passengers, 5);
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < shown; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(
                option.childSeat && i == shown - 1
                    ? Icons.child_care_rounded
                    : Icons.person_rounded,
                size: 20,
                color: color,
              ),
            ),
          if (option.passengers > shown)
            Text('+${option.passengers - shown}',
                style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
        ],
      ),
    );
  }
}
