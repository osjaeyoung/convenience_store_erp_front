import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/models/store_expense/store_expense_month.dart';
import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoreExpenseAddItemScreen extends StatefulWidget {
  const StoreExpenseAddItemScreen({
    super.key,
    required this.branchId,
    required this.expenseMonthId,
    required this.periodLabel,
  });

  final int branchId;
  final int expenseMonthId;
  final String periodLabel;

  @override
  State<StoreExpenseAddItemScreen> createState() => _StoreExpenseAddItemScreenState();
}

class _StoreExpenseAddItemScreenState extends State<StoreExpenseAddItemScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  DateTime? _expenseDate;
  StoreExpenseCategory? _selectedCategory;
  List<StoreExpenseCategory> _categories = const [];
  final List<PlatformFile> _pickedFiles = <PlatformFile>[];
  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = context.read<StoreExpenseRepository>();
      final cats = await repo.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats.where((e) => e.isActive).toList();
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        surfaceTintColor: AppColors.grey0,
        title: Text('항목추가', style: AppTypography.appBarTitle),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.periodLabel}월\n비용 지출 입력',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 44 / 2,
                        fontWeight: FontWeight.w400,
                        height: 32 / 24,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _label('구체 일자'),
                    SizedBox(height: 8.h),
                    _selectorTile(
                      value: _expenseDate == null
                          ? null
                          : DateFormat('yyyy-MM-dd').format(_expenseDate!),
                      hint: '입력해주세요.',
                      onTap: _pickDate,
                      showArrow: false,
                    ),
                    SizedBox(height: 20.h),
                    _label('항목'),
                    SizedBox(height: 8.h),
                    _selectorTile(
                      value: _selectedCategory?.categoryLabel,
                      hint: _loadingCategories ? '불러오는 중...' : '선택해주세요.',
                      onTap: _loadingCategories ? null : _pickCategory,
                    ),
                    SizedBox(height: 20.h),
                    _label('금액'),
                    SizedBox(height: 8.h),
                    _inputTile(
                      controller: _amountCtrl,
                      hint: '입력해주세요.',
                    ),
                    SizedBox(height: 20.h),
                    _fileArea(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey100,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.grey0,
                          ),
                        )
                      : Text(
                          '확인',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.bodyMediumM.copyWith(
        fontSize: 14.sp,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _selectorTile({
    required String? value,
    required String hint,
    required VoidCallback? onTap,
    bool showArrow = true,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.grey0Alt,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: AppTypography.bodyMediumR.copyWith(
                  fontSize: 14.sp,
                  color: hasValue ? AppColors.textPrimary : AppColors.grey100,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.grey150,
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputTile({
    required TextEditingController controller,
    required String hint,
  }) {
    return AuthInputField(
      controller: controller,
      hintText: hint,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _fileArea() {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 132),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary),
        ),
        child: _pickedFiles.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                  SizedBox(height: 8.h),
                  Text(
                    '파일을 첨부해주세요.',
                    style: AppTypography.bodyMediumB.copyWith(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in _pickedFiles)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Text(
                        '• ${f.name}',
                        style: AppTypography.bodySmallM.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Text(
                    '첨부 파일은 현재 메타데이터 저장만 지원합니다.',
                    style: AppTypography.bodySmallR.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _pickCategory() async {
    if (_categories.isEmpty) return;
    final selected = await showModalBottomSheet<StoreExpenseCategory>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final c in _categories)
                ListTile(
                  title: Text(c.categoryLabel),
                  onTap: () => Navigator.pop(ctx, c),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null || !mounted) return;
    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(result.files);
    });
  }

  Future<void> _save() async {
    final date = _expenseDate;
    final category = _selectedCategory;
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (date == null || category == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일자/항목/금액을 올바르게 입력해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<StoreExpenseRepository>();
      final fileDrafts = _pickedFiles
          .map(
            (file) => StoreExpenseFileDraft(
              fileKey: file.path ?? file.name,
              fileUrl: file.path ?? file.name,
              fileName: file.name,
            ),
          )
          .toList();
      await repo.createStep2(
        branchId: widget.branchId,
        expenseMonthId: widget.expenseMonthId,
        expenseDate: DateFormat('yyyy-MM-dd').format(date),
        categoryCode: category.categoryCode,
        amount: amount,
        files: fileDrafts,
      );
      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('항목 저장에 실패했습니다: $e')),
      );
      setState(() => _saving = false);
    }
  }
}

