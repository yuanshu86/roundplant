import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';

/// 成就 / 勋章系统（游戏化留存）
///
/// 完全基于 AppStore 现有 getter（totalPlants / maxCareDays / diaryCount /
/// completedTaskCount / totalPoints）计算解锁状态，无需任何后端或新增字段。
class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final unlockedCount =
            _achievements.where((a) => a.unlocked(store)).length;
        final total = _achievements.length;
        final level = _levelName(unlockedCount);

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
                    children: [
                      _progressCard(unlockedCount, total, level),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                        children: _achievements
                            .map((a) => _card(a, a.unlocked(store)))
                            .toList(),
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
          Text('我的成就', style: AppTypography.pageTitle),
          const SizedBox(height: 2),
          Text('养花路上的每一份坚持都被看见', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _progressCard(int unlocked, int total, String level) {
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text('已解锁 $unlocked / $total 枚成就',
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
                          fontSize: 13,
                          color: Colors.white70,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(_Achievement a, bool unlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.cardWhite : AppColors.softCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: unlocked ? AppColors.cardShadow : null,
        border:
            unlocked ? null : Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              a.icon,
              color: unlocked ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            a.title,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 15,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            a.desc,
            style: AppTypography.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            unlocked ? '已达成' : '目标 ${a.target} ${a.unit}',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontFamilyFallback: const [
                'PingFang SC',
                'Heiti SC',
                'Microsoft YaHei',
                'Noto Sans SC',
                'Source Han Sans SC',
                'sans-serif',
              ],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 成就定义（解锁状态完全由 AppStore getter 推导）
class _Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final int target;
  final String unit;
  final int Function(AppStore) current;

  const _Achievement({
    required this.title,
    required this.desc,
    required this.icon,
    required this.target,
    required this.unit,
    required this.current,
  });

  bool unlocked(AppStore s) => current(s) >= target;
}

String _levelName(int unlocked) {
  if (unlocked >= 9) return '植物大师';
  if (unlocked >= 6) return '园艺达人';
  if (unlocked >= 3) return '护花使者';
  return '萌芽新手';
}

/// 全部成就列表（顺序即展示顺序）。
const List<_Achievement> _achievements = [
  _Achievement(
    title: '初心萌芽',
    desc: '养下你的第一株植物',
    icon: Icons.spa,
    target: 1,
    unit: '株',
    current: _totalPlants,
  ),
  _Achievement(
    title: '小有规模',
    desc: '同时养护 5 株植物',
    icon: Icons.local_florist,
    target: 5,
    unit: '株',
    current: _totalPlants,
  ),
  _Achievement(
    title: '植物大户',
    desc: '同时养护 20 株植物',
    icon: Icons.forest,
    target: 20,
    unit: '株',
    current: _totalPlants,
  ),
  _Achievement(
    title: '初记日常',
    desc: '写下 3 篇生长日记',
    icon: Icons.edit_note,
    target: 3,
    unit: '篇',
    current: _diaryCount,
  ),
  _Achievement(
    title: '日记作家',
    desc: '写下 20 篇生长日记',
    icon: Icons.menu_book,
    target: 20,
    unit: '篇',
    current: _diaryCount,
  ),
  _Achievement(
    title: '护花使者',
    desc: '一株植物养护满 30 天',
    icon: Icons.favorite,
    target: 30,
    unit: '天',
    current: _maxCareDays,
  ),
  _Achievement(
    title: '养护大师',
    desc: '一株植物养护满 365 天',
    icon: Icons.emoji_events,
    target: 365,
    unit: '天',
    current: _maxCareDays,
  ),
  _Achievement(
    title: '行动派',
    desc: '完成 10 项养护任务',
    icon: Icons.check_circle,
    target: 10,
    unit: '项',
    current: _completedTaskCount,
  ),
  _Achievement(
    title: '积分达人',
    desc: '累计获得 100 积分',
    icon: Icons.stars,
    target: 100,
    unit: '分',
    current: _totalPoints,
  ),
  _Achievement(
    title: '园艺宗师',
    desc: '累计获得 500 积分',
    icon: Icons.workspace_premium,
    target: 500,
    unit: '分',
    current: _totalPoints,
  ),
];

int _totalPlants(AppStore s) => s.totalPlants;
int _diaryCount(AppStore s) => s.diaryCount;
int _maxCareDays(AppStore s) => s.maxCareDays;
int _completedTaskCount(AppStore s) => s.completedTaskCount;
int _totalPoints(AppStore s) => s.totalPoints;
