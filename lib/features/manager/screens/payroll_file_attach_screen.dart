import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../../../widgets/file_attachment_drop_zone.dart';
import '../../../widgets/file_form_name_save_dialog.dart';

/// 파일로 급여명세 등록 — 제목 + 파일 첨부 + 추가하기 → 저장 형태 모달
class PayrollFileAttachScreen extends StatefulWidget {
  const PayrollFileAttachScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
  });

  final int branchId;
  final int employeeId;

  @override
  State<PayrollFileAttachScreen> createState() =>
      _PayrollFileAttachScreenState();
}

class _PayrollFileAttachScreenState extends State<PayrollFileAttachScreen> {
  final _titleCtrl = TextEditingController();

  final int _year = DateTime.now().year;
  final int _month = DateTime.now().month;
  PlatformFile? _picked;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _bodyFromAutoFill(Map<String, dynamic> d) {
    return {
      'year': _year,
      'month': _month,
      'resident_id_masked': d['resident_id_masked'] ?? '',
      'total_work_minutes': (d['total_work_minutes'] as num?)?.toInt() ?? 0,
      'hourly_wage': (d['hourly_wage'] as num?)?.toInt() ?? 0,
      'weekly_allowance': (d['weekly_allowance'] as num?)?.toInt() ?? 0,
      'overtime_pay': (d['overtime_pay'] as num?)?.toInt() ?? 0,
      'taxable_salary': d['taxable_salary'],
      'gross_salary': d['gross_salary'],
    };
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: false,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _picked = res.files.first);
    }
  }

  Future<void> _onAddPressed() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해 주세요.')),
      );
      return;
    }

    final initialForm = _titleCtrl.text.trim();
    final formName = await showFileFormNameSaveDialog(
      context,
      initialFormName: initialForm,
    );
    if (formName == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final auto = await repo.getPayrollStatementAutoFill(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        year: _year,
        month: _month,
      );
      final body = _bodyFromAutoFill(auto);

      await repo.calculatePayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        body: body,
      );
      await repo.createPayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        body: body,
      );

      if (!mounted) return;
      final fileHint = _picked != null
          ? ' 파일 "${_picked!.name}"은(는) 업로드 URL 연결 후 PATCH로 등록할 수 있습니다.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「$formName」 급여명세가 저장되었습니다.$fileHint'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        title: Text(
          '파일로 첨부하기',
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '제목',
                    style: AppTypography.bodySmallB.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthInputField(
                    controller: _titleCtrl,
                    hintText: '제목을 입력해주세요.',
                    fillColor: AppColors.grey25,
                    focusedBorderColor: AppColors.primaryDark,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FileAttachmentDropZone(
                    onTap: _pickFile,
                    fileName: _picked?.name,
                    height: 200,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _onAddPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '추가하기',
                          style: AppTypography.bodyMediumB.copyWith(
                            color: AppColors.grey0,
                            fontSize: 16,
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
