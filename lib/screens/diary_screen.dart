import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../models/plant.dart';
import '../widgets/plant_image.dart';
import '../widgets/empty_garden_illustration.dart';
import 'diary_editor_screen.dart';

/// 生长日记 — 时间线列表页
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String? _filterPlantId;

  List<DiaryEntry> _filteredDiaries(AppStore store) {
    final all = store.diaries;
    if (_filterPlantId == null) return all;
    return all.where((d) => d.plantId == _filterPlantId).toList();
  }

  Plant? _getPlant(AppStore store, String plantId) => store.getPlant(plantId);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final diaries = _filteredDiaries(store);
        return Container(
          color: AppColors.bg,
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(store, diaries.isNotEmpty),
              if (diaries.isNotEmpty) _buildFilterChips(store),
              Expanded(
                child: diaries.isEmpty
                    ? _buildEmpty(store)
                    : _buildTimeline(diaries, store),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppStore store, bool showFab) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('生长日记', style: AppTypography.pageTitle),
              const SizedBox(height: 2),
              Text('${store.diaryCount} 条记录',
                style: AppTypography.caption),
            ],
          ),
          if (showFab)
            GestureDetector(
              onTap: () => _openEditor(store),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.buttonShadow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text('写日记',
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppStore store) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _chip('全部', null, isSelected: _filterPlantId == null),
          ...store.plants.map((p) => _chip(p.name, p.id,
            isSelected: _filterPlantId == p.id)),
        ],
      ),
    );
  }

  Widget _chip(String label, String? plantId, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterPlantId = plantId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.softCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  /// 空状态：温暖插画 + 故事化引导语 + 漂浮种子按钮
  Widget _buildEmpty(AppStore store) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GardenEmptyIllustration(size: MediaQuery.of(context).size.width * 0.62),
            const SizedBox(height: 20),
            Text('每一片新叶都值得被文字偏爱',
              style: AppTypography.cardTitle.copyWith(fontSize: 17),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('浇水会自动记录，也可以写下你和它的小故事',
              style: AppTypography.caption, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            SeedFab(onTap: () => _openEditor(store), label: '写第一篇日记'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<DiaryEntry> diaries, AppStore store) {
    final fmt = DateFormat('M月d日 HH:mm');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, AppSpacing.tabBarHeight + 20),
      itemCount: diaries.length,
      itemBuilder: (context, index) {
        final entry = diaries[index];
        final plant = _getPlant(store, entry.plantId);
        final isLast = index == diaries.length - 1;
        return _buildDiaryCard(entry, plant, fmt, isLast);
      },
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry, Plant? plant, DateFormat fmt, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间轴左侧线 + 圆点
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12, height: 12,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softCard, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // 日记卡片
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间 + 植物名
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(fmt.format(entry.createdAt),
                        style: AppTypography.caption),
                      const Spacer(),
                      if (plant != null) ...[
                        PlantImage(
                          plantName: plant.name,
                          imagePath: plant.imagePath,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(plant.name,
                          style: AppTypography.label.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  // 照片（单图 / 多图网格）
                  if (entry.allImagePaths.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDiaryImages(entry.allImagePaths),
                  ],
                  // 心得文字
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(entry.note!,
                      style: AppTypography.body.copyWith(height: 1.6)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日记照片：多图时网格展示，单图时大卡片展示
  Widget _buildDiaryImages(List<String> paths) {
    if (paths.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(paths.first),
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 180,
            color: AppColors.softCard,
            child: Center(
              child: Icon(Icons.broken_image, size: 48, color: AppColors.textHint),
            ),
          ),
        ),
      );
    }

    final displayPaths = paths.take(4).toList();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: paths.length == 2 ? 2 : 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1,
      children: displayPaths.asMap().entries.map((e) {
        final idx = e.key;
        final path = e.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.softCard,
                  child: Icon(Icons.broken_image, color: AppColors.textHint),
                ),
              ),
              if (paths.length > 4 && idx == 3)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: Text('+${paths.length - 3}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _openEditor(AppStore store) {
    if (store.plants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加一株植物')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
    ).then((_) => setState(() {}));
  }
}
