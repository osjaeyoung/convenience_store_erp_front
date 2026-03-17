import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 설정
/// .env 파일의 API_BASE_URL 사용
class ApiConfig {
  ApiConfig._();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://3.39.67.86:8000/api/v1';
}
