import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 圆形植物 - 字体系统（田园可爱风 · 标题=站酷快乐体本地打包）
///
/// ⚠️ 铁律：这里所有样式**必须是 getter**（`get xxx =>`），不能写成
/// `static TextStyle xxx = ...` 的字段形式。
///
/// 原因：Dart 的 static 字段是「懒加载 + 只求值一次」，如果写成字段，
/// TextStyle 里的 `AppColors.textPrimary` 会在类首次被访问的那一刻
/// **永久固化**成当时的主题色。后果：
///   1. 切换深色模式后全部文字颜色不跟着变；
///   2. 若首次访问发生在深色模式下，颜色被固化成近白色，
///      切回浅色主题就是「白卡片 + 白文字」= 整页纯白看不见任何内容。
///
/// getter 每次访问都重新构造 TextStyle（开销极小），确保永远跟随当前主题。
///
/// 另外：ZCOOLKuaiLe 为中文圆体（站酷快乐体，OFL 开源可商用，本地打包于
/// assets/fonts），拉丁正文仍用 NunitoSans；所有样式显式声明
/// fontFamilyFallback，优先使用系统常见中文字体兜底。
class AppTypography {
  AppTypography._();

  static const String _titleFamily = 'ZCOOLKuaiLe';
  static const String _bodyFamily = 'NunitoSans';

  // 系统常见中文字体回退（按优先顺序）。Flutter 会先在主字体找字形，
  // 找不到时依次尝试 fallback；命中任意一个即可正常渲染中文。
  static const List<String> _cnFallback = [
    'PingFang SC',
    'Heiti SC',
    'Microsoft YaHei',
    'Noto Sans SC',
    'Source Han Sans SC',
    'sans-serif',
  ];

  // === 标题 ===
  static TextStyle get pageTitle => TextStyle(
        fontFamily: _titleFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.29,
        color: AppColors.primaryText,
        decoration: TextDecoration.none,
      );

  static TextStyle get cardTitle => TextStyle(
        fontFamily: _titleFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: AppColors.textPrimary,
        decoration: TextDecoration.none,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontFamily: _titleFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.27,
        color: AppColors.primaryText,
        decoration: TextDecoration.none,
      );

  // === 正文 ===
  static TextStyle get body => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: AppColors.textPrimary,
        decoration: TextDecoration.none,
      );

  static TextStyle get bodySemiBold => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        color: AppColors.textPrimary,
        decoration: TextDecoration.none,
      );

  // === 标签 ===
  static TextStyle get label => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: AppColors.textSecondary,
        decoration: TextDecoration.none,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.27,
        color: AppColors.textSecondary,
        decoration: TextDecoration.none,
      );

  static TextStyle get badge => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: AppColors.textSecondary,
        decoration: TextDecoration.none,
      );

  // === 特殊 ===
  static TextStyle get statusTime => TextStyle(
        fontFamily: 'SF Pro',
        fontFamilyFallback: _cnFallback,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
        decoration: TextDecoration.none,
      );

  static TextStyle get buttonText => const TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        decoration: TextDecoration.none,
      );

  // === 深色底（绿色渐变 / 图片蒙层）上的文字，恒为白系 ===
  static TextStyle get onDarkTitle => const TextStyle(
        fontFamily: _titleFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 21,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        decoration: TextDecoration.none,
      );

  static TextStyle get onDarkBody => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.88),
        decoration: TextDecoration.none,
      );

  static TextStyle get onDarkCaption => TextStyle(
        fontFamily: _bodyFamily,
        fontFamilyFallback: _cnFallback,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.75),
        decoration: TextDecoration.none,
      );
}
