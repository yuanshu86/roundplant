import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// 底部导航栏 + FAB
class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.tabBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 3个标签位 + FAB占位
          Row(
            children: [
              _buildTabItem('首页', Icons.home_outlined, Icons.home, 0),
              _buildTabItem('任务', Icons.check_circle_outline, Icons.check_circle, 1),
              const SizedBox(width: AppSpacing.fabSize), // FAB 占位
              _buildTabItem('附近', Icons.map_outlined, Icons.map, 2),
              _buildTabItem('我的', Icons.person_outline, Icons.person, 3),
            ],
          ),
          // FAB —— 与 Tab 图标同处一行，不再向上凸起
          Positioned(
            bottom: (AppSpacing.tabBarHeight - 48) / 2,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/scan'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.fabShadow,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData inactiveIcon, IconData activeIcon, int index) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态栏组件
class CustomStatusBar extends StatelessWidget {
  final Color color;

  const CustomStatusBar({super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.statusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('9:41', style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          )),
          Row(
            children: [
              // 信号
              _buildSignalIcon(color),
              const SizedBox(width: 6),
              // WiFi
              Icon(Icons.wifi, size: 16, color: color),
              const SizedBox(width: 6),
              // 电池
              _buildBatteryIcon(color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIcon(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Container(
          width: 3,
          height: 4.0 + i * 2,
          margin: EdgeInsets.only(right: i < 3 ? 1.5 : 0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(0.5),
          ),
        );
      }),
    );
  }

  Widget _buildBatteryIcon(Color color) {
    return Container(
      width: 27,
      height: 13,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Positioned(
            left: 1.5,
            top: 1.5,
            child: Container(
              width: 19,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              width: 2,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 导航栏组件
class CustomNavBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const CustomNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              child: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
            ),
          ),
          Text(title, style: AppTypography.pageTitle),
          trailing ?? const SizedBox(width: 32),
        ],
      ),
    );
  }
}
