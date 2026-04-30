import 'package:dio/dio.dart';

const String defaultUserErrorMessage = '요청을 처리하지 못했습니다.\n잠시 후 다시 시도해주세요.';
const String serverUserErrorMessage = '알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
const String networkUserErrorMessage =
    '네트워크 연결이 원활하지 않습니다.\n연결 상태를 확인한 뒤 다시 시도해주세요.';

String userFriendlyErrorMessage(
  Object error, {
  String fallback = defaultUserErrorMessage,
}) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return serverUserErrorMessage;
    }
    if (_isNetworkError(error)) {
      return networkUserErrorMessage;
    }

    final message = _messageFromResponse(error.response?.data);
    if (message != null && !_looksLikeTechnicalMessage(message)) {
      return message;
    }
    return fallback;
  }

  final message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isNotEmpty && !_looksLikeTechnicalMessage(message)) {
    return message;
  }
  return fallback;
}

bool _isNetworkError(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}

String? _messageFromResponse(Object? data) {
  if (data is Map) {
    final raw = data['message'] ?? data['detail'] ?? data['error'];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
  final text = data?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool _looksLikeTechnicalMessage(String message) {
  final lower = message.toLowerCase();
  return lower.contains('dioexception') ||
      lower.contains('requestoptions') ||
      lower.contains('stacktrace') ||
      lower.contains('status code of') ||
      lower.contains('http status') ||
      lower.contains('traceback') ||
      lower.contains('exception:') ||
      lower.contains('null check operator') ||
      lower.contains('typeerror') ||
      lower.contains('socketexception');
}
