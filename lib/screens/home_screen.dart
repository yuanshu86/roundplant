import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/frosted.dart';
import '../widgets/water_ring.dart';
import '../widgets/plant_tag.dart';
import '../widgets/tag_editor_sheet.dart';
import '../widgets/plant_image.dart';
import '../store/app_store.dart';
import '../models/plant.dart';
import '../services/weather_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/tab_icons.dart';
import 'add_plant_screen.dart';
import 'diary_screen.dart';

/// Screen 1 - 首页（陪伴感花园）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _weatherText = '☀️ 今天阳光充足，适合浇水';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final text = await WeatherService.greeting();
    if (mounted) {
      setState(() => _weatherText = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(store),
              const SizedBox(height: 28),
              _buildWateringRitual(context, store),
              const SizedBox(height: 32),
              _buildPlantCarousel(context, store.plants),
              const SizedBox(height: 28),
              _buildQuickActions(context),
            ],
          ),
        );
      },
    );
  }

  /// 顶部问候 + 天气联动
  Widget _buildGreeting(AppStore store) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '早安' : (hour < 18 ? '午安' : '晚安');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.softCard, AppColors.bg],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting，植物管家',
                  style: AppTypography.pageTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  _weatherText,
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppColors.cardShadow,
            ),
            child: const AppLogo(size: 36),
          ),
        ],
      ),
    );
  }

  /// 浇水仪式：水滴进度环 + 俏皮话
  Widget _buildWateringRitual(BuildContext context, AppStore store) {
    final needWater = store.wateringCount;
    final total = store.totalPlants;

    String subtitle;
    switch (needWater) {
      case 0:
        subtitle = '今天很轻松，植物都喝饱了';
      case 1:
        subtitle = '1 位小伙伴渴了，别让它等太久';
      case 2:
        subtitle = '2 位小伙伴排队等水喝';
      case 3:
        subtitle = '3 位小伙伴渴了，今天阳光正好哦';
      default:
        subtitle = '$needWater 位小伙伴渴了，快行动起来';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showWateringSheet(context, store),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.cardShadow,
              ),
              child: WaterDropRing(needWater: needWater, total: total),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日浇水',
                  style: AppTypography.sectionTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (needWater > 0)
                  GestureDetector(
                    onTap: () => _showWateringSheet(context, store),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '去浇水 →',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 横向滑动植物卡片
  Widget _buildPlantCarousel(BuildContext context, List<Plant> plants) {
    if (plants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('我的植物',
                style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.eco,
                      size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('还没有植物', style: AppTypography.caption),
                  const SizedBox(height: 16),
                  _AddPlantButton(width: 200),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('我的植物',
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
              Row(
                children: [
                  Text('共 ${plants.length} 株',
                      style: AppTypography.label
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(width: 8),
                  _AddPlantButton(size: 28),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 290,
          child: PageView.builder(
            padEnds: false,
            controller: PageController(viewportFraction: 0.72),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return _PlantCarouselCard(
                plant: plant,
                onTap: () => Navigator.pushNamed(
                  context, '/detail', arguments: plant,
                ),
                onLongPress: () => TagEditorSheet.show(context, plant),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 地图 / 日记 / 添加 快捷入口
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: TabIcons.nearby(
              active: false,
              size: 22,
              color: Colors.white,
            ),
            label: '附近花友',
            gradient: AppColors.mapButtonGradient,
            onTap: () => Navigator.pushNamed(context, '/nearby'),
          ),
          _QuickAction(
            icon: TabIcons.diary(size: 22, color: AppColors.primary),
            label: '生长日记',
            color: AppColors.cardWhite,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiaryScreen()),
            ),
          ),
          _QuickAction(
            icon: TabIcons.scan(size: 22, color: AppColors.primary),
            label: 'AI 识别',
            color: AppColors.cardWhite,
            onTap: () => Navigator.pushNamed(context, '/scan'),
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
      builder: (ctx) => FrostedGlass(
        tint: AppColors.frostedTint,
        radius: const BorderRadius.vertical(top: Radius.circular(32)),
        height: MediaQuery.of(ctx).size.height * 0.6,
        padding: EdgeInsets.zero,
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

/// 横向滑动卡片：圆角大图 + 斜标签 + 状态表情 + 警示光晕
class _PlantCarouselCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PlantCarouselCard({
    required this.plant,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = plant.healthStatus == '健康';
    final statusColor = isHealthy ? AppColors.success : AppColors.accent;
    final statusEmoji = isHealthy ? '😊' : '💧';
    final statusText = isHealthy ? '健康' : '需关注';
    final hasWarning = !isHealthy;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: hasWarning
              ? [
                  ...AppColors.cardShadow,
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard - 4),
                      child: PlantImage(
                        plantName: plant.name,
                        imagePath: plant.imagePath,
                        borderRadius: 0,
                      ),
                    ),
                    // 斜标签（最多 3 个，按位置分布）
                    if (plant.tags.isNotEmpty) ...[
                      for (var i = 0; i < plant.tags.length; i++)
                        _tagPosition(i, plant.tags[i]),
                    ],
                  ],
                ),
              ),
            ),
            // 信息区
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.name,
                            style: AppTypography.bodySemiBold
                                .copyWith(fontSize: 16)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(statusEmoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(statusText,
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plant.daysUntilWatering <= 0)
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop,
                          color: Color(0xFF3B82F6), size: 18),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagPosition(int index, PlantTag tag) {
    final positions = [
      const Alignment(-0.85, -0.78),
      const Alignment(0.85, -0.65),
      const Alignment(-0.82, 0.65),
    ];
    final rotations = [-0.45, 0.35, -0.25];
    return PlantTagWidget(
      tag: tag,
      alignment: positions[index % positions.length],
      rotation: rotations[index % rotations.length],
    );
  }
}

class _AddPlantButton extends StatelessWidget {
  final double size;
  final double? width;

  const _AddPlantButton({this.size = 28, this.width});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width ?? size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(width != null ? Icons.add : Icons.add,
          color: Colors.white, size: width != null ? 20 : 18),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
      ),
      child: width != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(width: 6),
                Text('添加植物',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
              ],
            )
          : child,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: gradient != null ? AppColors.buttonShadow : AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 22, height: 22, child: icon),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: gradient != null ? Colors.white : AppColors.textPrimary,
                )),
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
              PlantImage(
                  plantName: updated.name,
                  imagePath: updated.imagePath,
                  width: 40,
                  height: 40,
                  borderRadius: 12),
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
