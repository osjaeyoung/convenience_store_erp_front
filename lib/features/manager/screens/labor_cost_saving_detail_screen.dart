import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/labor_cost/saving_detail.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';

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
                  padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('다시 시도')),
                    ],
                  ),
                ),
              )
            : _buildScroll(_data!);

    if (widget.embedded) {
      return ColoredBox(color: AppColors.grey0Alt, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _MonthBar(
            label: LaborCostFormatters.periodYearMonth(d.year, d.month),
            onTap: _pickMonth,
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: '퇴직금 발생 예정 인원'),
          const SizedBox(height: 10),
          if (d.retirementExpectedWorkers.isEmpty)
            _emptyCard('해당 조건에 해당하는 인원이 없습니다.')
          else
            ...d.retirementExpectedWorkers.map(_retirementCard),
          const SizedBox(height: 24),
          _SectionTitle(title: '주휴수당 개선안'),
          const SizedBox(height: 10),
          if (d.weeklyAllowanceImprovementPoints.isEmpty)
            _emptyCard('개선안 데이터가 없습니다.')
          else
            ...d.weeklyAllowanceImprovementPoints.map(_weeklyPointCard),
          const SizedBox(height: 24),
          _SectionTitle(title: '중복 근무 발생 현황'),
          const SizedBox(height: 10),
          if (d.overlappingWorkIssues.isEmpty)
            _emptyCard('중복 근무 이슈가 없습니다.')
          else
            ...d.overlappingWorkIssues.map(_overlapCard),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _retirementCard(RetirementExpectedWorker w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              w.employeeName,
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _miniRow('입사일', w.hireDate),
            _miniRow('퇴직금 기준 예정일', w.severanceEligibleDate),
            _miniRow(
              '최근 4주 평균 주 근로',
              LaborCostFormatters.workMinutesLabel(
                w.averageWeeklyMinutesRecent4weeks,
              ),
            ),
            _miniRow(
              '주 15시간(900분) 이상',
              w.legalWeeklyHoursConditionMet ? '충족' : '미충족',
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyPointCard(WeeklyAllowanceImprovementPoint p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.pointTitle,
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (p.legalBasis != null && p.legalBasis!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                p.legalBasis!,
                style: AppTypography.bodySmallR.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 16 / 12,
                ),
              ),
            ],
            if (p.beforeWorkers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '현황',
                style: AppTypography.bodySmallM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              ...p.beforeWorkers.map(_workerLine),
            ],
            if (p.afterWorkers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '개선안',
                style: AppTypography.bodySmallM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              ...p.afterWorkers.map(_workerLine),
            ],
          ],
        ),
      ),
    );
  }

  Widget _workerLine(WorkerInfo w) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              w.employeeName,
              style: AppTypography.bodyMediumR.copyWith(fontSize: 13),
            ),
          ),
          Text(
            w.category,
            style: AppTypography.bodySmallR.copyWith(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            LaborCostFormatters.workMinutesLabel(w.weeklyWorkMinutes),
            style: AppTypography.bodySmallM.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _overlapCard(OverlappingWorkIssue o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              o.workDate,
              style: AppTypography.bodyMediumM.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              o.employeeName,
              style: AppTypography.bodyMediumR.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '중복: ${o.overlapTimeRange}',
              style: AppTypography.bodySmallR.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: AppTypography.bodySmallR.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppTypography.bodySmallM.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
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
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.expand_more_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
