import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';

/// Screen 7 - 个人中心 (Tab 内容)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 20),
          child: Column(
            children: [
              _buildHeader(store),
              const SizedBox(height: 20),
              _buildStatsRow(store),
              const SizedBox(height: 20),
              _buildMenuSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppStore store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text('植物管家', style: TextStyle(
            fontFamily: 'VarelaRound', fontSize: 20, color: Colors.white,
          )),
          const SizedBox(height: 4),
          Text('已加入 ${store.maxCareDays} 天 · 养护 ${store.totalPlants} 株植物',
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            )),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(Icons.eco, '${store.totalPlants}', '我的植物'),
          const SizedBox(width: 12),
          _statCard(Icons.local_fire_department, '${store.maxCareDays}', '连续天数'),
          const SizedBox(width: 12),
          _statCard(Icons.star, '${store.totalPoints}', '总积分'),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.bodySemiBold.copyWith(
              fontSize: 18, color: AppColors.primary)),
            Text(label, style: AppTypography.badge),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            _menuItem(Icons.notifications_outlined, '浇水提醒', '每天 9:00', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('提醒设置开发中'),
                    backgroundColor: AppColors.primary),
              );
            }),
            _divider(),
            _menuItem(Icons.location_on_outlined, '附近花友', '查看同好', () {
              Navigator.pushNamed(context, '/nearby');
            }),
            _divider(),
            _menuItem(Icons.palette_outlined, '主题设置', '自然绿', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('主题设置开发中'),
                    backgroundColor: AppColors.primary),
              );
            }),
            _divider(),
            _menuItem(Icons.info_outline, '关于圆形植物', 'v1.0.0', () {
              _showAbout(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body),
                  Text(subtitle, style: AppTypography.badge),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.border, indent: 50);

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.eco, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('圆形植物', style: AppTypography.cardTitle.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本 1.0.0', style: AppTypography.body),
            const SizedBox(height: 8),
            Text('一款治愈温柔的居家植物养护App。\n陪伴你的每一株植物健康成长。',
              style: AppTypography.caption),
            const SizedBox(height: 12),
            Text('设计：Ardot 设计稿\n开发：Flutter', style: AppTypography.badge),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('知道了', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
