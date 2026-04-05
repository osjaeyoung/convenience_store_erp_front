import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 근로계약 목록·상세에서 첨부 파일·파일전용(##23-1) 판별
class EmploymentContractAttachmentHelpers {
  EmploymentContractAttachmentHelpers._();

  static String? chatStatus(Map<String, dynamic> c) {
    final value = c['chat_status']?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  static String? chatStatusLabel(Map<String, dynamic> c) {
    final rawStatus = chatStatus(c);
    if (rawStatus == null) return null;
    switch (rawStatus) {
      case 'business_draft':
      case 'waiting_worker':
        return '미완료';
      case 'completed':
        return '작성 완료';
    }
    final value = c['chat_status_label']?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// `files` 또는 단일 `contract_file_url`
  static bool hasAttachment(Map<String, dynamic> c) {
    final url = c['contract_file_url']?.toString().trim();
    if (url != null && url.isNotEmpty) return true;
    final files = c['files'];
    if (files is! List || files.isEmpty) return false;
    for (final f in files) {
      if (f is! Map) continue;
      final u = f['file_url']?.toString().trim();
      if (u != null && u.isNotEmpty) return true;
      final k = f['file_key']?.toString().trim();
      if (k != null && k.isNotEmpty) return true;
    }
    return false;
  }

  /// 스펙 ##23-1: `status=draft`, `completion_rate=0` + 첨부 → 화면상 "계약완료"·파일 중심 상세
  static bool isFileOnlyRegistration(Map<String, dynamic> c) {
    if (!hasAttachment(c)) return false;
    if (chatStatus(c) != null) return false;
    final status = c['status']?.toString() ?? '';
    if (status == 'completed') return false;
    final rate = (c['completion_rate'] as num?)?.toInt() ?? 0;
    return rate == 0;
  }

  static bool isCompleted(Map<String, dynamic> c) {
    final chat = chatStatus(c);
    if (chat != null) return chat == 'completed';
    final status = c['status']?.toString() ?? '';
    return status == 'completed' || isFileOnlyRegistration(c);
  }

  static String? primaryFileUrl(Map<String, dynamic> c) {
    final single = c['contract_file_url']?.toString().trim();
    if (single != null && single.isNotEmpty) return single;
    final files = c['files'];
    if (files is! List) return null;
    for (final f in files) {
      if (f is! Map) continue;
      final u = f['file_url']?.toString().trim();
      if (u != null && u.isNotEmpty) return u;
    }
    for (final f in files) {
      if (f is! Map) continue;
      final k = f['file_key']?.toString().trim();
      if (k != null && k.isNotEmpty) {
        final composed = _publicUrlForFileKey(k);
        if (composed != null) return composed;
      }
    }
    return null;
  }

  /// 응답에 `file_url`이 없고 `file_key`만 있을 때, 앱 `.env` 베이스로 조합 (업로드 시와 동일)
  static String? _publicUrlForFileKey(String fileKey) {
    final base = dotenv.env['S3_PUBLIC_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) return null;
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$normalized/$fileKey';
  }

  /// `files` 중 첫 `file_id` (##26-1 `file_id` 쿼리). 없으면 생략해도 됨.
  static int? primaryFileId(Map<String, dynamic> c) {
    final files = c['files'];
    if (files is! List) return null;
    for (final f in files) {
      if (f is! Map) continue;
      final id = f['file_id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    }
    return null;
  }

  static String? primaryFileName(Map<String, dynamic> c) {
    final files = c['files'];
    if (files is List) {
      for (final f in files) {
        if (f is! Map) continue;
        final n = f['file_name']?.toString().trim();
        if (n != null && n.isNotEmpty) return n;
      }
    }
    final url = primaryFileUrl(c);
    if (url != null) {
      final seg = Uri.tryParse(url)?.pathSegments;
      if (seg != null && seg.isNotEmpty && seg.last.isNotEmpty) {
        return seg.last;
      }
    }
    return null;
  }
}
