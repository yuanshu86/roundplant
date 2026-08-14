import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../models/plant.dart';

/// 年度植物报告 / 生长曲线
///
/// 纯本地计算：汇总 AppStore getter，并用 DiaryEntry.createdAt 按自然月聚合
/// 画出「生长活跃度」柱状图（手写 Container 柱状，不引入图表依赖）。
class AnnualReportScreen extends StatelessWidget {
  const AnnualReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final monthly = _monthlyDiaries(store.diaries);
        final year = DateTime.now().year;

        return Container(
          color: AppColors.bg,
          child: Column(
            children: [
              const SizedBox(height: 40),
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    AppSpacing.tabBarHeight + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCard(store, year),
                      const SizedBox(height: 18),
                      Text('养花数据一览', style: AppTypography.sectionTitle),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _statCard('植物总数', '${store.totalPlants}', '株',
                              Icons.local_florist),
                          _statCard('最长养护', '${store.maxCareDays}', '天',
                              Icons.favorite),
                          _statCard('日记总数', '${store.diaryCount}', '篇',
                              Icons.menu_book),
                          _statCard(
                              '累计积分', '${store.totalPoints}', '分', Icons.stars),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text('生长活跃度（每月日记）', style: AppTypography.sectionTitle),
                      const SizedBox(height: 12),
                      _chartCard(monthly),
                      const SizedBox(height: 10),
                      Text(
                        '柱子越高，代表那个月你和植物的互动越频繁',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('年度植物报告', style: AppTypography.pageTitle),
          const SizedBox(height: 2),
          Text('陪你养好每一株的小结', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _summaryCard(AppStore store, int year) {
    final text = store.diaryCount == 0
        ? '开始写第一篇生长日记，记录你和植物的小故事吧'
        : '${year} 年你记录了 ${store.diaryCount} 篇日记，最长的植物已陪伴你 ${store.maxCareDays} 天';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontFamilyFallback: [
                  'PingFang SC',
                  'Heiti SC',
                  'Microsoft YaHei',
                  'Noto Sans SC',
                  'Source Han Sans SC',
                  'sans-serif',
                ],
                fontSize: 14,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: AppTypography.pageTitle.copyWith(fontSize: 26)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: AppTypography.caption),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _chartCard(List<int> monthly) {
    final maxV = monthly.reduce((a, b) => a > b ? a : b).toDouble();
    const maxH = 120.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: SizedBox(
        height: maxH + 30,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(12, (i) {
            final v = monthly[i];
            final h = maxV == 0 ? 4.0 : (v / maxV) * maxH;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 14,
                  height: h,
                  decoration: BoxDecoration(
                    color: v > 0 ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${i + 1}',
                    style: AppTypography.caption
                        .copyWith(fontSize: 10, color: AppColors.textHint)),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// 按日记创建时间的自然月聚合（1-12 月）。
  List<int> _monthlyDiaries(List<DiaryEntry> diaries) {
    final counts = List<int>.filled(12, 0);
    for (final d in diaries) {
      counts[d.createdAt.month - 1]++;
    }
    return counts;
  }
}
