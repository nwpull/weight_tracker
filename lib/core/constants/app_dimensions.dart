import 'package:flutter/material.dart';

/// 应用尺寸常量
class AppDimensions {
  AppDimensions._();

  // 间距
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // 圆角
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusFull = 999;

  // 图标大小
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // 按钮高度
  static const double buttonHeightSmall = 32;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;

  // 输入框高度
  static const double inputHeight = 52;

  // 卡片
  static const double cardElevation = 0;
  static const double cardBorderRadius = radiusMedium;

  // 底部导航栏高度
  static const double bottomNavBarHeight = 64;

  // AppBar 高度
  static const double appBarHeight = 56;

  // 页面边距
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing12,
  );

  // 列表项边距
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing12,
  );
}
