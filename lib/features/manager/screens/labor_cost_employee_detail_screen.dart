import 'package:flutter/material.dart';

import '../../../data/models/labor_cost/monthly_detail.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';

/// 직원 월별 인건비 상세 (목록 → 상세)
class LaborCostEmployeeDetailScreen extends StatelessWidget {
  const LaborCostEmployeeDetailScreen({
    super.key,
    required this.periodLabel,
    required this.employee,
  });

  final String periodLabel;
  final EmployeeLaborDetail employee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        surfaceTintColor: AppColors.grey0,
        title: Text(employee.employeeName, style: AppTypography.appBarTitle),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            periodLabel,
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LaborCostFormatters.won(employee.totalCost),
                  style: AppTypography.heading2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '월 총 인건비',
                  style: AppTypography.bodySmallM.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            children: [
              _row('급여 유형', employee.wageTypeLabel),
              _row(
                '계약 단가',
                employee.wageType == 'hourly'
                    ? '${LaborCostFormatters.won(employee.wageAmount)} / 시'
                    : LaborCostFormatters.won(employee.wageAmount),
              ),
              _row(
                '근무 시간',
                '${LaborCostFormatters.workMinutesLabel(employee.totalWorkMinutes)} '
                '(${employee.totalWorkHours.toStringAsFixed(1)}시간)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '급여 구성',
            children: [
              _row('총급여(기본)', LaborCostFormatters.won(employee.basePay)),
              _row('주휴수당', LaborCostFormatters.won(employee.weeklyAllowance)),
              _row('기타·연장', LaborCostFormatters.won(employee.overtimePay)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              k,
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                title!,
                style: AppTypography.bodyLargeM.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}
