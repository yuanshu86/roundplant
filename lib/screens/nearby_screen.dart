import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/frosted.dart';
import '../widgets/radar_sweep.dart';
import '../models/plant.dart';

/// Screen 6 - 附近花友
/// showBack: true 时显示返回按钮 (push 路由), false 时作为 Tab 内容
class NearbyScreen extends StatefulWidget {
  final bool showBack;

  const NearbyScreen({super.key, this.showBack = false});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final List<NearbyUser> _users = NearbyUser.sampleUsers;
  NearbyUser? _selectedUser;
  int _range = 2; // 搜索半径（km）

  @override
  Widget build(BuildContext context) {
    // push 模式下没有底部 Tab 栏，卡片应贴底；Tab 模式下需避让悬浮 Tab 栏
    final cardBottom = widget.showBack ? 0.0 : AppSpacing.tabBarHeight;
    return Column(
      children: [
        _buildNavBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMapArea(),
              Positioned(
                left: 0,
                right: 0,
                bottom: cardBottom,
                child: _selectedUser != null
                    ? _buildUserCard(_selectedUser!)
                    : _buildSummaryCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    return FrostedTopBar(
      title: '附近花友',
      leading: widget.showBack
          ? GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
              ),
            )
          : null,
      trailing: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.tune, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.bg,
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: MapTerrainPainter()),
          LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2;
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: DistanceRingPainter(cx, cy),
                  ),
                  // 中心用户
                  Positioned(
                    left: cx - 50,
                    top: cy + 10,
                    child: Column(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12, spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text('你在这里',
                            style: TextStyle(fontFamily: 'NunitoSans', fontSize: 9, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  ..._buildUserMarkers(cx, cy),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserMarkers(double cx, double cy) {
    final positions = [
      Offset(cx - 95, cy - 100),
      Offset(cx + 58, cy + 40),
      Offset(cx - 139, cy + 105),
      Offset(cx + 100, cy - 120),
      Offset(cx - 60, cy + 160),
    ];
    return List.generate(_users.length, (i) {
      final user = _users[i];
      final pos = positions[i];
      final isSelected = _selectedUser?.id == user.id;
      return Positioned(
        left: pos.dx - 22,
        top: pos.dy - 22,
        child: GestureDetector(
          onTap: () => setState(() => _selectedUser = user),
          child: Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Color(user.avatarColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Color(user.avatarColor).withValues(alpha: 0.4), blurRadius: 12)]
                      : null,
                ),
                child: _buildPlantIcon(user.plantIcon),
              ),
              const SizedBox(height: 4),
              Text('${user.distance.round()}m', style: AppTypography.badge),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlantIcon(String icon) {
    IconData data = Icons.eco;
    if (icon == 'flower') data = Icons.local_florist;
    if (icon == 'sprout') data = Icons.grain;
    return Icon(data, color: Colors.white, size: 20);
  }

  /// 底部名片卡：雷达扫描 + 距离切换 + 横向错落瀑布卡
  Widget _buildSummaryCard() {
    final visible = _users.where((u) => u.distance <= _range * 1000).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
        boxShadow: AppColors.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              RadarSweep(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('正在扫描附近同好',
                      style: AppTypography.cardTitle.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('点亮一盏灯，也许就遇见同好', style: AppTypography.caption),
                  ],
                ),
              ),
              _rangeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => _buildFriendCard(visible[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.softCard, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _rangeChip('1km', 1),
          _rangeChip('方圆2km', 2),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, int km) {
    final active = _range == km;
    return GestureDetector(
      onTap: () => setState(() => _range = km),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  /// 横向错落瀑布卡：距离 / 头像 / 名字 / 彩色药丸标签 / 迷你盆栽数
  Widget _buildFriendCard(NearbyUser u, int i) {
    final h = i.isEven ? 190.0 : 158.0;
    final color = Color(u.avatarColor);
    return GestureDetector(
      onTap: () => setState(() => _selectedUser = u),
      child: Container(
        width: 150,
        height: h,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softCard, borderRadius: BorderRadius.circular(10)),
                child: Text('${u.distance.round()}m',
                  style: const TextStyle(
                    fontFamily: 'NunitoSans', fontSize: 11,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.12),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: _buildPlantIcon(u.plantIcon),
              ),
            ),
            Positioned(
              top: 70, left: 0, right: 0,
              child: Text(u.name,
                style: AppTypography.bodySemiBold, textAlign: TextAlign.center),
            ),
            Positioned(
              top: 96, left: 0, right: 0,
              child: Center(child: _tagPill(u.tag)),
            ),
            Positioned(
              bottom: 0, left: 0,
              child: GestureDetector(
                onTap: () => _sayHi(u),
                child: Text('打招呼',
                  style: TextStyle(
                    fontFamily: 'NunitoSans', fontSize: 11,
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Row(
                children: [
                  Icon(Icons.eco, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 2),
                  Text('${u.plants.length}', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 专属标签 → 彩色小药丸（按关键词匹配主题色）
  static const Map<String, List<Color>> _tagColors = {
    '多肉': [Color(0xFFE9D5F5), Color(0xFF7E22CE)],
    '蕨': [Color(0xFFD1FAE5), Color(0xFF065F46)],
    '苔藓': [Color(0xFFCCFBF1), Color(0xFF0F766E)],
    '香草': [Color(0xFFFEF3C7), Color(0xFF92400E)],
    '阳台': [Color(0xFFFCE7F3), Color(0xFF9D174D)],
    '花园': [Color(0xFFFCE7F3), Color(0xFF9D174D)],
  };

  Widget _tagPill(String tag) {
    Color bg = const Color(0xFFDBEAFE);
    Color fg = const Color(0xFF1E40AF);
    for (final e in _tagColors.entries) {
      if (tag.contains(e.key)) {
        bg = e.value[0];
        fg = e.value[1];
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(tag,
        style: TextStyle(
          fontFamily: 'NunitoSans', fontSize: 11,
          fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildUserCard(NearbyUser user) {
    final color = Color(user.avatarColor);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
        boxShadow: AppColors.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // 花友信息行
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.name, style: AppTypography.bodySemiBold.copyWith(fontSize: 17)),
                        const SizedBox(width: 8),
                        Text('${user.distance.round()}m',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _tagPill(user.tag),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _sayHi(user),
                child: Container(
                  width: 64, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.waving_hand, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('打招呼', style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 花友的植物列表
          if (user.plants.isNotEmpty) ...[
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.eco, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('${user.name}养护的 ${user.plants.length} 株植物',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: user.plants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                  _buildFriendPlantCard(user.plants[index], color),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('线下见面请选择公共场所，注意安全',
                style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendPlantCard(FriendPlant plant, Color accentColor) {
    final (statusIcon, statusColor) = switch (plant.healthStatus) {
      '健康' => (Icons.eco, AppColors.success),
      '需关注' => (Icons.warning_amber, AppColors.accent),
      _ => (Icons.help_outline, AppColors.textHint),
    };
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(plant.name,
                  style: AppTypography.bodySemiBold.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plant.scientificName,
            style: AppTypography.caption.copyWith(
              fontSize: 10, fontStyle: FontStyle.italic),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 3),
              Text(plant.healthStatus,
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${plant.careDays}天',
                style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  void _sayHi(NearbyUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('向 ${user.name} 打招呼', style: AppTypography.cardTitle),
        content: Text('已向 ${user.name}（${user.tag}）发送了一条问候消息。\n\n对方收到后可以回复你，开始聊天～',
          style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('好的', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// 地形纹理画笔 (装饰性)
class MapTerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.13, size.height * 0.23), width: 120, height: 90),
      paint..color = AppColors.mapTerrain.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.16), width: 100, height: 80),
      paint..color = AppColors.mapTerrain.withValues(alpha: 0.4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.08, size.height * 0.86), width: 110, height: 80),
      paint..color = const Color(0xFFD1FAE5).withValues(alpha: 0.4),
    );

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFBBF7D0).withValues(alpha: 0.5);

    final path1 = Path();
    path1.moveTo(-10, size.height / 2);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.43, size.width / 2, size.height / 2);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.57, size.width + 10, size.height / 2);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path();
    path2.moveTo(size.width / 2, -10);
    path2.quadraticBezierTo(size.width * 0.42, size.height * 0.23, size.width / 2, size.height / 2);
    path2.quadraticBezierTo(size.width * 0.58, size.height * 0.74, size.width / 2, size.height + 10);
    canvas.drawPath(path2, roadPaint..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 距离环画笔
class DistanceRingPainter extends CustomPainter {
  final double cx;
  final double cy;
  DistanceRingPainter(this.cx, this.cy);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.mapRing.withValues(alpha: 0.5);

    canvas.drawCircle(Offset(cx, cy), 55, paint);
    canvas.drawCircle(Offset(cx, cy), 110, paint..color = AppColors.mapRing.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(cx, cy), 170, paint..color = AppColors.mapRing.withValues(alpha: 0.3));

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, r) in [('100m', 55), ('500m', 110), ('1km', 170)]) {
      tp.text = TextSpan(text: label,
        style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppColors.mapRing));
      tp.layout();
      tp.paint(canvas, Offset(cx + r - 15, cy - r - 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
