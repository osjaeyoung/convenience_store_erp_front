import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/recruitment/recruitment_models.dart';

class RecruitmentChatReadStore {
  const RecruitmentChatReadStore._();

  static const String _prefix = 'recruitment_chat_last_read_at_';

  static Future<void> markReadThrough({
    required int chatId,
    String? lastMessageAt,
  }) async {
    final trimmed = lastMessageAt?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _key(chatId);
    final previous = prefs.getString(key);
    if (_compareIso(trimmed, previous) <= 0) return;

    await prefs.setString(key, trimmed);
  }

  static Future<List<RecruitmentChatSummary>> applyLocalReadState({
    required List<RecruitmentChatSummary> chats,
    required Future<RecruitmentChatMessagePage> Function(int chatId)
    fetchMessages,
  }) async {
    if (chats.isEmpty) return chats;

    final prefs = await SharedPreferences.getInstance();
    return Future.wait(
      chats.map((chat) async {
        final lastReadAt = prefs.getString(_key(chat.chatId));
        if (lastReadAt == null || lastReadAt.isEmpty || chat.unreadCount <= 0) {
          return chat;
        }

        if (_compareIso(chat.lastMessageAt, lastReadAt) <= 0) {
          return chat.copyWith(unreadCount: 0);
        }

        try {
          final page = await fetchMessages(chat.chatId);
          final currentRole = page.currentUserRole.toLowerCase();
          final unreadAfterLocalRead = page.messages.where((message) {
            final createdAt = message.createdAt;
            if (_compareIso(createdAt, lastReadAt) <= 0) return false;
            return message.senderRole?.toLowerCase() != currentRole;
          }).length;

          return chat.copyWith(unreadCount: unreadAfterLocalRead);
        } catch (_) {
          return chat;
        }
      }),
    );
  }

  static String _key(int chatId) => '$_prefix$chatId';

  static int _compareIso(String? left, String? right) {
    final leftDate = _parseDate(left);
    final rightDate = _parseDate(right);
    if (leftDate != null && rightDate != null) {
      return leftDate.compareTo(rightDate);
    }
    final safeLeft = left ?? '';
    final safeRight = right ?? '';
    return safeLeft.compareTo(safeRight);
  }

  static DateTime? _parseDate(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
}
