import 'dart:async';

import 'package:flutter/material.dart';

import '../mock/mock_books.dart';
import 'book_detail_page.dart';

/// 搜索页（对应原项目 QDSearchFlutterActivity）。
/// 支持输入关键词实时过滤书名/作者，并展示热搜词。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// 输入防抖：连续输入时只在停顿后过滤一次，避免每个字符都触发全量过滤 + 重建。
  static const Duration _debounceDuration = Duration(milliseconds: 200);

  final TextEditingController _controller = TextEditingController();
  List<Book> _results = const [];
  Timer? _debounceTimer;

  void _onQueryChanged(String keyword) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () => _search(keyword));
  }

  void _search(String keyword) {
    _debounceTimer?.cancel();
    final kw = keyword.trim();
    if (kw.isEmpty) {
      if (_results.isEmpty) return;
      setState(() => _results = const []);
      return;
    }
    setState(() {
      _results = mockBooks
          .where(
            (b) =>
                b.bookName.contains(kw) ||
                b.authorName.contains(kw) ||
                b.categoryName == kw,
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: '搜索书名 / 作者 / 标签',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _onQueryChanged,
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
                _search('');
              }
            },
            child: Text(
              _controller.text.isEmpty ? '取消' : '清除',
              style: const TextStyle(color: Color(0xFFE5353E)),
            ),
          ),
        ],
      ),
      body: _controller.text.trim().isEmpty
          ? _buildHotWords()
          : _results.isEmpty
          ? _buildNoResult()
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final book = _results[index];
                return ListTile(
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: const Color(0xFFE5353E),
                  ),
                  title: Text(book.bookName),
                  subtitle: Text('${book.authorName} · ${book.categoryName}'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookDetailPage(book: book),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(
            '没有找到“${_controller.text.trim()}”相关书籍',
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 6),
          const Text(
            '换个书名、作者或分类试试',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }

  Widget _buildHotWords() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热搜榜',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categoryList.map((word) {
              return GestureDetector(
                onTap: () {
                  _controller.text = word;
                  _search(word);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
