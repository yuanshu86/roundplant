import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 附近花友页顶部的极简弧形雷达扫描动效。
class RadarSweep extends StatefulWidget {
  final double size;
  final Color color;

  const RadarSweep({super.key, this.size = 72, this.color = AppColors.primary});

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (c, _) => CustomPaint(
        painter: _RadarPainter(_ctrl.value * 2 * math.pi, widget.color),
        size: Size.square(widget.size),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  _RadarPainter(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // 同心圆
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.35);
    for (final rr in [r * 0.33, r * 0.66, r]) {
      canvas.drawCircle(c, rr, ring);
    }

    // 扫描扇形渐变
    final grad = Gradient.sweep(
      c,
      [color.withValues(alpha: 0.0), color.withValues(alpha: 0.35)],
      [0.0, 1.0],
      TileMode.clamp,
      angle,
      angle + 0.6,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      angle,
      0.6,
      true,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = grad.createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // 扫描线
    canvas.drawLine(
      c,
      Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle)),
      Paint()..strokeWidth = 1.5..color = color.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.angle != angle;
}
