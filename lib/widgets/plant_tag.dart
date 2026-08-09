import 'package:flutter/material.dart';
import '../models/plant.dart';

/// 斜吊牌标签：贴在植物图片边角，像小挂牌
class PlantTagWidget extends StatelessWidget {
  final PlantTag tag;
  final Alignment alignment;
  final double rotation;

  const PlantTagWidget({
    super.key,
    required this.tag,
    this.alignment = Alignment.topLeft,
    this.rotation = -0.35,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(tag.color);
    final isLight = ThemeData.estimateBrightnessForColor(color) == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(
          painter: _TagPainter(color: color),
          size: const Size(62, 28),
          child: Container(
            width: 62,
            height: 28,
            padding: const EdgeInsets.only(left: 14, right: 8),
            alignment: Alignment.center,
            child: Text(
              tag.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 吊牌形状绘制：左边圆孔 + 圆角长条 + 细绳
class _TagPainter extends CustomPainter {
  final Color color;

  _TagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 4, size.height - 8),
      const Radius.circular(6),
    );

    // 标签主体
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);

    // 轻阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect, shadowPaint);

    // 重画主体覆盖阴影
    canvas.drawRRect(rect, paint);

    // 圆孔
    final holePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(12, size.height / 2),
      3.5,
      holePaint,
    );

    // 绳子：从圆孔向上弯曲
    final stringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path();
    path.moveTo(12, size.height / 2 - 3);
    path.quadraticBezierTo(16, -2, 24, -6);
    canvas.drawPath(path, stringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _TagPainter && oldDelegate.color != color;
}
