import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../payroll/payroll_formatters.dart';
import 'employee_etc_file_preview_common.dart';
import 'employee_etc_record_inline_preview.dart';
import 'payroll_statement_pdf_export.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 급여명세 상세 (아이콘 + 카드 + 공제 + 다운로드)
class PayrollStatementDetailScreen extends StatefulWidget {
  const PayrollStatementDetailScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.payrollId,
    required this.summaryRow,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final int payrollId;
  final Map<String, dynamic> summaryRow;

  @override
  State<PayrollStatementDetailScreen> createState() =>
      _PayrollStatementDetailScreenState();
}

class _PayrollStatementDetailScreenState
    extends State<PayrollStatementDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _pdfBusy = false;
  String? _error;

  static const _deductionKeys = <String, String>{
    'national_pension': '국민연금',
    'health_insurance': '건강보험',
    'employment_insurance': '고용보험',
    'long_term_care_insurance': '장기요양보험',
    'income_tax': '소득세',
    'local_income_tax': '지방소득세',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getPayrollStatementDetail(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        payrollId: widget.payrollId,
      );
      if (!mounted) return;
      setState(() {
        _detail = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detail = Map<String, dynamic>.from(widget.summaryRow);
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _row => _detail ?? widget.summaryRow;

  int? _num(String key) {
    final v = _row[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  Future<void> _onDelete() async {
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '이 급여명세를 삭제하시겠습니까?',
    );
    if (ok != true || !mounted) return;
    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.deletePayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        payrollId: widget.payrollId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  static String _sanitizeFileNameSegment(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _pdfFileName() {
    final name = _sanitizeFileNameSegment(widget.employeeName);
    if (name.isEmpty) return '급여명세서.pdf';
    return '급여명세서_$name.pdf';
  }

  Future<void> _onDownload() async {
    setState(() => _pdfBusy = true);
    try {
      final bytes = await buildPayrollStatementPdfBytes(
        row: _row,
        employeeName: widget.employeeName,
      );
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: _pdfFileName());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF 저장에 실패했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _onDownloadAttachedFile() async {
    final fileUrl = _primaryFileUrl(_row);
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('다운로드할 첨부 파일이 없습니다.')));
      return;
    }
    setState(() => _pdfBusy = true);
    try {
      await EtcFilePreviewCommon.downloadAttachment(
        fileUrl: fileUrl,
        recordTitle: _displayTitle(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('파일 저장에 실패했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  String _displayTitle() {
    final title = _row['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    final y = (_row['year'] as num?)?.toInt() ?? 0;
    final m = (_row['month'] as num?)?.toInt() ?? 0;
    return '$y.$m월 급여 명세';
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

    if (!_hasAttachment(item)) return false;
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

  bool _hasAttachment(Map<String, dynamic> item) {
    final files = item['files'];
    if (files is List && files.isNotEmpty) return true;
    return (_stringValue(item['s3_file_url'])?.isNotEmpty ?? false) ||
        (_stringValue(item['file_url'])?.isNotEmpty ?? false);
  }

  String? _primaryFileUrl(Map<String, dynamic> item) {
    final files = item['files'];
    if (files is List) {
      for (final file in files) {
        if (file is! Map) continue;
        final url =
            _stringValue(file['file_url']) ??
            _stringValue(file['s3_file_url']) ??
            _stringValue(file['url']);
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return _stringValue(item['s3_file_url']) ?? _stringValue(item['file_url']);
  }

  String? _primaryFileName(Map<String, dynamic> item) {
    final files = item['files'];
    if (files is List) {
      for (final file in files) {
        if (file is! Map) continue;
        final name =
            _stringValue(file['file_name']) ??
            _stringValue(file['name']) ??
            _stringValue(file['original_name']);
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return _stringValue(item['file_name']) ?? _displayTitle();
  }

  String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _displayTitle();
    final isFileOnly = _isFileOnlyPayroll(_row);

    final deductions = <MapEntry<String, int>>[];
    for (final e in _deductionKeys.entries) {
      final amt = _num(e.key) ?? 0;
      if (amt > 0) deductions.add(MapEntry(e.value, amt));
    }
    final totalDed = _num('total_deduction') ?? 0;
    final hasDeductions = deductions.isNotEmpty || totalDed > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('급여명세'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        '일부 정보를 불러오지 못했습니다.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/svg/icon/payroll_document_24.svg',
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          titleText,
                          style: AppTypography.heading3.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _onDelete,
                        icon: SvgPicture.asset(
                          'assets/icons/svg/icon/trash.svg',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (isFileOnly)
                    _filePreviewContent()
                  else ...[
                    _infoCard(),
                    SizedBox(height: 20.h),
                    Text(
                      '공제항목',
                      style: AppTypography.bodyMediumB.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (!hasDeductions)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey25,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.grey50),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.grey150),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                '공제항목이 없습니다.',
                                style: AppTypography.bodyMediumR.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.grey0Alt,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.grey50),
                        ),
                        child: Column(
                          children: [
                            for (final d in deductions)
                              _kvRow(d.key, PayrollFormatters.krwInt(d.value)),
                            if (totalDed > 0)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: _kvRow(
                                  '공제 합계',
                                  PayrollFormatters.krwInt(totalDed),
                                  emphasize: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24.h),
                    if ((_num('net_pay') ?? 0) > 0)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _kvRow(
                          '실지급액',
                          PayrollFormatters.krwInt(_num('net_pay')),
                          emphasize: true,
                        ),
                      ),
                    _downloadButton(onPressed: _onDownload),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _filePreviewContent() {
    final fileUrl = _primaryFileUrl(_row);
    final fileName = _primaryFileName(_row);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fileUrl != null && fileUrl.isNotEmpty)
          EtcRecordInlineFilePreview(
            fileUrl: fileUrl,
            height: 460,
            displayFileName: fileName,
          )
        else
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.grey25,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey50),
            ),
            child: Text(
              '등록된 첨부 파일을 불러오지 못했습니다.',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        SizedBox(height: 24.h),
        _downloadButton(
          onPressed: fileUrl == null || fileUrl.isEmpty
              ? null
              : _onDownloadAttachedFile,
        ),
      ],
    );
  }

  Widget _downloadButton({required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (_pdfBusy || _loading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _pdfBusy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              )
            : Text(
                '다운로드',
                style: AppTypography.bodyMediumB.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }

  Widget _infoCard() {
    final resident = _row['resident_id_masked'] as String? ?? '-';
    final minutes = _num('total_work_minutes');
    final hourly = _num('hourly_wage');
    final base = _num('base_pay');
    final weeklyAllow = _num('weekly_allowance');

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: [
          _kvRow('성명', widget.employeeName),
          _kvRow('주민번호', resident),
          _kvRow('총 근무시간', PayrollFormatters.hoursFromMinutes(minutes)),
          _kvRow('시급', PayrollFormatters.krwInt(hourly)),
          _kvRow('기본급', PayrollFormatters.krwInt(base)),
          _kvRow('주휴수당', PayrollFormatters.krwInt(weeklyAllow)),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
