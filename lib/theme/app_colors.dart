import 'package:flutter/material.dart';

/// 圆形植物 - 色彩系统
/// 基于 Ardot 设计稿变量集 PlantCare
///
/// 支持浅色 / 深色双主题：凡随主题切换的颜色均为 getter，
/// 由 [mode]（运行时由 [AppStore] 驱动）决定返回浅色还是深色值。
/// 品牌主色、功能色、渐变、阴影在深浅背景下均协调，保持为常量。
class AppColors {
  AppColors._();

  // === 主题模式（运行时由 AppStore 驱动）===
  static ThemeMode _mode = ThemeMode.light;
  static set mode(ThemeMode m) => _mode = m;
  static ThemeMode get mode => _mode;
  static bool get isDark => _mode == ThemeMode.dark;

  // === 主色（深浅同色，作为品牌锚点）===
  static const Color primary = Color(0xFF15803D); // 森林绿
  static const Color secondary = Color(0xFF059669); // 翡翠绿
  static const Color accent = Color(0xFFD97706); // 琥珀橙

  // === 背景 ===
  static const Color _bgLight = Color(0xFFF0FDF4); // 页面背景（浅）
  static const Color _bgDark = Color(0xFF0B1411); // 页面背景（深·墨绿黑）
  static Color get bg => isDark ? _bgDark : _bgLight;

  static const Color _cardWhiteLight = Color(0xFFFFFFFF); // 卡片白（浅）
  static const Color _cardWhiteDark = Color(0xFF142019); // 卡片（深·深绿灰）
  static Color get cardWhite => isDark ? _cardWhiteDark : _cardWhiteLight;

  static const Color _softCardLight = Color(0xFFF0F7F3); // 次级卡片/输入框（浅）
  static const Color _softCardDark = Color(0xFF1B2A22); // 次级卡片/输入框（深）
  static Color get softCard => isDark ? _softCardDark : _softCardLight;

  // === 文字 ===
  static const Color _textPrimaryLight = Color(0xFF1E293B);
  static const Color _textPrimaryDark = Color(0xFFE9F1EC);
  static Color get textPrimary => isDark ? _textPrimaryDark : _textPrimaryLight;

  static const Color _textSecondaryLight = Color(0xFF64748B);
  static const Color _textSecondaryDark = Color(0xFFA6B4AB);
  static Color get textSecondary =>
      isDark ? _textSecondaryDark : _textSecondaryLight;

  static const Color _textHintLight = Color(0xFF94A3B8);
  static const Color _textHintDark = Color(0xFF73827A);
  static Color get textHint => isDark ? _textHintDark : _textHintLight;

  // === 边框/分割线 ===
  static const Color _borderLight = Color(0xFFE2EFE7);
  static const Color _borderDark = Color(0xFF24332B);
  static Color get border => isDark ? _borderDark : _borderLight;

  static const Color _dividerLight = Color(0xFFE2EFE7);
  static const Color _dividerDark = Color(0xFF24332B);
  static Color get divider => isDark ? _dividerDark : _dividerLight;

  // === 功能色（深浅通用）===
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // === 特殊场景（保持常量）===
  static const Color scanBg = Color(0xFF0A2E1A); // AI识别暗绿背景
  static const Color mapRing = Color(0xFF86C8A8); // 地图距离环
  static const Color mapTerrain = Color(0xFFDCFCE7); // 地图地形
  static const Color dimOverlay = Color(0x800A2E1A); // 半透明蒙层

  // === 品牌色 (分享目标) ===
  static const Color wechat = Color(0xFF07C160);
  static const Color xiaohongshu = Color(0xFFFF2442);

  // === 渐变（深浅通用，保持常量）===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient mapButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF148533), secondary],
  );

  // === 阴影（深浅通用，保持 getter）===
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get sheetShadow => [
        BoxShadow(
          color: scanBg.withValues(alpha: 0.25),
          blurRadius: 40,
          offset: const Offset(0, -8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.30),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // === 毛玻璃材质 ===
  static const Color frostedTint = Color(0xD9FFFFFF); // 浅色毛玻璃（白 85%）
  static const Color frostedTintDark = Color(0xCC0A2E1A); // 深色毛玻璃
}
