import 'package:flutter/material.dart';

/// 圆形植物 - 色彩系统（田园可爱风 · A配色+B玻璃质感 定稿 2026-08-13）
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

  // === 主色（田园草绿系）===
  static const Color primary = Color(0xFF6FA45B); // 田园草绿（主色）
  static const Color primaryDark = Color(0xFF3E6B2F); // 深草绿（立体暗部）
  static const Color primaryMid = Color(0xFF5C8F4A); // 中草绿（立体中间层）
  static const Color leafLight = Color(0xFF8DBE75); // 浅叶绿
  static const Color secondary = Color(0xFF5C8F4A); // 渐变下段（中草绿）

  // === 点缀（田园糖果色）===
  static const Color accent = Color(0xFFE08B57); // 陶土橙（花盆/FAB）
  static const Color accentDark = Color(0xFFC98A4B); // 深陶土
  static const Color sun = Color(0xFFF2C14E); // 柠檬黄（阳光）
  static const Color sunDeep = Color(0xFFE8B93F);
  static const Color petal = Color(0xFFE58A9B); // 花瓣粉
  static const Color petalDeep = Color(0xFFC96F84);
  static const Color sky = Color(0xFF8FBFD4); // 天空蓝
  static const Color skyDeep = Color(0xFF5F97B5);

  /// 品牌绿「用于文字/图标」时的自适应版本（深色提亮，保证 WCAG AA）。
  /// 规则：**做背景/渐变**用 [primary]，**做文字/图标**用 [primaryText]。
  static const Color _primaryTextDark = Color(0xFF9BD98A);
  static Color get primaryText => isDark ? _primaryTextDark : primary;

  static const Color _accentTextDark = Color(0xFFF2B98F);
  static Color get accentText => isDark ? _accentTextDark : accent;

  // === 背景 ===
  static const Color _bgLight = Color(0xFFFAF7EE); // 奶油米底（浅）
  static const Color _bgDark = Color(0xFF0B1411); // 墨绿黑（深）
  static Color get bg => isDark ? _bgDark : _bgLight;

  static const Color _cardWhiteLight = Color(0xFFFFFDF8); // 奶白卡（浅）
  static const Color _cardWhiteDark = Color(0xFF142019); // 深绿灰（深）
  static Color get cardWhite => isDark ? _cardWhiteDark : _cardWhiteLight;

  static const Color _softCardLight = Color(0xFFF3EEDD); // 次级卡/米黄纸感（浅）
  static const Color _softCardDark = Color(0xFF1B2A22); // 次级卡（深）
  static Color get softCard => isDark ? _softCardDark : _softCardLight;

  // === 玻璃（B 质感：半透磨砂）===
  static const Color _glassLight = Color(0x8CFFFFFF); // 白 55%
  static const Color _glassDark = Color(0x99142019); // 墨绿 60%
  static Color get glassCardTint => isDark ? _glassDark : _glassLight;
  static Color get glassHighlight =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0x59FFFFFF); // 顶部高光条
  static Color get glassBorder =>
      isDark ? const Color(0x33FFFFFF) : Colors.white; // 玻璃描边

  // === 文字（暖棕系）===
  static const Color _textPrimaryLight = Color(0xFF4A3F35); // 暖棕（浅）
  static const Color _textPrimaryDark = Color(0xFFE9F1EC); // 浅（深）
  static Color get textPrimary => isDark ? _textPrimaryDark : _textPrimaryLight;

  static const Color _textSecondaryLight = Color(0xFF8A7F6B); // 暖灰（浅）
  static const Color _textSecondaryDark = Color(0xFFA6B4AB);
  static Color get textSecondary =>
      isDark ? _textSecondaryDark : _textSecondaryLight;

  static const Color _textHintLight = Color(0xFFB5AC97);
  static const Color _textHintDark = Color(0xFF73827A);
  static Color get textHint => isDark ? _textHintDark : _textHintLight;

  // === 边框/分割线 ===
  static const Color _borderLight = Color(0xFFE3DCC8); // 米褐（浅）
  static const Color _borderDark = Color(0xFF24332B);
  static Color get border => isDark ? _borderDark : _borderLight;

  static const Color _dividerLight = Color(0xFFE3DCC8);
  static const Color _dividerDark = Color(0xFF24332B);
  static Color get divider => isDark ? _dividerDark : _dividerLight;

  // === 功能色（深浅通用）===
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF6FA45B);

  // === 背景光斑 / 植物剪影（GardenBackground 用）===
  static Color get glowGreen =>
      isDark ? const Color(0x661E3A1E) : const Color(0x99DCE9C8); // 草绿光斑
  static Color get glowSun =>
      isDark ? const Color(0x663A2F1A) : const Color(0x99F8E7B5); // 柠檬光斑
  static Color get glowPetal =>
      isDark ? const Color(0x663A2028) : const Color(0x8CF9DCE4); // 花瓣光斑
  static Color get silhouetteLeaf =>
      isDark ? const Color(0x59304E30) : const Color(0x66A3CC8B); // 叶片剪影
  static Color get silhouettePot =>
      isDark ? const Color(0x594A3620) : const Color(0x61E0B48F); // 陶土剪影

  // === 特殊场景（保持常量）===
  static const Color scanBg = Color(0xFF14301C); // AI识别暖调深绿
  static const Color mapRing = Color(0xFF86C8A8); // 地图距离环
  static const Color mapTerrain = Color(0xFFDCFCE7); // 地图地形
  static const Color dimOverlay = Color(0x8014301C); // 半透明蒙层

  // === 品牌色 (分享目标) ===
  static const Color wechat = Color(0xFF07C160);
  static const Color xiaohongshu = Color(0xFFFF2442);

  // === 渐变（深浅通用，保持常量）===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static const LinearGradient mapButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C8F4A), Color(0xFF6FA45B)],
  );

  // === 阴影（暖棕调，深浅通用，保持 getter）===
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0x144A3F35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get sheetShadow => [
        BoxShadow(
          color: const Color(0x40543D2B),
          blurRadius: 40,
          offset: const Offset(0, -8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0x306FA45B),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: const Color(0x40C98A4B),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // === 毛玻璃材质 ===
  static const Color frostedTint = Color(0x99FFFFFF); // 玻璃白 60%
  static const Color frostedTintDark = Color(0x99142019); // 深色玻璃

  // === 显式取色（供 ThemeData 构建用）===
  static Color bgFor(bool dark) => dark ? _bgDark : _bgLight;
  static Color cardFor(bool dark) => dark ? _cardWhiteDark : _cardWhiteLight;
  static Color softCardFor(bool dark) => dark ? _softCardDark : _softCardLight;
  static Color textPrimaryFor(bool dark) =>
      dark ? _textPrimaryDark : _textPrimaryLight;
  static Color textSecondaryFor(bool dark) =>
      dark ? _textSecondaryDark : _textSecondaryLight;
  static Color borderFor(bool dark) => dark ? _borderDark : _borderLight;
  static Color primaryTextFor(bool dark) => dark ? _primaryTextDark : primary;
}
