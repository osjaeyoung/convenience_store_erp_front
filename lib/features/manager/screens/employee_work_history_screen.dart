import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/employee_profile_box.dart';
import '../widgets/work_status_badge.dart';
import 'employee_work_history_edit_screen.dart';

class EmployeeWorkHistoryScreen extends StatefulWidget {
  const EmployeeWorkHistoryScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.employeeName,
    required this.hireDate,
    required this.contact,
    this.resignationDate,
    this.starCount,
    required this.workHistories,
  });

  final int branchId;
  final String branchName;
  final String employeeName;
  final String hireDate;
  final String contact;
  final String? resignationDate;
  final int? starCount;
  final List<Map<String, dynamic>> workHistories;

  @override
  State<EmployeeWorkHistoryScreen> createState() =>
      _EmployeeWorkHistoryScreenState();
}

class _EmployeeWorkHistoryScreenState extends State<EmployeeWorkHistoryScreen> {
  late List<Map<String, dynamic>> _workHistories;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _workHistories = widget.workHistories
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _openEditScreen() async {
    final updatedRows = await Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute<List<Map<String, dynamic>>>(
        builder: (_) => EmployeeWorkHistoryEditScreen(
          branchId: widget.branchId,
          branchName: widget.branchName,
          workHistories: _workHistories,
        ),
      ),
    );

    if (updatedRows == null || !mounted) return;
    setState(() {
      _workHistories = updatedRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      _hasUpdated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, _hasUpdated),
        ),
        title: const Text('근무 이력'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmployeeProfileBox(
              name: widget.employeeName,
              hireDate: widget.hireDate,
              contact: widget.contact,
              resignationDate: widget.resignationDate,
              showEditButton: false,
              starCount: widget.starCount,
            ),
            SizedBox(height: 24.h),
            Row(
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
                const Spacer(),
                FilledButton(
                  onPressed: _openEditScreen,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9D9DAA),
                    foregroundColor: AppColors.grey0,
                    minimumSize: Size(58.w, 30.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    '수정',
                    style: AppTypography.bodySmallB.copyWith(
                      color: AppColors.grey0,
                      fontSize: 12.sp,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _WorkHistoryTable(
              branchName: widget.branchName,
              rows: _workHistories,
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
                _HeaderCell('근무지점', flex: _branchFlex),
                _HeaderCell('근무날짜', flex: _dateFlex),
                _HeaderCell('근무시간', flex: _timeFlex),
                _HeaderCell('근무상태', flex: _statusFlex),
                _HeaderCell('메모', flex: _memoFlex),
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
                    _BodyCell(
                      _extractBranchName(row, branchName),
                      flex: _branchFlex,
                    ),
                    _BodyCell(_formatWorkDate(row), flex: _dateFlex),
                    _BodyCell(_formatWorkTime(row), flex: _timeFlex),
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
                        child: Center(child: _MemoButton(memo: memo)),
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

  String _formatWorkDate(Map<String, dynamic> row) {
    final directDate = _parseDate(row['work_date']?.toString());
    if (directDate != null) return _toDotDate(directDate);

    final updatedAt = _parseDate(row['updated_at']?.toString());
    if (updatedAt != null) return _toDotDate(updatedAt);

    return '-';
  }

  String _formatWorkTime(Map<String, dynamic> row) {
    final start = row['start_time']?.toString().trim() ?? '';
    final end = row['end_time']?.toString().trim() ?? '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start~$end';
    }

    final timeLabel = row['time_label']?.toString().trim() ?? '';
    if (timeLabel.isNotEmpty) return timeLabel;
    return '-';
  }

  DateTime? _parseDate(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;

    final match = RegExp(
      r'(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})',
    ).firstMatch(text);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    return DateTime.tryParse(text);
  }

  String _toDotDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}

class _MemoButton extends StatelessWidget {
  const _MemoButton({required this.memo});

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

class _HeaderCell extends StatelessWidget {
  // ignore: unused_element_parameter
  const _HeaderCell(this.text, {this.width, this.flex});

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

class _BodyCell extends StatelessWidget {
  // ignore: unused_element_parameter
  const _BodyCell(this.text, {this.width, this.flex});

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
