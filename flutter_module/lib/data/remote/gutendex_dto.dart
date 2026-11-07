/// Gutendex 接口的原始 DTO。
///
/// 手写 fromJson 而不是用 codegen：只有两个结构体，引入 build_runner
/// 会让模块构建链路变重，而模块不允许新增依赖。
class GutendexBookDto {
  final int id;
  final String title;
  final String authorName;
  final int downloadCount;
  final Map<String, String> formats;
  final String? language;

  const GutendexBookDto({
    required this.id,
    required this.title,
    required this.authorName,
    required this.downloadCount,
    required this.formats,
    this.language,
  });

  factory GutendexBookDto.fromJson(Map<String, dynamic> json) {
    var authorName = '';
    final authors = json['authors'];
    if (authors is List && authors.isNotEmpty) {
      final Object? firstAuthor = authors.first;
      if (firstAuthor is Map) {
        final Object? name = firstAuthor['name'];
        authorName = name?.toString() ?? '';
      }
    }

    final formats = <String, String>{};
    final rawFormats = json['formats'];
    if (rawFormats is Map) {
      for (final entry in rawFormats.entries) {
        final Object? key = entry.key;
        final Object? value = entry.value;
        if (key != null && value != null) {
          formats[key.toString()] = value.toString();
        }
      }
    }

    String? language;
    final languages = json['languages'];
    if (languages is List && languages.isNotEmpty) {
      final Object? firstLanguage = languages.first;
      language = firstLanguage?.toString();
    }

    final rawId = json['id'];
    final rawDownloads = json['download_count'];

    return GutendexBookDto(
      id: rawId is num ? rawId.toInt() : 0,
      title: json['title'] is String ? json['title'] as String : '',
      authorName: authorName,
      downloadCount: rawDownloads is num ? rawDownloads.toInt() : 0,
      formats: formats,
      language: language,
    );
  }
}

class GutendexResponseDto {
  final int count;
  final String? next;
  final List<GutendexBookDto> results;

  const GutendexResponseDto({
    required this.count,
    required this.next,
    required this.results,
  });

  /// 接口返回 next 才代表还有下一页，不能只看当前页条数。
  bool get hasMore => next != null && next!.isNotEmpty;

  factory GutendexResponseDto.fromJson(Map<String, dynamic> json) {
    final results = <GutendexBookDto>[];
    final rawResults = json['results'];
    if (rawResults is List) {
      for (final item in rawResults) {
        if (item is Map) {
          results.add(
            GutendexBookDto.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawCount = json['count'];
    final rawNext = json['next'];

    return GutendexResponseDto(
      count: rawCount is num ? rawCount.toInt() : 0,
      next: rawNext is String && rawNext.isNotEmpty ? rawNext : null,
      results: results,
    );
  }
}
