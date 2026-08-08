import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/plant.dart';
import '../widgets/plant_image.dart';

/// Screen 5 - 分享面板 (全屏 Push Route，底部 Sheet 样式)
class ShareSheet extends StatefulWidget {
  final Plant? plant;

  const ShareSheet({super.key, this.plant});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 蒙层
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.dimOverlay,
            ),
          ),
          // 底部面板
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 540,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusSheet),
                ),
                boxShadow: AppColors.sheetShadow,
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhotoPreview(),
                          const SizedBox(height: 16),
                          _buildCaptionField(),
                          const SizedBox(height: 20),
                          Text('分享到', style: AppTypography.sectionTitle),
                          const SizedBox(height: 16),
                          _buildShareTargets(),
                          const Spacer(),
                          Container(height: 1, color: AppColors.divider),
                          const SizedBox(height: 12),
                          _buildCancelButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    final name = widget.plant?.name ?? '我的植物';
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Stack(
        children: [
          PlantImage(plantName: name, height: 150, borderRadius: AppSpacing.radiusCard),
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('1/3', style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 11,
                fontWeight: FontWeight.w600, color: Colors.white,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.edit, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _captionController,
              style: AppTypography.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '添加分享文案…',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textHint),
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildShareTargets() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _target(Icons.chat_bubble, '微信', AppColors.wechat, Colors.white, _share),
        _target(Icons.favorite, '小红书', AppColors.xiaohongshu, Colors.white, _share),
        _target(Icons.share, '更多', AppColors.softCard, AppColors.primary, _share),
        _target(Icons.download, '保存图片', AppColors.softCard, AppColors.primary, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('图片已保存到相册'),
              backgroundColor: AppColors.primary,
            ),
          );
        }),
      ],
    );
  }

  Widget _target(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.softCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        alignment: Alignment.center,
        child: Text('取消', style: AppTypography.bodySemiBold.copyWith(
          color: AppColors.textSecondary, fontSize: 16,
        )),
      ),
    );
  }

  void _share() {
    final name = widget.plant?.name ?? '我的植物';
    final text = _captionController.text.isEmpty
        ? '我在用「圆形植物」养护我的$name，它长得真好！'
        : '${_captionController.text}\n\n—— 来自「圆形植物」App';
    Share.share(text, subject: '圆形植物 - 分享');
  }
}
