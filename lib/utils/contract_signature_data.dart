import 'dart:convert';
import 'dart:typed_data';

bool isContractSignatureDataUrl(String? v) {
  if (v == null || v.isEmpty) return false;
  final s = v.trim();
  return s.startsWith('data:image/') && s.contains(';base64,');
}

Uint8List? decodeContractSignatureDataUrl(String v) {
  final s = v.trim();
  final idx = s.indexOf(';base64,');
  if (idx < 0) return null;
  try {
    return base64Decode(s.substring(idx + 8));
  } catch (_) {
    return null;
  }
}

/// PDF·플레인 텍스트 본문용 — data URL 전체를 넣지 않고 짧은 표기만 사용
String contractSignaturePlainText(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return '';
  if (isContractSignatureDataUrl(s)) return '[전자서명]';
  return s;
}
