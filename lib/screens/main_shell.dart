import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../store/app_store.dart';
import '../services/supabase_service.dart';
import '../widgets/frosted.dart';
import '../widgets/tab_icons.dart';
import '../widgets/garden_background.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

/// 主导航壳 — 底部 Tab Bar + FAB
/// 使用 IndexedStack 保持各页面状态
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _fabPressed = false;

  // 未读消息红点：每 10 秒轮询一次（与聊天轮询同节奏，量小无压力）
  int _unreadCount = 0;
  Timer? _unreadTimer;

  /// 切 Tab 时的柔和过渡。
  /// 注意：**不能**用 AnimatedSwitcher 去包 IndexedStack —— 那样每次切换
  /// key 变化会让整棵树重建，四个页面的 State（滚动位置、动画、输入框内容）
  /// 全部丢失，而且新旧两份 IndexedStack 会同时存在，等于 build 八个页面。
  /// 这里改成保持 IndexedStack 唯一实例，只在外层叠一层透明度/缩放动画。
  late final AnimationController _pageFade;

  final _screens = const [
    HomeScreen(),
    TasksScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    // 云端接入时启动未读轮询；本地模式（未注入 key）直接跳过
    if (SupabaseService.isInitialized) {
      _refreshUnread();
      _unreadTimer =
          Timer.periodic(const Duration(seconds: 10), (_) => _refreshUnread());
    }
  }

  Future<void> _refreshUnread() async {
    final c = await SupabaseService.fetchUnreadCount();
    if (mounted && c != _unreadCount) {
      setState(() => _unreadCount = c);
    }
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    _pageFade.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageFade.forward(from: 0.0);
  }

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
                // 田园背景（奶油光斑+植物剪影）铺在所有 tab 页面之下，
                // 玻璃卡叠上去即可透出「晨雾花园」氛围
                Positioned.fill(
                  child: GardenBackground(
                    child: AnimatedBuilder(
                      animation: _pageFade,
                      builder: (context, child) {
                        final t =
                            Curves.easeOutCubic.transform(_pageFade.value);
                        return Opacity(
                          opacity: 0.35 + 0.65 * t,
                          child: Transform.scale(
                            scale: 0.985 + 0.015 * t,
                            child: child,
                          ),
                        );
                      },
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
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
    // 关键：底栏必须把系统手势条 / iPhone Home Indicator 的高度加进来，
    // 否则 83px 的栏体被手势条压掉一截，Tab 图标和 FAB 会整体显得偏高。
    final gestureInset = MediaQuery.of(context).viewPadding.bottom;
    // FAB 药丸形（圆角矩形 Extended FAB）· 80×44 · 凸出约 19px
    const double fabSize = 80.0;
    const double fabHeight = 44.0;
    const double fabIconSize = 20.0;

    return FrostedGlass(
      height: AppSpacing.tabBarHeight + gestureInset,
      tint:
          AppColors.isDark ? AppColors.frostedTintDark : AppColors.frostedTint,
      radius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      border: Border(
        top: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: gestureInset),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Row(
              children: [
                _tabItem('首页', 0,
                    ({required bool active}) => TabIcons.home(active: active)),
                _tabItem('任务', 1,
                    ({required bool active}) => TabIcons.tasks(active: active)),
                const SizedBox(width: fabSize + 12),
                _tabItem(
                    '消息',
                    2,
                    ({required bool active}) =>
                        TabIcons.messages(active: active),
                    badge: _unreadCount > 0
                        ? _UnreadBadge(count: _unreadCount)
                        : null),
                _tabItem(
                    '我的',
                    3,
                    ({required bool active}) =>
                        TabIcons.profile(active: active)),
              ],
            ),
            // FAB —— 药丸形「识花」圆角矩形（陶土橙立体，按下缩放反馈）
            Positioned(
              bottom: (AppSpacing.tabBarHeight - fabHeight) / 2,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _fabPressed = true),
                  onTapUp: (_) {
                    setState(() => _fabPressed = false);
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/scan');
                  },
                  onTapCancel: () => setState(() => _fabPressed = false),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    scale: _fabPressed ? 0.94 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: fabSize,
                      height: fabHeight,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient, // 陶土橙渐变
                        borderRadius:
                            BorderRadius.circular(fabHeight / 2), // 22 = 完全药丸
                        boxShadow: AppColors.fabShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabIcons.scan(
                              size: fabIconSize, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text(
                            '识花',
                            style: TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index,
      Widget Function({required bool active}) iconBuilder,
      {Widget? badge}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.08 : 0.86,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: iconBuilder(active: isActive),
                ),
                if (badge != null)
                  Positioned(top: -4, right: -12, child: badge),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontFamilyFallback: const [
                  'PingFang SC',
                  'Microsoft YaHei',
                  'Noto Sans SC',
                  'Source Han Sans SC',
                  'sans-serif',
                ],
                fontSize: 11,
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

/// 未读消息红点（花瓣粉小徽章，>99 显示 99+）
class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.petalDeep,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardWhite, width: 1.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
