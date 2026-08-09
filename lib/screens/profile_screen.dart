import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../widgets/leafy_background.dart';
import '../widgets/achievement_medals.dart';
import '../widgets/handy_icons.dart';
import 'about_screen.dart';
import 'changelog_screen.dart';

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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: LeafyBackground(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
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
              Text('植物管家',
                style: TextStyle(
                  fontFamily: 'VarelaRound', fontSize: 20, color: Colors.white)),
              const SizedBox(height: 4),
              Text('已加入 ${store.maxCareDays} 天 · 养护 ${store.totalPlants} 株植物',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AchievementMedals(
        plants: store.totalPlants,
        days: store.maxCareDays,
        points: store.totalPoints,
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
            _menuItem(HandyIcons.alarm(), '浇水提醒', '每天 9:00', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('提醒设置开发中'),
                  backgroundColor: AppColors.primary),
              );
            }),
            _divider(),
            _menuItem(HandyIcons.compass(), '附近花友', '查看同好', () {
              Navigator.pushNamed(context, '/nearby');
            }),
            _divider(),
            _menuItem(HandyIcons.brush(), '主题设置', '自然绿', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('主题设置开发中'),
                  backgroundColor: AppColors.primary),
              );
            }),
            _divider(),
            _menuItem(HandyIcons.update(), '更新通知', '看看这次更新了什么', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangelogScreen()));
            }),
            _divider(),
            _menuItem(HandyIcons.info(), '关于圆形植物', '无广告 · 本地存储 · 打赏', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(Widget icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 14),
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
      const Divider(height: 1, color: AppColors.border, indent: 54);
}
