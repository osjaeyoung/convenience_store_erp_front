class PushNotificationSettings {
  const PushNotificationSettings({
    required this.pushEnabled,
    this.updatedAt,
  });

  final bool pushEnabled;
  final String? updatedAt;

  factory PushNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PushNotificationSettings(
      pushEnabled: json['push_enabled'] as bool? ?? false,
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
