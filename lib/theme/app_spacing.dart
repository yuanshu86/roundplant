/// 圆形植物 - 间距与圆角常量
class AppSpacing {
  AppSpacing._();

  // === 间距 ===
  static const double pagePadding = 20.0; // 页面左右边距
  static const double cardPadding = 16.0; // 卡片内边距
  static const double itemGap = 12.0; // 列表项间距
  static const double smallGap = 8.0; // 元素间小间距
  static const double tinyGap = 4.0; // 元素间超小间距

  // === 圆角（田园可爱风：超圆角）===
  static const double radiusPill = 48.0; // 药丸/输入框
  static const double radiusSheet = 32.0; // 底部面板 (仅上方)
  static const double radiusCard = 24.0; // 卡片（超圆角）
  static const double radiusCardSmall = 20.0; // 小卡/图标容器
  static const double radiusIcon = 20.0; // 小图标容器

  // === 尺寸 ===
  static const double screenWidth = 375.0;
  static const double screenHeight = 812.0;
  static const double statusBarHeight = 62.0;
  static const double navBarHeight = 48.0;
  static const double tabBarHeight = 83.0;
  static const double homeIndicator = 34.0;
  static const double contentHeight = 716.0; // 812 - 62 - 34

  // === 组件尺寸 ===
  static const double fabSize = 56.0;
  static const double plantCardWidth = 161.5;
  static const double avatarSize = 44.0;
  static const double iconButtonSize = 32.0;
  static const double shareTargetSize = 56.0;
}
