import 'dart:convert';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../../../widgets/file_attachment_drop_zone.dart';
import '../../../widgets/file_or_gallery_picker.dart';
import 'employee_etc_record_file_bytes.dart';
import 'employee_etc_record_inline_preview.dart';
import 'picked_file_inline_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 기타자료 — 추가 또는 조회(폼) — 스펙 ##21
/// - [viewRecord]가 있으면 조회 모드: 필드 읽기 전용, 첨부 **인라인 미리보기**, 하단 **삭제**만.
/// - 없으면 추가 모드: 하단 **추가하기**만.
/// - 첨부 있음(추가): multipart → 실패 시 Base64 JSON.
class EmployeeEtcRecordAddScreen extends StatefulWidget {
  const EmployeeEtcRecordAddScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    this.viewRecord,
  });

  final int branchId;
  final int employeeId;

  /// 목록 행 등 기존 레코드가 있으면 조회 화면(삭제만).
  final Map<String, dynamic>? viewRecord;

  @override
  State<EmployeeEtcRecordAddScreen> createState() =>
      _EmployeeEtcRecordAddScreenState();
}

class _EmployeeEtcRecordAddScreenState
    extends State<EmployeeEtcRecordAddScreen> {
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _issuedIso;
  PlatformFile? _picked;
  bool _submitting = false;

  bool get _isViewMode => widget.viewRecord != null;

  String? get _viewFileUrl => widget.viewRecord?['file_url']?.toString().trim();

  @override
  void initState() {
    super.initState();
    final v = widget.viewRecord;
    if (v != null) {
      _applyViewRecord(v);
    }
  }

  void _applyViewRecord(Map<String, dynamic> v) {
    _titleCtrl.text = v['title']?.toString() ?? '';
    final issued = v['issued_date']?.toString().trim();
    String? iso;
    if (issued != null && issued.isNotEmpty) {
      iso = issued.length >= 10 ? issued.substring(0, 10) : issued;
    } else {
      final created = v['created_at']?.toString();
      final d = created != null ? DateTime.tryParse(created) : null;
      if (d != null) {
        iso =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
    }
    if (iso != null) {
      _issuedIso = iso;
      final d = DateTime.tryParse(iso);
      if (d != null) {
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        _dateCtrl.text = '${d.year}.$m.$day';
      }
    }
  }

  String? get _existingFileDisplayName {
    final v = widget.viewRecord;
    if (v == null) return null;
    final url = v['file_url']?.toString().trim();
    if (url == null || url.isEmpty) return null;
    final seg = Uri.tryParse(url)?.pathSegments;
    if (seg != null && seg.isNotEmpty && seg.last.isNotEmpty) {
      return seg.last;
    }
    return '첨부 파일';
  }

  Future<void> _delete() async {
    final v = widget.viewRecord;
    if (v == null) return;
    final id = v['record_id'];
    final rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제할 수 없습니다. (record_id 없음)')),
        );
      }
      return;
    }
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '이 기타 자료를 삭제할까요?',
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await context.read<StaffManagementRepository>().deleteEmployeeRecord(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        recordId: rid,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${userFriendlyErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _issuedIso != null
        ? DateTime.tryParse(_issuedIso!) ?? now
        : now;
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (d == null || !mounted) return;
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    setState(() {
      _issuedIso = '$y-$m-$day';
      _dateCtrl.text = '$y.$m.$day';
    });
  }

  Future<void> _pickFile() async {
    final picked = await pickSingleFileOrGallery(
      context: context,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked == null || !mounted) return;
    setState(() => _picked = picked);
  }

  bool _isEtcUploadConnectionFailure(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      final msg = '${e.message ?? ''} ${e.error ?? ''}';
      if (msg.contains('Connection reset') ||
          msg.contains('SocketException') ||
          msg.contains('Failed host lookup')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final hasFile = _picked != null;

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }

    final repo = context.read<StaffManagementRepository>();
    setState(() => _submitting = true);
    try {
      if (hasFile) {
        final issued = _issuedIso;
        if (issued == null || issued.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('파일을 첨부한 경우 작성일을 선택해 주세요.')),
            );
          }
          return;
        }
        try {
          await repo.createEmployeeRecordEtcMultipart(
            branchId: widget.branchId,
            employeeId: widget.employeeId,
            title: title,
            issuedDateYmd: issued,
            file: _picked!,
          );
        } catch (e) {
          if (!_isEtcUploadConnectionFailure(e)) rethrow;
          final raw = await readEtcPickedFileBytes(_picked!);
          if (raw == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('연결에 실패했습니다. Base64 전송을 쓰려면 파일을 다시 선택해 주세요.'),
                ),
              );
            }
            rethrow;
          }
          final name = _picked!.name.trim().isEmpty
              ? 'attachment'
              : _picked!.name.trim();
          await repo.createEmployeeRecordEtcBase64(
            branchId: widget.branchId,
            employeeId: widget.employeeId,
            title: title,
            issuedDateYmd: issued,
            fileContentBase64: base64Encode(raw),
            attachmentFileName: name,
          );
        }
      } else {
        await repo.createEmployeeRecordEtc(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          body: {
            'title': title,
            if (_issuedIso != null && _issuedIso!.isNotEmpty)
              'issued_date': _issuedIso,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기타 자료가 등록되었습니다.')));
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

  static EdgeInsets get _fieldPadding =>
      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h);

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.bodySmallB.copyWith(
      color: AppColors.textPrimary,
      fontSize: 14.sp,
      height: 20 / 14,
    );

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('기타'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.appBarTitle,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('제목', style: labelStyle),
            SizedBox(height: 8.h),
            AuthInputField(
              controller: _titleCtrl,
              hintText: '제목을 입력해주세요.',
              readOnly: _isViewMode,
              fillColor: AppColors.grey25,
              focusedBorderColor: AppColors.primaryDark,
              contentPadding: _fieldPadding,
            ),
            SizedBox(height: 20.h),
            Text('작성일', style: labelStyle),
            SizedBox(height: 8.h),
            Stack(
              children: [
                AuthInputField(
                  controller: _dateCtrl,
                  hintText: '작성일을 입력해주세요.',
                  readOnly: true,
                  fillColor: AppColors.grey25,
                  focusedBorderColor: AppColors.primaryDark,
                  contentPadding: _fieldPadding,
                ),
                if (!_isViewMode)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: _pickDate,
                      ),
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1, thickness: 1, color: AppColors.grey50),
            ),
            if (_isViewMode) ...[
              if ((_viewFileUrl ?? '').isNotEmpty)
                EtcRecordInlineFilePreview(
                  fileUrl: _viewFileUrl!,
                  height: 320,
                  displayFileName: _existingFileDisplayName,
                )
              else
                Container(
                  height: 132,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.grey25,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '첨부된 파일이 없습니다.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
            ] else ...[
              if (_picked == null)
                FileAttachmentDropZone(
                  onTap: _pickFile,
                  fileName: null,
                  emptySubtitle: '파일을 첨부해주세요.',
                  fullWidthBarHeight: 132,
                  iconSize: 28,
                )
              else ...[
                PickedFileInlinePreview(
                  key: ValueKey<String>('${_picked!.name}_${_picked!.size}'),
                  file: _picked!,
                  height: 320,
                  onTapReplace: _pickFile,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _picked = null),
                    child: Text(
                      '첨부 제거',
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: AppColors.grey0,
        child: SafeArea(
          minimum: EdgeInsets.only(bottom: 8.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
            child: _isViewMode
                ? SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _delete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey150,
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
                              '삭제',
                              style: AppTypography.bodyMediumB.copyWith(
                                color: AppColors.grey0,
                                fontSize: 16.sp,
                                height: 24 / 16,
                              ),
                            ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
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
