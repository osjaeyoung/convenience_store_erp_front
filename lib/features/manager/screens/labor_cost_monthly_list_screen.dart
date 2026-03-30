import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/labor_cost/monthly_detail.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';
import 'labor_cost_employee_detail_screen.dart';

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
  /// true: 탭 내부 — 앱바 없이 본문만
  final bool embedded;

  @override
  State<LaborCostMonthlyListScreen> createState() =>
      _LaborCostMonthlyListScreenState();
}

class _LaborCostMonthlyListScreenState extends State<LaborCostMonthlyListScreen> {
  late int _year;
  late int _month;
  MonthlyLaborDetail? _data;
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
      final d = await repo.getMonthlyDetail(
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
        actions: [
          IconButton(
            onPressed: _pickMonth,
            icon: Icon(Icons.calendar_month_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildBody(MonthlyLaborDetail d) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.grey0,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    d.periodLabel,
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
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _summaryRow('총 인건비', LaborCostFormatters.won(d.totalCost)),
                const Divider(height: 20, color: AppColors.grey25),
                _summaryRow('근무 인원', '${d.totalEmployeeCount}명'),
                const Divider(height: 20, color: AppColors.grey25),
                _summaryRow(
                  '총 근무시간',
                  LaborCostFormatters.workMinutesLabel(d.totalWorkMinutes),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '직원별 내역',
            style: AppTypography.bodyLargeM.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (d.employees.isEmpty)
            Container(
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
            )
          else
            ...d.employees.map((e) => _EmployeeTile(
                  employee: e,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => LaborCostEmployeeDetailScreen(
                          periodLabel: d.periodLabel,
                          employee: e,
                        ),
                      ),
                    );
                  },
                )),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMediumM.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, required this.onTap});

  final EmployeeLaborDetail employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.employeeName,
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _WageBadge(label: employee.wageTypeLabel),
                          const SizedBox(width: 8),
                          Text(
                            LaborCostFormatters.won(employee.totalCost),
                            style: AppTypography.bodySmallM.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey100,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WageBadge extends StatelessWidget {
  const _WageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmallM.copyWith(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
