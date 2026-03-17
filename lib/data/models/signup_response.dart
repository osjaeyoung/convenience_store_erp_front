import 'auth_user.dart';

/// 회원가입 1차 응답
class SignupResponse {
  const SignupResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    this.isNewUser = true,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final bool isNewUser;
  final AuthUser user;

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      isNewUser: json['is_new_user'] as bool? ?? true,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
