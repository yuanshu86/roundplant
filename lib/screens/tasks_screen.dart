import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../widgets/growth_progress.dart';
import '../widgets/leaf_check.dart';
import '../models/plant.dart';

/// Screen 4 - 养护任务 (Tab 内容)
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const List<String> _quotes = [
    '绿萝说：今天我想喝点柠檬水（酸性肥）哦~',
    '多肉嘟囔：太阳晒得好暖，别忘了我也渴啦',
    '龟背竹伸了个懒腰：新叶子要冒头了，给我点耐心',
    '薄荷在风里招手：浇水时顺便陪我聊两句呗',
    '绣球悄悄话：想要更蓝的花，记得调调土哦',
    '仙人掌打哈欠：少浇点没事，多浇我会闹脾气',
  ];

  static String _quoteOfDay() {
    final idx = DateTime.now().day % _quotes.length;
    return _quotes[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final tasks = store.tasks;
        final completed = store.completedTaskCount;
        final total = tasks.length;
        final progress = total > 0 ? completed / total : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildProgressCard(completed, total, progress),
              const SizedBox(height: 20),
              _buildTaskList(context, store, tasks),
              const SizedBox(height: 20),
              _buildAchievements(store),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 32),
          Text('养护任务', style: AppTypography.pageTitle),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日任务',
                style: TextStyle(
                    fontFamily: 'VarelaRound',
                    fontSize: 16,
                    color: Colors.white)),
            const SizedBox(height: 14),
            GrowthProgressBar(
              progress: progress,
              done: completed,
              total: total,
              textColor: Colors.white,
            ),
            const SizedBox(height: 14),
            Text(_quoteOfDay(),
                style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
      BuildContext context, AppStore store, List<CareTask> tasks) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('今日任务',
                style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Icon(Icons.check_circle,
                size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('今天没有待办任务', style: AppTypography.caption),
            Text('所有植物都浇过水了', style: AppTypography.badge),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日任务',
              style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          ...tasks.map((task) => _TaskItem(
                task: task,
                onToggle: () => store.toggleTask(task.id),
              )),
        ],
      ),
    );
  }

  Widget _buildAchievements(AppStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('成就', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _achievementCard(
                  Icons.local_fire_department, '${store.maxCareDays}', '天连续养护'),
              const SizedBox(width: 8),
              _achievementCard(Icons.eco, '${store.totalPlants}', '株养护植物'),
              const SizedBox(width: 8),
              _achievementCard(Icons.star, '${store.totalPoints}', '获得积分'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.bodySemiBold
                    .copyWith(fontSize: 16, color: AppColors.primary)),
            Text(label, style: AppTypography.badge),
          ],
        ),
      ),
    );
  }
}

String _taskEmoji(String type) => switch (type) {
      'watering' => '💧',
      'fertilizing' => '🧪',
      'pruning' => '✂️',
      _ => '🪴',
    };

class _TaskItem extends StatelessWidget {
  final CareTask task;
  final VoidCallback onToggle;

  const _TaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.softCard : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          LeafCheckButton(
            value: isDone,
            size: 30,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(_taskEmoji(task.taskType),
                style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: AppTypography.bodySemiBold.copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    )),
                Text(task.plantName, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
