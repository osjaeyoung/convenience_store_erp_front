import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/work_status_badge.dart';

class EmployeeWorkHistoryEditScreen extends StatefulWidget {
  const EmployeeWorkHistoryEditScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.workHistories,
  });

  final int branchId;
  final String branchName;
  final List<Map<String, dynamic>> workHistories;

  @override
  State<EmployeeWorkHistoryEditScreen> createState() =>
      _EmployeeWorkHistoryEditScreenState();
}

class _EmployeeWorkHistoryEditScreenState
    extends State<EmployeeWorkHistoryEditScreen> {
  static const _statusOptions = ['근무완료', '근무예정', '결근', '미정'];

  late final List<_EditableWorkHistory> _rows;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.workHistories
        .map((row) => _EditableWorkHistory.fromMap(row, widget.branchName))
        .toList();
  }

  bool get _hasChanges => _rows.any((row) => row.isDirty);

  Future<void> _selectStatus(_EditableWorkHistory row) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (dialogContext) {
        Widget statusButton(String status) {
          final isSelected = row.status == status;
          return Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(status),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(56.h),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.grey50,
                ),
                backgroundColor: isSelected
                    ? AppColors.primaryLight
                    : AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                status,
                style: AppTypography.bodyLargeM.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  '근무 상태를 선택해 주세요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    statusButton(_statusOptions[0]),
                    SizedBox(width: 12.w),
                    statusButton(_statusOptions[1]),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    statusButton(_statusOptions[2]),
                    SizedBox(width: 12.w),
                    statusButton(_statusOptions[3]),
                  ],
                ),
                SizedBox(height: 16.h),
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(48.h),
                    side: const BorderSide(color: AppColors.grey25),
                    backgroundColor: AppColors.grey0,
                    foregroundColor: AppColors.grey150,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => row.status = selected);
  }

  Future<void> _editMemo(_EditableWorkHistory row) async {
    final controller = TextEditingController(text: row.memo);
    final saved = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '메모 수정',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '메모를 입력해 주세요.',
                    filled: true,
                    fillColor: AppColors.grey0Alt,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(48.h),
                          side: const BorderSide(color: AppColors.grey25),
                          backgroundColor: AppColors.grey0,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(controller.text.trim()),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(48.h),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();

    if (saved == null || !mounted) return;
    setState(() => row.memo = saved);
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final dirtyRows = _rows.where((row) => row.isDirty).toList();
    if (dirtyRows.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final invalidRows = dirtyRows.where((row) => row.scheduleId <= 0).toList();
    if (invalidRows.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일부 근무 이력은 수정할 수 없습니다.')));
      return;
    }

    setState(() => _isSaving = true);
    final repo = context.read<StaffManagementRepository>();

    try {
      for (final row in dirtyRows) {
        await repo.patchSchedule(
          branchId: widget.branchId,
          scheduleId: row.scheduleId,
          status: _toApiStatus(row.status),
          memo: row.memo.isEmpty ? null : row.memo,
          includeMemo: true,
        );
        row.markSaved();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('근무 이력이 저장되었습니다.')));
      Navigator.of(
        context,
      ).pop(_rows.map((row) => row.toMap()).toList(growable: false));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _toApiStatus(String status) {
    switch (WorkStatusBadge.normalize(status)) {
      case '근무완료':
        return 'done';
      case '근무예정':
        return 'scheduled';
      case '결근':
        return 'absent';
      case '미정':
        return 'unset';
      default:
        return status.trim().toLowerCase();
    }
  }

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
                    rows: _rows,
                    enabled: !_isSaving,
                    onTapStatus: _selectStatus,
                    onTapMemo: _editMemo,
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
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.grey0,
                    disabledBackgroundColor: AppColors.grey50,
                    disabledForegroundColor: AppColors.grey150,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.grey0,
                            ),
                          ),
                        )
                      : Text(
                          _hasChanges ? '저장' : '닫기',
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
    required this.rows,
    required this.enabled,
    required this.onTapStatus,
    required this.onTapMemo,
  });

  final List<_EditableWorkHistory> rows;
  final bool enabled;
  final ValueChanged<_EditableWorkHistory> onTapStatus;
  final ValueChanged<_EditableWorkHistory> onTapMemo;

  static const int _branchFlex = 23;
  static const int _dateFlex = 25;
  static const int _timeFlex = 26;
  static const int _statusFlex = 18;
  static const int _memoFlex = 8;

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
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey25)),
                ),
                child: Row(
                  children: [
                    _EditBodyCell(row.branchName, flex: _branchFlex),
                    _EditBodyCell(row.workDate, flex: _dateFlex),
                    _EditBodyCell(row.workTime, flex: _timeFlex),
                    Expanded(
                      flex: _statusFlex,
                      child: SizedBox(
                        height: 40.h,
                        child: Center(
                          child: InkWell(
                            onTap: enabled ? () => onTapStatus(row) : null,
                            borderRadius: BorderRadius.circular(8.r),
                            child: WorkStatusBadge(
                              status: row.status,
                              compact: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _memoFlex,
                      child: SizedBox(
                        height: 40.h,
                        child: Center(
                          child: _EditMemoButton(
                            hasMemo: row.memo.isNotEmpty,
                            enabled: enabled,
                            onTap: () => onTapMemo(row),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          Container(height: 1, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _EditMemoButton extends StatelessWidget {
  const _EditMemoButton({
    required this.hasMemo,
    required this.enabled,
    required this.onTap,
  });

  final bool hasMemo;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: hasMemo ? AppColors.primary : AppColors.grey50,
          ),
          color: hasMemo ? AppColors.primaryLight : AppColors.grey25,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icons/svg/icon/pencil_grey_12.svg',
          width: 12,
          height: 12,
          colorFilter: ColorFilter.mode(
            hasMemo ? AppColors.primary : AppColors.grey150,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _EditableWorkHistory {
  _EditableWorkHistory({
    required this.raw,
    required this.scheduleId,
    required this.branchName,
    required this.workDate,
    required this.workTime,
    required this.status,
    required this.memo,
  }) : _savedStatus = status,
       _savedMemo = memo;

  factory _EditableWorkHistory.fromMap(
    Map<String, dynamic> row,
    String fallbackBranchName,
  ) {
    final copied = Map<String, dynamic>.from(row);
    return _EditableWorkHistory(
      raw: copied,
      scheduleId: _toInt(copied['schedule_id']),
      branchName: _extractBranchName(copied, fallbackBranchName),
      workDate: _formatWorkDate(copied),
      workTime: _formatWorkTime(copied),
      status: WorkStatusBadge.normalize(copied['status']?.toString() ?? ''),
      memo: (copied['memo'] as String?)?.trim() ?? '',
    );
  }

  final Map<String, dynamic> raw;
  final int scheduleId;
  final String branchName;
  final String workDate;
  final String workTime;
  String status;
  String memo;
  String _savedStatus;
  String _savedMemo;

  bool get isDirty => status != _savedStatus || memo != _savedMemo;

  void markSaved() {
    _savedStatus = status;
    _savedMemo = memo;
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(raw)
      ..['schedule_id'] = scheduleId
      ..['branch_name'] = branchName
      ..['status'] = status
      ..['memo'] = memo;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _extractBranchName(
    Map<String, dynamic> row,
    String fallbackBranchName,
  ) {
    final fromRow = row['branch_name']?.toString().trim();
    if (fromRow != null && fromRow.isNotEmpty) return fromRow;
    final fallback = fallbackBranchName.trim();
    if (fallback.isNotEmpty) return fallback;
    return '-';
  }

  static String _formatWorkDate(Map<String, dynamic> row) {
    final directDate = _parseDate(row['work_date']?.toString());
    if (directDate != null) return _toDotDate(directDate);

    final updatedAt = _parseDate(row['updated_at']?.toString());
    if (updatedAt != null) return _toDotDate(updatedAt);

    return '-';
  }

  static String _formatWorkTime(Map<String, dynamic> row) {
    final start = row['start_time']?.toString().trim() ?? '';
    final end = row['end_time']?.toString().trim() ?? '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start~$end';
    }

    final timeLabel = row['time_label']?.toString().trim() ?? '';
    if (timeLabel.isNotEmpty) return timeLabel;
    return '-';
  }

  static DateTime? _parseDate(String? raw) {
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

  static String _toDotDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
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
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final centered = SizedBox(
      height: 40.h,
      child: Center(child: label),
    );
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
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 19 / 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final centered = SizedBox(
      height: 40.h,
      child: Center(child: label),
    );
    if (flex != null) {
      return Expanded(flex: flex!, child: centered);
    }
    if (width != null) {
      return SizedBox(width: width!.w, child: centered);
    }
    return Expanded(child: centered);
  }
}
