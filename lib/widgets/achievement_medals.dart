import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 个人中心的三枚悬挂园艺勋章（金 / 银 / 铜）。
class AchievementMedals extends StatelessWidget {
  final int plants;
  final int days;
  final int points;

  const AchievementMedals({
    super.key,
    required this.plants,
    required this.days,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _Medal(
              color: const Color(0xFFF5C518),
              icon: Icons.eco,
              value: '$plants',
              label: '养护植物',
            ),
            const SizedBox(width: 10),
            _Medal(
              color: const Color(0xFFC0C7CF),
              icon: Icons.local_fire_department,
              value: '$days',
              label: '连续天数',
            ),
            const SizedBox(width: 10),
            _Medal(
              color: const Color(0xFFCD7F32),
              icon: Icons.star,
              value: '$points',
              label: '总积分',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.softCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '第 $days 次日出守护 · 你已坚持得很棒',
            style: AppTypography.caption.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

class _Medal extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _Medal({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // 挂绳
          Container(width: 2, height: 14, color: AppColors.border),
          // 奖牌
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.92), color],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'VarelaRound',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.badge),
        ],
      ),
    );
  }
}
