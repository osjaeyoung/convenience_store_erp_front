/// 근로계약 `form_values`의 요일별 근무 (`docs/api_spec_contract_chat.md`).
/// - API: `work_day_1` = 월요일 … `work_day_7` = 일요일
/// - 화면 루프 인덱스 `i`: 0 = 월 … 6 = 일
String contractWorkDayFormFieldKey(int mondayIndex0to6, String suffix) {
  assert(mondayIndex0to6 >= 0 && mondayIndex0to6 <= 6, 'mondayIndex0to6');
  return 'work_day_${mondayIndex0to6 + 1}_$suffix';
}

final _workDayKeyRe = RegExp(r'^work_day_(\d+)(?:_(.+))?$');

/// `work_day_0`…`work_day_6`만 저장된 계약 데이터를 API 규격 `work_day_1`…`7`로 옮깁니다.
/// 명세상 `work_day_0`…`6`은 Sunday-first 체크박스 형식(0=일, 6=토)입니다.
/// 이미 `work_day_7`이 있거나 `work_day_0`이 없으면 변경하지 않습니다.
Map<String, dynamic> migrateLegacyWorkDayKeysInMap(Map<String, dynamic> raw) {
  final legacy = raw.keys.any(
    (k) => k == 'work_day_0' || k.startsWith('work_day_0_'),
  );
  final hasApiSunday = raw.keys.any(
    (k) => k == 'work_day_7' || k.startsWith('work_day_7_'),
  );
  if (!legacy || hasApiSunday) return raw;

  final out = Map<String, dynamic>.from(raw);
  final remove = <String>[];
  final add = <String, dynamic>{};

  for (final e in out.entries) {
    final m = _workDayKeyRe.firstMatch(e.key);
    if (m == null) continue;
    final d = int.tryParse(m.group(1)!) ?? -1;
    if (d < 0 || d > 6) continue;
    remove.add(e.key);
    final apiDay = d == 0 ? 7 : d;
    final suffix = m.group(2);
    add[suffix == null ? 'work_day_$apiDay' : 'work_day_${apiDay}_$suffix'] =
        e.value;
  }
  for (final k in remove) {
    out.remove(k);
  }
  out.addAll(add);
  return out;
}
