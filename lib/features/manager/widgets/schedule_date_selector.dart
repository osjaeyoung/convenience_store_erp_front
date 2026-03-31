import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 근무일정용 날짜 선택기
/// - 년/월/일 드롭다운 (selector 스타일)
/// - 가로 스크롤 일별 캘린더 (오늘 가운데)
class ScheduleDateSelector extends StatefulWidget {
  const ScheduleDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<ScheduleDateSelector> createState() => _ScheduleDateSelectorState();
}

class _ScheduleDateSelectorState extends State<ScheduleDateSelector> {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    const itemWidth = 56.0;
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 14));
    final days = List.generate(28, (i) => start.add(Duration(days: i)));
    final todayIndex = days.indexWhere(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );
    if (todayIndex >= 0) {
      final offset = (todayIndex * itemWidth) - (_scrollController.position.viewportDimension / 2) + (itemWidth / 2);
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedDate;
    final year = selectedDate.year;
    final month = selectedDate.month;
    final day = selectedDate.day;

    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 2 + i);
    final months = List.generate(12, (i) => i + 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = List.generate(daysInMonth, (i) => i + 1);

    final start = now.subtract(const Duration(days: 14));
    final weekDays = List.generate(28, (i) => start.add(Duration(days: i)));

    final labelStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      height: 19 / 14,
      color: AppColors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Selector(
                  value: year,
                  options: years,
                  onChanged: (v) => _apply(year: v),
                ),
                SizedBox(width: 8.w),
                Text('년', style: labelStyle),
                SizedBox(width: 16.w),
                _Selector(
                  value: month,
                  options: months,
                  onChanged: (v) => _apply(month: v),
                ),
                SizedBox(width: 8.w),
                Text('월', style: labelStyle),
                SizedBox(width: 16.w),
                _Selector(
                  value: day,
                  options: days,
                  onChanged: (v) => _apply(day: v),
                ),
                SizedBox(width: 8.w),
                Text('일', style: labelStyle),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          height: 60,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemExtent: 56,
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final d = weekDays[index];
              final isSelected = d.year == year &&
                  d.month == month &&
                  d.day == day;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => widget.onDateChanged(d),
                  child: Container(
                    width: 48,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdays[d.weekday - 1],
                          style: AppTypography.bodyMediumM.copyWith(
                            color: isSelected
                                ? AppColors.grey0
                                : AppColors.grey200,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 16 / 14,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${d.day}',
                          style: AppTypography.heading3.copyWith(
                            color: isSelected
                                ? AppColors.grey0
                                : AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            height: 24 / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h),
        const Divider(height: 1, color: AppColors.grey50),
      ],
    );
  }

  void _apply({int? year, int? month, int? day}) {
    final y = year ?? widget.selectedDate.year;
    final m = month ?? widget.selectedDate.month;
    var d = day ?? widget.selectedDate.day;
    final maxDay = DateTime(y, m + 1, 0).day;
    if (d > maxDay) d = maxDay;
    widget.onDateChanged(DateTime(y, m, d));
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56, maxWidth: 80),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey50),
        color: AppColors.grey0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.grey150,
          ),
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            height: 19 / 14,
          ),
          items: options
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text('$v', textAlign: TextAlign.center),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
