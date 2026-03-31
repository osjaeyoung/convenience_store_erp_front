import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/labor_cost/saving_detail.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 인건비 절감 상세 (API 3)
class LaborCostSavingDetailScreen extends StatefulWidget {
  const LaborCostSavingDetailScreen({
    super.key,
    required this.branchId,
    this.initialYear,
    this.initialMonth,
    this.embedded = false,
  });

  final int branchId;
  final int? initialYear;
  final int? initialMonth;
  final bool embedded;

  @override
  State<LaborCostSavingDetailScreen> createState() =>
      _LaborCostSavingDetailScreenState();
}

class _LaborCostSavingDetailScreenState extends State<LaborCostSavingDetailScreen> {
  late int _year;
  late int _month;
  LaborSavingDetail? _data;
  bool _loading = true;
  String? _error;
  final Set<int> _expandedPointIndex = <int>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<LaborCostRepository>();
      final d = await repo.getSavingDetail(
        branchId: widget.branchId,
        year: _year,
        month: _month,
      );
      if (!mounted) return;
      setState(() {
        _data = d;
        _expandedPointIndex
          ..clear()
          ..addAll(List<int>.generate(d.weeklyAllowanceImprovementPoints.length, (i) => i));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: '조회할 월 선택',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _year = picked.year;
      _month = picked.month;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMediumR.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      FilledButton(onPressed: _load, child: const Text('다시 시도')),
                    ],
                  ),
                ),
              )
            : _buildScroll(_data!);

    if (widget.embedded) {
      return ColoredBox(color: AppColors.grey0, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        surfaceTintColor: AppColors.grey0,
        title: Text('인건비 절감 상세', style: AppTypography.appBarTitle),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _pickMonth,
            icon: Icon(Icons.calendar_month_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildScroll(LaborSavingDetail d) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.only(bottom: 32.h),
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: '퇴직금 발생 예정 인원'),
                SizedBox(height: 12.h),
                if (d.retirementExpectedWorkers.isEmpty)
                  _emptyCard('해당 조건에 해당하는 인원이 없습니다.')
                else
                  _RetirementTable(workers: d.retirementExpectedWorkers),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.grey25,
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _SectionTitle(title: '주휴수당 절감 개선'),
          ),
          SizedBox(height: 12.h),
          if (d.weeklyAllowanceImprovementPoints.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyCard(text: '개선안 데이터가 없습니다.'),
            )
          else
            ...List<Widget>.generate(
              d.weeklyAllowanceImprovementPoints.length,
              (i) => _weeklyPointCard(
                i,
                d.weeklyAllowanceImprovementPoints[i],
                expanded: _expandedPointIndex.contains(i),
              ),
            ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.grey25,
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: '중복 근무 발생 현황'),
                SizedBox(height: 12.h),
                if (d.overlappingWorkIssues.isEmpty)
                  _emptyCard('중복 근무 이슈가 없습니다.')
                else
                  _OverlapTable(items: d.overlappingWorkIssues),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return _EmptyCard(text: text);
  }

  Widget _weeklyPointCard(
    int index,
    WeeklyAllowanceImprovementPoint p, {
    required bool expanded,
  }) {
    final afterWorkers = p.resolvedAfterWorkers;
    final hasBefore = p.beforeWorkers.isNotEmpty;
    final hasAfter = afterWorkers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey0,
            border: Border(
              bottom: BorderSide(color: AppColors.grey50),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_expandedPointIndex.contains(index)) {
                    _expandedPointIndex.remove(index);
                  } else {
                    _expandedPointIndex.add(index);
                  }
                });
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                child: Row(
                  children: [
                    Text(
                      p.pointTitle,
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          Container(
            width: double.infinity,
            color: AppColors.grey0Alt,
            padding: EdgeInsets.all(20.r),
            child: Column(
              children: [
                if (hasBefore)
                  _WorkersMiniTable(
                    title: '변경 전',
                    titleBg: AppColors.grey50,
                    rows: p.beforeWorkers,
                  ),
                if (hasBefore && hasAfter) ...[
                  SizedBox(height: 16.h),
                  const _PointFlowArrow(),
                  SizedBox(height: 16.h),
                ],
                if (hasAfter)
                  _WorkersMiniTable(
                    title: '변경 후',
                    titleBg: AppColors.primary,
                    rows: afterWorkers,
                  ),
                if (!hasBefore && !hasAfter)
                  const _EmptyCard(text: '표시할 근로자 정보가 없습니다.'),
              ],
            ),
          ),
      ],
    );
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.bodyLargeM.copyWith(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        height: 24 / 18,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _RetirementTable extends StatelessWidget {
  const _RetirementTable({required this.workers});

  final List<RetirementExpectedWorker> workers;

  @override
  Widget build(BuildContext context) {
    return _ThreeColumnTable(
      headers: const ['이름', '근로 계약일', '퇴직금 발생일'],
      rows: [
        for (final w in workers) [
          w.employeeName,
          w.hireDate,
          w.severanceEligibleDate,
        ],
      ],
    );
  }
}

class _WorkersMiniTable extends StatelessWidget {
  const _WorkersMiniTable({
    required this.title,
    required this.titleBg,
    required this.rows,
  });

  final String title;
  final Color titleBg;
  final List<WorkerInfo> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: titleBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            alignment: Alignment.center,
            child: Text(
              title,
              style: AppTypography.bodyMediumB.copyWith(
                fontSize: 14.sp,
                height: 16 / 14,
                color: titleBg == AppColors.primary
                    ? AppColors.grey0
                    : AppColors.textTertiary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 8.h),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _WorkerDetailRow(
                    worker: rows[i],
                    showDivider: i != rows.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlapTable extends StatelessWidget {
  const _OverlapTable({required this.items});

  final List<OverlappingWorkIssue> items;

  @override
  Widget build(BuildContext context) {
    return _ThreeColumnTable(
      headers: const ['날짜', '근무자', '근무시간'],
      rows: [
        for (final i in items) [
          i.workDate,
          i.employeeName,
          i.overlapTimeRange,
        ],
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _PointFlowArrow extends StatelessWidget {
  const _PointFlowArrow();

  static const String _arrowSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="17" height="11" viewBox="0 0 17 11" fill="none">
  <path d="M9.53139 10.2543C8.73385 11.1752 7.30522 11.1752 6.50767 10.2543L0.493172 3.30931C-0.62858 2.01402 0.291525 0 2.00503 0L14.034 0C15.7475 0 16.6676 2.01402 15.5459 3.30931L9.53139 10.2543Z" fill="#70D2B3"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.string(
        _arrowSvg,
        width: 17,
        height: 11,
      ),
    );
  }
}

class _WorkerDetailRow extends StatelessWidget {
  const _WorkerDetailRow({
    required this.worker,
    required this.showDivider,
  });

  final WorkerInfo worker;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isNewHire = worker.employeeName.contains('신규채용');
    final workHours = _weeklyHoursLabel(worker.weeklyWorkMinutes);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.grey25),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              worker.employeeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLargeR.copyWith(
                height: 1,
                color: isNewHire ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WorkerMetaItem(label: '구분', value: worker.category),
              Container(
                width: 1,
                height: 14,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                color: AppColors.grey25,
              ),
              _WorkerMetaItem(
                label: '주 근로시간',
                value: workHours,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerMetaItem extends StatelessWidget {
  const _WorkerMetaItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmallB.copyWith(
            color: AppColors.textTertiary,
            fontSize: 12.sp,
            height: 16 / 12,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
            height: 19 / 14,
          ),
        ),
      ],
    );
  }
}

class _ThreeColumnTable extends StatelessWidget {
  const _ThreeColumnTable({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  static const List<int> _columnFlexes = [47, 57, 57];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TableRow(
          cells: headers,
          flexes: _columnFlexes,
          isHeader: true,
        ),
        for (final row in rows)
          _TableRow(
            cells: row,
            flexes: _columnFlexes,
          ),
        Container(
          height: 1,
          color: AppColors.grey200,
        ),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.flexes,
    this.isHeader = false,
  });

  final List<String> cells;
  final List<int> flexes;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textStyle = isHeader
        ? AppTypography.bodySmallB.copyWith(
            color: AppColors.textSecondary,
            height: 16 / 12,
          )
        : AppTypography.bodyMediumR.copyWith(
            color: AppColors.textPrimary,
            height: 19 / 14,
          );

    return Container(
      constraints: BoxConstraints(minHeight: isHeader ? 32 : 40),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.grey25 : AppColors.grey0,
        border: Border(
          top: isHeader
              ? const BorderSide(color: AppColors.grey200)
              : BorderSide.none,
          bottom: isHeader
              ? BorderSide.none
              : const BorderSide(color: AppColors.grey25),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: i == 0 ? 10 : 12,
                  vertical: isHeader ? 8 : 10,
                ),
                child: Text(
                  cells[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _weeklyHoursLabel(int minutes) {
  if (minutes % 60 == 0) {
    return '${minutes ~/ 60}';
  }
  return LaborCostFormatters.workMinutesLabel(minutes);
}
