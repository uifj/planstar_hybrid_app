import 'package:flutter/foundation.dart';

import '../../domain/model/book.dart';
import '../../domain/model/book_page.dart';

/// 分页数据加载器：调用方把「第 N 页」翻译成具体数据源请求。
typedef BookPageLoader = Future<BookPage> Function(int page);

/// 书列表状态（ChangeNotifier）。
///
/// 书城与搜索共用同一套分页逻辑，避免两处各写一份「加载更多」后行为不一致：
/// 1. 只用 [_loading] / [_loadingMore] 两个标志去重，重复触底不会并发请求；
/// 2. 每次请求带自增序号，先发后到的旧响应会被丢弃，防止旧关键词覆盖新结果；
/// 3. 所有异常统一转成 [error] / [loadMoreError]，页面无需再 try/catch。
class BookListState extends ChangeNotifier {
  BookListState({BookPageLoader? fetchPage}) : _fetchPage = fetchPage;

  BookPageLoader? _fetchPage;

  List<Book> _items = const [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasLoaded = false;
  String? _error;
  String? _loadMoreError;

  /// 请求序号：每次发起请求自增，响应回来时序号不一致说明已被新请求取代。
  int _requestSeq = 0;
  bool _disposed = false;

  List<Book> get items => _items;
  int get page => _page;
  bool get hasMore => _hasMore;

  /// 首屏加载中（用于整页转圈）。
  bool get loading => _loading;

  /// 加载更多中（用于底部小转圈）。
  bool get loadingMore => _loadingMore;

  String? get error => _error;

  /// 翻页/刷新失败提示：只在底部展示，不清空已有数据。
  String? get loadMoreError => _loadMoreError;

  /// 是否成功加载过至少一页：页面重建时据此决定要不要重新请求。
  bool get hasLoaded => _hasLoaded;

  bool get hasItems => _items.isNotEmpty;

  /// 首屏加载完成且确实没有数据。
  bool get isEmpty => _items.isEmpty && !_loading && _error == null;

  /// 切换数据源（如搜索关键词变化）时替换加载器，不自动发起请求。
  void updateLoader(BookPageLoader loader) {
    _fetchPage = loader;
  }

  /// 清空列表并让在途请求失效；用于搜索关键词切换或页面重新开始。
  void reset() {
    _requestSeq++;
    _items = const [];
    _page = 0;
    _hasMore = true;
    _loading = false;
    _loadingMore = false;
    _refreshing = false;
    _hasLoaded = false;
    _error = null;
    _loadMoreError = null;
    notifyListeners();
  }

  /// 加载第 1 页（首屏或失败重试）。
  Future<void> loadFirstPage() async {
    final loader = _fetchPage;
    if (loader == null) return;
    final seq = ++_requestSeq;
    _loading = true;
    _loadingMore = false;
    _refreshing = false;
    _error = null;
    _loadMoreError = null;
    notifyListeners();
    await _request(loader, seq: seq, page: 1, replace: true);
  }

  /// 下拉刷新：回到第 1 页，但刷新期间保留旧列表，避免整页闪空。
  Future<void> refresh() async {
    final loader = _fetchPage;
    if (loader == null || _refreshing) return;
    final seq = ++_requestSeq;
    _refreshing = true;
    _loadingMore = false;
    _loadMoreError = null;
    notifyListeners();
    await _request(loader, seq: seq, page: 1, replace: true);
  }

  /// 上拉加载下一页；重复触底由 [loading] / [loadingMore] / [hasMore] 拦截。
  Future<void> loadMore() async {
    final loader = _fetchPage;
    if (loader == null) return;
    if (_loading || _loadingMore || _refreshing || !_hasMore) return;
    final seq = ++_requestSeq;
    _loadingMore = true;
    _loadMoreError = null;
    notifyListeners();
    await _request(loader, seq: seq, page: _page + 1, replace: false);
  }

  Future<void> _request(
    BookPageLoader loader, {
    required int seq,
    required int page,
    required bool replace,
  }) async {
    try {
      final result = await loader(page);
      if (_disposed || seq != _requestSeq) return;
      _items = replace
          ? List<Book>.of(result.items)
          : <Book>[..._items, ...result.items];
      _page = result.page > 0 ? result.page : page;
      _hasMore = result.hasMore;
      _hasLoaded = true;
      _error = null;
      _loadMoreError = null;
    } catch (_) {
      if (_disposed || seq != _requestSeq) return;
      // 首屏失败才占满整页；翻页/刷新失败保留旧数据，只在底部提示
      if (replace && _items.isEmpty) {
        _error = '加载失败，请检查网络后重试';
      } else {
        _loadMoreError = '加载失败，点击重试';
      }
    } finally {
      if (!_disposed && seq == _requestSeq) {
        _loading = false;
        _loadingMore = false;
        _refreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    // 页面销毁后可能还有响应回来，用标记阻断 notifyListeners，避免异常
    _disposed = true;
    super.dispose();
  }
}
