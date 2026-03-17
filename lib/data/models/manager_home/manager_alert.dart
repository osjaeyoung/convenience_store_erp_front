/// 점장/경영주 알림
class ManagerAlert {
  const ManagerAlert({
    required this.alertId,
    required this.title,
    required this.content,
    this.priority,
    this.isOpen = true,
    this.createdAt,
  });

  final int alertId;
  final String title;
  final String content;
  final String? priority;
  final bool isOpen;
  final String? createdAt;

  factory ManagerAlert.fromJson(Map<String, dynamic> json) {
    return ManagerAlert(
      alertId: json['alert_id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}
