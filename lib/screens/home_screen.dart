import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../models/plant.dart';
import '../widgets/plant_image.dart';
import '../widgets/plant_card.dart';
import '../widgets/app_logo.dart';
import 'add_plant_screen.dart';
import 'diary_screen.dart';

/// Screen 1 - 首页 (作为 Tab 内容，不含 TabBar)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroAndGreeting(store),
              _buildWaterAndMapRow(context, store),
              const SizedBox(height: 20),
              _buildPlantGrid(context, store.plants),
            ],
          ),
        );
      },
    );
  }

  /// 合并品牌插图与问候语，顶部不再留大块空白
  Widget _buildHeroAndGreeting(AppStore store) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '早上好' : (hour < 18 ? '下午好' : '晚上好');
    final wateringCount = store.wateringCount;

    return Container(
      width: double.infinity,
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.softCard, AppColors.bg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting，植物管家',
                    style: AppTypography.pageTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    wateringCount > 0
                        ? '有 $wateringCount 株植物等你浇水'
                        : '你的植物今天都很健康',
                    style: AppTypography.caption.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const AppLogo(size: 64),
          ],
        ),
      ),
    );
  }


  Widget _buildWaterAndMapRow(BuildContext context, AppStore store) {
    final wateringCount = store.wateringCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 浇水卡片 (缩小版)
          GestureDetector(
            onTap: () => _showWateringSheet(context, store),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.buttonShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.water_drop, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今日浇水', style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.white,
                      )),
                      Text('$wateringCount株待浇水', style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      )),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 地图按钮 (独立) — push 到 nearby 页面
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/nearby'),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.mapButtonGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.buttonShadow,
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 24),
            ),
          ),
          const Spacer(),
          // 生长日记快捷入口
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiaryScreen()),
            ),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.softCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.book_outlined,
                color: AppColors.primary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid(BuildContext context, List<Plant> plants) {
    // 空状态引导
    if (plants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('我的植物', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Icon(Icons.eco, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('还没有植物', style: AppTypography.caption),
            const SizedBox(height: 16),
            GradientButton(
              label: '添加第一株植物',
              icon: Icons.add,
              width: 200, height: 44,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
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
              Text('我的植物', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
              Row(
                children: [
                  Text('共 ${plants.length} 株',
                    style: AppTypography.label.copyWith(color: AppColors.primary)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
                    ),
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return PlantCard(
                name: plant.name,
                imagePath: plant.imagePath,
                healthStatus: plant.healthStatus,
                onTap: () => Navigator.pushNamed(
                  context, '/detail', arguments: plant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWateringSheet(BuildContext context, AppStore store) {
    final needWater = store.plants.where((p) => p.daysUntilWatering <= 0).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('今日浇水', style: AppTypography.cardTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text('${needWater.length} 株植物等你浇水', style: AppTypography.caption),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: needWater.length,
                itemBuilder: (ctx, i) => _WateringItem(plant: needWater[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WateringItem extends StatelessWidget {
  final Plant plant;
  const _WateringItem({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final updated = store.getPlant(plant.id) ?? plant;
        final isDone = updated.daysUntilWatering > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDone ? AppColors.softCard : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              PlantImage(plantName: updated.name, imagePath: updated.imagePath, width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.name, style: AppTypography.bodySemiBold),
                    Text(
                      isDone ? '已浇水 ✓' : '今天该浇水了',
                      style: AppTypography.caption.copyWith(
                        color: isDone ? AppColors.primary : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDone)
                GestureDetector(
                  onTap: () => store.waterPlant(plant.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('浇水', style: TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
