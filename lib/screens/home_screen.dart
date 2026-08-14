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
import 'package:url_launcher/url_launcher.dart';
import 'add_plant_screen.dart';
import 'diary_screen.dart';

/// Screen 1 - 首页（陪伴感花园）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (_isLoadingWeather) return;
    setState(() => _isLoadingWeather = true);
    final w = await WeatherService.current();
    if (mounted) {
      setState(() {
        _weather = w;
        _isLoadingWeather = false;
      });
    }
  }

  /// 城市选择 BottomSheet：自动定位失败时让用户手动选本地城市，支持搜索。
  void _pickCity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('选择城市',
                        style: AppTypography.pageTitle.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('手动选一个城市，天气就显示该城市的实时情况',
                        style: AppTypography.caption
                            .copyWith(fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(height: 12),
                    // 搜索框
                    TextField(
                      controller: controller,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: '搜索城市（如：杭州）',
                        hintStyle: AppTypography.caption
                            .copyWith(color: AppColors.textHint),
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.softCard,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // 城市列表（支持滚动 + 搜索过滤）
                    Flexible(
                      child: _CityPickerList(
                        controller: controller,
                        onSelected: (c) async {
                          Navigator.pop(ctx);
                          await WeatherService.saveManualCity(
                              c.name, c.lat, c.lon);
                          _loadWeather();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
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
    final w = _weather;

    return GestureDetector(
      onTap: _loadWeather,
      behavior: HitTestBehavior.opaque,
      child: FrostedCard(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting，${store.myNickname ?? '植物管家'}',
                    style: AppTypography.pageTitle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  if (_isLoadingWeather)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '正在获取天气…',
                          style: AppTypography.caption.copyWith(fontSize: 13),
                        ),
                      ],
                    )
                  else if (w != null && w.temperature != null)
                    Row(
                      children: [
                        Icon(_weatherIcon(w.weatherCode),
                            size: 16, color: AppColors.primaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${w.temperature!.round()}°',
                          style: AppTypography.caption.copyWith(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          w.condition,
                          style: AppTypography.caption.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _pickCity,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  w.city != null ? '· ${w.city}' : '· 切换城市',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '⚠️ 天气获取失败，点击重试（请检查网络）',
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (w != null && w.note != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        w.note!,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  Text(
                    w?.greeting ?? '今天也别忘了照顾你的植物~',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const AppLogo(size: 44),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '圆形植物',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamilyFallback: [
                        'PingFang SC',
                        'Heiti SC',
                        'Microsoft YaHei',
                        'Noto Sans SC',
                        'Source Han Sans SC',
                        'sans-serif',
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 天气代码(WMO) → 图标
  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 2) return Icons.wb_cloudy;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.blur_on;
    if (code >= 51 && code <= 67) return Icons.umbrella;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 86) return Icons.umbrella;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.wb_sunny;
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
            child: FrostedCard(
              padding: const EdgeInsets.all(14),
              radius: 28,
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
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.3)),
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
                  context,
                  '/detail',
                  arguments: plant,
                ),
                onLongPress: () => TagEditorSheet.show(context, plant),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 首页快捷入口：只放底部 Tab 没有的功能，避免重复。
  /// 三宫格 = 我的成就 / 生长日记 / 年度报告；下方固定官网入口 banner。
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickAction(
                icon: const Icon(Icons.emoji_events,
                    size: 22, color: Colors.white),
                label: '我的成就',
                gradient: AppColors.primaryGradient,
                onTap: () => Navigator.pushNamed(context, '/achievement'),
              ),
              _QuickAction(
                icon: TabIcons.diary(size: 22, color: AppColors.primary),
                label: '生长日记',
                color: AppColors.glassCardTint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiaryScreen()),
                ),
              ),
              _QuickAction(
                icon: Icon(Icons.bar_chart, size: 22, color: AppColors.primary),
                label: '年度报告',
                color: AppColors.glassCardTint,
                onTap: () => Navigator.pushNamed(context, '/report'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildOfficialBanner(context),
      ],
    );
  }

  /// 官网入口：点击跳 roundplant.com（外部浏览器打开）
  Widget _buildOfficialBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openOfficial(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.glassCardTint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('圆形植物官网',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('roundplant.com · 了解更多养花知识',
                        style: AppTypography.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOfficial(BuildContext context) async {
    final url = Uri.parse('https://roundplant.com');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开官网，请稍后再试')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开官网，请稍后再试')),
        );
      }
    }
  }

  void _showWateringSheet(BuildContext context, AppStore store) {
    final needWater =
        store.plants.where((p) => p.daysUntilWatering <= 0).toList();
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
              width: 40,
              height: 4,
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
          color: AppColors.glassCardTint,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.glassBorder, width: 1.5),
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard - 4),
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
                              Text(statusEmoji,
                                  style: const TextStyle(fontSize: 12)),
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
                      width: 36,
                      height: 36,
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
          boxShadow:
              gradient != null ? AppColors.buttonShadow : AppColors.cardShadow,
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
                  color:
                      gradient != null ? Colors.white : AppColors.textPrimary,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('浇水',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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

/// 城市选择器：按搜索框内容过滤，网格展示城市名。
class _CityPickerList extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<ManualCity> onSelected;

  const _CityPickerList({
    required this.controller,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();
    final cities = query.isEmpty
        ? WeatherService.hotCities
        : WeatherService.hotCities
            .where((c) => c.name.contains(query))
            .toList();

    if (cities.isEmpty) {
      return Center(
        child: Text('未找到 "$query"，试试别的城市',
            style: AppTypography.caption
                .copyWith(fontSize: 13, color: AppColors.textHint)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: cities.length,
      itemBuilder: (ctx, i) {
        final c = cities[i];
        return GestureDetector(
          onTap: () => onSelected(c),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              c.name,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
