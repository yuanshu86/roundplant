import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 个人中心菜单的手绘风线稿小图标（小闹钟 / 罗盘 / 画笔 / 更新 / 信息）。
class HandyIcons {
  static Widget alarm({double size = 22, Color color = AppColors.primary}) =>
      _Handy(_AlarmPainter(color), size);
  static Widget compass({double size = 22, Color color = AppColors.primary}) =>
      _Handy(_CompassPainter(color), size);
  static Widget brush({double size = 22, Color color = AppColors.primary}) =>
      _Handy(_BrushPainter(color), size);
  static Widget update({double size = 22, Color color = AppColors.primary}) =>
      _Handy(_UpdatePainter(color), size);
  static Widget info({double size = 22, Color color = AppColors.primary}) =>
      _Handy(_InfoPainter(color), size);
}

class _Handy extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  const _Handy(this.painter, this.size);

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: painter, size: Size.square(size));
}

abstract class _LinePainter extends CustomPainter {
  final Color color;
  final Paint _pen;
  _LinePainter(this.color)
      : _pen = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

  Paint get pen => _pen;

  @override
  bool shouldRepaint(covariant CustomPainter? old) => false;
}

class _AlarmPainter extends _LinePainter {
  _AlarmPainter(super.color);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2 + 1);
    // 表盘
    canvas.drawCircle(c, s.width * 0.32, pen);
    // 顶铃
    canvas.drawLine(Offset(c.dx - s.width * 0.22, c.dy - s.height * 0.26),
        Offset(c.dx, c.dy - s.height * 0.40), pen);
    canvas.drawLine(Offset(c.dx + s.width * 0.22, c.dy - s.height * 0.26),
        Offset(c.dx, c.dy - s.height * 0.40), pen);
    // 双腿
    canvas.drawLine(Offset(c.dx - s.width * 0.18, c.dy + s.height * 0.30),
        Offset(c.dx - s.width * 0.26, c.dy + s.height * 0.42), pen);
    canvas.drawLine(Offset(c.dx + s.width * 0.18, c.dy + s.height * 0.30),
        Offset(c.dx + s.width * 0.26, c.dy + s.height * 0.42), pen);
    // 指针
    canvas.drawLine(c, Offset(c.dx, c.dy - s.height * 0.20), pen);
    canvas.drawLine(
        c, Offset(c.dx + s.width * 0.16, c.dy + s.height * 0.04), pen);
  }
}

class _CompassPainter extends _LinePainter {
  _CompassPainter(super.color);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    canvas.drawCircle(c, s.width * 0.40, pen);
    // 指针（南北）
    final path = Path();
    path.moveTo(c.dx, c.dy - s.height * 0.30);
    path.lineTo(c.dx + s.width * 0.10, c.dy);
    path.lineTo(c.dx, c.dy + s.height * 0.30);
    path.lineTo(c.dx - s.width * 0.10, c.dy);
    path.close();
    canvas.drawPath(path, pen);
    // 中心
    canvas.drawCircle(c, 1.5, Paint()..color = color);
  }
}

class _BrushPainter extends _LinePainter {
  _BrushPainter(super.color);
  @override
  void paint(Canvas canvas, Size s) {
    // 笔杆（斜）
    canvas.drawLine(Offset(s.width * 0.72, s.height * 0.10),
        Offset(s.width * 0.40, s.height * 0.55), pen);
    // 笔尖
    canvas.drawLine(Offset(s.width * 0.40, s.height * 0.55),
        Offset(s.width * 0.26, s.height * 0.92), pen);
    canvas.drawLine(Offset(s.width * 0.40, s.height * 0.55),
        Offset(s.width * 0.52, s.height * 0.66), pen);
    // 笔尾小头
    canvas.drawCircle(Offset(s.width * 0.75, s.height * 0.085), 3, pen);
  }
}

class _UpdatePainter extends _LinePainter {
  _UpdatePainter(super.color);
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width * 0.34;
    final c = Offset(s.width / 2, s.height / 2);
    // 缺口环
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0.5, 4.6, false, pen);
    // 箭头（右上）
    final ax = c.dx + r * 0.88;
    final ay = c.dy - r * 0.46;
    canvas.drawLine(Offset(ax - 7, ay - 1), Offset(ax + 2, ay - 2), pen);
    canvas.drawLine(Offset(ax + 2, ay - 2), Offset(ax - 3, ay + 7), pen);
  }
}

class _InfoPainter extends _LinePainter {
  _InfoPainter(super.color);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    canvas.drawCircle(c, s.width * 0.36, pen);
    // 字母 i 的竖线 + 点
    canvas.drawLine(Offset(c.dx, c.dy - s.height * 0.12),
        Offset(c.dx, c.dy + s.height * 0.16), pen);
    canvas.drawCircle(
        Offset(c.dx, c.dy - s.height * 0.20), 1.6, Paint()..color = color);
  }
}
