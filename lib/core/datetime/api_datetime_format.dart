import 'package:intl/intl.dart';

/// API 날짜/시간 직렬화 (서버 참고)
///
/// - FastAPI/Pydantic이 `datetime` / `date`를 반환하면 보통 **ISO 8601 문자열**로 JSON에 실립니다.
/// - DB에서 **timezone-aware**이면 `...+00:00` 같은 오프셋이 붙을 수 있습니다.
/// - 일부 코드 경로는 **`datetime.utcnow()` 등 naive**가 오프셋/`Z` 없이 나갈 수 있어, 클라이언트만으로는
///   UTC인지 로컬(점포 시각)인지 구분이 안 될 수 있습니다.
/// - 앱 전역에서 “항상 UTC + 항상 Z”로 강제하는 설정은 없으며, 이 파일은 **표시용 로컀 시각** 맞춤용
///   공통 파싱만 둡니다.
///
/// [tryParseApiDateTimeToLocal]은 **순간 시각** 문자열에 오프셋/`Z`가 없으면 관례상 **UTC**로 해석한 뒤
/// [DateTime.toLocal]합니다. (실제로 로컬 시각을 naive로 보내는 엔드포인트가 있으면 서버에서
/// timezone-aware 직렬화로 맞추는 편이 안전합니다.)
///
/// 날짜만 오는 값(`yyyy-MM-dd` 등)은 시각이 없다고 보고, Dart [DateTime.tryParse] 기본 해석을 유지합니다.

bool _hasExplicitTimezone(String s) {
  if (s.endsWith('Z') || s.endsWith('z')) return true;
  return RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s) ||
      RegExp(r'[+-]\d{4}$').hasMatch(s);
}

bool _looksLikeDateTimeInstant(String s) {
  return s.contains('T') || RegExp(r'\d{4}-\d{2}-\d{2}\s+\d').hasMatch(s);
}

/// API에서 내려오는 ISO 8601 문자열을 **기기 로컀** [DateTime]으로 파싱합니다.
DateTime? tryParseApiDateTimeToLocal(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  if (_hasExplicitTimezone(s)) {
    final dt = DateTime.tryParse(s);
    return dt?.toLocal();
  }

  if (!_looksLikeDateTimeInstant(s)) {
    final dt = DateTime.tryParse(s);
    return dt?.toLocal();
  }

  var normalized = s;
  if (normalized.contains(' ') && !normalized.contains('T')) {
    normalized = normalized.replaceFirst(RegExp(r'\s+'), 'T');
  }
  final asUtc = DateTime.tryParse('${normalized}Z');
  final dt = asUtc ?? DateTime.tryParse(normalized);
  return dt?.toLocal();
}

/// 계약 채팅 목록·말풍선 등 짧은 시각 표기 (로컬).
String formatContractChatBubbleTime(String? raw) {
  final local = tryParseApiDateTimeToLocal(raw);
  if (local == null) return '';
  return DateFormat('a h:mm', 'ko_KR').format(local);
}

/// 계약 채팅 목록 행 우측 등 날짜+시각 표기 (로컬).
String formatContractChatListTime(String? raw) {
  final local = tryParseApiDateTimeToLocal(raw);
  if (local == null) return '';
  return DateFormat('M.d a h:mm', 'ko_KR').format(local);
}
