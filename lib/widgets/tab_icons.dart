import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 底部导航立体徽章图标（田园可爱风 · 定稿 2026-08-13）
///
/// 立体公式 = ①主体层（深色底偏移 +2 模拟厚度，亮面上盖）
///          + ②左上高光椭圆（白 α30%）
///          + ③底部投影椭圆（黑 α10%）
///          + ④图标本体（米白 #F4E9C9，2px 圆润描边）
///
/// - 选中态：草绿系（#6FA45B 面 / #3E6B2F 边）
/// - 未选中：降饱和灰绿（浅 #C9D6C0 / 深 #2E4A36）
/// - FAB 识别：陶土橙系，传入白色时只画白色相机（容器自带橙渐变）
class TabIcons {
  /// 统一绘制立体徽章底
  static void paintBadge(Canvas canvas, Offset c, double r,
      {required Color face, required Color edge}) {
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(0, r * 0.85), width: r * 1.9, height: r * 0.55),
      Paint()..color = const Color(0x18000000),
    );
    canvas.drawCircle(c + Offset(0, r * 0.12), r, Paint()..color = edge);
    canvas.drawCircle(c, r, Paint()..color = face);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(-r * 0.38, -r * 0.42),
          width: r * 1.15,
          height: r * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.restore();
  }

  /// 图标内容画笔（米白圆润描边）
  static Paint _ink(Color? override) {
    return Paint()
      ..color = override ?? const Color(0xFFF4E9C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  static Paint _inkFill(Color? override) {
    return Paint()
      ..color = override ?? const Color(0xFFF4E9C9)
      ..style = PaintingStyle.fill;
  }

  /// 选中/未选中徽章配色
  static Color _face(Color? override, bool active) {
    if (override != null) return override;
    if (active) return AppColors.primary;
    return AppColors.isDark ? const Color(0xFF2E4A36) : const Color(0xFFC9D6C0);
  }

  static Color _edge(Color? override, bool active) {
    if (override != null) return AppColors.primaryDark;
    if (active) return AppColors.primaryDark;
    return AppColors.isDark ? const Color(0xFF24402E) : const Color(0xFFA8B89C);
  }

  static Widget home({required bool active, double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HomeIconPainter(
        face: _face(color, active),
        edge: _edge(color, active),
      ),
    );
  }

  static Widget tasks({required bool active, double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TasksIconPainter(
        face: _face(color, active),
        edge: _edge(color, active),
      ),
    );
  }

  static Widget nearby({required bool active, double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NearbyIconPainter(
        face: _face(color, active),
        edge: _edge(color, active),
      ),
    );
  }

  static Widget profile(
      {required bool active, double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProfileIconPainter(
        face: _face(color, active),
        edge: _edge(color, active),
      ),
    );
  }

  static Widget messages(
      {required bool active, double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MessagesIconPainter(
        face: _face(color, active),
        edge: _edge(color, active),
      ),
    );
  }

  static Widget diary({double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DiaryIconPainter(
        face: _face(color, true),
        edge: _edge(color, true),
      ),
    );
  }

  /// AI 识别：容器已是陶土橙渐变时传入 Colors.white，只画白色相机
  static Widget scan({double size = 27, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ScanIconPainter(
        face: color == Colors.white ? null : _face(color, true),
        edge: color == Colors.white ? null : _edge(color, true),
        plain: color == Colors.white,
      ),
    );
  }

  static Widget vineIndicator({double width = 28}) {
    return CustomPaint(
      size: Size(width, 4),
      painter: _VinePainter(),
    );
  }
}

class _HomeIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _HomeIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 屋顶
    final roof = Path()
      ..moveTo(c.dx - r * 0.55, c.dy - r * 0.15)
      ..lineTo(c.dx, c.dy - r * 0.62)
      ..lineTo(c.dx + r * 0.55, c.dy - r * 0.15);
    canvas.drawPath(roof, p);
    // 房体
    final body = Path()
      ..moveTo(c.dx - r * 0.45, c.dy - r * 0.15)
      ..lineTo(c.dx - r * 0.45, c.dy + r * 0.5)
      ..lineTo(c.dx + r * 0.45, c.dy + r * 0.5)
      ..lineTo(c.dx + r * 0.45, c.dy - r * 0.15);
    canvas.drawPath(body, p);
    // 门口小叶子
    final leaf = Path()
      ..moveTo(c.dx, c.dy + r * 0.5)
      ..quadraticBezierTo(
          c.dx - r * 0.18, c.dy + r * 0.22, c.dx - r * 0.05, c.dy + r * 0.02)
      ..quadraticBezierTo(
          c.dx + r * 0.18, c.dy + r * 0.22, c.dx, c.dy + r * 0.5);
    canvas.drawPath(leaf, TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _TasksIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _TasksIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 壶体
    final pot = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - r * 0.42, c.dy - r * 0.35, r * 0.78, r * 0.85),
      Radius.circular(r * 0.18),
    );
    canvas.drawRRect(pot, p);
    // 壶嘴
    canvas.drawLine(
        c + Offset(-r * 0.42, -r * 0.08), c + Offset(-r * 0.6, -r * 0.3), p);
    // 把手
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(-r * 0.05, -r * 0.35), radius: r * 0.3),
      -0.2,
      2.6,
      false,
      p,
    );
    // 溅起小水滴
    canvas.drawCircle(c + Offset(r * 0.1, -r * 0.52), r * 0.06,
        TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _MessagesIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _MessagesIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 气泡主体
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - r * 0.55, c.dy - r * 0.42, r * 0.95, r * 0.72),
      Radius.circular(r * 0.28),
    );
    canvas.drawRRect(bubble, p);
    // 尾巴
    final tail = Path()
      ..moveTo(c.dx + r * 0.38, c.dy + r * 0.18)
      ..lineTo(c.dx + r * 0.6, c.dy + r * 0.42)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.3);
    canvas.drawPath(tail, p);
    // 点
    canvas.drawCircle(
        c + Offset(-r * 0.18, -r * 0.06), r * 0.07, TabIcons._inkFill(null));
    canvas.drawCircle(
        c + Offset(r * 0.12, -r * 0.06), r * 0.07, TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _ProfileIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _ProfileIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 盆沿
    canvas.drawLine(c + Offset(-r * 0.52, -r * 0.05), c + Offset(r * 0.52, -r * 0.05), p);
    // 盆体
    final pot = Path()
      ..moveTo(c.dx - r * 0.42, c.dy - r * 0.05)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.05)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.55)
      ..lineTo(c.dx - r * 0.28, c.dy + r * 0.55);
    canvas.drawPath(pot, p);
    // 小芽
    final stem = Path()
      ..moveTo(c.dx, c.dy - r * 0.05)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.3, c.dx, c.dy - r * 0.42);
    canvas.drawPath(stem, p);
    final l1 = Path()
      ..moveTo(c.dx, c.dy - r * 0.28)
      ..quadraticBezierTo(
          c.dx - r * 0.22, c.dy - r * 0.32, c.dx - r * 0.28, c.dy - r * 0.5)
      ..quadraticBezierTo(
          c.dx - r * 0.08, c.dy - r * 0.48, c.dx, c.dy - r * 0.28);
    final l2 = Path()
      ..moveTo(c.dx, c.dy - r * 0.34)
      ..quadraticBezierTo(
          c.dx + r * 0.2, c.dy - r * 0.4, c.dx + r * 0.28, c.dy - r * 0.58)
      ..quadraticBezierTo(
          c.dx + r * 0.06, c.dy - r * 0.56, c.dx, c.dy - r * 0.34);
    canvas.drawPath(l1, TabIcons._inkFill(null));
    canvas.drawPath(l2, TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _NearbyIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _NearbyIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 罗盘外圈
    canvas.drawCircle(c, r * 0.42, p);
    // 指针
    final pin = Path()
      ..moveTo(c.dx, c.dy - r * 0.4)
      ..lineTo(c.dx + r * 0.14, c.dy)
      ..lineTo(c.dx, c.dy + r * 0.4)
      ..lineTo(c.dx - r * 0.14, c.dy);
    canvas.drawPath(pin, TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _DiaryIconPainter extends CustomPainter {
  final Color face;
  final Color edge;
  _DiaryIconPainter({required this.face, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    TabIcons.paintBadge(canvas, c, r, face: face, edge: edge);
    final p = TabIcons._ink(null);
    // 左页
    final left = Path()
      ..moveTo(c.dx - r * 0.45, c.dy + r * 0.45)
      ..lineTo(c.dx - r * 0.45, c.dy - r * 0.4)
      ..quadraticBezierTo(
          c.dx - r * 0.25, c.dy - r * 0.52, c.dx, c.dy - r * 0.42)
      ..lineTo(c.dx, c.dy + r * 0.42);
    canvas.drawPath(left, p);
    // 右页
    final right = Path()
      ..moveTo(c.dx + r * 0.45, c.dy + r * 0.45)
      ..lineTo(c.dx + r * 0.45, c.dy - r * 0.4)
      ..quadraticBezierTo(
          c.dx + r * 0.25, c.dy - r * 0.52, c.dx, c.dy - r * 0.42)
      ..lineTo(c.dx, c.dy + r * 0.42);
    canvas.drawPath(right, p);
    // 底部书脊
    canvas.drawLine(c + Offset(-r * 0.45, c.dy + r * 0.45),
        c + Offset(r * 0.45, c.dy + r * 0.45), p);
    // 小芽
    canvas.drawCircle(c + Offset(-r * 0.15, c.dy + r * 0.05), r * 0.06,
        TabIcons._inkFill(null));
    canvas.drawCircle(c + Offset(r * 0.15, c.dy + r * 0.05), r * 0.06,
        TabIcons._inkFill(null));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// FAB 识别图标：陶土橙徽章 + 白色相机（plain 时只画白色相机）
class _ScanIconPainter extends CustomPainter {
  final Color? face;
  final Color? edge;
  final bool plain;
  _ScanIconPainter({this.face, this.edge, this.plain = false});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.60;
    if (!plain) {
      TabIcons.paintBadge(canvas, c, r,
          face: face ?? AppColors.accent, edge: edge ?? AppColors.accentDark);
    }
    final ink = plain ? const Color(0xFFFFFFFF) : const Color(0xFFF4E9C9);
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // 相机机身
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - r * 0.42, c.dy - r * 0.22, r * 0.84, r * 0.6),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(body, p);
    // 取景凸起
    canvas.drawLine(
        c + Offset(-r * 0.22, c.dy - r * 0.22),
        c + Offset(-r * 0.22, c.dy - r * 0.38),
        p);
    canvas.drawLine(
        c + Offset(-r * 0.22, c.dy - r * 0.38),
        c + Offset(r * 0.02, c.dy - r * 0.38),
        p);
    // 镜头
    canvas.drawCircle(c + Offset(0, r * 0.04), r * 0.16, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _VinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    // 藤蔓
    final vine = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5,
          size.height / 2)
      ..quadraticBezierTo(
          size.width * 0.75, size.height, size.width, size.height / 2);
    canvas.drawPath(vine, paint);
    // 叶节点
    final leafP = Paint()
      ..color = AppColors.leafLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.45), 1.6, leafP);
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.55), 1.6, leafP);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
