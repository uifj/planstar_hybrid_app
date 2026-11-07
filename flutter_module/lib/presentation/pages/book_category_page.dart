import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/service_locator.dart';
import '../../domain/model/book.dart';
import '../state/book_list_state.dart';
import '../widgets/book_cover.dart';
import 'book_detail_page.dart';
import 'search_page.dart';

/// 书城列表状态放在 widget 之外：原生 Tab 切换会销毁并重建页面 State，
/// 单例让返回书城时无需重新请求即可恢复已加载列表。
final BookListState _bookCategoryState = BookListState(
  fetchPage: (page) => ServiceLocator.getBooks(page: page),
);

/// 书城页（对应原生 app 中的 BookCategoryFlutterActivity / 书城 Tab）。
class BookCategoryPage extends StatefulWidget {
  const BookCategoryPage({super.key});

  @override
  State<BookCategoryPage> createState() => _BookCategoryPageState();
}

class _BookCategoryPageState extends State<BookCategoryPage> {
  final List<String> _chips = ['全部', ...ServiceLocator.bookCategories];
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = '全部';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 只在从未成功加载过时请求；已加载/加载中直接复用单例里的数据
    if (!_bookCategoryState.hasLoaded && !_bookCategoryState.loading) {
      unawaited(_bookCategoryState.loadFirstPage());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // 距底部 300px 提前预取，用户不会滑到底才看到转圈；重复回调由状态层去重
    if (position.pixels >= position.maxScrollExtent - 300) {
      unawaited(_bookCategoryState.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('书城'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(
            child: ListenableBuilder(
              listenable: _bookCategoryState,
              builder: (context, _) => _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  void _openSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
  }

  Widget _buildContent() {
    final state = _bookCategoryState;
    // 四种状态互斥：首次加载 / 首屏失败 / 空数据 / 正常列表
    if (state.loading && !state.hasItems) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && !state.hasItems) {
      return _buildRefreshableStatus(
        icon: Icons.wifi_off_rounded,
        title: state.error!,
        actionText: '重新加载',
        onAction: () => unawaited(state.loadFirstPage()),
      );
    }
    if (!state.hasItems) {
      return _buildRefreshableStatus(
        icon: Icons.menu_book_outlined,
        title: '暂无书籍',
        subtitle: '下拉刷新或稍后再来看看',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: state.refresh,
      child: _buildGrid(state),
    );
  }

  Widget _buildGrid(BookListState state) {
    // 分类只是对已加载数据的客户端筛选，切换分类不会清空网络数据
    final books = _filteredBooks(state.items);
    return CustomScrollView(
      // PageStorageKey 让同一 Tab 内的滚动位置在重建后仍能恢复
      key: const PageStorageKey<String>('book_category_grid'),
      controller: _scrollController,
      cacheExtent: 600,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (books.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildFilterEmpty(state.hasMore),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    RepaintBoundary(child: _BookCard(book: books[index])),
                childCount: books.length,
              ),
            ),
          ),
        if (state.hasMore || state.loadingMore || state.loadMoreError != null)
          SliverToBoxAdapter(child: _buildFooter(state)),
      ],
    );
  }

  List<Book> _filteredBooks(List<Book> books) {
    if (_selectedCategory == '全部') return books;
    return books
        .where((book) => book.categoryName == _selectedCategory)
        .toList();
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
      // 翻页失败只在底部提示并允许重试，已有列表保持不动
      return Center(
        child: TextButton(
          onPressed: () => unawaited(state.loadMore()),
          child: Text(state.loadMoreError!),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Center(
        child: Text(
          '上拉加载更多',
          style: TextStyle(
            fontSize: AppTextSize.caption,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterEmpty(bool hasMore) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: AppColors.iconMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            '当前分类暂无书籍',
            style: TextStyle(
              fontSize: AppTextSize.bodySmall,
              color: AppColors.textHint,
            ),
          ),
          if (hasMore)
            TextButton(
              onPressed: () => unawaited(_bookCategoryState.loadMore()),
              child: const Text('加载更多书籍'),
            ),
        ],
      ),
    );
  }

  /// 空态/错误态也要能下拉刷新，因此套一层可滚动的容器撑满视口。
  Widget _buildRefreshableStatus({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _bookCategoryState.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _buildStatusView(
              icon: icon,
              title: title,
              subtitle: subtitle,
              actionText: actionText,
              onAction: onAction,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.iconMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTextSize.bodySmall,
                color: AppColors.textHint,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: AppTextSize.caption,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openSearch,
      child: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textHint, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '搜索书名 / 作者 / 标签',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppTextSize.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: AppColors.surface,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _chips.length,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final selected = chip == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = chip),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: AppTextSize.bodySmall,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 书城卡片：外层 RepaintBoundary 隔开封面加载时的重绘，滑动更稳。
class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: BookCover(book: book)),
          const SizedBox(height: 6),
          Text(
            book.bookName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTextSize.bodySmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            book.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: AppTextSize.caption,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                book.finished ? '完结' : '连载',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTextSize.caption,
                ),
              ),
              const Spacer(),
              Text(
                '${book.wordsInWan}万字',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppTextSize.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
