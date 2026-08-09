import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 水滴进度环：外环显示 needWater / total，内环流动蓝色水波
class WaterDropRing extends StatefulWidget {
  final int needWater;
  final int total;
  final double size;

  const WaterDropRing({
    super.key,
    required this.needWater,
    required this.total,
    this.size = 120,
  });

  @override
  State<WaterDropRing> createState() => _WaterDropRingState();
}

class _WaterDropRingState extends State<WaterDropRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _WaterRingPainter(
                needWater: widget.needWater,
                total: widget.total,
                wavePhase: _ctrl.value * 2 * pi,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.needWater}',
                style: AppTypography.pageTitle.copyWith(
                  fontSize: 36,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '/${widget.total}',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterRingPainter extends CustomPainter {
  final int needWater;
  final int total;
  final double wavePhase;

  _WaterRingPainter({
    required this.needWater,
    required this.total,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 6;
    final innerRadius = outerRadius - 10;

    // 外环背景
    final bgPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, outerRadius - 4, bgPaint);

    // 外环进度
    final progress = total == 0 ? 0 : needWater / total;
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF0EA5E9)],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius - 4),
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );

    // 内环水波（填充）
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.clipPath(clipPath);

    final wavePaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.25);
    final path = Path();
    path.moveTo(center.dx - innerRadius, center.dy + innerRadius);
    for (double x = -innerRadius; x <= innerRadius; x += 4) {
      final y = sin((x / innerRadius) * 2 * pi + wavePhase) * 8;
      path.lineTo(center.dx + x, center.dy + y + innerRadius * 0.35);
    }
    path.lineTo(center.dx + innerRadius, center.dy - innerRadius);
    path.lineTo(center.dx - innerRadius, center.dy - innerRadius);
    path.close();
    canvas.drawPath(path, wavePaint);

    // 水面高光
    final highlightPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35);
    final path2 = Path();
    path2.moveTo(center.dx - innerRadius, center.dy + innerRadius * 0.6);
    for (double x = -innerRadius; x <= innerRadius; x += 6) {
      final y = sin((x / innerRadius) * 1.5 * pi + wavePhase + 1.5) * 5;
      path2.lineTo(center.dx + x, center.dy + y + innerRadius * 0.15);
    }
    path2.lineTo(center.dx + innerRadius, center.dy - innerRadius);
    path2.lineTo(center.dx - innerRadius, center.dy - innerRadius);
    path2.close();
    canvas.drawPath(path2, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter? old) =>
      old?.needWater != needWater || old?.total != total || old?.wavePhase != wavePhase;
}
