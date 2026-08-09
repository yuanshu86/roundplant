import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../widgets/leafy_background.dart';
import '../widgets/achievement_medals.dart';
import 'about_screen.dart';
import 'changelog_screen.dart';
import '../services/backup_service.dart';

/// Screen 7 - 个人中心 (Tab 内容)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        try {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 20),
            child: Column(
              children: [
                _safeBuild('header', () => _buildHeader(store)),
                const SizedBox(height: 20),
                _safeBuild('stats', () => _buildStatsRow(store)),
                const SizedBox(height: 20),
                _safeBuild('menu', () => _buildMenuSection(context, store)),
              ],
            ),
          );
        } catch (e, stack) {
          debugPrint('ProfileScreen build error: $e\n$stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '我的页面渲染出错：\n$e',
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _safeBuild(String name, Widget Function() builder) {
    try {
      return builder();
    } catch (e, stack) {
      debugPrint('ProfileScreen $name error: $e\n$stack');
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.danger),
        ),
        child: Text(
          '$name 渲染出错：\n$e',
          style: AppTypography.body.copyWith(color: AppColors.danger),
        ),
      );
    }
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
                  fontFamily: 'VarelaRound', fontSize: 20, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('已加入 ${store.maxCareDays} 天 · 养护 ${store.totalPlants} 株植物',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 12,
                  color: AppColors.textSecondary)),
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

  Widget _buildMenuSection(BuildContext context, AppStore store) {
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
            _menuItem(const Icon(Icons.alarm_outlined, size: 22, color: AppColors.primary), '浇水提醒', '每天 9:00', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('提醒设置开发中'),
                  backgroundColor: AppColors.primary),
              );
            }),
            _divider(),
            _menuItem(const Icon(Icons.explore_outlined, size: 22, color: AppColors.primary), '附近花友', '查看同好', () {
              Navigator.pushNamed(context, '/nearby');
            }),
            _divider(),
            _menuItem(const Icon(Icons.brush_outlined, size: 22, color: AppColors.primary), '主题设置',
                store.themeMode == ThemeMode.dark ? '深色' : '浅色', () {
              _showThemePicker(context);
            }),
            _menuItem(
              const Icon(Icons.backup_outlined, size: 22, color: AppColors.primary),
              '数据备份', '导出 / 恢复', () {
              _showBackupSheet(context);
            }),
            _divider(),
            _menuItem(const Icon(Icons.update_outlined, size: 22, color: AppColors.primary), '更新通知', '看看这次更新了什么', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangelogScreen()));
            }),
            _divider(),
            _menuItem(const Icon(Icons.info_outline, size: 22, color: AppColors.primary), '关于圆形植物', '无广告 · 本地存储 · 打赏', () {
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
      Divider(height: 1, color: AppColors.border, indent: 54);

  void _showThemePicker(BuildContext context) {
    final store = Provider.of<AppStore>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text('主题设置', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(ctx, store, '浅色', false),
            _themeOption(ctx, store, '深色', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, AppStore store, String label, bool dark) {
    final target = dark ? ThemeMode.dark : ThemeMode.light;
    final selected = store.themeMode == target;
    return ListTile(
      title: Text(label, style: AppTypography.body),
      trailing: selected ? Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () {
        store.setThemeMode(target);
        Navigator.pop(ctx);
      },
    );
  }

  void _showBackupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BackupSheet(),
    );
  }
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet();

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  bool _backing = false;
  String? _msg;

  Future<void> _doBackup() async {
    setState(() => _backing = true);
    try {
      final (path, exported) = await BackupService.backup();
      setState(() =>
          _msg = exported ? '备份成功，已导出到手机存储' : '备份成功（应用内）');
    } catch (e) {
      setState(() => _msg = '备份失败: $e');
    } finally {
      setState(() => _backing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<AppStore>(context, listen: false);
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('数据备份', style: AppTypography.cardTitle),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _backing ? null : _doBackup,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.buttonShadow,
                ),
                child: Center(
                  child: Text(
                    _backing ? '备份中…' : '立即备份',
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_msg!,
                  style: AppTypography.caption.copyWith(color: AppColors.primary)),
            ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<BackupFile>>(
              future: BackupService.listBackups(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Text('暂无备份', style: AppTypography.caption),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final f = list[i];
                    return ListTile(
                      leading: Icon(Icons.save_outlined, color: AppColors.primary),
                      title: Text(f.name, style: AppTypography.body),
                      subtitle: Text(_fmt(f.time), style: AppTypography.caption),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            await BackupService.restore(f.path);
                            await store.reloadData();
                            if (mounted) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('恢复成功'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('恢复失败: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                        child: Text('恢复',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)} ${pad(t.hour)}:${pad(t.minute)}';
  }
}
