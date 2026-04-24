// `docs/api_spec_recruitment.md` — `region` 쿼리·시·도 별칭(1-1)과 맞춤.

/// 한 번의 요청에 실을 수 있는 `region` 값 개수 상한(서버가 초과 시 앞 5개만 사용).
const int kRegionQueryMaxValues = 5;

/// 시·도 단일 토큰(또는 경로의 첫 토큰)을 앱 지역 트리 라벨로 맞춤.
String canonicalSidoToken(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  const aliases = <String, String>{
    '서울시': '서울',
    '서울특별시': '서울',
    '부산시': '부산',
    '부산광역시': '부산',
    '울산시': '울산',
    '울산광역시': '울산',
    '대구시': '대구',
    '대구광역시': '대구',
    '인천시': '인천',
    '인천광역시': '인천',
    '광주시': '광주',
    '광주광역시': '광주',
    '대전시': '대전',
    '대전광역시': '대전',
    '세종시': '세종',
    '세종특별자치시': '세종',
    '경기도': '경기',
    '강원도': '강원',
    '강원특별자치도': '강원',
    '충청북도': '충북',
    '충청남도': '충남',
    '경상북도': '경북',
    '경상남도': '경남',
    '전라북도': '전북',
    '전북특별자치도': '전북',
    '전라남도': '전남',
    '제주특별자치도': '제주',
    '제주도': '제주',
    // 응답 `region_options`가 시·도가 아닌 짧은 표기로 올 때(명세 예시)
    '제주시': '제주',
  };
  return aliases[t] ?? t;
}

/// `서울 강남구 개포2동`처럼 공백 경로면 **첫 토큰만** 시·도 별칭 정규화.
String normalizeRegionQueryPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return trimmed;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.isEmpty) return trimmed;
  parts[0] = canonicalSidoToken(parts[0]);
  return parts.join(' ');
}

/// 쿼리·칩 비교용(공백 정리 + 첫 토큰 별칭).
String normalizeRegionQueryKey(String path) =>
    normalizeRegionQueryPath(path).replaceAll(RegExp(r'\s+'), ' ').trim();

bool regionQueryKeysEqual(String a, String b) =>
    normalizeRegionQueryKey(a) == normalizeRegionQueryKey(b);

/// `GET .../postings` 등에 넣기 전: 빈 값 제거, 경로 정규화, **최대 [kRegionQueryMaxValues]개**.
List<String> prepareRegionQueryList(List<String>? regions) {
  if (regions == null || regions.isEmpty) return const [];
  final out = <String>[];
  for (final r in regions) {
    final n = normalizeRegionQueryPath(r);
    if (n.isEmpty) continue;
    out.add(n);
    if (out.length >= kRegionQueryMaxValues) break;
  }
  return out;
}

/// `region=서울&region=경기` 와 동일하게 파싱되는 `region=서울,경기` 형식.
String? regionQueryParamCommaJoined(List<String>? regions) {
  final list = prepareRegionQueryList(regions);
  if (list.isEmpty) return null;
  return list.join(',');
}

/// 응답 `region_options` — 시·도 별칭 통일·중복 제거·순서 유지.
List<String> dedupeNormalizedRegionOptions(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in raw) {
    final n = normalizeRegionQueryPath(r);
    if (n.isEmpty || seen.contains(n)) continue;
    seen.add(n);
    out.add(n);
  }
  return out;
}
