import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/frosted.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/plant.dart';
import '../widgets/plant_image.dart';
import '../widgets/app_logo.dart';

/// 分享卡片固定配色（与 App 主题解耦：分享图是独立产物，
/// 不能随深浅主题变色，否则深色模式下白底卡片会白字白底看不见）。
const Color _cardBg = Colors.white;
const Color _ink = Color(0xFF1E293B);
const Color _inkSoft = Color(0xFF64748B);
const Color _brand = Color(0xFF15803D);
const Color _brand2 = Color(0xFF059669);

/// Screen 5 - 分享面板 (全屏 Push Route，底部 Sheet 样式)
///
/// 硬约束：所有对外分享图必须带「圆形植物」水印。
/// 本页用 RepaintBoundary 包裹一张「植物身份证」卡片，
/// 卡片右下角带一个低调的品牌角标（圆形植物 LOGO +「圆形植物」字样），
/// 分享时把这张带水印的 PNG 真正发出去 / 存进相册。
class ShareSheet extends StatefulWidget {
  final Plant? plant;

  const ShareSheet({super.key, this.plant});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final TextEditingController _captionController = TextEditingController();
  final GlobalKey _cardKey = GlobalKey();
  bool _generating = false;

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
            child: FrostedGlass(
              tint: AppColors.isDark
                  ? AppColors.frostedTintDark
                  : AppColors.frostedTint,
              sigma: 24,
              height: 600,
              radius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusSheet),
              ),
              shadows: AppColors.sheetShadow,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 40,
                    height: 4,
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
                          _buildCardPreview(),
                          const SizedBox(height: 16),
                          _buildCaptionField(),
                          const SizedBox(height: 16),
                          Text('分享到', style: AppTypography.sectionTitle),
                          const SizedBox(height: 4),
                          Text(
                            '图片已自动添加「圆形植物」水印',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 12),
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

  /// 预览：把固定尺寸 (340x480) 的分享卡用 FittedBox 缩放进 200px 高的框里。
  /// RepaintBoundary 自身仍是 340x480，因此截图导出时是全分辨率，
  /// FittedBox 的缩放只是视觉上的，不会进入边界自己的图层。
  Widget _buildCardPreview() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(
              key: _cardKey,
              child: _buildShareCard(),
            ),
          ),
          if (_generating)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 植物身份证卡片（固定 340x480，导出尺寸）。
  Widget _buildShareCard() {
    final plant = widget.plant;
    final name = plant?.name ?? '我的植物';
    final sci = plant?.scientificName ?? '';
    final careDays = plant?.careDays ?? 0;
    final health = plant?.healthStatus ?? '健康';
    final days = plant?.daysUntilWatering ?? 0;
    final waterText = days <= 0 ? '今天' : '$days 天后';

    return Container(
      width: 340,
      height: 480,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              _brandHeader(),
              SizedBox(
                height: 220,
                width: double.infinity,
                child: PlantImage(
                  plantName: name,
                  imagePath: plant?.imagePath,
                  width: double.infinity,
                  height: 220,
                  borderRadius: 0,
                ),
              ),
              _infoPanel(name, sci, careDays, health, waterText),
            ],
          ),
          // 右下角品牌水印角标（硬约束：对外分享图必须带「圆形植物」标识）
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 18),
                  const SizedBox(width: 5),
                  const Text(
                    '圆形植物',
                    style: TextStyle(
                      color: _brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NunitoSans',
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

  Widget _brandHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brand, _brand2],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          const Text(
            '圆形植物',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'VarelaRound',
            ),
          ),
          const Spacer(),
          const Text(
            '记录每一株生长',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 11,
              fontFamily: 'NunitoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel(
    String name,
    String sci,
    int careDays,
    String health,
    String waterText,
  ) {
    return Expanded(
      child: Container(
        width: double.infinity,
        color: _cardBg,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'VarelaRound',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sci.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sci,
                  style: const TextStyle(
                    color: _inkSoft,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'NunitoSans',
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('养护天数', '$careDays'),
                _stat('健康状态', health, color: _brand),
                _stat('下次浇水', waterText),
              ],
            ),
            const Spacer(),
            Container(height: 1, color: const Color(0xFFE2EFE7)),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '圆形植物 · 陪你养好每一株',
                style: const TextStyle(
                  color: _inkSoft,
                  fontSize: 11,
                  fontFamily: 'NunitoSans',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _inkSoft,
              fontSize: 11,
              fontFamily: 'NunitoSans',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? _ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'NunitoSans',
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
                hintStyle:
                    AppTypography.body.copyWith(color: AppColors.textHint),
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
    return Opacity(
      opacity: _generating ? 0.5 : 1.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _target(Icons.chat_bubble, '微信', AppColors.wechat, Colors.white,
              () => _shareImage()),
          _target(Icons.favorite, '小红书', AppColors.xiaohongshu, Colors.white,
              () => _shareImage()),
          _target(Icons.share, '更多', AppColors.softCard, AppColors.primary,
              () => _shareImage()),
          _target(Icons.download, '保存图片', AppColors.softCard, AppColors.primary,
              () => _saveImage()),
        ],
      ),
    );
  }

  Widget _target(IconData icon, String label, Color bg, Color iconColor,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
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
        child: Text('取消',
            style: AppTypography.bodySemiBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            )),
      ),
    );
  }

  // === 导出与分享逻辑 ===

  /// 把分享卡渲染成 PNG 字节（pixelRatio 3 → 1020x1440 高清）。
  Future<Uint8List?> _captureCard() async {
    try {
      final ctx = _cardKey.currentContext;
      if (ctx == null) return null;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// 分享到 微信 / 小红书 / 更多：把带水印的 PNG 真正发出去（不再是纯文本）。
  Future<void> _shareImage() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _toast('图片生成失败，请重试');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/circleplant_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      final name = widget.plant?.name ?? '我的植物';
      final text = _captionController.text.isEmpty
          ? '我在用「圆形植物」记录我的$name，它长得真好！'
          : _captionController.text;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
        subject: '圆形植物 - 分享',
      );
    } catch (e) {
      _toast('分享失败：$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// 保存图片到相册（真存，不再是假提示）。
  Future<void> _saveImage() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _toast('图片生成失败，请重试');
        return;
      }
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: '圆形植物_${widget.plant?.name ?? '我的植物'}',
      );
      final ok =
          result is Map ? (result['isSuccess'] == true) : (result == true);
      _toast(ok ? '图片已保存到相册' : '保存失败，请检查相册权限');
    } catch (e) {
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }
}
