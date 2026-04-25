import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import 'employee_document_menu_actions.dart';

class GuestWorkerRegistrationScreen extends StatefulWidget {
  const GuestWorkerRegistrationScreen({
    super.key,
    required this.branchId,
    this.onRegistered,
  });

  final int branchId;
  final VoidCallback? onRegistered;

  @override
  State<GuestWorkerRegistrationScreen> createState() =>
      _GuestWorkerRegistrationScreenState();
}

class _GuestWorkerRegistrationScreenState
    extends State<GuestWorkerRegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _registeredEmployee;
  bool _submitting = false;
  bool _deleting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _todayYmd() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _registerGuestWorker() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll('-', '');

    if (name.isEmpty) {
      _showSnackBar('이름을 입력해 주세요.');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('연락처를 입력해 주세요.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await context
          .read<StaffManagementRepository>()
          .registerGuestEmployee(
            branchId: widget.branchId,
            name: name,
            phoneNumber: phone,
            hireDate: _todayYmd(),
          );
      if (!mounted) return;
      setState(() {
        _registeredEmployee = {
          ...data,
          'is_guest': data['is_guest'] ?? true,
          'linked_user_id': data['linked_user_id'],
        };
      });
      widget.onRegistered?.call();
      _showSnackBar('비회원 근무자가 등록되었습니다.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('등록 실패: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteGuestWorker() async {
    final emp = _registeredEmployee;
    final employeeId = (emp?['employee_id'] as num?)?.toInt();
    if (employeeId == null) return;

    final confirmed = await showAppStyledConfirmDialog(
      context,
      message: '이 비회원 근무자를 삭제하시겠습니까?',
      confirmLabel: '삭제',
      confirmBackgroundColor: AppColors.error,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<StaffManagementRepository>().deleteEmployee(
        branchId: widget.branchId,
        employeeId: employeeId,
      );
      if (!mounted) return;
      widget.onRegistered?.call();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('삭제 실패: $error');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registered = _registeredEmployee != null;
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, registered),
        ),
        title: const Text('비회원 근무자 등록'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (registered)
            IconButton(
              onPressed: _deleting ? null : _deleteGuestWorker,
              icon: Image.asset(
                'assets/icons/png/common/trash_icon.png',
                width: 28.r,
                height: 28.r,
              ),
            ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 29.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GuestWorkerProfileCard(
              nameController: _nameController,
              phoneController: _phoneController,
              employee: _registeredEmployee,
              submitting: _submitting,
              onSubmit: registered ? null : _registerGuestWorker,
            ),
            if (registered) ...[
              SizedBox(height: 20.h),
              _GuestWorkerDocumentList(
                employee: _registeredEmployee!,
                branchId: widget.branchId,
                onChanged: widget.onRegistered,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestWorkerProfileCard extends StatelessWidget {
  const _GuestWorkerProfileCard({
    required this.nameController,
    required this.phoneController,
    required this.employee,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final Map<String, dynamic>? employee;
  final bool submitting;
  final VoidCallback? onSubmit;

  bool get _registered => employee != null;

  @override
  Widget build(BuildContext context) {
    final name = employee?['name']?.toString() ?? '';
    final phone = employee?['phone_number']?.toString() ?? '';
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE1F0B8), Color(0xFF9FEDD4)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1D1D1F),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/svg/icon/profile_default_80.svg',
                width: 80.r,
                height: 80.r,
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  children: [
                    _GuestWorkerProfileRow(
                      label: '근무자명',
                      value: name,
                      hint: '입력해주세요',
                      controller: nameController,
                      readOnly: _registered,
                    ),
                    SizedBox(height: 4.h),
                    _GuestWorkerProfileRow(
                      label: '연락처',
                      value: phone,
                      hint: '입력해주세요',
                      controller: phoneController,
                      readOnly: _registered,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: FilledButton(
              onPressed: submitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.grey0,
                disabledBackgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.grey0,
                      ),
                    )
                  : Text(
                      _registered ? '수정' : '등록',
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.grey0,
                        fontSize: 16.sp,
                        height: 24 / 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestWorkerProfileRow extends StatelessWidget {
  const _GuestWorkerProfileRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.controller,
    required this.readOnly,
    this.keyboardType,
  });

  final String label;
  final String value;
  final String hint;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 58.w,
            child: Text(
              label,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                height: 16 / 14,
              ),
            ),
          ),
          Expanded(
            child: readOnly
                ? _ReadonlyPill(text: value.isEmpty ? '-' : value)
                : SizedBox(
                    height: 30.h,
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        height: 20 / 12,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12.sp,
                          height: 20 / 12,
                        ),
                        filled: true,
                        fillColor: AppColors.grey25,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.r),
                          borderSide: BorderSide.none,
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

class _ReadonlyPill extends StatelessWidget {
  const _ReadonlyPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(5.r),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          height: 20 / 12,
        ),
      ),
    );
  }
}

class _GuestWorkerDocumentList extends StatelessWidget {
  const _GuestWorkerDocumentList({
    required this.employee,
    required this.branchId,
    this.onChanged,
  });

  final Map<String, dynamic> employee;
  final int branchId;
  final VoidCallback? onChanged;

  static const _items = [
    '급여명세',
    '근로계약서',
    '연소근로자(18세 미만) 표준근로계약',
    '친권동의서',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final title in _items)
            _GuestWorkerDocumentRow(
              title: title,
              onTap: () => _openDocument(context, title),
            ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, String title) {
    final employeeId = (employee['employee_id'] as num?)?.toInt();
    if (employeeId == null) return;
    openEmployeeDocumentMenuItem(
      context,
      title: title,
      branchId: branchId,
      employeeId: employeeId,
      employeeName: employee['name']?.toString() ?? '-',
      branchName: '-',
      hireDate: employee['hire_date']?.toString() ?? '',
      contact: employee['phone_number']?.toString() ?? '-',
      resignationDate: employee['resignation_date']?.toString(),
      starCount: null,
      workHistories: const <Map<String, dynamic>>[],
      payrollStatementsRaw: null,
      fileOnlyDocuments: true,
      onPayrollFlowFinished: onChanged,
    );
  }
}

class _GuestWorkerDocumentRow extends StatelessWidget {
  const _GuestWorkerDocumentRow({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    height: 16 / 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey100,
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
