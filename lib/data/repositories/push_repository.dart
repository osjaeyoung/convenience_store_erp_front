import '../models/push_notification_settings.dart';
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

  Future<PushNotificationSettings> getNotificationSettings() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/push-settings',
    );
    return PushNotificationSettings.fromJson(res.data!);
  }

  Future<PushNotificationSettings> updateNotificationSettings({
    required bool pushEnabled,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/me/push-settings',
      data: {'push_enabled': pushEnabled},
    );
    return PushNotificationSettings.fromJson(res.data!);
  }
}
