import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/plant_card.dart';
import '../services/notification_service.dart';

/// 首次启动引导页
/// 3 屏品牌介绍 + 在最后一屏自然请求通知权限，全程无弹窗、不打扰。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _reminderOn = false;

  final List<_Page> _pages = const [
    _Page(
      icon: Icons.eco,
      title: '欢迎来到圆形植物',
      desc: '养花不再是难题。记录、提醒、识别，陪你把每一株都养得更好。',
    ),
    _Page(
      icon: Icons.local_florist,
      title: 'AI 识花 · 温柔提醒',
      desc: '拍照即可识别植物与养护要点；每天一条温和提醒，绝不打扰你。',
    ),
    _Page(
      icon: Icons.auto_awesome,
      title: '记录成长每一刻',
      desc: '成长对比、养护年轮、植物身份证，把美好分享给同样爱植物的朋友。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('跳过', style: AppTypography.caption),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            shape: BoxShape.circle,
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: Icon(p.icon, size: 56, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(p.title,
                            style: AppTypography.pageTitle.copyWith(fontSize: 22)),
                        const SizedBox(height: 16),
                        Text(p.desc,
                            style: AppTypography.caption.copyWith(fontSize: 15),
                            textAlign: TextAlign.center),
                        if (isLast) ...[
                          const SizedBox(height: 28),
                          _buildReminderToggle(),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildDots(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: GradientButton(
                label: isLast ? '开始使用' : '下一步',
                icon: isLast ? Icons.check : Icons.arrow_forward,
                onTap: isLast
                    ? _finish
                    : () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderToggle() {
    return GestureDetector(
      onTap: () async {
        await NotificationService.requestPermission();
        if (mounted) setState(() => _reminderOn = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _reminderOn ? AppColors.softCard : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              _reminderOn ? '每日提醒已开启 ✓' : '开启每日养护提醒',
              style: AppTypography.bodySemiBold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = _page == i;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String desc;
  const _Page({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
