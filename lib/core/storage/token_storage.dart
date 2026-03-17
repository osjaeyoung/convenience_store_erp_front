import 'package:shared_preferences/shared_preferences.dart';

/// 액세스/리프레시 토큰 저장소
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  String? getAccessToken() => _prefs.getString(_accessTokenKey);
  String? getRefreshToken() => _prefs.getString(_refreshTokenKey);

  /// 하위 호환: 기존 코드 유지용
  Future<void> save(String token) => saveAccessToken(token);

  /// 하위 호환: 기존 코드 유지용
  String? get() => getAccessToken();

  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _prefs.remove(_refreshTokenKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}
