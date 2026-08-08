import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../models/plant.dart';
import '../widgets/plant_image.dart';
import '../widgets/plant_card.dart';
import '../widgets/share_card.dart';
import 'add_plant_screen.dart';
import 'diary_editor_screen.dart';

/// Screen 2 - 植物详情页 (Push Route)
class DetailScreen extends StatelessWidget {
  final Plant plant;

  const DetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        // 从 store 获取最新状态
        final p = store.getPlant(plant.id) ?? plant;
        return Scaffold(
          body: Container(
        color: AppColors.bg,
        child: SafeArea(
          top: true, bottom: false,
          child: Column(
            children: [
              _buildNavBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHero(p),
                          _buildNameSection(p),
                          _buildCareParams(p),
                          _buildCareReminders(context, store, p),
                          _buildDiary(p),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _buildShareBar(context, p),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 32, height: 32,
              child: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
            ),
          ),
          Text(plant.name, style: AppTypography.pageTitle),
          GestureDetector(
            onTap: () => _showOptions(context),
            child: SizedBox(
              width: 32, height: 32,
              child: Icon(Icons.more_horiz, color: AppColors.primary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Plant p) {
    return Container(
      width: double.infinity,
      height: 215,
      color: AppColors.softCard,
      child: Center(
        child: PlantImage(
          plantName: p.name,
          imagePath: p.imagePath,
          width: 180,
          height: 180,
          borderRadius: AppSpacing.radiusCard,
          isHero: true,
        ),
      ),
    );
  }

  Widget _buildNameSection(Plant p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.name, style: AppTypography.pageTitle.copyWith(fontSize: 22)),
              HealthBadge(text: p.healthStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.scientificName, style: AppTypography.caption.copyWith(
            fontSize: 13, fontStyle: FontStyle.italic,
          )),
        ],
      ),
    );
  }

  Widget _buildCareParams(Plant p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: [
          CareParamCard(icon: Icons.wb_sunny_outlined, label: '光照', value: p.lightRequirement),
          CareParamCard(icon: Icons.water_drop_outlined, label: '浇水', value: '每${p.wateringFrequency}天一次'),
          CareParamCard(icon: Icons.thermostat_outlined, label: '温度', value: p.temperatureRange),
          CareParamCard(icon: Icons.water_outlined, label: '湿度', value: p.humidityRange),
        ],
      ),
    );
  }

  Widget _buildCareReminders(BuildContext context, AppStore store, Plant p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('养护提醒', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          _careRow(
            icon: Icons.water_drop,
            color: AppColors.primary,
            label: '浇水',
            cycle: '每${p.wateringFrequency}天',
            daysLeft: p.daysUntilWatering,
            onTap: () {
              store.markCare(p.id, 'watering');
              _careSnack(context, '${p.name} 浇水成功！+5积分');
            },
          ),
          const SizedBox(height: 8),
          _careRow(
            icon: Icons.grain,
            color: AppColors.accent,
            label: '施肥',
            cycle: '每${p.fertilizingFrequency}天',
            daysLeft: p.daysUntilFertilizing,
            onTap: () {
              store.markCare(p.id, 'fertilizing');
              _careSnack(context, '${p.name} 施肥成功！+5积分');
            },
          ),
          const SizedBox(height: 8),
          _careRow(
            icon: Icons.content_cut,
            color: AppColors.secondary,
            label: '修剪',
            cycle: '每${p.pruningFrequency}天',
            daysLeft: p.daysUntilPruning,
            onTap: () {
              store.markCare(p.id, 'pruning');
              _careSnack(context, '${p.name} 修剪成功！+5积分');
            },
          ),
        ],
      ),
    );
  }

  Widget _careRow({
    required IconData icon,
    required Color color,
    required String label,
    required String cycle,
    required int daysLeft,
    required VoidCallback onTap,
  }) {
    final needsNow = daysLeft <= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySemiBold),
                const SizedBox(height: 2),
                Text('$cycle · ${needsNow ? "今天该做啦" : "$daysLeft天后"}',
                  style: AppTypography.caption.copyWith(
                    color: needsNow ? AppColors.accent : AppColors.textSecondary)),
              ],
            ),
          ),
          if (needsNow)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
                child: const Text('完成', style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.softCard, borderRadius: BorderRadius.circular(18)),
              child: Text('$daysLeft天后', style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  void _careSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildDiary(Plant p) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final diaries = store.getDiariesForPlant(p.id);
        if (diaries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('生长日记', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.softCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.book_outlined,
                        size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text('还没有日记',
                        style: AppTypography.caption),
                      const SizedBox(height: 4),
                      Text('浇水后会自动记录',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('生长日记', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
                  Row(
                    children: [
                      Text('${diaries.length}条', style: AppTypography.label),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openDiaryEditor(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 2),
                              Text('记一笔',
                                style: TextStyle(fontFamily: 'NunitoSans', fontSize: 12,
                                  fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildGrowthComparison(context, diaries),
              ...diaries.take(3).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.softCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: d.imagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(d.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                  Icon(Icons.eco, color: AppColors.primary, size: 24),
                              ),
                            )
                          : Icon(Icons.water_drop,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.note ?? '养护瞬间',
                              style: AppTypography.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${d.createdAt.month}月${d.createdAt.day}日 ${d.createdAt.hour}:${d.createdAt.minute.toString().padLeft(2, '0')}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  /// 成长对比拼图：取该植物所有日记中最早与最新两张照片做 Before/After
  Widget _buildGrowthComparison(BuildContext context, List<DiaryEntry> diaries) {
    // 把每条日记的所有图片（主图 + 附加图）都展开
    final imageRecords = <({String path, DateTime createdAt, String? note})>[];
    for (final d in diaries) {
      for (final path in d.allImagePaths) {
        if (path.isNotEmpty) {
          imageRecords.add((path: path, createdAt: d.createdAt, note: d.note));
        }
      }
    }

    if (imageRecords.length < 2) {
      return _buildGrowthComparisonHint(context, imageRecords.length);
    }

    final newest = imageRecords.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
    final oldest = imageRecords.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);

    final fmt = (DateTime d) => '${d.month}月${d.day}日';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('成长对比', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
              const Spacer(),
              Text('${fmt(oldest.createdAt)} → ${fmt(newest.createdAt)}',
                style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                _compareImage(oldest),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(height: 4),
                    Text('成长', style: AppTypography.caption.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 8),
                _compareImage(newest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 成长对比空状态：引导用户记录更多带图日记
  Widget _buildGrowthComparisonHint(BuildContext context, int imageCount) {
    final remaining = 2 - imageCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成长对比', style: AppTypography.bodySemiBold),
                  const SizedBox(height: 2),
                  Text(
                    imageCount == 0
                        ? '记录 2 张带图日记，就能看到植物成长变化'
                        : '再记录 $remaining 张带图日记，即可生成对比',
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openDiaryEditor(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('记一笔',
                  style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13,
                    fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareImage(({String path, DateTime createdAt, String? note}) record) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(record.path),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: AppColors.softCard,
                child: Icon(Icons.eco, color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            record.note != null && record.note!.isNotEmpty
                ? (record.note!.length > 12 ? '${record.note!.substring(0, 12)}…' : record.note!)
                : '养护瞬间',
            style: AppTypography.caption.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShareBar(BuildContext context, Plant p) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.scanBg.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GradientButton(
        label: '分享给好友',
        icon: Icons.share,
        onTap: () {
          final store = context.read<AppStore>();
          ShareCardService.sharePlantCard(context, p, store);
        },
      ),
    );
  }

  void _openDiaryEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryEditorScreen(initialPlantId: plant.id),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: AppColors.primary),
              title: const Text('分享植物'),
              onTap: () {
                Navigator.pop(ctx);
                ShareCardService.sharePlantCard(context, plant,
                  context.read<AppStore>());
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primary),
              title: const Text('编辑信息'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditPlantScreen(plant: plant),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('删除植物', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                context.read<AppStore>().removePlant(plant.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
