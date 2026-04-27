class AccountNotificationPage {
  const AccountNotificationPage({
    required this.items,
    required this.totalCount,
    required this.unreadCount,
    required this.page,
    required this.pageSize,
  });

  final List<AccountNotificationItem> items;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;

  factory AccountNotificationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final parsedItems = rawItems
        .whereType<Map>()
        .map(
          (item) => AccountNotificationItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
    final responseUnreadCount = _toInt(json['unread_count']);
    final itemUnreadCount = parsedItems.where((item) => !item.isRead).length;
    return AccountNotificationPage(
      items: parsedItems,
      totalCount: _toInt(json['total_count']),
      unreadCount: responseUnreadCount > itemUnreadCount
          ? responseUnreadCount
          : itemUnreadCount,
      page: _toInt(json['page'], fallback: 1),
      pageSize: _toInt(json['page_size'], fallback: 20),
    );
  }
}

class AccountNotificationItem {
  const AccountNotificationItem({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.targetRole,
    required this.targetRoute,
    required this.tab,
    required this.recruitmentTab,
    required this.laborCostTab,
    required this.branchId,
    required this.entityType,
    required this.entityId,
    required this.readAt,
    required this.createdAt,
  });

  final int notificationId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? targetRole;
  final String? targetRoute;
  final int? tab;
  final int? recruitmentTab;
  final int? laborCostTab;
  final String? branchId;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory AccountNotificationItem.fromJson(Map<String, dynamic> json) {
    return AccountNotificationItem(
      notificationId: _toInt(json['notification_id']),
      title: (json['title'] ?? '').toString().trim(),
      body: (json['body'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim(),
      isRead: _toBool(json['is_read']),
      targetRole: _toNullableString(json['target_role']),
      targetRoute: _toNullableString(json['target_route']),
      tab: _toNullableInt(json['tab']),
      recruitmentTab: _toNullableInt(json['recruitment_tab']),
      laborCostTab: _toNullableInt(json['labor_cost_tab']),
      branchId: _toNullableString(json['branch_id']),
      entityType: _toNullableString(json['entity_type']),
      entityId: _toNullableString(json['entity_id']),
      readAt: _toNullableDateTime(json['read_at']),
      createdAt: _toNullableDateTime(json['created_at']),
    );
  }

  String get summaryText {
    if (title.isNotEmpty) return title;
    if (body.isNotEmpty) return body;
    return '알림';
  }

  AccountNotificationItem copyWith({bool? isRead, DateTime? readAt}) {
    return AccountNotificationItem(
      notificationId: notificationId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      targetRole: targetRole,
      targetRoute: targetRoute,
      tab: tab,
      recruitmentTab: recruitmentTab,
      laborCostTab: laborCostTab,
      branchId: branchId,
      entityType: entityType,
      entityId: entityId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toRoutePayload() {
    return <String, dynamic>{
      if (type.isNotEmpty) 'type': type,
      if (targetRole != null) 'target_role': targetRole,
      if (targetRoute != null) 'target_route': targetRoute,
      if (tab != null) 'tab': tab.toString(),
      if (recruitmentTab != null) 'recruitment_tab': recruitmentTab.toString(),
      if (laborCostTab != null) 'labor_cost_tab': laborCostTab.toString(),
      if (branchId != null) 'branch_id': branchId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
    };
  }
}

class AccountNotificationReadResult {
  const AccountNotificationReadResult({
    required this.notificationId,
    required this.isRead,
    required this.readAt,
  });

  final int notificationId;
  final bool isRead;
  final DateTime? readAt;

  factory AccountNotificationReadResult.fromJson(Map<String, dynamic> json) {
    return AccountNotificationReadResult(
      notificationId: _toInt(json['notification_id']),
      isRead: _toBool(json['is_read']),
      readAt: _toNullableDateTime(json['read_at']),
    );
  }
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  final parsed = int.tryParse(value.toString());
  return parsed;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String? _toNullableString(Object? value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty || normalized == 'null') {
    return null;
  }
  return normalized;
}

DateTime? _toNullableDateTime(Object? value) {
  final normalized = _toNullableString(value);
  if (normalized == null) return null;
  return DateTime.tryParse(normalized)?.toLocal();
}
