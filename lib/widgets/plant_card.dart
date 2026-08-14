import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/plant_image.dart';

/// 植物卡片组件
class PlantCard extends StatelessWidget {
  final String name;
  final String? imagePath; // 本地图片路径（可选）
  final String healthStatus;
  final VoidCallback? onTap;

  const PlantCard({
    super.key,
    required this.name,
    this.imagePath,
    required this.healthStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = healthStatus == '健康';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSpacing.plantCardWidth,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusCard),
              ),
              child: SizedBox(
                height: AppSpacing.plantCardWidth,
                width: double.infinity,
                child: PlantImage(plantName: name, imagePath: imagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.bodySemiBold),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco,
                            size: 10,
                            color: isHealthy
                                ? AppColors.primary
                                : AppColors.accent),
                        const SizedBox(width: 4),
                        Text(healthStatus,
                            style: TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isHealthy
                                  ? AppColors.primary
                                  : AppColors.accent,
                            )),
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
}

/// 渐变按钮
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: AppColors.buttonShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTypography.buttonText),
          ],
        ),
      ),
    );
  }
}

/// 健康徽章
class HealthBadge extends StatelessWidget {
  final String text;
  const HealthBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ],
      ),
    );
  }
}

/// 养护参数软卡
class CareParamCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CareParamCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.bodySemiBold),
        ],
      ),
    );
  }
}
