import 'package:flutter/material.dart';

/// 视觉 token：颜色、圆角、字号集中定义，避免各页面散落魔法值后出现
/// 「同一主色三个色值」这类难以统一的视觉偏差。
abstract final class AppColors {
  /// 品牌主色，与原生书城保持一致。
  static const Color primary = Color(0xFFE5353E);

  /// 主色 10% 透明度：用于选中分类 chip 的浅红底。
  static const Color primaryLight = Color(0x1AE5353E);

  /// 页面背景（浅灰），让白色卡片有层次。
  static const Color background = Color(0xFFF7F7F9);

  /// 卡片 / 列表容器底色。
  static const Color surface = Colors.white;

  /// 主要文字：书名、标题。
  static const Color textPrimary = Color(0xFF222222);

  /// 次要文字：作者、简介。
  static const Color textSecondary = Color(0xFF555555);

  /// 提示文字：占位、辅助说明。
  static const Color textHint = Color(0xFF999999);

  /// 更弱的提示文字（空态建议词等）。
  static const Color textDisabled = Color(0xFFBBBBBB);

  /// 弱化图标：空态图标、不可点击箭头。
  static const Color iconMuted = Color(0xFFCCCCCC);

  /// 分割线。
  static const Color divider = Color(0xFFEEEEEE);

  /// 未选中 chip / 搜索框底色。
  static const Color chipBackground = Color(0xFFF2F2F2);

  /// 详情页头部的浅灰分区底色。
  static const Color sectionBackground = Color(0xFFFAFAFA);

  /// 评分强调色。
  static const Color rating = Color(0xFFFF9800);
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 18;
}

abstract final class AppTextSize {
  static const double caption = 11;
  static const double bodySmall = 13;
  static const double body = 15;
  static const double title = 17;
}

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      // 与原生宿主保持一致的中文字体，避免混排时字重与字形不一致
      fontFamily: 'YuewenFont',
    );
  }
}
