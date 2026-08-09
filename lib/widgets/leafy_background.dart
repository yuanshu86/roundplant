import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 顶部「超大虚化龟背竹叶片」背景暗纹。包裹内容即可获得呼吸感。
class LeafyBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;

  const LeafyBackground({
    super.key,
    required this.child,
    this.gradient = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.16,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: CustomPaint(
                painter: _LeafVeinPainter(),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LeafVeinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void leaf(Offset c, double rx, double ry, double rot) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint,
      );
      // 主叶脉
      canvas.drawLine(
        Offset.zero,
        Offset(0, -ry),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );
      canvas.restore();
    }

    leaf(Offset(size.width * 0.82, size.height * 0.16), 80, 120, -0.5);
    leaf(Offset(size.width * 0.18, size.height * 0.06), 70, 100, 0.42);
    leaf(Offset(size.width * 0.96, size.height * 0.52), 56, 84, 0.18);
    leaf(Offset(size.width * 0.04, size.height * 0.5), 50, 78, -0.3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => false;
}
