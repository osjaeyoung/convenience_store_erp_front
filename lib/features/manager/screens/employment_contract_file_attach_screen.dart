import 'package:file_picker/file_picker.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../../../widgets/file_attachment_drop_zone.dart';
import '../../../widgets/file_or_gallery_picker.dart';
import '../../../widgets/file_form_name_save_dialog.dart';
import 'picked_file_inline_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 근로계약서 파일 전용 등록 (스펙 ##23-1)
class EmploymentContractFileAttachScreen extends StatefulWidget {
  const EmploymentContractFileAttachScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.templateVersion,
    required this.screenTitle,
  });

  final int branchId;
  final int employeeId;
  final String templateVersion;
  final String screenTitle;

  @override
  State<EmploymentContractFileAttachScreen> createState() =>
      _EmploymentContractFileAttachScreenState();
}

class _EmploymentContractFileAttachScreenState
    extends State<EmploymentContractFileAttachScreen> {
  final _titleCtrl = TextEditingController();
  PlatformFile? _picked;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await pickSingleFileOrGallery(
      context: context,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked == null || !mounted) return;
    setState(() => _picked = picked);
  }

  Future<void> _openTitleModal() async {
    final saved = await showFileFormNameSaveDialog(
      context,
      initialFormName: _titleCtrl.text,
    );
    if (saved != null && mounted) {
      setState(() => _titleCtrl.text = saved);
    }
  }

  Future<void> _onAddPressed() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }
    final picked = _picked;
    if (picked == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일을 첨부해 주세요.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.createEmploymentContractFileOnly(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        templateVersion: widget.templateVersion,
        title: _titleCtrl.text.trim(),
        files: [picked],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일이 등록되었습니다.')));
      Navigator.pop(context, true);
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: ${userFriendlyErrorMessage(e)}')),
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
        title: const Text('파일로 첨부하기'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '제목',
              style: AppTypography.bodySmallB.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Stack(
              children: [
                AuthInputField(
                  controller: _titleCtrl,
                  hintText: '제목을 입력해주세요.',
                  readOnly: true,
                  fillColor: AppColors.grey25,
                  focusedBorderColor: AppColors.primaryDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: _openTitleModal,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            if (_picked == null)
              FileAttachmentDropZone(
                onTap: _pickFile,
                fileName: null,
                height: 200,
              )
            else ...[
              PickedFileInlinePreview(
                key: ValueKey<String>('${_picked!.name}_${_picked!.size}'),
                file: _picked!,
                height: 280,
                onTapReplace: _pickFile,
              ),
            ],
          ],
        ),
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
                onPressed: _submitting ? null : _onAddPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
