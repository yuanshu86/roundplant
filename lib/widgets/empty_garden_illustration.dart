import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 生长日记空状态插画：花盆里刚冒出的小芽 + 一支羽毛笔。
class GardenEmptyIllustration extends StatelessWidget {
  final double size;
  const GardenEmptyIllustration({super.key, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: CustomPaint(painter: _GardenPainter()),
    );
  }
}

class _GardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 地面椭圆阴影
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.92),
        width: w * 0.5,
        height: h * 0.06,
      ),
      Paint()..color = AppColors.primary.withValues(alpha: 0.08),
    );

    // 花盆
    final pot = Paint()..color = const Color(0xFFD9A066);
    final potDark = Paint()..color = const Color(0xFFC98A4B);
    final potPath = Path();
    potPath.moveTo(w * 0.24, h * 0.58);
    potPath.lineTo(w * 0.60, h * 0.58);
    potPath.lineTo(w * 0.54, h * 0.90);
    potPath.lineTo(w * 0.30, h * 0.90);
    potPath.close();
    canvas.drawPath(potPath, pot);
    // 盆口
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.21, h * 0.52, w * 0.63, h * 0.60),
        const Radius.circular(6),
      ),
      potDark,
    );
    // 盆身条纹
    canvas.drawLine(Offset(w * 0.30, h * 0.70), Offset(w * 0.54, h * 0.70),
        Paint()..color = const Color(0xFFB57A3C)..strokeWidth = 3);

    // 泥土
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.56), width: w * 0.32, height: h * 0.06),
      Paint()..color = const Color(0xFF6B4F3A),
    );

    // 茎
    final stem = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.42, h * 0.56), Offset(w * 0.42, h * 0.34), stem);

    // 两片小芽
    final leaf = Paint()..color = AppColors.secondary;
    _petal(canvas, Offset(w * 0.42, h * 0.36), -0.9, -1.0, w * 0.12, leaf);
    _petal(canvas, Offset(w * 0.42, h * 0.40), 0.9, -0.7, w * 0.10, leaf);

    // 羽毛笔（斜放在右边）
    final pen = Paint()..color = AppColors.accent..strokeWidth = 4..strokeCap = StrokeCap.round;
    final p0 = Offset(w * 0.74, h * 0.86);
    final p1 = Offset(w * 0.60, h * 0.44);
    canvas.drawLine(p0, p1, pen);
    // 笔尖
    canvas.drawLine(p1, Offset(w * 0.56, h * 0.38),
        Paint()..color = AppColors.textHint..strokeWidth = 3..strokeCap = StrokeCap.round);
    // 羽毛
    final feather = Paint()..color = AppColors.accent.withValues(alpha: 0.85);
    _feather(canvas, p0, p1, w * 0.12, feather);
  }

  void _petal(Canvas canvas, Offset base, double dir, double rise, double len, Paint paint) {
    final tip = Offset(base.dx + dir * len, base.dy + rise * len);
    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      base.dx + dir * len * 0.7, base.dy + rise * len * 0.2, tip.dx, tip.dy);
    path.quadraticBezierTo(
      base.dx + dir * len * 0.45, base.dy + rise * len * 0.7, base.dx, base.dy);
    canvas.drawPath(path, paint);
  }

  void _feather(Canvas canvas, Offset base, Offset tip, double halfW, Paint paint) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final len = (dx * dx + dy * dy);
    final nx = -dy / (len) * halfW;
    final ny = dx / (len) * halfW;
    final path = Path();
    path.moveTo(base.dx + nx, base.dy + ny);
    path.quadraticBezierTo((base.dx + tip.dx) / 2 + nx, (base.dy + tip.dy) / 2 + ny,
        tip.dx, tip.dy);
    path.quadraticBezierTo((base.dx + tip.dx) / 2 - nx, (base.dy + tip.dy) / 2 - ny,
        base.dx - nx, base.dy - ny);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 漂浮的种子形态「写日记」按钮，按压有绿色水波纹扩散反馈。
class SeedFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const SeedFab({super.key, required this.onTap, this.label = '写第一篇日记'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primary.withValues(alpha: 0.35),
        highlightColor: AppColors.primary.withValues(alpha: 0.18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppColors.fabShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTypography.buttonText.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
