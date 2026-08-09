import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 圆形植物 - 字体系统
class AppTypography {
  AppTypography._();

  static const String _titleFamily = 'VarelaRound';
  static const String _bodyFamily = 'NunitoSans';

  // === 标题 ===
  static TextStyle pageTitle = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.29,
    color: AppColors.primary,
  );

  static TextStyle cardTitle = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionTitle = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.27,
    color: AppColors.primary,
  );

  // === 正文 ===
  static TextStyle body = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySemiBold = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  // === 标签 ===
  static TextStyle label = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.27,
    color: AppColors.textSecondary,
  );

  static TextStyle badge = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.30,
    color: AppColors.textSecondary,
  );

  // === 特殊 ===
  static TextStyle statusTime = TextStyle(
    fontFamily: 'SF Pro',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle buttonText = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
