import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/region/korea_region_tree.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 채용 필터 칩 등 — 저장 경로를 Figma처럼 `서울 > 강남구 > 개포2동`으로 표시.
String regionPathChevronLabel(String storagePath) =>
    regionPathDisplayChevron(storagePath);

/// 다중 선택 필터 칩 라벨 (단일·복수).
String regionFilterPillLabel(List<String> storagePaths) {
  final paths = storagePaths
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (paths.isEmpty) return '전체';
  if (paths.length == 1) return regionPathChevronLabel(paths.single);
  return '${regionPathChevronLabel(paths.first)} 외 ${paths.length - 1}';
}

/// 3단 지역 선택 (시·도 / 시·군·구 / 동·읍·면). [maxSelections]개까지 중복 없이 추가.
/// 반환: 저장용 경로 문자열 목록(공백 구분), 뒤로가기 시 `null`.
Future<List<String>?> showHierarchicalRegionPicker(
  BuildContext context, {
  List<String>? initialSelections,
  int maxSelections = 5,
}) {
  return Navigator.of(context).push<List<String>?>(
    MaterialPageRoute<List<String>?>(
      fullscreenDialog: true,
      builder: (ctx) => _HierarchicalRegionPickerScaffold(
        initialSelections: initialSelections ?? const [],
        maxSelections: maxSelections,
      ),
    ),
  );
}

class _HierarchicalRegionPickerScaffold extends StatefulWidget {
  const _HierarchicalRegionPickerScaffold({
    required this.initialSelections,
    required this.maxSelections,
  });

  final List<String> initialSelections;
  final int maxSelections;

  @override
  State<_HierarchicalRegionPickerScaffold> createState() =>
      _HierarchicalRegionPickerScaffoldState();
}

class _HierarchicalRegionPickerScaffoldState
    extends State<_HierarchicalRegionPickerScaffold> {
  late final TextEditingController _searchCtrl;

  /// `null` = 「지역 전체」행(필터 없음, 적용 시 빈 목록).
  String? _sido;
  String? _district;

  late List<String> _selections;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _selections = widget.initialSelections
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_selections.isNotEmpty) {
      _applyPathToColumns(_selections.first);
    }
    // 빈 상태로 열면 「지역 전체」(적용 시 필터 없음). 시·도를 고르면 시·군·구·동은 `전체`가 기본.
  }

  void _applyPathToColumns(String? storagePath) {
    final raw = storagePath?.trim();
    if (raw == null || raw.isEmpty) return;
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.isEmpty) return;
    final sidoCandidate = parts.first;
    if (!kSidoListFigmaOrder.contains(sidoCandidate)) return;
    _sido = sidoCandidate;
    if (parts.length >= 2) {
      final d = parts[1];
      if (districtsForSido(sidoCandidate).contains(d)) {
        _district = d;
      }
    } else {
      _district = '전체';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// [basePath]보다 한 단계 더 깊은 저장 경로만 제거 (동·읍·면 `전체`로 올릴 때).
  List<String> _pruneSelectionsStrictChildOfPath(
    List<String> current,
    String basePath,
  ) {
    final base = basePath.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (base.isEmpty) return List<String>.from(current);
    final prefix = '$base ';
    return current
        .where(
          (p) =>
              !p.trim().replaceAll(RegExp(r'\s+'), ' ').startsWith(prefix),
        )
        .toList();
  }

  void _tryAddSelection(
    String path, {
    bool pruneStrictChildren = false,
  }) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;

    var baseList = List<String>.from(_selections);
    if (pruneStrictChildren) {
      baseList = _pruneSelectionsStrictChildOfPath(baseList, trimmed);
    }

    for (final existing in baseList) {
      if (regionPathEquals(existing, trimmed)) {
        if (pruneStrictChildren || baseList.length != _selections.length) {
          setState(() => _selections = baseList);
        }
        return;
      }
    }
    if (widget.maxSelections == 1) {
      setState(() => _selections = [trimmed]);
      return;
    }
    if (baseList.length >= widget.maxSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지역은 최대 ${widget.maxSelections}곳까지 선택할 수 있습니다.'),
        ),
      );
      setState(() => _selections = baseList);
      return;
    }
    setState(() => _selections = [...baseList, trimmed]);
  }

  void _removeSelection(String path) {
    setState(() {
      _selections = _selections
          .where((e) => !regionPathEquals(e, path))
          .toList();
    });
  }

  void _resetAll() {
    setState(() {
      _selections = [];
      _sido = null;
      _district = null;
    });
  }

  /// 같은 시·도로 시·도 전체(또는 시·군·구 `전체`)로 돌아가면, 그 시·도의 세부 경로 칩만 제거.
  List<String> _pruneSelectionsForSidoWideBrowse(
    List<String> current,
    String sidoName,
  ) {
    return current
        .where((p) {
          final parts = p.trim().split(RegExp(r'\s+'));
          if (parts.isEmpty) return true;
          if (parts.first != sidoName) return true;
          return parts.length == 1;
        })
        .toList();
  }

  /// 칩이 없을 때 적용 — 현재 열(시·도·시군구·동 기본 전체) 또는 필터 없음.
  List<String> _effectiveApplyList() {
    if (_selections.isNotEmpty) {
      return List<String>.from(_selections);
    }
    if (_sido == null) {
      return <String>[];
    }
    final d = _district ?? '전체';
    return [
      buildRegionStoragePath(
        sido: _sido!,
        district: d,
        dong: '전체',
      ),
    ];
  }

  bool _matchesQuery(String label) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final sido = _sido;
    final districts = sido == null ? const <String>[] : districtsForSido(sido);
    final dongs = (sido == null || _district == null)
        ? const <String>[]
        : dongsFor(sido, _district!);

    final qEmpty = _searchCtrl.text.trim().isEmpty;
    final sidoItems =
        kSidoListFigmaOrder.where(_matchesQuery).toList(growable: false);
    final districtItems =
        districts.where(_matchesQuery).toList(growable: false);
    final dongItems = dongs.where(_matchesQuery).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        backgroundColor: AppColors.grey0,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '지역',
          style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '지역명 검색 예) 서울, 서초구',
                  hintStyle: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Row(
              children: [
                Text(
                  '${_selections.length}/${widget.maxSelections}',
                  style: AppTypography.bodySmallR.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetAll,
                  icon: Icon(Icons.restart_alt_rounded, size: 18.r),
                  label: const Text('초기화'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 23,
                  child: _ColumnPanel(
                    header: '시·도',
                    child: ListView.builder(
                      itemCount: (qEmpty ? 1 : 0) + sidoItems.length,
                      itemBuilder: (context, i) {
                        if (qEmpty && i == 0) {
                          final selected = sido == null;
                          return _Cell(
                            label: '지역 전체',
                            selected: selected,
                            emphasize: selected,
                            onTap: () => setState(() {
                              _sido = null;
                              _district = null;
                              _selections = [];
                            }),
                          );
                        }
                        final idx = i - (qEmpty ? 1 : 0);
                        final name = sidoItems[idx];
                        final selected = sido == name;
                        return _Cell(
                          label: name,
                          selected: selected,
                          emphasize: selected,
                          onTap: () => setState(() {
                            _sido = name;
                            _district = '전체';
                            _selections =
                                _pruneSelectionsForSidoWideBrowse(_selections, name);
                          }),
                        );
                      },
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  flex: 33,
                  child: _ColumnPanel(
                    header: '시·군·구',
                    child: sido == null
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            itemCount: districtItems.length,
                            itemBuilder: (context, i) {
                              final name = districtItems[i];
                              final selected = _district == name;
                              return _Cell(
                                label: name,
                                selected: selected,
                                emphasize: selected,
                                onTap: () => setState(() {
                                  _district = name;
                                  if (name == '전체' && _sido != null) {
                                    _selections =
                                        _pruneSelectionsForSidoWideBrowse(
                                      _selections,
                                      _sido!,
                                    );
                                  }
                                }),
                              );
                            },
                          ),
                  ),
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  flex: 33,
                  child: _ColumnPanel(
                    header: '동·읍·면',
                    child: (sido == null || _district == null)
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            itemCount: dongItems.length,
                            itemBuilder: (context, i) {
                              final dong = dongItems[i];
                              final path = buildRegionStoragePath(
                                sido: sido,
                                district: _district!,
                                dong: dong,
                              );
                              final isPicked = _selections.any(
                                (s) => regionPathEquals(s, path),
                              );
                              return _Cell(
                                label: dong,
                                selected: isPicked,
                                emphasize: isPicked,
                                onTap: () {
                                  _tryAddSelection(
                                    path,
                                    pruneStrictChildren: dong == '전체',
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_selections.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in _selections)
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: InputChip(
                          label: Text(
                            regionPathChevronLabel(p),
                            style: AppTypography.bodySmallR,
                          ),
                          onDeleted: () => _removeSelection(p),
                          deleteIconColor: AppColors.textTertiary,
                          backgroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop<List<String>?>(
                  _effectiveApplyList(),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  minimumSize: Size(double.infinity, 52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('적용'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnPanel extends StatelessWidget {
  const _ColumnPanel({required this.header, required this.child});

  final String header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48.h,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            header,
            style: AppTypography.bodyMediumB.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.selected,
    required this.emphasize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool emphasize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? AppColors.primary : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primaryLight.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          child: Text(
            label,
            style: AppTypography.bodyMediumR.copyWith(
              color: color,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// 이력서 등 단일 경로 선택 — [maxSelections] 1로 동일 화면 사용.
Future<String?> showHierarchicalRegionPickerSingle(
  BuildContext context, {
  String? initialPath,
}) async {
  final list = await showHierarchicalRegionPicker(
    context,
    initialSelections: initialPath == null || initialPath.trim().isEmpty
        ? const []
        : [initialPath.trim()],
    maxSelections: 1,
  );
  if (list == null) return null;
  if (list.isEmpty) return '';
  return list.first;
}
