import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../store/app_store.dart';
import '../widgets/frosted.dart';
import '../widgets/tab_icons.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'nearby_screen.dart';
import 'profile_screen.dart';

/// 主导航壳 — 底部 Tab Bar + FAB
/// 使用 IndexedStack 保持各页面状态
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    TasksScreen(),
    NearbyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Consumer<AppStore>(
          builder: (context, store, _) {
            if (store.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildTabBar(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return FrostedGlass(
      height: AppSpacing.tabBarHeight,
      tint: AppColors.isDark ? AppColors.frostedTintDark : AppColors.frostedTint,
      radius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      border: Border(
        top: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            children: [
              _tabItem('首页', 0, (active) => TabIcons.home(active: active)),
              _tabItem('任务', 1, (active) => TabIcons.tasks(active: active)),
              const SizedBox(width: AppSpacing.fabSize),
              _tabItem('附近', 2, (active) => TabIcons.nearby(active: active)),
              _tabItem('我的', 3, (active) => TabIcons.profile(active: active)),
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
                child: TabIcons.scan(size: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index,
      Widget Function({required bool active}) iconBuilder) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconBuilder(active: isActive),
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
