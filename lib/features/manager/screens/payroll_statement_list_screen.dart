import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../payroll/payroll_formatters.dart';
import 'payroll_add_method_screen.dart';
import 'payroll_file_attach_screen.dart';
import 'payroll_statement_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 급여명세 목록 (빈 목록 / 리스트 + 하단 추가하기)
class PayrollStatementListScreen extends StatefulWidget {
  const PayrollStatementListScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    this.initialItemsPayload,
    this.fileOnly = false,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final bool fileOnly;

  /// 직원 상세 API 등에서 넘긴 `payroll_statements` 또는 `{ "items": [...] }` 형태
  final Map<String, dynamic>? initialItemsPayload;

  @override
  State<PayrollStatementListScreen> createState() =>
      _PayrollStatementListScreenState();
}

class _PayrollStatementListScreenState
    extends State<PayrollStatementListScreen> {
  /// Figma Body medium_M — 목록 행 제목 (`2025년 12월 급여명세`)
  static TextStyle get _rowTitleStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    color: Color(0xFF000000),
  );

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final seed = PayrollFormatters.parseItemList(widget.initialItemsPayload);
    if (seed.isNotEmpty) {
      _items = seed;
      PayrollFormatters.sortPayrollItems(_items);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getPayrollStatements(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
      if (!mounted) return;
      final list = PayrollFormatters.parseItemList(data);
      PayrollFormatters.sortPayrollItems(list);
      setState(() {
        _items = list;
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

  Future<void> _openAdd() async {
    final directWrittenPeriods = _items
        .where((item) => !_isFileOnlyPayroll(item))
        .map(_periodKeyOf)
        .whereType<String>()
        .toSet();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => widget.fileOnly
            ? PayrollFileAttachScreen(
                branchId: widget.branchId,
                employeeId: widget.employeeId,
              )
            : PayrollAddMethodScreen(
                branchId: widget.branchId,
                employeeId: widget.employeeId,
                employeeName: widget.employeeName,
                directWrittenPeriods: directWrittenPeriods,
              ),
      ),
    );
    if (changed == true && mounted) {
      _dirty = true;
      _load();
    }
  }

  String? _periodKeyOf(Map<String, dynamic> item) {
    final year = (item['year'] as num?)?.toInt();
    final month = (item['month'] as num?)?.toInt();
    if (year == null || month == null) return null;
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  bool _isFileOnlyPayroll(Map<String, dynamic> item) {
    final type =
        (item['entry_type'] ??
                item['creation_type'] ??
                item['source'] ??
                item['payroll_type'] ??
                item['input_mode'])
            ?.toString()
            .toLowerCase();
    if (type != null &&
        (type.contains('manual') ||
            type.contains('direct') ||
            type.contains('written'))) {
      return false;
    }
    if (type != null &&
        (type.contains('file') ||
            type.contains('upload') ||
            type.contains('attachment'))) {
      return true;
    }
    if (item['is_file_only'] == true || item['file_only'] == true) {
      return true;
    }

    final files = item['files'];
    final hasFiles =
        (files is List && files.isNotEmpty) ||
        (item['s3_file_key']?.toString().trim().isNotEmpty ?? false) ||
        (item['s3_file_url']?.toString().trim().isNotEmpty ?? false);
    if (!hasFiles) return false;

    const numericKeys = [
      'total_work_minutes',
      'hourly_wage',
      'base_pay',
      'weekly_allowance',
      'overtime_pay',
      'taxable_salary',
      'gross_salary',
      'national_pension',
      'health_insurance',
      'employment_insurance',
      'long_term_care_insurance',
      'income_tax',
      'local_income_tax',
      'total_deduction',
      'net_pay',
    ];
    final allAmountsEmpty = numericKeys.every((key) {
      final value = item[key];
      if (value == null) return true;
      if (value is num) return value == 0;
      return num.tryParse(value.toString()) == 0;
    });
    final resident = item['resident_id_masked']?.toString().trim() ?? '';
    return allAmountsEmpty && resident.isEmpty;
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final id = (row['payroll_id'] as num?)?.toInt();
    if (id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PayrollStatementDetailScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          payrollId: id,
          summaryRow: row,
        ),
      ),
    );
    if (changed == true && mounted) {
      _dirty = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, _dirty),
        ),
        title: const Text('급여명세'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  )
                : _items.isEmpty
                ? Center(
                    child: Text(
                      '등록된 급여명세서가 없습니다.',
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 0.h),
                    itemBuilder: (context, i) {
                      final row = _items[i];
                      final y = (row['year'] as num?)?.toInt() ?? 0;
                      final m = (row['month'] as num?)?.toInt() ?? 0;
                      final title = row['title']?.toString().trim();
                      return Material(
                        color: AppColors.grey0,
                        child: InkWell(
                          onTap: () => _openDetail(row),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey0Alt,
                                    borderRadius: BorderRadius.circular(100.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    'assets/icons/svg/icon/payroll_document_24.svg',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    title == null || title.isEmpty
                                        ? '$y년 $m월 급여명세'
                                        : title,
                                    style: _rowTitleStyle,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.grey100,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: AppColors.grey0,
        child: SafeArea(
          minimum: EdgeInsets.only(bottom: 8.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _openAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  '추가하기',
                  style: AppTypography.bodyMediumB.copyWith(
                    color: AppColors.grey0,
                    fontSize: 16.sp,
                    height: 24 / 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
