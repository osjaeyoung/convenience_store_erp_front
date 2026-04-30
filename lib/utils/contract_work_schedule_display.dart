import 'dart:convert';

import 'contract_work_day_form.dart';

const List<String> _weekdayKor = ['월', '화', '수', '목', '금', '토', '일'];

typedef ContractWorkSlot = ({
  int dayIndex,
  String start,
  String end,
  bool breakHas,
  String breakStart,
  String breakEnd,
});

String? contractWorkScheduleSummary(Map<String, dynamic> formValues) {
  final slots = contractWorkSlotsFromFormValues(formValues);
  if (slots.isEmpty) return null;
  final groups = <String, List<int>>{};
  for (final slot in slots) {
    final key = _formatRange(slot.start, slot.end);
    groups.putIfAbsent(key, () => []).add(slot.dayIndex);
  }
  return groups.entries
      .map((entry) => '${_formatDayIndexRuns(entry.value)} ${entry.key}')
      .join(' / ');
}

String? contractBreakTimeSummary(Map<String, dynamic> formValues) {
  final slots = contractWorkSlotsFromFormValues(formValues);
  if (slots.isEmpty) return null;
  final workDays = slots.map((slot) => slot.dayIndex).toSet();
  final groups = <String, List<int>>{};
  for (final slot in slots) {
    if (!slot.breakHas) continue;
    final start = slot.breakStart;
    final end = slot.breakEnd;
    if (start.isEmpty && end.isEmpty) continue;
    final key = start.isNotEmpty && end.isNotEmpty
        ? _formatRange(start, end)
        : '$start~$end';
    groups.putIfAbsent(key, () => []).add(slot.dayIndex);
  }
  if (groups.isEmpty) return null;
  if (groups.length == 1) {
    final entry = groups.entries.first;
    final days = entry.value.toSet();
    if (days.length == workDays.length && workDays.every(days.contains)) {
      return entry.key;
    }
  }
  return groups.entries
      .map((entry) => '${_formatDayIndexRuns(entry.value)} ${entry.key}')
      .join(' / ');
}

List<ContractWorkSlot> contractWorkSlotsFromFormValues(
  Map<String, dynamic> formValues,
) {
  final values = migrateLegacyWorkDayKeysInMap(
    Map<String, dynamic>.from(formValues),
  );
  final out = <ContractWorkSlot>[];
  for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
    final apiDay = dayIndex + 1;
    final slots = _decodeSlots(values['work_day_${apiDay}_slots']);
    if (slots.isNotEmpty) {
      for (final slot in slots) {
        final start = slot['start']?.toString().trim() ?? '';
        final end = slot['end']?.toString().trim() ?? '';
        if (start.isEmpty && end.isEmpty) continue;
        final breakStart = slot['break_start']?.toString().trim() ?? '';
        final breakEnd = slot['break_end']?.toString().trim() ?? '';
        out.add((
          dayIndex: dayIndex,
          start: start,
          end: end,
          breakHas: breakStart.isNotEmpty || breakEnd.isNotEmpty,
          breakStart: breakStart,
          breakEnd: breakEnd,
        ));
      }
      continue;
    }

    final enabled = values['work_day_${apiDay}_enabled']?.toString().trim();
    if (enabled == '0') continue;
    final start = values['work_day_${apiDay}_start']?.toString().trim() ?? '';
    final end = values['work_day_${apiDay}_end']?.toString().trim() ?? '';
    if (enabled != '1' && start.isEmpty && end.isEmpty) continue;
    if (start.isEmpty && end.isEmpty) continue;
    final breakHas =
        values['work_day_${apiDay}_break_has']?.toString().trim() == '1';
    out.add((
      dayIndex: dayIndex,
      start: start,
      end: end,
      breakHas: breakHas,
      breakStart:
          values['work_day_${apiDay}_break_start']?.toString().trim() ?? '',
      breakEnd: values['work_day_${apiDay}_break_end']?.toString().trim() ?? '',
    ));
  }
  return out;
}

List<Map<String, dynamic>> _decodeSlots(Object? raw) {
  Object? decoded = raw;
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const [];
    }
  }
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry('$key', value)))
      .toList();
}

String _formatRange(String start, String end) => '$start~$end';

String _formatDayIndexRuns(Iterable<int> rawIndices) {
  final indices = rawIndices.toSet().toList()..sort();
  if (indices.isEmpty) return '';
  if (indices.length == 7 && indices.first == 0 && indices.last == 6) {
    return '매일';
  }
  if (indices.length == 5 &&
      indices[0] == 0 &&
      indices[1] == 1 &&
      indices[2] == 2 &&
      indices[3] == 3 &&
      indices[4] == 4) {
    return '월~금';
  }
  final runs = <List<int>>[];
  for (final index in indices) {
    if (runs.isEmpty || index != runs.last.last + 1) {
      runs.add([index]);
    } else {
      runs.last.add(index);
    }
  }
  return runs
      .map(
        (run) => run.length == 1
            ? _weekdayKor[run.first]
            : '${_weekdayKor[run.first]}~${_weekdayKor[run.last]}',
      )
      .join('·');
}
