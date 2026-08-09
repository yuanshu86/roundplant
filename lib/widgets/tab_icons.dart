import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 底部导航轻拟态图标
/// - 首页：带叶子的小房子
/// - 任务：小水壶
/// - 附近：叶子罗盘针
/// - 我的：花盆轮廓
class TabIcons {
  static Widget home({required bool active, double size = 24, Color? color}) {
    final c = color ?? (active ? AppColors.primary : AppColors.textHint);
    return CustomPaint(
      size: Size(size, size),
      painter: _HomeIconPainter(color: c, active: active),
    );
  }

  static Widget tasks({required bool active, double size = 24, Color? color}) {
    final c = color ?? (active ? AppColors.primary : AppColors.textHint);
    return CustomPaint(
      size: Size(size, size),
      painter: _TasksIconPainter(color: c, active: active),
    );
  }

  static Widget nearby({required bool active, double size = 24, Color? color}) {
    final c = color ?? (active ? AppColors.primary : AppColors.textHint);
    return CustomPaint(
      size: Size(size, size),
      painter: _NearbyIconPainter(color: c, active: active),
    );
  }

  static Widget profile({required bool active, double size = 24, Color? color}) {
    final c = color ?? (active ? AppColors.primary : AppColors.textHint);
    return CustomPaint(
      size: Size(size, size),
      painter: _ProfileIconPainter(color: c, active: active),
    );
  }

  /// 生长日记：书本 + 小叶芽
  static Widget diary({double size = 24, Color? color}) {
    final c = color ?? AppColors.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _DiaryIconPainter(color: c),
    );
  }

  /// AI 识别：扫描框 + 镜头里的小叶子
  static Widget scan({double size = 24, Color? color}) {
    final c = color ?? AppColors.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _ScanIconPainter(color: c),
    );
  }

  /// 选中状态下的藤蔓指示条
  static Widget vineIndicator({double width = 28}) {
    return CustomPaint(
      size: Size(width, 4),
      painter: _VinePainter(),
    );
  }
}

class _HomeIconPainter extends CustomPainter {
  final Color color;
  final bool active;

  _HomeIconPainter({required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.25 : 0.12)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    // 房子主体
    path.moveTo(center.dx - 9, center.dy + 2);
    path.lineTo(center.dx - 9, center.dy + 9);
    path.lineTo(center.dx + 9, center.dy + 9);
    path.lineTo(center.dx + 9, center.dy + 2);
    // 屋顶
    path.moveTo(center.dx - 12, center.dy + 2);
    path.lineTo(center.dx, center.dy - 8);
    path.lineTo(center.dx + 12, center.dy + 2);
    canvas.drawPath(path, paint);

    // 门上小叶子
    final leafPath = Path();
    leafPath.moveTo(center.dx, center.dy + 9);
    leafPath.quadraticBezierTo(center.dx - 3, center.dy + 4,
        center.dx - 1, center.dy + 1);
    leafPath.quadraticBezierTo(center.dx + 3, center.dy + 4,
        center.dx, center.dy + 9);
    canvas.drawPath(leafPath, fillPaint);
    canvas.drawPath(leafPath, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => true;
}

class _TasksIconPainter extends CustomPainter {
  final Color color;
  final bool active;

  _TasksIconPainter({required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.25 : 0.12)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // 壶身
    final body = Path();
    body.moveTo(center.dx - 7, center.dy - 2);
    body.quadraticBezierTo(center.dx - 9, center.dy + 8,
        center.dx, center.dy + 8);
    body.quadraticBezierTo(center.dx + 9, center.dy + 8,
        center.dx + 7, center.dy - 2);
    body.close();
    canvas.drawPath(body, fillPaint);
    canvas.drawPath(body, paint);

    // 壶嘴
    final spout = Path();
    spout.moveTo(center.dx + 6, center.dy);
    spout.quadraticBezierTo(center.dx + 13, center.dy - 1,
        center.dx + 11, center.dy - 6);
    canvas.drawPath(spout, paint);

    // 壶把
    final handle = Path();
    handle.moveTo(center.dx - 7, center.dy);
    handle.quadraticBezierTo(center.dx - 15, center.dy - 2,
        center.dx - 10, center.dy - 6);
    canvas.drawPath(handle, paint);

    // 顶部水滴
    final dropPath = Path();
    dropPath.moveTo(center.dx + 11, center.dy - 9);
    dropPath.quadraticBezierTo(center.dx + 13, center.dy - 13,
        center.dx + 11, center.dy - 14);
    dropPath.quadraticBezierTo(center.dx + 9, center.dy - 13,
        center.dx + 11, center.dy - 9);
    canvas.drawPath(dropPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => true;
}

class _NearbyIconPainter extends CustomPainter {
  final Color color;
  final bool active;

  _NearbyIconPainter({required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.25 : 0.12)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // 外圆
    canvas.drawCircle(center, 10, paint);
    // 内十字
    canvas.drawLine(Offset(center.dx, center.dy - 6),
        Offset(center.dx, center.dy + 6), paint);
    canvas.drawLine(Offset(center.dx - 6, center.dy),
        Offset(center.dx + 6, center.dy), paint);

    // 叶子指针
    final leaf = Path();
    leaf.moveTo(center.dx, center.dy - 2);
    leaf.quadraticBezierTo(center.dx + 6, center.dy - 8,
        center.dx + 4, center.dy - 12);
    leaf.quadraticBezierTo(center.dx, center.dy - 8,
        center.dx, center.dy - 2);
    canvas.drawPath(leaf, fillPaint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => true;
}

class _ProfileIconPainter extends CustomPainter {
  final Color color;
  final bool active;

  _ProfileIconPainter({required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.25 : 0.12)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // 花盆梯形
    final pot = Path();
    pot.moveTo(center.dx - 7, center.dy - 4);
    pot.lineTo(center.dx + 7, center.dy - 4);
    pot.lineTo(center.dx + 5, center.dy + 8);
    pot.lineTo(center.dx - 5, center.dy + 8);
    pot.close();
    canvas.drawPath(pot, fillPaint);
    canvas.drawPath(pot, paint);

    // 盆口
    canvas.drawLine(Offset(center.dx - 8, center.dy - 4),
        Offset(center.dx + 8, center.dy - 4), paint);

    // 小植物
    final plant = Path();
    plant.moveTo(center.dx, center.dy - 4);
    plant.quadraticBezierTo(center.dx - 4, center.dy - 10,
        center.dx - 2, center.dy - 12);
    plant.moveTo(center.dx, center.dy - 4);
    plant.quadraticBezierTo(center.dx + 4, center.dy - 10,
        center.dx + 2, center.dy - 12);
    canvas.drawPath(plant, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => true;
}

class _DiaryIconPainter extends CustomPainter {
  final Color color;

  _DiaryIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // 打开的书本
    final book = Path();
    // 左页
    book.moveTo(center.dx, center.dy - 8);
    book.lineTo(center.dx - 9, center.dy - 5);
    book.lineTo(center.dx - 9, center.dy + 5);
    book.lineTo(center.dx, center.dy + 8);
    // 右页
    book.moveTo(center.dx, center.dy - 8);
    book.lineTo(center.dx + 9, center.dy - 5);
    book.lineTo(center.dx + 9, center.dy + 5);
    book.lineTo(center.dx, center.dy + 8);
    // 书脊
    book.moveTo(center.dx, center.dy - 8);
    book.lineTo(center.dx, center.dy + 8);
    canvas.drawPath(book, paint);

    // 书页上长出的小叶芽
    final leaf = Path();
    leaf.moveTo(center.dx - 2, center.dy + 2);
    leaf.quadraticBezierTo(
        center.dx - 6, center.dy - 2, center.dx - 5, center.dy - 6);
    leaf.quadraticBezierTo(
        center.dx - 2, center.dy - 2, center.dx - 2, center.dy + 2);
    canvas.drawPath(leaf, fillPaint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => false;
}

class _ScanIconPainter extends CustomPainter {
  final Color color;

  _ScanIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // 扫描/相机外框（四个角）
    const corner = 6.0;
    const len = 6.0;
    // 左上
    canvas.drawLine(Offset(center.dx - corner, center.dy - corner - len),
        Offset(center.dx - corner, center.dy - corner), paint);
    canvas.drawLine(Offset(center.dx - corner, center.dy - corner),
        Offset(center.dx - corner - len, center.dy - corner), paint);
    // 右上
    canvas.drawLine(Offset(center.dx + corner, center.dy - corner - len),
        Offset(center.dx + corner, center.dy - corner), paint);
    canvas.drawLine(Offset(center.dx + corner, center.dy - corner),
        Offset(center.dx + corner + len, center.dy - corner), paint);
    // 左下
    canvas.drawLine(Offset(center.dx - corner, center.dy + corner + len),
        Offset(center.dx - corner, center.dy + corner), paint);
    canvas.drawLine(Offset(center.dx - corner, center.dy + corner),
        Offset(center.dx - corner - len, center.dy + corner), paint);
    // 右下
    canvas.drawLine(Offset(center.dx + corner, center.dy + corner + len),
        Offset(center.dx + corner, center.dy + corner), paint);
    canvas.drawLine(Offset(center.dx + corner, center.dy + corner),
        Offset(center.dx + corner + len, center.dy + corner), paint);

    // 中心小叶子（识别植物）
    final leaf = Path();
    leaf.moveTo(center.dx, center.dy + 3);
    leaf.quadraticBezierTo(
        center.dx - 4, center.dy - 1, center.dx - 3, center.dy - 5);
    leaf.quadraticBezierTo(center.dx, center.dy - 1, center.dx, center.dy + 3);
    canvas.drawPath(leaf, fillPaint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => false;
}

class _VinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.primaryGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
        size.width * 0.3, 0, size.width * 0.5, size.height / 2);
    path.quadraticBezierTo(
        size.width * 0.7, size.height, size.width, size.height / 2);
    canvas.drawPath(path, paint);

    // 小叶
    final leafPaint = Paint()
      ..shader = AppColors.primaryGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final leaf = Path();
    leaf.moveTo(size.width * 0.65, size.height * 0.65);
    leaf.quadraticBezierTo(size.width * 0.75, size.height * 0.35,
        size.width * 0.85, size.height * 0.55);
    leaf.quadraticBezierTo(size.width * 0.75, size.height * 0.75,
        size.width * 0.65, size.height * 0.65);
    canvas.drawPath(leaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? old) => false;
}
