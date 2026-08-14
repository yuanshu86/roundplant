import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 田园背景层（A配色+B玻璃质感的底色）：奶油光斑 + 植物剪影
///
/// 用法：包在任何页面内容最外层（或作为 Stack 底层层），
/// 半透玻璃卡叠在上面即可透出「晨雾花园」氛围。
class GardenBackground extends StatelessWidget {
  final Widget child;
  const GardenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _GardenPainter()),
        ),
        child,
      ],
    );
  }
}

class _GardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 三处柔和光斑：右上草绿 / 右下柠檬 / 左下花瓣粉
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.84, h * 0.14), width: w * 0.9, height: h * 0.42),
      Paint()..color = AppColors.glowGreen,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.9, h * 0.62), width: w * 1.0, height: h * 0.5),
      Paint()..color = AppColors.glowSun,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.06, h * 0.8), width: w * 0.85, height: h * 0.45),
      Paint()..color = AppColors.glowPetal,
    );
    // 植物剪影
    final leafPaint = Paint()..color = AppColors.silhouetteLeaf;
    final potPaint = Paint()..color = AppColors.silhouettePot;
    _leaf(canvas, Offset(w * 0.30, h * 0.20), w * 0.16, -0.5, leafPaint);
    _pot(canvas, Offset(w * 0.88, h * 0.92), w * 0.18, potPaint);
    _leaf(canvas, Offset(w * 0.06, h * 0.42), w * 0.12, 0.45, leafPaint);
  }

  void _leaf(Canvas canvas, Offset c, double s, double rot, Paint p) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final path = Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * 1.1, 0, 0, s)
      ..quadraticBezierTo(-s * 1.1, 0, 0, -s);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  void _pot(Canvas canvas, Offset c, double s, Paint p) {
    final pot = Path()
      ..moveTo(-s, 0)
      ..lineTo(s, 0)
      ..lineTo(s * 0.7, s * 1.25)
      ..lineTo(-s * 0.7, s * 1.25);
    canvas.drawPath(pot, p);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -s * 0.4), width: s * 1.1, height: s * 0.9),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
