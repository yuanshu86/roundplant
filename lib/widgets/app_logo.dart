import 'package:flutter/material.dart';

/// 圆形植物品牌 LOGO
/// 与 Android 启动图标同源（assets/images/roundplant_logo.png），透明背景。
/// 复用于首页 Hero、关于页、分享卡等任何需要品牌标识的位置。
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = 64,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/roundplant_logo.png',
      width: size,
      height: size,
      fit: fit,
    );
  }
}
