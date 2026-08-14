import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 毛玻璃容器：在任意背景上叠加半透明材质 + 背景模糊（iOS 风格）
///
/// 用法：把它当成 Container 用，放在一个 Stack 里、且背后有内容（滚动列表 /
/// 地图 / 页面背景）时，会自动对背后的内容做高斯模糊，呈现真正的毛玻璃质感。
class FrostedGlass extends StatelessWidget {
  final Widget child;
  final double sigma;
  final Color tint;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final double? height;
  final double? width;

  const FrostedGlass({
    super.key,
    required this.child,
    this.sigma = 20,
    this.tint = AppColors.frostedTint,
    this.radius,
    this.padding,
    this.border,
    this.shadows,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: r,
            border: border,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 田园可爱风玻璃卡（B 质感定稿）：半透磨砂 + 白描边 + 顶部高光条
///
/// 在 GardenBackground（奶油光斑）之上叠放时，透出背后景色，
/// 呈现「阳光透过磨砂玻璃洒在奶油花园」的效果。
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double? height;
  final double? width;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppSpacing.radiusCard,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlass(
      height: height,
      width: width,
      tint: AppColors.glassCardTint,
      sigma: 20,
      radius: BorderRadius.circular(radius),
      padding: EdgeInsets.zero,
      border: Border.all(color: AppColors.glassBorder, width: 1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.glassHighlight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 毛玻璃顶部导航栏（iOS 风格：半透明材质 + 底部发丝分隔线 + 居中标题）
///
/// [dark] 为 true 时用于深色背景（如 AI 识别页），材质改为深色毛玻璃、文字白色。
class FrostedTopBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool dark;
  final double height;
  final double titleFontSize;

  const FrostedTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.dark = false,
    this.height = 48,
    this.titleFontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = dark ? Colors.white : AppColors.textPrimary;
    return FrostedGlass(
      height: height,
      tint: dark ? AppColors.frostedTintDark : AppColors.frostedTint,
      radius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      border: Border(
        bottom: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.18) : AppColors.border,
          width: 0.5,
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            leading ?? const SizedBox(width: 32),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (dark ? AppTypography.pageTitle : AppTypography.cardTitle)
                    .copyWith(color: contentColor, fontSize: titleFontSize),
              ),
            ),
            trailing ?? const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}
