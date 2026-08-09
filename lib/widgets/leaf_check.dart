import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 空心圆 → 点击后叶片舒展 + 绿勾动画。用于养护任务的"完成"按钮。
class LeafCheckButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  const LeafCheckButton({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 28,
  });

  @override
  State<LeafCheckButton> createState() => _LeafCheckButtonState();
}

class _LeafCheckButtonState extends State<LeafCheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    if (widget.value) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(covariant LeafCheckButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged?.call(!widget.value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final p = _anim.value;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(Colors.transparent, AppColors.primary, p)!,
              border: Border.all(
                color: Color.lerp(AppColors.border, AppColors.primary, p)!,
                width: 2,
              ),
            ),
            child: p > 0.02
                ? CustomPaint(
                    painter: _LeafCheckPainter(p),
                    size: Size.square(widget.size),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _LeafCheckPainter extends CustomPainter {
  final double progress;
  _LeafCheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final white = Paint()..color = Colors.white;
    final stem = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final len = size.width * 0.26 * progress;
    // 茎
    canvas.drawLine(c, Offset(c.dx, c.dy - size.height * 0.30 * progress), stem);
    // 两片舒展的叶
    _leaf(canvas, c, -0.55, -len, white, size);
    _leaf(canvas, c, 0.55, -len, white, size);

    // 对勾（后半段才出现）
    if (progress > 0.5) {
      final cp = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final path = Path();
      path.moveTo(size.width * 0.30, size.height * 0.55);
      path.quadraticBezierTo(
        size.width * 0.46, size.height * 0.70,
        size.width * 0.64, size.height * 0.40,
      );
      final m = path.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * cp),
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = size.width * 0.09
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _leaf(Canvas canvas, Offset base, double dir, double len, Paint paint, Size size) {
    if (len <= 0) return;
    final tip = Offset(base.dx + dir * len * 0.95, base.dy - len);
    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      base.dx + dir * len * 0.7, base.dy - len * 0.15, tip.dx, tip.dy);
    path.quadraticBezierTo(
      base.dx + dir * len * 0.45, base.dy - len * 0.6, base.dx, base.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafCheckPainter? old) => old?.progress != progress;
}
