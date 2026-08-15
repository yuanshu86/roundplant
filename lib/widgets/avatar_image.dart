import 'package:flutter/material.dart';

/// 统一头像渲染：优先显示网络头像（avatar_url），
/// 未设置/加载失败时回退为「彩色圆底 + 植物图标」立体徽章。
class AvatarImage extends StatelessWidget {
  final String? url;
  final String plantIcon;
  final Color color;
  final double size;

  const AvatarImage({
    super.key,
    this.url,
    this.plantIcon = 'leaf',
    this.color = const Color(0xFF6FA45B),
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: _plantIcon(plantIcon, size * 0.5),
    );
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // 限制解码尺寸（头像渲染尺寸很小，按 3x 解码即可），
        // 同一 URL 会命中 Flutter 内置 ImageCache，进出页面不再重复下载
        cacheWidth: (size * 3).round(),
        cacheHeight: (size * 3).round(),
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }

  Widget _plantIcon(String icon, double s) {
    switch (icon) {
      case 'flower':
        return Icon(Icons.local_florist, color: Colors.white, size: s);
      case 'cactus':
        return Icon(Icons.eco, color: Colors.white, size: s);
      default:
        return Icon(Icons.eco, color: Colors.white, size: s);
    }
  }
}
