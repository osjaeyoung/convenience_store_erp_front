import 'package:dio/dio.dart';

String accountDioMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['detail'] ?? data['error'])?.toString() ??
          '요청에 실패했습니다.';
    }
    return e.message ?? '요청에 실패했습니다.';
  }
  return e.toString();
}
