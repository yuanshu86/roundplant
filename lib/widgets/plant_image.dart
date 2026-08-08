import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 植物图片组件
/// 有 imagePath 时显示真实照片，否则用渐变+图标占位
class PlantImage extends StatelessWidget {
  final String plantName;
  final String? imagePath;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isHero;

  const PlantImage({
    super.key,
    required this.plantName,
    this.imagePath,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    // 有本地图片时显示真实照片
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final (icon, gradientColors) = _getPlantVisual(plantName);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          icon,
          size: isHero ? 80 : 40,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  /// 根据植物名匹配图标和配色
  (IconData, List<Color>) _getPlantVisual(String name) {
    switch (name) {
      case '龟背竹':
        return (Icons.eco, [const Color(0xFF15803D), const Color(0xFF059669)]);
      case '白桃星美人':
        return (Icons.local_florist, [const Color(0xFFD97706), const Color(0xFFF59E0B)]);
      case '绿萝':
        return (Icons.vpn_key, [const Color(0xFF059669), const Color(0xFF10B981)]);
      case '琴叶榕':
        return (Icons.park, [const Color(0xFF0D9488), const Color(0xFF15803D)]);
      default:
        return (Icons.eco, [AppColors.primary, AppColors.secondary]);
    }
  }
}

/// 群植 Hero 占位 — 多植物组合
class HeroPlantImage extends StatelessWidget {
  final double? width;
  final double? height;

  const HeroPlantImage({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 220,
      height: height ?? 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15803D), Color(0xFF059669), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 30, top: 40,
            child: Icon(Icons.eco, size: 50, color: Colors.white.withValues(alpha: 0.4)),
          ),
          Positioned(
            right: 25, top: 25,
            child: Icon(Icons.local_florist, size: 45, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Positioned(
            left: 45, bottom: 35,
            child: Icon(Icons.park, size: 55, color: Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned(
            right: 35, bottom: 30,
            child: Icon(Icons.grain, size: 40, color: Colors.white.withValues(alpha: 0.25)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '圆形植物',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 日记缩略图占位
class DiaryThumbnail extends StatelessWidget {
  final int index;

  const DiaryThumbnail({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF15803D), const Color(0xFF059669)],
      [const Color(0xFF059669), const Color(0xFF0D9488)],
      [const Color(0xFFD97706), const Color(0xFFF59E0B)],
    ];
    final c = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt,
          size: 24,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
