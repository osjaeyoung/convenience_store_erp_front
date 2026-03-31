import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/employee_profile_box.dart';
import '../widgets/work_status_badge.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmployeeWorkHistoryScreen extends StatelessWidget {
  const EmployeeWorkHistoryScreen({
    super.key,
    required this.branchName,
    required this.employeeName,
    required this.hireDate,
    required this.contact,
    this.resignationDate,
    this.starCount,
    required this.workHistories,
  });

  final String branchName;
  final String employeeName;
  final String hireDate;
  final String contact;
  final String? resignationDate;
  final int? starCount;
  final List<Map<String, dynamic>> workHistories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('근무 이력'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmployeeProfileBox(
              name: employeeName,
              hireDate: hireDate,
              contact: contact,
              resignationDate: resignationDate,
              showEditButton: false,
              starCount: starCount,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Text(
                  '근무 이력',
                  style: AppTypography.heading3.copyWith(
                    color: const Color(0xFF1D1D1F),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    height: 24 / 18,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9D9DAA),
                    foregroundColor: AppColors.grey0,
                    minimumSize: const Size(58, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    '수정',
                    style: AppTypography.bodySmallB.copyWith(
                      color: AppColors.grey0,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _WorkHistoryTable(
              branchName: branchName,
              rows: workHistories,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkHistoryTable extends StatelessWidget {
  const _WorkHistoryTable({
    required this.branchName,
    required this.rows,
  });

  final String branchName;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            color: AppColors.grey25,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: const Row(
              children: [
                _HeaderCell('근무지점'),
                _HeaderCell('근무날짜'),
                _HeaderCell('근무시간'),
                _HeaderCell('근무상태'),
                _HeaderCell('메모'),
              ],
            ),
          ),
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey25)),
              ),
              child: Text(
                '근무 이력이 없습니다.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ...rows.map((row) {
              final memo = (row['memo'] as String?)?.trim() ?? '';
              return Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey25)),
                ),
                child: Row(
                  children: [
                    _BodyCell(_extractBranchName(row, branchName)),
                    _BodyCell(_extractWorkDate(row)),
                    _BodyCell(_extractWorkTime(row)),
                    Expanded(
                      child: Center(
                        child: WorkStatusBadge(
                          status: row['status']?.toString() ?? '',
                          compact: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _MemoButton(memo: memo),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _extractBranchName(Map<String, dynamic> row, String fallbackBranchName) {
    final branchName = row['branch_name']?.toString().trim();
    if (branchName != null && branchName.isNotEmpty) return branchName;
    if (fallbackBranchName.trim().isNotEmpty) return fallbackBranchName.trim();
    return '-';
  }

  String _extractWorkDate(Map<String, dynamic> row) {
    final workDate = row['work_date']?.toString();
    if (workDate != null && workDate.isNotEmpty) return workDate;
    final updatedAt = row['updated_at']?.toString();
    if (updatedAt != null && updatedAt.contains('T')) {
      return updatedAt.split('T').first;
    }
    return '-';
  }

  String _extractWorkTime(Map<String, dynamic> row) {
    final startTime = row['start_time']?.toString() ?? '';
    final endTime = row['end_time']?.toString() ?? '';
    if (startTime.isEmpty && endTime.isEmpty) return '-';
    if (startTime.isNotEmpty && endTime.isNotEmpty) return '$startTime~$endTime';
    return startTime.isNotEmpty ? startTime : endTime;
  }
}

class _MemoButton extends StatelessWidget {
  const _MemoButton({required this.memo});

  final String memo;

  @override
  Widget build(BuildContext context) {
    final hasMemo = memo.isNotEmpty;
    return InkWell(
      onTap: hasMemo
          ? () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('메모'),
                  content: Text(memo),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Opacity(
        opacity: hasMemo ? 1 : 0.4,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.grey50),
            color: AppColors.grey25,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/svg/icon/pencil_grey_12.svg',
            width: 12,
            height: 12,
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmallB.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          height: 19 / 14,
        ),
      ),
    );
  }
}
