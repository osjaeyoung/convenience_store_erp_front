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
  static const _dayItemExtent = 56.0;
  static const _visibleDayRange = 28;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelectedDate());
  }

  @override
  void didUpdateWidget(covariant ScheduleDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _animateToSelectedDate(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _buildVisibleDates(DateTime centerDate) {
    final start = centerDate.subtract(
      Duration(days: _visibleDayRange ~/ 2),
    );
    return List.generate(
      _visibleDayRange,
      (i) => start.add(Duration(days: i)),
    );
  }

  void _jumpToSelectedDate() {
    _scrollToSelectedDate(animated: false);
  }

  void _animateToSelectedDate() {
    _scrollToSelectedDate(animated: true);
  }

  void _scrollToSelectedDate({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final visibleDates = _buildVisibleDates(widget.selectedDate);
    final selectedIndex = visibleDates.indexWhere(
      (d) => _isSameDate(d, widget.selectedDate),
    );
    if (selectedIndex < 0) return;

    final offset =
        (selectedIndex * _dayItemExtent) -
        (_scrollController.position.viewportDimension / 2) +
        (_dayItemExtent / 2);
    final targetOffset = offset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    ).toDouble();

    if (animated) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
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

    final weekDays = _buildVisibleDates(selectedDate);

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
                  minWidth: 72.w,
                  maxWidth: 88.w,
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
            itemExtent: _dayItemExtent,
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
    this.minWidth = 56,
    this.maxWidth = 80,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
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
                  child: Text(
                    '$v',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
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
