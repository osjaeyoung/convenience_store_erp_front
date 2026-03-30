/// 입력 모달 등에서 라벨을 제목으로 쓸 때, 괄호 안 부연을 제거합니다.
/// 예: `주민등록번호(마스킹)` → `주민등록번호`, `친권자(후견인) 성명` → `친권자 성명`
String modalTitleWithoutParenthetical(String label) {
  var s = label.trim();
  if (s.isEmpty) return s;
  final asciiParen = RegExp(r'\([^)]*\)');
  final fullwidthParen = RegExp(r'（[^）]*）');
  var guard = 0;
  while (guard++ < 32) {
    final next = s
        .replaceAll(asciiParen, '')
        .replaceAll(fullwidthParen, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (next == s) break;
    s = next;
  }
  if (s.isEmpty) {
    // 라벨이 전부 괄호만 있는 등 예외: 첫 구간만 사용
    final beforeParen = label.trim().split(RegExp(r'[（(]'));
    if (beforeParen.isNotEmpty) return beforeParen.first.trim();
    return label.trim();
  }
  return s;
}
