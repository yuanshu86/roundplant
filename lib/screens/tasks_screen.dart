import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../store/app_store.dart';
import '../models/plant.dart';

/// Screen 4 - 养护任务 (Tab 内容)
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

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
        child: Row(
          children: [
            SizedBox(
              width: 96, height: 96,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(96, 96),
                    painter: ProgressRingPainter(progress),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'VarelaRound',
                            fontSize: 20, color: Colors.white,
                          )),
                        Text('完成',
                          style: TextStyle(
                            fontFamily: 'NunitoSans', fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日任务',
                    style: TextStyle(fontFamily: 'VarelaRound',
                      fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('$completed / $total 已完成',
                    style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 8),
                  Text('加油，植物们在等你！',
                    style: TextStyle(fontFamily: 'NunitoSans', fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, AppStore store, List<CareTask> tasks) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('今日任务', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Icon(Icons.check_circle, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
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
          Text('今日任务', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
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
              _achievementCard(Icons.local_fire_department,
                '${store.maxCareDays}', '天连续养护'),
              const SizedBox(width: 8),
              _achievementCard(Icons.eco,
                '${store.totalPlants}', '株养护植物'),
              const SizedBox(width: 8),
              _achievementCard(Icons.star,
                '${store.totalPoints}', '获得积分'),
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
            Text(value, style: AppTypography.bodySemiBold.copyWith(
              fontSize: 16, color: AppColors.primary)),
            Text(label, style: AppTypography.badge),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final CareTask task;
  final VoidCallback onToggle;

  const _TaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.softCard : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTypography.bodySemiBold.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
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

/// 进度环画笔
class ProgressRingPainter extends CustomPainter {
  final double progress;
  ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.3));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
