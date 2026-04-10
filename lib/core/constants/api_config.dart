import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 설정
/// .env의 API_BASE_URL이 있으면 사용, 없으면 기본값 사용 (.env 로딩 실패 시에도 동작)
class ApiConfig {
  ApiConfig._();

  static const String _defaultBaseUrl = 'https://nanum-store.com/api/v1';

  static String get baseUrl {
    try {
      final url = dotenv.env['API_BASE_URL']?.trim();
      return (url != null && url.isNotEmpty) ? url : _defaultBaseUrl;
    } catch (_) {
      return _defaultBaseUrl;
    }
  }
}
