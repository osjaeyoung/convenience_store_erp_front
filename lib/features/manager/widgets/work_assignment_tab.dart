import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../bloc/staff_management_bloc.dart';
import 'schedule_date_selector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 30분 슬롯 시간 라벨 (00:00 ~ 23:30)
const _slotTimes = [
  '00:00',
  '00:30',
  '01:00',
  '01:30',
  '02:00',
  '02:30',
  '03:00',
  '03:30',
  '04:00',
  '04:30',
  '05:00',
  '05:30',
  '06:00',
  '06:30',
  '07:00',
  '07:30',
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
  '19:00',
  '19:30',
  '20:00',
  '20:30',
  '21:00',
  '21:30',
  '22:00',
  '22:30',
  '23:00',
  '23:30',
];

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String _slotEndTime(String time) {
  final parts = time.split(':');
  var h = int.tryParse(parts[0]) ?? 0;
  var m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  m += 30;
  if (m >= 60) {
    m -= 60;
    h += 1;
  }
  if (h >= 24) h = 0;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// 근무 배정 탭
/// - 일별/주별 전환, 일별: 오늘, 주별: 가로 스크롤 그리드
/// - 일별/직원 미지정 selector 스타일
/// - 드래그 필터: 직원 미지정 시 + 버튼, 지정 시 드래그로 시간대 선택
class WorkAssignmentTab extends StatefulWidget {
  const WorkAssignmentTab({
    super.key,
    required this.branchId,
    required this.daySchedule,
    required this.weekSchedule,
    required this.employeesCompare,
    required this.today,
    required this.onPullToRefresh,
    required this.onRefreshToday,
    required this.onRefreshWeek,
    this.onDragModeChanged,
  });

  final int branchId;
  final Map<String, dynamic>? daySchedule;
  final Map<String, dynamic>? weekSchedule;
  final Map<String, dynamic>? employeesCompare;
  final DateTime today;
  final Future<void> Function(String weekStartDate) onPullToRefresh;
  final VoidCallback onRefreshToday;
  final void Function(String weekStartDate) onRefreshWeek;
  final void Function(bool isDragMode)? onDragModeChanged;

  @override
  State<WorkAssignmentTab> createState() => _WorkAssignmentTabState();
}

class _WorkAssignmentTabState extends State<WorkAssignmentTab> {
  ({int id, String name})? _dragFilterEmployee;
  Set<String> _dragSelectedSlots = {};
  Map<String, List<({int id, String name})>> _assignments = {};
  bool _isDailyView = true;
  DateTime _weekSelectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncFromDaySchedule();
    _syncFromWeekSchedule();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefreshToday();
      widget.onRefreshWeek(_toIsoDate(_getWeekStart(widget.today)));
    });
  }

  @override
  void didUpdateWidget(WorkAssignmentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.daySchedule != widget.daySchedule) {
      _syncFromDaySchedule();
    }
    if (oldWidget.weekSchedule != widget.weekSchedule) {
      _syncFromWeekSchedule();
    }
  }

  DateTime _getWeekStart(DateTime d) {
    final weekday = d.weekday;
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  void _syncFromWeekSchedule() {
    final days = (widget.weekSchedule?['days'] as List?) ?? [];
    final map = <String, Map<String, List<({int id, String name})>>>{};
    for (final dayData in days) {
      if (dayData is! Map) continue;
      final workDate = dayData['work_date']?.toString().trim() ?? '';
      if (workDate.isEmpty) continue;
      final slots = (dayData['slots'] as List?) ?? [];
      final dayMap = <String, List<({int id, String name})>>{};
      for (final slot in slots) {
        if (slot is! Map) continue;
        final time = slot['time']?.toString().trim() ?? '';
        if (time.isEmpty) continue;
        final employees = (slot['employees'] as List?) ?? [];
        dayMap[time] = employees
            .whereType<Map>()
            .map(
              (e) => (
                id: _toInt(e['employee_id']),
                name:
                    e['worker_name']?.toString() ??
                    e['name']?.toString() ??
                    '-',
              ),
            )
            .toList();
      }
      for (final t in _slotTimes) {
        dayMap.putIfAbsent(t, () => []);
      }
      map[workDate] = dayMap;
    }
    setState(() => _weekAssignments = map);
  }

  Map<String, Map<String, List<({int id, String name})>>> _weekAssignments = {};

  void _syncFromDaySchedule() {
    final slots = ((widget.daySchedule?['slots'] as List?) ?? [])
        .whereType<Map>()
        .toList();
    final map = <String, List<({int id, String name})>>{};
    for (final slot in slots) {
      final time = slot['time']?.toString().trim() ?? '';
      if (time.isEmpty) continue;
      final employees = ((slot['employees'] as List?) ?? [])
          .whereType<Map>()
          .toList();
      map[time] = employees
          .map(
            (e) => (
              id: _toInt(e['employee_id']),
              name:
                  e['worker_name']?.toString() ?? e['name']?.toString() ?? '-',
            ),
          )
          .toList();
    }
    for (final t in _slotTimes) {
      map.putIfAbsent(t, () => []);
    }
    setState(() => _assignments = map);
  }

  List<({int id, String name})> _getActiveWorkers() {
    final list = (widget.employeesCompare?['active_workers'] as List?) ?? [];
    return list
        .whereType<Map>()
        .map(
          (e) => (
            id: _toInt(e['employee_id']),
            name: e['name']?.toString() ?? '-',
          ),
        )
        .toList();
  }

  List<({int id, String name})> _getRetiredWorkers() {
    final list = (widget.employeesCompare?['retired_workers'] as List?) ?? [];
    return list
        .whereType<Map>()
        .map(
          (e) => (
            id: _toInt(e['employee_id']),
            name: e['name']?.toString() ?? '-',
          ),
        )
        .toList();
  }

  bool get _isDragMode => _dragFilterEmployee != null;

  /// "이사라, 김테스트" 형태를 ["이사라", "김테스트"]로 분리 (1인 1줄 표시)
  static List<String> _expandNames(List<String> names) {
    final result = <String>[];
    for (final n in names) {
      final parts = n
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      result.addAll(parts.isEmpty ? [n] : parts);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handlePullToRefresh,
            child: _isDailyView ? _buildDailyView() : _buildWeeklyView(),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Future<void> _handlePullToRefresh() {
    final targetDate = _isDailyView ? widget.today : _weekSelectedDate;
    return widget.onPullToRefresh(_toIsoDate(_getWeekStart(targetDate)));
  }

  Widget _buildDailyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectorRow(),
          if (_isDragMode) ...[
            SizedBox(height: 24.h),
            _buildDragInstruction(),
            SizedBox(height: 12.h),
          ],
          SizedBox(height: 12.h),
          _buildDateLabel(),
          SizedBox(height: 12.h),
          _buildSlotGridContent(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    final weekStart = _getWeekStart(_weekSelectedDate);
    final weekDays = _getWeekDays(weekStart);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleDateSelector(
            selectedDate: _weekSelectedDate,
            onDateChanged: (date) {
              setState(() {
                _weekSelectedDate = date;
                widget.onRefreshWeek(_toIsoDate(_getWeekStart(date)));
              });
            },
          ),
          SizedBox(height: 16.h),
          _buildSelectorRow(),
          SizedBox(height: 16.h),
          if (_isDragMode)
            _buildWeeklyGridContent(weekDays)
          else
            _buildWeeklyTableContent(weekDays),
        ],
      ),
    );
  }

  Widget _buildWeeklyTableContent(List<DateTime> weekDays) {
    const minRowHeight = 44.0;
    final tableBodyHeight = _slotTimes.length * minRowHeight * 2.5;
    final tableHeaderHeight = 120.0;
    final totalTableHeight = tableHeaderHeight + tableBodyHeight;
    return SizedBox(
      height: totalTableHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: weekDays.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return Padding(
              padding: EdgeInsets.only(right: i < weekDays.length - 1 ? 12 : 0),
              child: _WeekDayTable(
                dateLabel:
                    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}(${_weekdays[d.weekday - 1]})',
                dateStr: _toIsoDate(d),
                assignments: _weekAssignments[_toIsoDate(d)] ?? {},
                slotTimes: _slotTimes,
                isDragMode: false,
                dragSelectedSlots: const {},
                onSlotTap: (time) =>
                    _showEmployeePickerForSlot(time, _toIsoDate(d)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 드래그 시 주별: 가로 스크롤, 1줄=1날짜, 1화면에 2개 날짜 넓이, 날짜 chip + 슬롯 세로 배치
  Widget _buildWeeklyGridContent(List<DateTime> weekDays) {
    const columnSpacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - columnSpacing) / 2;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weekDays.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value;
              final dateStr = _toIsoDate(d);
              final dateLabel =
                  '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}(${_weekdays[d.weekday - 1]})';
              return SizedBox(
                width: columnWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < weekDays.length - 1 ? columnSpacing : 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 12.h),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(color: AppColors.grey25),
                              color: AppColors.grey0Alt,
                            ),
                            child: Text(
                              dateLabel,
                              style: AppTypography.bodyMediumM.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ..._slotTimes.map((time) {
                        final isSelected = _dragSelectedSlots.contains(
                          _dragSlotKey(dateStr, time),
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _SlotCard(
                            startTime: time,
                            endTime: _slotEndTime(time),
                            assignedNames: const [],
                            isDragSelected: isSelected,
                            showPlusButton: false,
                            onPlusTap: () {},
                            onTap: () => _toggleDragSlot(time, dateStr),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSelectorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SelectorChip(
          label: _isDailyView ? '일별' : '주별',
          onTap: () => setState(() {
            _isDailyView = !_isDailyView;
            if (!_isDailyView) {
              _weekSelectedDate = widget.today;
              widget.onRefreshWeek(
                _toIsoDate(_getWeekStart(_weekSelectedDate)),
              );
            }
          }),
        ),
        _SelectorChip(
          label: _dragFilterEmployee?.name ?? '직원 미지정',
          onTap: _showEmployeeFilterModal,
        ),
      ],
    );
  }

  Widget _buildDateLabel() {
    final date = widget.today;
    final dateLabel = '${date.day}일 (${_weekdays[date.weekday - 1]})';
    return Text(
      dateLabel,
      style: AppTypography.bodyLargeM.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 20 / 16,
      ),
    );
  }

  Widget _buildDragInstruction() {
    final name = _dragFilterEmployee?.name ?? '';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: RichText(
        text: TextSpan(
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w400,
            height: 32 / 24,
          ),
          children: [
            const TextSpan(text: '현 근무자 '),
            TextSpan(
              text: '$name',
              style: TextStyle(color: AppColors.primary),
            ),
            const TextSpan(text: ' 사원의\n근무 배정 시간대를\n드래그 해주세요.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGridContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _slotTimes.map((time) {
            final assigned = _assignments[time] ?? [];
            final isSelected = _dragSelectedSlots.contains(
              _dragSlotKey(_toIsoDate(widget.today), time),
            );
            final names = _isDragMode
                ? <String>[]
                : _expandNames(assigned.map((a) => a.name).toList());
            return SizedBox(
              width: itemWidth,
              child: _SlotCard(
                startTime: time,
                endTime: _slotEndTime(time),
                assignedNames: names,
                isDragSelected: isSelected,
                showPlusButton: !_isDragMode,
                onPlusTap: () => _showEmployeePickerForSlot(time),
                onTap: _isDragMode ? () => _toggleDragSlot(time) : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    final isComplete = _isDragMode;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isComplete ? _onCompleteDrag : _onConfirmSchedule,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.grey0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              isComplete ? '완료' : '일정 확정',
              style: AppTypography.bodyLargeB.copyWith(color: AppColors.grey0),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeFilterModal() async {
    final active = _getActiveWorkers();
    final retired = _getRetiredWorkers();
    final selected = await showDialog<({int id, String name})>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _EmployeeSelectionModal(
        activeWorkers: active,
        retiredWorkers: retired,
        initialSelected: _dragFilterEmployee,
      ),
    );
    if (mounted) {
      setState(() {
        _dragFilterEmployee = selected;
        _dragSelectedSlots = {};
      });
      widget.onDragModeChanged?.call(selected != null);
    }
  }

  void _showEmployeePickerForSlot(String time, [String? dateStr]) async {
    final active = _getActiveWorkers();
    final retired = _getRetiredWorkers();
    if (active.isEmpty && retired.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('배정 가능한 직원이 없습니다.')));
      }
      return;
    }
    final picked = await showDialog<({int id, String name})>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _EmployeeSelectionModal(
        activeWorkers: active,
        retiredWorkers: retired,
        title: '직원 선택',
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (dateStr != null) {
          final dayMap = Map<String, List<({int id, String name})>>.from(
            _weekAssignments[dateStr] ?? {},
          );
          final list = dayMap[time] ?? [];
          if (!list.any((e) => e.id == picked.id)) {
            dayMap[time] = [...list, picked];
            _weekAssignments = {..._weekAssignments, dateStr: dayMap};
          }
        } else {
          final list = _assignments[time] ?? [];
          if (!list.any((e) => e.id == picked.id)) {
            _assignments[time] = [...list, picked];
          }
        }
      });
    }
  }

  void _toggleDragSlot(String time, [String? dateStr]) {
    final key = _dragSlotKey(dateStr ?? _toIsoDate(widget.today), time);
    setState(() {
      if (_dragSelectedSlots.contains(key)) {
        _dragSelectedSlots = {..._dragSelectedSlots}..remove(key);
      } else {
        _dragSelectedSlots = {..._dragSelectedSlots, key};
      }
    });
  }

  static String _dragSlotKey(String dateStr, String time) => '$dateStr\_$time';

  void _onCompleteDrag() {
    final emp = _dragFilterEmployee;
    if (emp == null) return;
    final todayStr = _toIsoDate(widget.today);
    setState(() {
      for (final key in _dragSelectedSlots) {
        final idx = key.indexOf('_');
        if (idx < 0) continue;
        final dateStr = key.substring(0, idx);
        final time = key.substring(idx + 1);
        if (dateStr == todayStr) {
          final list = _assignments[time] ?? [];
          if (!list.any((e) => e.id == emp.id)) {
            _assignments[time] = [...list, emp];
          }
        } else {
          final dayMap = Map<String, List<({int id, String name})>>.from(
            _weekAssignments[dateStr] ?? {},
          );
          final list = dayMap[time] ?? [];
          if (!list.any((e) => e.id == emp.id)) {
            dayMap[time] = [...list, emp];
            _weekAssignments = {..._weekAssignments, dateStr: dayMap};
          }
        }
      }
      _dragFilterEmployee = null;
      _dragSelectedSlots = {};
    });
    widget.onDragModeChanged?.call(false);
  }

  void _onConfirmSchedule() {
    final bloc = context.read<StaffManagementBloc>();
    final slots = _slotTimes.map((time) {
      final list = _assignments[time] ?? [];
      return {
        'time': time,
        'assignments': list
            .map(
              (a) => {'employee_id': a.id, 'status': 'scheduled', 'memo': null},
            )
            .toList(),
      };
    }).toList();
    bloc.add(
      StaffManagementDaySchedulePutRequested(
        branchId: widget.branchId,
        workDate: _toIsoDate(widget.today),
        slots: slots,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일정이 확정되었습니다.')));
    }
  }

  static String _toIsoDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static int _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// 주별 일일 테이블 - 근무일정과 유사한 테이블 형식 (시간, 직원 헤더)
class _WeekDayTable extends StatelessWidget {
  const _WeekDayTable({
    required this.dateLabel,
    required this.dateStr,
    required this.assignments,
    required this.slotTimes,
    required this.isDragMode,
    required this.dragSelectedSlots,
    required this.onSlotTap,
  });

  final String dateLabel;
  final String dateStr;
  final Map<String, List<({int id, String name})>> assignments;
  final List<String> slotTimes;
  final bool isDragMode;
  final Set<String> dragSelectedSlots;
  final void Function(String time) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 날짜 헤더 - 근무일정과 동일한 pill 스타일
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppColors.grey25),
                  color: AppColors.grey0Alt,
                ),
                child: Text(
                  dateLabel,
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // 테이블 헤더 - 시간, 직원 (근무일정 스타일)
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey25,
              border: Border(
                top: BorderSide(color: Color(0xFF666874), width: 1),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    '시간',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmallB.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '직원',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmallB.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 30분 단위 행 - 같은 사람이어도 30분씩 끊어서 표시, 행마다 회색 디바이더
          ...slotTimes.map((time) {
            final endTime = _slotEndTime(time);
            final assigned = isDragMode
                ? <({int id, String name})>[]
                : (assignments[time] ?? []);
            final isDragSelected = dragSelectedSlots.contains(
              '$dateStr\_$time',
            );
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey25)),
              ),
              child: _SlotRow(
                startTime: time,
                endTime: endTime,
                assigned: assigned,
                isDragSelected: isDragSelected,
                showPlusButton: !isDragMode,
                onSlotTap: onSlotTap,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 주별 테이블 슬롯 행 - 30분 단위, 시간 2줄(시작~종료) + 직원 칩, 드래그 선택 시 녹색
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.startTime,
    required this.endTime,
    required this.assigned,
    required this.isDragSelected,
    required this.showPlusButton,
    required this.onSlotTap,
  });

  final String startTime;
  final String endTime;
  final List<({int id, String name})> assigned;
  final bool isDragSelected;
  final bool showPlusButton;
  final void Function(String time) onSlotTap;

  @override
  Widget build(BuildContext context) {
    final timeColor = isDragSelected
        ? AppColors.primary
        : AppColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: isDragSelected
          ? BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.primary),
            )
          : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startTime,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: timeColor,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    endTime,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: timeColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onSlotTap(startTime),
                behavior: HitTestBehavior.opaque,
                child: _StaffSlotCell(
                  assigned: assigned,
                  showPlusButton: showPlusButton,
                  onAddTap: () => onSlotTap(startTime),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 직원 슬롯 셀 - 근무자명 1인당 1줄(세로), 맨 밑에 + 버튼 (드래그 모드에서는 숨김)
class _StaffSlotCell extends StatelessWidget {
  const _StaffSlotCell({
    required this.assigned,
    required this.showPlusButton,
    required this.onAddTap,
  });

  final List<({int id, String name})> assigned;
  final bool showPlusButton;
  final VoidCallback onAddTap;

  /// "이사라, 김테스트" 형태도 1인 1줄로 분리
  List<String> _namesToDisplay() {
    final result = <String>[];
    for (final a in assigned) {
      final parts = a.name
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      if (parts.isEmpty) {
        result.add(a.name);
      } else {
        result.addAll(parts);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final names = _namesToDisplay();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...names.map(
          (name) => Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: _StaffNameChip(name: name),
          ),
        ),
        if (showPlusButton)
          GestureDetector(
            onTap: onAddTap,
            behavior: HitTestBehavior.opaque,
            child: const _AddEmployeeChip(),
          ),
      ],
    );
  }
}

/// 근무자명 칩 - 1인 1줄, 중앙 정렬
class _StaffNameChip extends StatelessWidget {
  const _StaffNameChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey50),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: AppTypography.bodySmallR.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
        ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 직원 추가 버튼 칩 - 연두색 배경, 직원 body 전체 너비
class _AddEmployeeChip extends StatelessWidget {
  const _AddEmployeeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.primary),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.add, size: 18, color: AppColors.primary),
    );
  }
}

/// 근무일정 년도 selector와 동일 스타일
class _SelectorChip extends StatelessWidget {
  const _SelectorChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: onTap != null ? AppColors.grey150 : AppColors.grey100,
            ),
          ],
        ),
      ),
    );
  }
}

/// 슬롯 카드: 시작/종료 시간 2줄, 추가버튼, 근무자칩
class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.startTime,
    required this.endTime,
    required this.assignedNames,
    required this.isDragSelected,
    required this.showPlusButton,
    required this.onPlusTap,
    this.onTap,
  });

  final String startTime;
  final String endTime;
  final List<String> assignedNames;
  final bool isDragSelected;
  final bool showPlusButton;
  final VoidCallback onPlusTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDragSlot = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isDragSlot ? 16 : 8),
        decoration: BoxDecoration(
          color: isDragSelected ? AppColors.primaryLight : AppColors.grey0,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDragSelected ? AppColors.primary : AppColors.grey50,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              startTime,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumM.copyWith(
                color: isDragSelected ? AppColors.primary : AppColors.grey200,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
            if (isDragSlot) SizedBox(height: 8.h),
            Text(
              endTime,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumM.copyWith(
                color: isDragSelected ? AppColors.primary : AppColors.grey200,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
            if (assignedNames.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: assignedNames
                      .map(
                        (n) => Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey0Alt,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.grey150),
                            ),
                            child: Text(
                              n,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMediumM.copyWith(
                                color: AppColors.grey200,
                                fontSize: 14.sp,
                                height: 16 / 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (showPlusButton)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: GestureDetector(
                  onTap: onPlusTap,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 직원 선택 모달 - 드래그 지정/슬롯 추가 공통
class _EmployeeSelectionModal extends StatefulWidget {
  const _EmployeeSelectionModal({
    required this.activeWorkers,
    required this.retiredWorkers,
    this.initialSelected,
    this.title = '드래그 입력 직원 지정',
  });

  final List<({int id, String name})> activeWorkers;
  final List<({int id, String name})> retiredWorkers;
  final ({int id, String name})? initialSelected;
  final String title;

  @override
  State<_EmployeeSelectionModal> createState() =>
      _EmployeeSelectionModalState();
}

class _EmployeeSelectionModalState extends State<_EmployeeSelectionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ({int id, String name})? _selected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selected = widget.initialSelected;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.grey150,
              indicatorColor: AppColors.textPrimary,
              indicatorWeight: 0.5,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              dividerColor: Colors.transparent,
              labelStyle: AppTypography.bodyLargeB.copyWith(
                color: AppColors.textPrimary,
                height: 24 / 16,
              ),
              unselectedLabelStyle: AppTypography.bodyLargeB.copyWith(
                color: AppColors.grey150,
                height: 24 / 16,
              ),
              tabs: const [
                Tab(text: '현근무자'),
                Tab(text: '퇴사자'),
              ],
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EmployeeGrid(
                    workers: widget.activeWorkers,
                    selected: _selected,
                    onSelect: (e) => setState(() => _selected = e),
                  ),
                  _EmployeeGrid(
                    workers: widget.retiredWorkers,
                    selected: _selected,
                    onSelect: (e) => setState(() => _selected = e),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                      backgroundColor: AppColors.grey0,
                      foregroundColor: AppColors.grey150,
                      side: const BorderSide(color: AppColors.grey25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected != null
                        ? () => Navigator.of(context).pop(_selected)
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 직원 그리드 - 1줄에 2개씩, 선택: 연두 배경/테두리, 미선택: 회색 배경/테두리
class _EmployeeGrid extends StatelessWidget {
  const _EmployeeGrid({
    required this.workers,
    required this.selected,
    required this.onSelect,
  });

  final List<({int id, String name})> workers;
  final ({int id, String name})? selected;
  final ValueChanged<({int id, String name})> onSelect;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return Center(
        child: Text(
          '직원이 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(color: AppColors.grey150),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.only(top: 16.h),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: workers.length,
      itemBuilder: (context, i) {
        final w = workers[i];
        final isSelected = selected?.id == w.id;
        return GestureDetector(
          onTap: () => onSelect(w),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.grey0Alt,
              borderRadius: BorderRadius.circular(isSelected ? 12 : 8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey150,
              ),
            ),
            child: Center(
              child: Text(
                w.name,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.grey200,
                  height: 16 / 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
