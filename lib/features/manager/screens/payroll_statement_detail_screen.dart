import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../payroll/payroll_formatters.dart';
import 'payroll_statement_pdf_export.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
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
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 저장에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = (_row['year'] as num?)?.toInt() ?? 0;
    final m = (_row['month'] as num?)?.toInt() ?? 0;
    final titleText = '$y.$m월 급여 명세';

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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          titleText,
                          style: AppTypography.heading3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _onDelete,
                        icon: Image.asset(
                          'assets/icons/png/common/trash_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoCard(),
                  const SizedBox(height: 20),
                  Text(
                    '공제항목',
                    style: AppTypography.bodyMediumB.copyWith(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!hasDeductions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey25,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey50),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.grey150),
                          const SizedBox(width: 8),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey0Alt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey50),
                      ),
                      child: Column(
                        children: [
                          for (final d in deductions)
                            _kvRow(d.key, PayrollFormatters.krwInt(d.value)),
                          if (totalDed > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _kvRow(
                                '공제 합계',
                                PayrollFormatters.krwInt(totalDed),
                                emphasize: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if ((_num('net_pay') ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _kvRow(
                        '실지급액',
                        PayrollFormatters.krwInt(_num('net_pay')),
                        emphasize: true,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: (_pdfBusy || _loading) ? null : _onDownload,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primaryDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
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
                fontSize: 14,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
