import '../network/api_client.dart';

/// 푸시 디바이스 토큰 등록/갱신 API
class PushRepository {
  PushRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 서버에 디바이스 토큰을 upsert한다.
  Future<void> upsertDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _apiClient.dio.post<void>(
      '/push/device-tokens',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
