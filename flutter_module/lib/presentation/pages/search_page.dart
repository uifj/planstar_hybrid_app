import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/service_locator.dart';
import '../../domain/model/book.dart';
import '../state/book_list_state.dart';
import '../widgets/book_cover.dart';
import 'book_detail_page.dart';

/// 搜索页（对应原项目 QDSearchFlutterActivity）。
/// 输入 300ms 防抖后实时搜索，结果列表复用书城的分页状态。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// 连续输入时只在停顿 300ms 后请求一次，避免每个字符都打一次网络。
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// 空结果时给用户的建议词，取自书城分类，点击即可直接搜索。
  static const List<String> _suggestions = ['玄幻', '都市', '言情', '科幻', '悬疑', '历史'];

  final TextEditingController _controller = TextEditingController();
  final BookListState _results = BookListState();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  /// 已生效的关键词（防抖结束后才更新），空串代表展示热搜占位。
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _results.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(_results.loadMore());
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.isEmpty) {
      // 空格/空串不请求，直接回到热门关键词占位
      _clearSearch();
      return;
    }
    // 让右上角「取消/清除」文案跟着输入状态实时变化
    setState(() {});
    _debounce = Timer(_debounceDuration, () => unawaited(_search(keyword)));
  }

  Future<void> _search(String keyword) async {
    _debounce?.cancel();
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    if (kw != _keyword) {
      // 关键词变化时先清空旧结果，并让仍在途的旧请求失效
      _keyword = kw;
      _results.reset();
    }
    _results.updateLoader((page) => ServiceLocator.searchBooks(kw, page: page));
    if (mounted) setState(() {});
    await _results.loadFirstPage();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _keyword = '';
    _results.reset();
    if (mounted) setState(() {});
  }

  /// 点击热搜词/建议词：同步搜索框并立即搜索（跳过防抖）。
  void _applyKeyword(String word) {
    _controller.text = word;
    _controller.selection = TextSelection.collapsed(offset: word.length);
    unawaited(_search(word));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.chipBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textHint, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: AppTextSize.bodySmall,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '搜索书名 / 作者 / 标签',
                    hintStyle: TextStyle(
                      fontSize: AppTextSize.bodySmall,
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    unawaited(_search(value));
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_controller.text.isEmpty) {
                Navigator.of(context).pop();
              } else {
                _controller.clear();
                _clearSearch();
              }
            },
            child: Text(
              _controller.text.isEmpty ? '取消' : '清除',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _keyword.isEmpty ? _buildHotWords() : _buildResults(),
    );
  }

  Widget _buildResults() {
    return ListenableBuilder(
      listenable: _results,
      builder: (context, _) {
        final state = _results;
        if (state.loading && !state.hasItems) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && !state.hasItems) {
          return _buildError(state.error!);
        }
        if (state.items.isEmpty) {
          return _buildNoResult();
        }
        return ListView.builder(
          controller: _scrollController,
          cacheExtent: 400,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index == state.items.length) return _buildFooter(state);
            return _buildResultTile(state.items[index]);
          },
        );
      },
    );
  }

  Widget _buildResultTile(Book book) {
    return ListTile(
      leading: BookCover(
        book: book,
        width: 44,
        height: 60,
        fallbackFontSize: 20,
      ),
      title: Text(
        book.bookName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: AppTextSize.body,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${book.authorName} · ${book.finished ? '完结' : '连载'} · ${book.wordsInWan}万字',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: AppTextSize.caption,
          color: AppColors.textHint,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconMuted),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
      },
    );
  }

  Widget _buildFooter(BookListState state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.loadMoreError != null) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(state.loadMore()),
          child: Text(state.loadMoreError!),
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '没有更多了',
            style: TextStyle(
              fontSize: AppTextSize.caption,
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.iconMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppTextSize.bodySmall,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => unawaited(_search(_keyword)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResult() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      children: [
        const Icon(
          Icons.search_off_rounded,
          size: 56,
          color: AppColors.iconMuted,
        ),
        const SizedBox(height: 12),
        const Text(
          '没有找到相关书籍',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '关键词「$_keyword」暂无结果，试试下面这些',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTextSize.caption,
            color: AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _suggestions.map(_buildKeywordChip).toList(),
        ),
      ],
    );
  }

  Widget _buildHotWords() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '热门搜索',
          style: TextStyle(
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ServiceLocator.bookCategories
              .map(_buildKeywordChip)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(String word) {
    return GestureDetector(
      onTap: () => _applyKeyword(word),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          word,
          style: const TextStyle(
            fontSize: AppTextSize.bodySmall,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
