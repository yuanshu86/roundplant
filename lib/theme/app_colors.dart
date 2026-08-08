import 'package:flutter/material.dart';

/// 圆形植物 - 色彩系统
/// 基于 Ardot 设计稿变量集 PlantCare
class AppColors {
  AppColors._();

  // === 主色 ===
  static const Color primary = Color(0xFF15803D);       // 森林绿
  static const Color secondary = Color(0xFF059669);      // 翡翠绿
  static const Color accent = Color(0xFFD97706);         // 琥珀橙

  // === 背景 ===
  static const Color bg = Color(0xFFF0FDF4);             // 页面背景
  static const Color cardWhite = Color(0xFFFFFFFF);      // 卡片白
  static const Color softCard = Color(0xFFF0F7F3);       // 次级卡片/输入框

  // === 文字 ===
  static const Color textPrimary = Color(0xFF1E293B);    // 主文字
  static const Color textSecondary = Color(0xFF64748B);  // 次文字
  static const Color textHint = Color(0xFF94A3B8);       // 占位文字

  // === 边框/分割线 ===
  static const Color border = Color(0xFFE2EFE7);
  static const Color divider = Color(0xFFE2EFE7);

  // === 功能色 ===
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // === 特殊场景 ===
  static const Color scanBg = Color(0xFF0A2E1A);         // AI识别暗绿背景
  static const Color mapRing = Color(0xFF86C8A8);        // 地图距离环
  static const Color mapTerrain = Color(0xFFDCFCE7);     // 地图地形
  static const Color dimOverlay = Color(0x800A2E1A);     // 半透明蒙层

  // === 品牌色 (分享目标) ===
  static const Color wechat = Color(0xFF07C160);
  static const Color xiaohongshu = Color(0xFFFF2442);

  // === 渐变 ===
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

  // === 阴影 ===
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
}
