import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/work_status_badge.dart';

class EmployeeWorkHistoryEditScreen extends StatelessWidget {
  const EmployeeWorkHistoryEditScreen({
    super.key,
    required this.branchName,
    required this.workHistories,
  });

  final String branchName;
  final List<Map<String, dynamic>> workHistories;

  static const String fixedWorkDate = '2025.10.10';
  static const String fixedWorkTime = '00:00~07:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('근무 이력 수정'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '근무 이력',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      height: 24 / 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _EditWorkHistoryTable(
                    branchName: branchName,
                    rows: workHistories,
                    fixedWorkDate: fixedWorkDate,
                    fixedWorkTime: fixedWorkTime,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.grey0,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.grey0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '저장',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.grey0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditWorkHistoryTable extends StatelessWidget {
  const _EditWorkHistoryTable({
    required this.branchName,
    required this.rows,
    required this.fixedWorkDate,
    required this.fixedWorkTime,
  });

  final String branchName;
  final List<Map<String, dynamic>> rows;
  final String fixedWorkDate;
  final String fixedWorkTime;
  static const int _branchFlex = 22;
  static const int _dateFlex = 23;
  static const int _timeFlex = 27;
  static const int _statusFlex = 20;
  static const int _memoFlex = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            color: AppColors.grey25,
            child: const Row(
              children: [
                _EditHeaderCell('근무지점', flex: _branchFlex),
                _EditHeaderCell('근무날짜', flex: _dateFlex),
                _EditHeaderCell('근무시간', flex: _timeFlex),
                _EditHeaderCell('근무상태', flex: _statusFlex),
                _EditHeaderCell('메모', flex: _memoFlex),
              ],
            ),
          ),
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              height: 52.h,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
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
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey25)),
                ),
                child: Row(
                  children: [
                    _EditBodyCell(
                      _extractBranchName(row, branchName),
                      flex: _branchFlex,
                    ),
                    _EditBodyCell(fixedWorkDate, flex: _dateFlex),
                    _EditBodyCell(fixedWorkTime, flex: _timeFlex),
                    Expanded(
                      flex: _statusFlex,
                      child: SizedBox(
                        height: 40.h,
                        child: Center(
                          child: WorkStatusBadge(
                            status: row['status']?.toString() ?? '',
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _memoFlex,
                      child: SizedBox(
                        height: 40.h,
                        child: Center(
                          child: _EditMemoButton(memo: memo),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          Container(
            height: 1,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  String _extractBranchName(Map<String, dynamic> row, String fallbackBranchName) {
    final fromRow = row['branch_name']?.toString().trim();
    if (fromRow != null && fromRow.isNotEmpty) return fromRow;
    final fallback = fallbackBranchName.trim();
    if (fallback.isNotEmpty) return fallback;
    return '-';
  }
}

class _EditMemoButton extends StatelessWidget {
  const _EditMemoButton({required this.memo});

  final String memo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: memo.isNotEmpty
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
      child: Container(
        width: 20.w,
        height: 20.h,
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
    );
  }
}

class _EditHeaderCell extends StatelessWidget {
  // ignore: unused_element_parameter
  const _EditHeaderCell(this.text, {this.width, this.flex});

  final String text;
  final double? width;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.bodySmallB.copyWith(
        color: AppColors.textSecondary,
        fontSize: 13.1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final centered = SizedBox(height: 40.h, child: Center(child: label));
    if (flex != null) {
      return Expanded(flex: flex!, child: centered);
    }
    if (width != null) {
      return SizedBox(width: width!.w, child: centered);
    }
    return Expanded(child: centered);
  }
}

class _EditBodyCell extends StatelessWidget {
  // ignore: unused_element_parameter
  const _EditBodyCell(this.text, {this.width, this.flex});

  final String text;
  final double? width;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 19 / 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final centered = SizedBox(height: 40.h, child: Center(child: label));
    if (flex != null) {
      return Expanded(flex: flex!, child: centered);
    }
    if (width != null) {
      return SizedBox(width: width!.w, child: centered);
    }
    return Expanded(child: centered);
  }
}
