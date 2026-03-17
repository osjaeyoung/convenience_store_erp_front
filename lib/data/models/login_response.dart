import 'auth_user.dart';

/// 로그인 응답
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
