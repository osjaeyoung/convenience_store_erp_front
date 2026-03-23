/// 인증 관련 예외
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}
