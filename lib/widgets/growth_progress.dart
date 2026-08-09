import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 养护任务顶部进度条：随完成度"长出小嫩芽"的动态进度，
/// 取代死板的百分比数字。
class GrowthProgressBar extends StatelessWidget {
  final double progress;
  final int done;
  final int total;
  final String mood;

  const GrowthProgressBar({
    super.key,
    required this.progress,
    required this.done,
    required this.total,
    this.mood = '',
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    const stops = [0.0, 0.25, 0.5, 0.75, 1.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$done / $total',
                style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 18, color: AppColors.primary)),
            const SizedBox(width: 6),
            Text('已完成', style: AppTypography.caption),
            const Spacer(),
            if (mood.isNotEmpty)
              Flexible(
                child: Text(mood,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.secondary),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, c) {
            final w = c.maxWidth;
            const sprout = 16.0;
            return SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 进度条底槽
                  Positioned.fill(
                    top: 2,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.softCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ),
                  // 已填充的绿色生长层
                  Positioned(
                    top: 2,
                    left: 0,
                    child: SizedBox(
                      width: w * p,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // 沿条分布的嫩芽
                  for (final s in stops)
                    Positioned(
                      left: s * (w - sprout),
                      top: 0,
                      child: _Sprout(active: p >= s - 0.001, size: sprout),
                    ),
                  // 领先的"正在生长"芽
                  if (p > 0.01)
                    Positioned(
                      left: (p * w).clamp(0, w - 22) - 4,
                      top: -8,
                      child: _Sprout(active: true, size: 22, leader: true),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 一棵会轻轻摇摆、呼吸的小嫩芽
class _Sprout extends StatefulWidget {
  final bool active;
  final double size;
  final bool leader;

  const _Sprout({required this.active, this.size = 16, this.leader = false});

  @override
  State<_Sprout> createState() => _SproutState();
}

class _SproutState extends State<_Sprout> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.primary
        : AppColors.textHint.withValues(alpha: 0.5);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (c, _) {
        final sway = math.sin(_ctrl.value * math.pi) *
            (widget.leader ? 0.14 : 0.08);
        final breathe = 0.85 + 0.15 * math.sin(_ctrl.value * math.pi);
        return Transform.rotate(
          angle: sway,
          child: Transform.scale(
            scale: breathe,
            child: CustomPaint(
              painter: _SproutPainter(color),
              size: Size.square(widget.size),
            ),
          ),
        );
      },
    );
  }
}

class _SproutPainter extends CustomPainter {
  final Color color;
  _SproutPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.80);
    final stem = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, Offset(c.dx, c.dy - size.height * 0.55), stem);

    final leaf = Paint()..color = color;
    _leaf(canvas, c.dx - size.width * 0.05, c.dy - size.height * 0.30, -0.6, size, leaf);
    _leaf(canvas, c.dx + size.width * 0.05, c.dy - size.height * 0.30, 0.6, size, leaf);
  }

  void _leaf(Canvas canvas, double bx, double by, double dir, Size size, Paint paint) {
    final path = Path();
    final tip = Offset(bx + dir * size.width * 0.28, by - size.height * 0.32);
    path.moveTo(bx, by);
    path.quadraticBezierTo(bx + dir * size.width * 0.22, by - size.height * 0.18, tip.dx, tip.dy);
    path.quadraticBezierTo(bx + dir * size.width * 0.14, by - size.height * 0.24, bx, by);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SproutPainter old) => old.color != color;
}
