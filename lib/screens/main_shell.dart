import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../store/app_store.dart';
import '../widgets/frosted.dart';
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
      tint: AppColors.frostedTint,
      radius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      border: const Border(
        top: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            children: [
              _tabItem('首页', Icons.home_outlined, Icons.home, 0),
              _tabItem('任务', Icons.check_circle_outline, Icons.check_circle, 1),
              const SizedBox(width: AppSpacing.fabSize),
              _tabItem('附近', Icons.map_outlined, Icons.map, 2),
              _tabItem('我的', Icons.person_outline, Icons.person, 3),
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

  Widget _tabItem(String label, IconData inactive, IconData active, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? active : inactive,
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
