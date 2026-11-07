import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/service_locator.dart';
import '../../domain/model/book.dart';
import '../../domain/model/book_detail.dart';
import '../../domain/model/chapter.dart';
import '../../services/native_bridge.dart';
import '../widgets/book_cover.dart';

/// 书详情页（对应原生 app 中的 QDBookDetailFlutterActivity）。
class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  /// 目录只展示前 30 章：足够判断内容风格，又不会一次构建上千条列表项。
  static const int _maxChapters = 30;

  BookDetail? _detail;
  bool _loading = true;
  bool _loadFailed = false;
  bool _opening = false;

  Book get _book => _detail?.book ?? widget.book;

  List<Chapter> get _chapters {
    final all = _detail?.chapters ?? const <Chapter>[];
    return all.length > _maxChapters ? all.sublist(0, _maxChapters) : all;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetail());
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ServiceLocator.getBookDetail(widget.book.bookId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      // 仓库层已做本地兜底，这里只兜住「彻底查不到」的情况，
      // 保留列表页传入的基础信息，避免详情页整页报错。
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openReader() async {
    if (_opening) return;
    setState(() => _opening = true);
    final book = _book;
    try {
      await ServiceLocator.openReader(
        bookId: book.bookId,
        title: book.bookName,
        author: book.authorName,
      );
    } on BridgeException catch (error) {
      // 原生阅读页唤起失败只用 SnackBar 提示，详情页仍可继续浏览
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开阅读页失败（${error.code}）')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('打开阅读页失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('书籍详情'),
        elevation: 0.5,
        shadowColor: AppColors.divider,
      ),
      body: CustomScrollView(
        cacheExtent: 400,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(book)),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.divider),
          ),
          SliverToBoxAdapter(child: _buildIntro(book)),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.divider),
          ),
          SliverToBoxAdapter(child: _buildCatalogHeader()),
          _buildCatalogSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      // 该页运行在 FlutterFragment 内，底部为原生 BottomNavigationView，
      // 系统导航栏安全区已由原生侧统一处理，这里不叠加 SafeArea 避免双重留白。
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.sectionBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.small),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: BookCover(
              book: book,
              width: 96,
              height: 128,
              borderRadius: BorderRadius.circular(AppRadius.small),
              fallbackFontSize: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.bookName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTextSize.title,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '作者：${book.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppTextSize.bodySmall,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '分类：${book.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppTextSize.bodySmall,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '字数：${book.wordsInWan} 万字',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppTextSize.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.rating,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${(book.bookStar / 10).toStringAsFixed(1)} 分',
                      style: const TextStyle(
                        fontSize: AppTextSize.caption,
                        color: AppColors.rating,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(book),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Book book) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        book.finished ? '已完结' : '连载中',
        style: const TextStyle(
          fontSize: AppTextSize.caption,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildIntro(Book book) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '作品简介',
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description.isEmpty ? '暂无简介' : book.description,
            style: const TextStyle(
              fontSize: AppTextSize.bodySmall,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Text(
            '目录',
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            _loading ? '加载中…' : '共 ${_book.chapterCount} 章',
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: AppTextSize.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSliver() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    final chapters = _chapters;
    if (chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              _loadFailed ? '目录加载失败，请稍后重试' : '暂无目录',
              style: const TextStyle(
                fontSize: AppTextSize.caption,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ListTile(
          dense: true,
          leading: const Icon(
            Icons.article_outlined,
            size: 18,
            color: AppColors.textHint,
          ),
          title: Text(
            chapter.title,
            style: const TextStyle(
              fontSize: AppTextSize.bodySmall,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.iconMuted,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('演示模式，暂未接入正文：${chapter.title}')),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已加入书架（演示）')));
                },
                child: const Text(
                  '加入书架',
                  style: TextStyle(fontSize: AppTextSize.body),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _opening ? null : () => unawaited(_openReader()),
                child: _opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '开始阅读',
                        style: TextStyle(fontSize: AppTextSize.body),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
