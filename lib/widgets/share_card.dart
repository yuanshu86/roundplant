import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/plant.dart';
import '../store/app_store.dart';

/// 分享卡片生成器
/// 使用 RepaintBoundary 将植物信息渲染为 PNG 图片，再通过 share_plus 分享
class ShareCardService {
  static final GlobalKey _cardKey = GlobalKey();

  /// 生成并分享植物卡片
  static Future<void> sharePlantCard(BuildContext context, Plant plant, AppStore store) async {
    // 获取该植物的最近日记
    final recentDiaries = store.getDiariesForPlant(plant.id).take(3).toList();

    // 先弹窗展示卡片预览，再分享
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SharePreviewSheet(
        plant: plant,
        recentDiaries: recentDiaries,
      ),
    );
  }
}

/// 分享预览弹窗
class _SharePreviewSheet extends StatelessWidget {
  final Plant plant;
  final List<DiaryEntry> recentDiaries;

  const _SharePreviewSheet({
    required this.plant,
    required this.recentDiaries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ).copyWith(boxShadow: AppColors.sheetShadow),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('分享植物', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          // 卡片预览
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RepaintBoundary(
                key: ShareCardService._cardKey,
                child: ShareCard(
                  plant: plant,
                  recentDiaries: recentDiaries,
                ),
              ),
            ),
          ),
          // 分享按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: GestureDetector(
                onTap: () => _shareAsImage(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('分享图片',
                        style: TextStyle(
                          fontFamily: 'NunitoSans', fontSize: 16,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareAsImage(BuildContext context) async {
    try {
      final boundary = ShareCardService._cardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/circle_plant_share.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '来看看我的 ${plant.name}！${recentDiaries.isNotEmpty ? " 已养护${plant.careDays}天，积分${plant.points}" : ""}',
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('分享失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e'),
            backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

/// 静态分享卡片（纯展示，不绑 RepaintBoundary 逻辑）
class ShareCard extends StatelessWidget {
  final Plant plant;
  final List<DiaryEntry> recentDiaries;

  const ShareCard({
    super.key,
    required this.plant,
    required this.recentDiaries,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：植物图片 + 名称
          _buildHeader(),
          // 健康徽章
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _buildHealthBadge(),
          ),
          // 养护数据
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildStats(),
          ),
          // 养护参数
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildParams(),
          ),
          // 日记摘录
          if (recentDiaries.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Divider(color: AppColors.border),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildDiaryExcerpt(),
            ),
          ],
          // 底部品牌
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text('圆形植物 · 一起养花',
                  style: TextStyle(
                    fontFamily: 'VarelaRound', fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
      ),
      _buildWatermarkOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: plant.imagePath != null
              ? Image.file(
                  File(plant.imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildHeaderPlaceholder(),
                )
              : _buildHeaderPlaceholder(),
        ),
      ],
    );
  }

  /// 全卡水印层：斜向大字「圆形植物」铺底 + 角落品牌标，确保对外分享图打上品牌
  Widget _buildWatermarkOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Center(
              child: Transform.rotate(
                angle: -0.35,
                child: Text(
                  '圆形植物',
                  style: TextStyle(
                    fontFamily: 'VarelaRound',
                    fontSize: 60,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('圆形植物',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(plant.name,
            style: const TextStyle(
              fontFamily: 'VarelaRound', fontSize: 28,
              fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 4),
          Text(plant.scientificName,
            style: const TextStyle(
              fontFamily: 'NunitoSans', fontSize: 14,
              color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildHealthBadge() {
    final (icon, color) = switch (plant.healthStatus) {
      '健康' => (Icons.eco, AppColors.success),
      '需关注' => (Icons.warning_amber, AppColors.accent),
      _ => (Icons.help_outline, AppColors.textHint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(plant.healthStatus,
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 12,
              fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem(Icons.calendar_today, '养护', '${plant.careDays}天'),
        _statItem(Icons.stars, '积分', '${plant.points}'),
        _statItem(Icons.water_drop, '${plant.wateringFrequency}天/次', '浇水'),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 16,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label,
          style: AppTypography.caption),
      ],
    );
  }

  Widget _buildParams() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _paramRow(Icons.light_mode, '光照', plant.lightRequirement),
          const SizedBox(height: 8),
          _paramRow(Icons.thermostat, '温度', plant.temperatureRange),
          const SizedBox(height: 8),
          _paramRow(Icons.water_drop, '湿度', plant.humidityRange),
        ],
      ),
    );
  }

  Widget _paramRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500)),
        ),
        Text(value, style: AppTypography.body),
      ],
    );
  }

  Widget _buildDiaryExcerpt() {
    final fmt = DateFormat('M/d');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近日记',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(height: 8),
        ...recentDiaries.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmt.format(d.createdAt),
                style: AppTypography.caption.copyWith(
                  fontFamily: 'NunitoSans', color: AppColors.textHint)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.note ?? '记录了养护瞬间',
                  style: AppTypography.body.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
