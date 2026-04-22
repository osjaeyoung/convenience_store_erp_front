import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/thousands_separator_input_formatter.dart';
import '../../../data/models/store_expense/store_expense_month.dart';
import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/file_or_gallery_picker.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'picked_file_inline_preview.dart';
import 'employee_etc_record_inline_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoreExpenseAddItemScreen extends StatefulWidget {
  const StoreExpenseAddItemScreen({
    super.key,
    required this.branchId,
    required this.expenseMonthId,
    required this.periodLabel,
    required this.year,
    required this.month,
  });

  final int branchId;
  final int expenseMonthId;
  final String periodLabel;
  final int year;
  final int month;

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
      inputFormatters: [ThousandsSeparatorInputFormatter()],
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
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.grey50),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: _buildInlinePreview(f),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedFiles.remove(f);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.grey200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.grey0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildInlinePreview(PlatformFile f) {
    final path = f.path;
    final isRemoteOrS3 = path != null && (path.startsWith('http') || path.contains('amazonaws.com') || path.startsWith('expenses/'));
    
    if (isRemoteOrS3) {
      return EtcRecordInlineFilePreview(
        fileUrl: path,
        height: 280,
        displayFileName: f.name,
      );
    }
    
    return PickedFileInlinePreview(
      key: ValueKey<String>('${f.name}_${f.size}'),
      file: f,
      height: 280,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(widget.year, widget.month, 1);
    final lastDayOfMonth = DateTime(widget.year, widget.month + 1, 0);

    var initialDate = _expenseDate ?? now;
    if (initialDate.isBefore(firstDayOfMonth)) {
      initialDate = firstDayOfMonth;
    } else if (initialDate.isAfter(lastDayOfMonth)) {
      initialDate = lastDayOfMonth;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDayOfMonth,
      lastDate: lastDayOfMonth,
      helpText: '${widget.year}년 ${widget.month}월의 일자를 선택해주세요',
    );
    if (picked != null && mounted) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _pickCategory() async {
    if (_categories.isEmpty) return;
    final selected = await showModalBottomSheet<StoreExpenseCategory>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in _categories)
                      ListTile(
                        title: Text(c.categoryLabel, textAlign: TextAlign.center),
                        onTap: () => Navigator.pop(ctx, c),
                      ),
                  ],
                ),
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
    final result = await pickMultipleFilesOrGallery(
      context: context,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    if (result == null || !mounted) return;
    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(result);
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
      final createdItem = await repo.createStep2(
        branchId: widget.branchId,
        expenseMonthId: widget.expenseMonthId,
        expenseDate: DateFormat('yyyy-MM-dd').format(date),
        categoryCode: category.categoryCode,
        amount: amount,
        files: [], // 메타데이터 저장 (파일 없음)
      );

      if (_pickedFiles.isNotEmpty) {
        await repo.appendItemFiles(
          branchId: widget.branchId,
          expenseItemId: createdItem.expenseItemId,
          files: _pickedFiles,
        );
      }

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

