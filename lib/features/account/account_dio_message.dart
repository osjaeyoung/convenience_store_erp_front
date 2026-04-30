import '../../core/errors/user_friendly_error_message.dart';

String accountDioMessage(Object e) {
  return userFriendlyErrorMessage(e, fallback: '요청에 실패했습니다.\n잠시 후 다시 시도해주세요.');
}
