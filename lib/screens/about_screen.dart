import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// 「关于圆形植物」独立页
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.isDark
            ? AppColors.frostedTintDark
            : AppColors.frostedTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('关于圆形植物', style: AppTypography.cardTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 16),
            Text('圆形植物', style: AppTypography.cardTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: AppTypography.badge),
            const SizedBox(height: 28),
            _buildHighlightCard(),
            const SizedBox(height: 28),
            _buildRewardSection(),
            const SizedBox(height: 32),
            // 上架合规：Google Play / App Store 强制要求 APP 提供可访问的隐私政策链接
            _buildPrivacyLink(),
            const SizedBox(height: 16),
            Text('© 2026 圆形植物 Circle Plant', style: AppTypography.badge),
            const SizedBox(height: 8),
            Text('陪伴你的每一株植物健康成长', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyLink() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://roundplant.cn/privacy');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.privacy_tip_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('隐私政策',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 12, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco, size: 40, color: AppColors.primary),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _highlightRow(Icons.block, '完全没有广告', '没有任何弹窗、开屏、插屏或横幅广告，只给你安静的陪伴。'),
          const SizedBox(height: 16),
          _highlightRow(
              Icons.storage, '数据本地存储', '你的植物数据全部保存在手机本地，不上传任何云端，隐私由你掌握。'),
          const SizedBox(height: 16),
          _highlightRow(Icons.favorite_outline, '自愿打赏支持',
              '如果圆形植物帮你照顾好了花草，欢迎扫码打赏，支持我继续做下去。'),
        ],
      ),
    );
  }

  Widget _highlightRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySemiBold),
              const SizedBox(height: 4),
              Text(desc, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardSection() {
    return Column(
      children: [
        Text('打赏支持', style: AppTypography.bodySemiBold),
        const SizedBox(height: 4),
        Text('你的支持是我持续优化这款 App 的动力', style: AppTypography.caption),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: AppColors.cardShadow,
          ),
          child: Image.asset(
            'assets/images/reward_qr.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 180,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('收款二维码',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textHint)),
                    Text('（待添加图片）',
                        style: AppTypography.badge
                            .copyWith(color: AppColors.textHint)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
