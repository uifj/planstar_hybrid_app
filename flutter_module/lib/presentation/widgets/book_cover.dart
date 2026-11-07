import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../domain/model/book.dart';

/// 书籍封面：有网络封面时加载图片，为空或加载失败时回退成渐变色块 + 书名首字。
///
/// 统一封装让书城、搜索、详情三处保持一致的降级行为，也避免重复编写 errorBuilder。
class BookCover extends StatelessWidget {
  final Book book;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// 回退色块中首字的大小，随封面尺寸调整。
  final double fallbackFontSize;

  const BookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackFontSize = 34,
  });

  /// 渐变色板属于封面插画本身，不是主题色，因此保留在组件内。
  static const List<Color> _palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.small);
    final url = book.coverUrl;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? _buildFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                // 列表封面展示尺寸只有几十像素，按 300px 解码兼顾清晰度与内存
                cacheWidth: 300,
                errorBuilder: (_, _, _) => _buildFallback(),
              ),
      ),
    );
  }

  Widget _buildFallback() {
    final color = _palette[book.bookName.hashCode.abs() % _palette.length];
    final title = book.bookName.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          title.isEmpty ? '书' : title.characters.first,
          style: TextStyle(
            color: Colors.white,
            fontSize: fallbackFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
