import 'package:flutter/material.dart';

import '../../../data/models/labor_cost/monthly_detail.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../labor/labor_cost_formatters.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        children: [
          Text(
            periodLabel,
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LaborCostFormatters.won(employee.totalCost),
                  style: AppTypography.heading2.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '월 총 인건비',
                  style: AppTypography.bodySmallM.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _SectionCard(
            children: [
              _row('급여 유형', employee.wageTypeLabel),
              _row(
                '계약 단가',
                _wageAmountLabel(employee),
              ),
              _row(
                '근무 시간',
                '${LaborCostFormatters.workMinutesLabel(employee.totalWorkMinutes)} '
                '(${employee.totalWorkHours.toStringAsFixed(1)}시간)',
              ),
            ],
          ),
          SizedBox(height: 12.h),
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
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              k,
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _wageAmountLabel(EmployeeLaborDetail employee) {
    final amount = employee.wageAmount;
    if (amount == null || amount <= 0) return '미설정';
    final won = LaborCostFormatters.won(amount);
    return employee.wageType == 'hourly' ? '$won / 시' : won;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
              child: Text(
                title!,
                style: AppTypography.bodyLargeM.copyWith(
                  fontSize: 15.sp,
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
