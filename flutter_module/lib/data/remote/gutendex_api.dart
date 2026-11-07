import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'gutendex_dto.dart';

/// Gutendex 公版书开放接口（无需鉴权）。
///
/// 直接用 dart:io 而不是引入 http/dio：模块禁止新增第三方依赖，
/// 而这里只需要一个 GET 请求。
class GutendexApi {
  static const String _host = 'gutendex.com';
  static const String _booksPath = '/books';

  /// 连接与读取合计超时，超过即视为网络不可用，由仓库层回退本地书单。
  static const Duration _timeout = Duration(seconds: 8);

  Future<GutendexResponseDto> fetchBooks({int page = 1, String? search}) {
    return _requestBooks(page: page, search: search).timeout(_timeout);
  }

  Future<GutendexResponseDto> _requestBooks({
    required int page,
    String? search,
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    final uri = Uri.https(_host, _booksPath, {
      'page': '$page',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'planstar_flutter');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Gutendex 返回状态码 ${response.statusCode}', uri: uri);
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Gutendex 响应不是 JSON 对象');
      }
      return GutendexResponseDto.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }
}
