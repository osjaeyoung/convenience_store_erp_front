import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/labor_cost/monthly_detail.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';

/// 월별 인건비 직원 목록 (API 2)
class LaborCostMonthlyListScreen extends StatefulWidget {
  const LaborCostMonthlyListScreen({
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
  State<LaborCostMonthlyListScreen> createState() =>
      _LaborCostMonthlyListScreenState();
}

class _LaborCostMonthlyListScreenState extends State<LaborCostMonthlyListScreen> {
  late int _year;
  late int _month;
  int _day = 1;
  MonthlyLaborDetail? _data;
  bool _loading = true;
  String? _error;
  final Set<int> _expandedEmployeeIds = <int>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
    _day = now.day;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<LaborCostRepository>();
      final d = await repo.getMonthlyDetail(
        branchId: widget.branchId,
        year: _year,
        month: _month,
      );
      if (!mounted) return;
      setState(() {
        _data = d;
        _expandedEmployeeIds
          ..clear()
          ..addAll(d.employees.map((e) => e.employeeId).take(1));
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
      _day = picked.day;
    });
    _load();
  }

  String _filterDateLabel() {
    final weekday = ['월', '화', '수', '목', '금', '토', '일'];
    final lastDay = DateTime(_year, _month + 1, 0).day;
    final safeDay = _day.clamp(1, lastDay);
    final date = DateTime(_year, _month, safeDay);
    final w = weekday[date.weekday - 1];
    final mm = _month.toString().padLeft(2, '0');
    final dd = safeDay.toString().padLeft(2, '0');
    return '$_year.$mm.$dd($w)';
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
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
            : _buildBody(_data!);

    if (widget.embedded) {
      return ColoredBox(color: AppColors.grey0Alt, child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        surfaceTintColor: AppColors.grey0,
        title: Text('월별 인건비', style: AppTypography.appBarTitle),
        centerTitle: false,
      ),
      body: content,
    );
  }

  Widget _buildBody(MonthlyLaborDetail d) {
    final changePercent = d.changeRatePercent.abs().toStringAsFixed(0);
    final changeWentUp = d.changeRatePercent >= 0;
    final allowanceSummary = d.componentSummaries
        .map((e) => '${e.componentName} ${LaborCostFormatters.won(e.amount)}')
        .join(' · ');

    return RefreshIndicator(
      onRefresh: _load,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          children: [
          _MonthFilterBar(
            label: _filterDateLabel(),
            businessDays: d.businessDays,
            onTap: _pickMonth,
          ),
          const SizedBox(height: 12),
          if (d.employees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.grey0,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '해당 월 급여 데이터가 없습니다.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            ...d.employees.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmployeeAccordionCard(
                  employee: e,
                  expanded: _expandedEmployeeIds.contains(e.employeeId),
                  onToggle: () {
                    setState(() {
                      if (_expandedEmployeeIds.contains(e.employeeId)) {
                        _expandedEmployeeIds.remove(e.employeeId);
                      } else {
                        _expandedEmployeeIds.add(e.employeeId);
                      }
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          _MonthlySummaryCard(
            totalWorkMinutes: d.totalWorkMinutes,
            totalCost: d.totalCost,
            allowanceSummary: allowanceSummary.isEmpty ? '-' : allowanceSummary,
            totalEmployeeCount: d.totalEmployeeCount,
            changePercentText: '$changePercent%',
            changeWentUp: changeWentUp,
          ),
          ],
        ),
      ),
    );
  }
}

class _MonthFilterBar extends StatelessWidget {
  const _MonthFilterBar({
    required this.label,
    required this.businessDays,
    required this.onTap,
  });

  final String label;
  final int businessDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.grey25),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTypography.bodyMediumM.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 16 / 14,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Text(
              '영업일수 $businessDays일',
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14,
                color: AppColors.textTertiary,
                height: 19 / 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeAccordionCard extends StatelessWidget {
  const _EmployeeAccordionCard({
    required this.employee,
    required this.expanded,
    required this.onToggle,
  });

  final EmployeeLaborDetail employee;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final badgeOn = employee.wageType == 'monthly';
    final weeklyHours = (employee.totalWorkMinutes / 60).toStringAsFixed(0);
    final badgeText = badgeOn ? '월급' : '시급';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey50),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: badgeOn ? AppColors.primary : AppColors.grey200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTypography.bodySmallB.copyWith(
                              fontSize: 12,
                              color: AppColors.grey0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(
                          'assets/icons/png/common/star_green_icon.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          employee.employeeName,
                          style: AppTypography.bodyLargeR.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 16 / 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: AppColors.grey150,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: _metricValue(
                              label: '근무시간',
                              value: '${employee.totalWorkMinutes}',
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.grey50,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: _metricValue(
                              label: '주 근로',
                              value: weeklyHours,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        decoration: BoxDecoration(
                          color: AppColors.grey0Alt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _detailLine(
                              label: employee.wageTypeLabel,
                              value: _wageAmountText(employee.wageAmount),
                            ),
                            _detailLine(
                              label: '기타수당액',
                              value: LaborCostFormatters.won(employee.overtimePay),
                            ),
                            _detailLine(
                              label: '주휴수당액',
                              value: LaborCostFormatters.won(employee.weeklyAllowance),
                            ),
                            _detailLine(
                              label: '기본 급여액',
                              value: LaborCostFormatters.won(employee.basePay),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ],
                  ),
                ),
                if (expanded)
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.grey0Alt,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: AppColors.grey25),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _detailLine(
                      label: '총 급여액',
                      value: LaborCostFormatters.won(employee.totalCost),
                      strong: true,
                      bottomPadding: 0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _wageAmountText(int? amount) {
    if (amount == null || amount <= 0) return '-';
    return LaborCostFormatters.won(amount);
  }

  Widget _metricValue({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodySmallB.copyWith(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 16 / 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMediumR.copyWith(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 20 / 16,
          ),
        ),
      ],
    );
  }

  Widget _detailLine({
    required String label,
    required String value,
    bool strong = false,
    double bottomPadding = 12,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMediumR.copyWith(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: (strong ? AppTypography.bodyLargeB : AppTypography.bodyMediumR)
                .copyWith(
              fontSize: strong ? 16 : 15,
              color: strong ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.totalWorkMinutes,
    required this.totalCost,
    required this.allowanceSummary,
    required this.totalEmployeeCount,
    required this.changePercentText,
    required this.changeWentUp,
  });

  final int totalWorkMinutes;
  final int totalCost;
  final String allowanceSummary;
  final int totalEmployeeCount;
  final String changePercentText;
  final bool changeWentUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey0,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey0Alt,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                _summaryLine(label: '총 근무시간 합계', value: '$totalWorkMinutes'),
                const Divider(height: 16, color: AppColors.grey25),
                _summaryLine(label: '총 급여', value: LaborCostFormatters.won(totalCost)),
                const Divider(height: 16, color: AppColors.grey25),
                _summaryLine(label: '수당내역', value: allowanceSummary),
                const Divider(height: 16, color: AppColors.grey25),
                _summaryLine(label: '총 근무자', value: '$totalEmployeeCount명'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '전월대비',
                  style: AppTypography.bodyLargeR.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$changePercentText ${changeWentUp ? '증가' : '감소'}',
                  style: AppTypography.bodyLargeR.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumB.copyWith(
            fontSize: 14,
            color: AppColors.textTertiary,
            height: 16 / 14,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyLargeR.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 16 / 16,
            ),
          ),
        ),
      ],
    );
  }
}
