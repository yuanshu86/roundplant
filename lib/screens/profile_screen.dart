import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../widgets/avatar_image.dart';
import 'about_screen.dart';
import 'changelog_screen.dart';
import '../services/backup_service.dart';
import '../services/supabase_service.dart';

/// Screen 7 - 个人中心 (Tab 内容)
///
/// 配色铁律：头部是绿色渐变底，其上的文字/图标一律走 `AppTypography.onDark*`
/// 或硬编码白色，**绝不能**用 `AppColors.textPrimary`（浅色模式下是深灰，
/// 压在绿底上几乎看不清）。
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// 逐项进场：淡入 + 轻微上滑，index 越大越晚出现
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        return Container(
          color: AppColors.bg,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 24),
            child: Column(
              children: [
                _staggered(0, _buildHeader(store)),
                // 统计卡上移，与头部形成叠压层次
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: _staggered(1, _buildStatsCard(store)),
                ),
                _staggered(2, _buildMenuSection(context, store)),
                const SizedBox(height: 20),
                _staggered(3, _buildFooter()),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- 头部

  Widget _buildHeader(AppStore store) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF166534), Color(0xFF15803D), Color(0xFF22A45D)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 20,
          20,
          52, // 给下方叠压的统计卡留位
        ),
        child: Column(
          children: [
            // 头像：点击可从相册换头像（上传 Supabase Storage，云端同步）
            GestureDetector(
              onTap: () => _pickAvatar(store),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarImage(
                    url: store.myAvatarUrl,
                    color: AppColors.primary,
                    size: 76,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.photo_camera,
                          size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(store.myNickname ?? '植物管家',
                style: AppTypography.onDarkTitle),
            const SizedBox(height: 6),
            Text(
              '已守护 ${store.maxCareDays} 天 · 养护 ${store.totalPlants} 株植物',
              style: AppTypography.onDarkBody,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 统计

  Widget _buildStatsCard(AppStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statColumn('${store.totalPlants}', '株植物'),
            _statDivider(),
            _statColumn('${store.maxCareDays}', '天守护'),
            _statDivider(),
            _statColumn('${store.totalPoints}', '积分'),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 32, color: AppColors.border);

  Widget _statColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 22,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  // ---------------------------------------------------------------- 菜单

  Widget _buildMenuSection(BuildContext context, AppStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Column(
            children: [
              _menuItem(
                icon: Icons.notifications_active_outlined,
                title: '浇水提醒',
                subtitle: '已开启 · 每天 9:00 温和提醒',
                onTap: () => _showReminderHint(context),
              ),
              _divider(),
              _menuItem(
                icon: Icons.chat_bubble_outline,
                title: '微信号（可选）',
                subtitle: '不填也能聊天；填了对方可见，方便加微信',
                onTap: () => _showWechatSheet(context),
              ),
              _divider(),
              _menuItem(
                icon: Icons.explore_outlined,
                title: '附近植友',
                subtitle: '看看同城都在养什么',
                onTap: () => Navigator.pushNamed(context, '/nearby'),
              ),
              _divider(),
              _menuItem(
                icon: Icons.dark_mode_outlined,
                title: '主题外观',
                subtitle: store.themeModeLabel,
                onTap: () => _showThemePicker(context),
              ),
              _divider(),
              _menuItem(
                icon: Icons.backup_outlined,
                title: '数据备份',
                subtitle: '导出到手机 / 一键恢复',
                onTap: () => _showBackupSheet(context),
              ),
              _divider(),
              _menuItem(
                icon: Icons.auto_awesome_outlined,
                title: '更新通知',
                subtitle: '看看这次更新了什么',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangelogScreen()),
                ),
              ),
              _divider(),
              _menuItem(
                icon: Icons.favorite_outline,
                title: '关于圆形植物',
                subtitle: '无广告 · 数据本地 · 打赏支持',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              _divider(),
              _menuItem(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                subtitle: '我们如何处理你的数据',
                onTap: () => _openPrivacy(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56), // ≥48dp 触摸目标
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryText),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.bodySemiBold),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: AppColors.border, indent: 68);

  // ---------------------------------------------------------------- 页脚

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            '圆形植物 · 一株一世界',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            '无广告 · 无弹窗 · 数据只存在你的手机里',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 交互

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  void _showReminderHint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text('浇水提醒', style: AppTypography.cardTitle),
        content: Text(
          '已为你开启每日 9:00 温和提醒，固定时间通知。\n\n自定义提醒时间等功能正在打磨中，敬请期待～',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('好的', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacy(BuildContext context) async {
    final uri = Uri.parse('https://roundplant.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _toast(context, '打开链接失败，请检查网络');
    }
  }

  /// 从相册选头像并上传（Supabase Storage + profiles.avatar_url 云端同步）
  Future<void> _pickAvatar(AppStore store) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final ok = await store.setMyAvatar(File(picked.path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '头像已更新 🌿' : '头像上传失败，稍后再试'),
        backgroundColor: ok ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final store = Provider.of<AppStore>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text('主题外观', style: AppTypography.cardTitle),
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeOption(
                  ctx, store, ThemeMode.light, '浅色', Icons.light_mode_outlined),
              _themeOption(
                  ctx, store, ThemeMode.dark, '深色', Icons.dark_mode_outlined),
              _themeOption(ctx, store, ThemeMode.system, '跟随系统',
                  Icons.brightness_auto_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('关闭', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, AppStore store, ThemeMode mode,
      String label, IconData icon) {
    final selected = store.themeMode == mode;
    return ListTile(
      leading: Icon(icon,
          size: 20,
          color: selected ? AppColors.primaryText : AppColors.textSecondary),
      title: Text(label, style: AppTypography.body),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.primaryText, size: 20)
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        store.setThemeMode(mode);
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

  /// 微信号设置（非必填）。用户填了存到 profiles.wechat，对话页加微信按钮可用。
  Future<void> _showWechatSheet(BuildContext context) async {
    if (!SupabaseService.isInitialized) {
      _toast(context, '未接入云端，无法保存微信号');
      return;
    }
    final initial = (await SupabaseService.fetchMyWechat()) ?? '';
    if (!context.mounted) return;
    final ctrl = TextEditingController(text: initial);
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusSheet)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('微信号（非必选项）', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  Text('填写后，对方在与你对话时可一键加你微信。\n不填也可以正常聊天。',
                      style: AppTypography.caption),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      hintText: '如：circle_plant',
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: saving
                              ? null
                              : () => Navigator.pop(ctx, '__CLEAR__'),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text('清空',
                                  style: TextStyle(
                                      fontFamily: 'NunitoSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: saving ? null : () => Navigator.pop(ctx, ctrl.text),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(saving ? '保存中…' : '保存',
                                  style: const TextStyle(
                                      fontFamily: 'NunitoSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    if (result == null) return;
    final ok = await SupabaseService.updateMyWechat(
        result == '__CLEAR__' ? null : result);
    if (!mounted) return;
    if (ok) {
      _toast(context, result == '__CLEAR__' ? '已清空微信号' : '已保存微信号');
    } else {
      _toast(context, '保存失败，请稍后再试');
    }
  }
}

// ==================================================================== 备份面板

class _BackupSheet extends StatefulWidget {
  const _BackupSheet();

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  bool _backing = false;
  String? _msg;
  int _reloadTick = 0; // 备份成功后强制刷新列表

  Future<void> _doBackup() async {
    setState(() => _backing = true);
    try {
      final (_, exported) = await BackupService.backup();
      if (!mounted) return;
      setState(() {
        _msg = exported ? '备份成功，已导出到手机存储' : '备份成功（保存在应用内）';
        _reloadTick++;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = '备份失败：$e');
    } finally {
      if (mounted) setState(() => _backing = false);
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
          const SizedBox(height: 14),
          Text('数据备份', style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text('备份文件不含水印，仅供你自己恢复使用', style: AppTypography.caption),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _backing ? null : _doBackup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: Center(
                    child: _backing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '立即备份',
                            style: TextStyle(
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
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                _msg!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: _msg!.contains('失败')
                      ? AppColors.danger
                      : AppColors.primaryText,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: FutureBuilder<List<BackupFile>>(
              key: ValueKey(_reloadTick),
              future: BackupService.listBackups(),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primaryText),
                  );
                }
                final list = snap.data ?? const <BackupFile>[];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 40, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        Text('还没有备份', style: AppTypography.caption),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border, indent: 56),
                  itemBuilder: (c, i) {
                    final f = list[i];
                    return ListTile(
                      leading: Icon(Icons.save_outlined,
                          color: AppColors.primaryText),
                      title: Text(f.name, style: AppTypography.body),
                      subtitle:
                          Text(_fmt(f.time), style: AppTypography.caption),
                      trailing: TextButton(
                        onPressed: () => _confirmRestore(f, store),
                        child: Text('恢复',
                            style: TextStyle(color: AppColors.primaryText)),
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

  /// 恢复是破坏性操作（覆盖当前数据），必须二次确认
  Future<void> _confirmRestore(BackupFile f, AppStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text('确认恢复？', style: AppTypography.cardTitle),
        content: Text(
          '将用「${f.name}」覆盖当前全部植物、日记和养护记录，此操作不可撤销。',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('确认恢复', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.restore(f.path);
      await store.reloadData();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
            content: const Text('恢复成功'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('恢复失败：$e'), backgroundColor: AppColors.danger),
      );
    }
  }

  String _fmt(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)} ${pad(t.hour)}:${pad(t.minute)}';
  }
}
