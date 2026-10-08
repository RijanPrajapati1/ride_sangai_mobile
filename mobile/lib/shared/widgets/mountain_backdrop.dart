import 'package:flutter/material.dart';

/// Layered mountain ridges, the app's signature motif. Drawn in translucent
/// [color] over whatever sits behind it (usually a brand gradient), so it
/// works on any background. Fills its parent; pair with [Positioned.fill].
class MountainBackdrop extends StatelessWidget {
  final Color color;

  /// How far up the ridges reach, as a fraction of the height (0–1).
  final double height;

  /// Draws a soft sun above the far ridge.
  final bool showSun;

  const MountainBackdrop({
    super.key,
    this.color = Colors.white,
    this.height = 0.6,
    this.showSun = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MountainPainter(color: color, height: height, showSun: showSun),
        size: Size.infinite,
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  final Color color;
  final double height;
  final bool showSun;

  const _MountainPainter({required this.color, required this.height, required this.showSun});

  // Ridge outlines as (x, y) fractions of the drawing area, far to near.
  // y = 0 is the top of the ridge band, 1 its bottom.
  static const _far = [
    Offset(0, .42), Offset(.1, .26), Offset(.17, .34), Offset(.3, .02), Offset(.4, .22),
    Offset(.47, .16), Offset(.58, .36), Offset(.72, 0), Offset(.84, .24), Offset(.92, .18), Offset(1, .3),
  ];
  static const _mid = [
    Offset(0, .6), Offset(.12, .42), Offset(.26, .56), Offset(.42, .36), Offset(.56, .54),
    Offset(.7, .44), Offset(.86, .58), Offset(1, .46),
  ];
  static const _near = [
    Offset(0, .8), Offset(.18, .66), Offset(.36, .78), Offset(.52, .64), Offset(.7, .78),
    Offset(.86, .68), Offset(1, .76),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * (1 - height);
    final band = size.height - top;

    if (showSun) {
      canvas.drawCircle(
        Offset(size.width * .78, top - band * .08),
        band * .14,
        Paint()..color = color.withValues(alpha: .35),
      );
    }

    void ridge(List<Offset> points, double alpha) {
      final path = Path()..moveTo(0, size.height);
      for (final p in points) {
        path.lineTo(p.dx * size.width, top + p.dy * band);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
    }

    ridge(_far, .16);
    ridge(_mid, .22);
    ridge(_near, .3);
  }

  @override
  bool shouldRepaint(_MountainPainter old) =>
      old.color != color || old.height != height || old.showSun != showSun;
}
