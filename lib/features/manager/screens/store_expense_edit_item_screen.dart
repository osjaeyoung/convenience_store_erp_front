import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/thousands_separator_input_formatter.dart';
import '../../../data/models/store_expense/store_expense_month.dart';
import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoreExpenseEditItemScreen extends StatefulWidget {
  const StoreExpenseEditItemScreen({
    super.key,
    required this.branchId,
    required this.periodLabel,
    required this.item,
  });

  final int branchId;
  final String periodLabel;
  final StoreExpenseItem item;

  @override
  State<StoreExpenseEditItemScreen> createState() => _StoreExpenseEditItemScreenState();
}

class _StoreExpenseEditItemScreenState extends State<StoreExpenseEditItemScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _memoCtrl = TextEditingController();
  DateTime? _expenseDate;
  StoreExpenseCategory? _selectedCategory;
  List<StoreExpenseCategory> _categories = const [];
  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _expenseDate = DateTime.tryParse(widget.item.expenseDate);
    _amountCtrl.text = NumberFormat('#,###', 'ko_KR').format(widget.item.amount);
    _memoCtrl.text = widget.item.memo ?? '';
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = context.read<StoreExpenseRepository>();
      final cats = await repo.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats.where((e) => e.isActive).toList();
        _selectedCategory = _categories.where((e) => e.categoryCode == widget.item.categoryCode).firstOrNull;
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
        title: Text('항목 정보 수정', style: AppTypography.appBarTitle),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _delete,
            child: Text(
              '삭제',
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
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
                      '${widget.periodLabel}월\n비용 지출 수정',
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
                      value: _selectedCategory?.categoryLabel ?? widget.item.categoryLabel,
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
                    _label('메모 (선택)'),
                    SizedBox(height: 8.h),
                    AuthInputField(
                      controller: _memoCtrl,
                      hintText: '메모를 입력해주세요.',
                      keyboardType: TextInputType.text,
                    ),
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
                          '수정하기',
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

  Future<void> _save() async {
    final date = _expenseDate;
    final category = _selectedCategory;
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (date == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일자/항목/금액을 올바르게 입력해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<StoreExpenseRepository>();
      await repo.patchItem(
        branchId: widget.branchId,
        expenseItemId: widget.item.expenseItemId,
        expenseDate: DateFormat('yyyy-MM-dd').format(date),
        categoryCode: category?.categoryCode ?? widget.item.categoryCode,
        amount: amount,
        memo: _memoCtrl.text.isNotEmpty ? _memoCtrl.text : null,
      );
      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('항목 수정에 실패했습니다: $e')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '이 지출 항목을 삭제할까요?',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  height: 24 / 18,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        backgroundColor: AppColors.grey0,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '삭제',
                        style: AppTypography.bodyMediumB.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;

    if (!sure || !mounted) return;

    setState(() => _saving = true);
    try {
      final repo = context.read<StoreExpenseRepository>();
      await repo.deleteItem(
        branchId: widget.branchId,
        expenseItemId: widget.item.expenseItemId,
      );
      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('항목 삭제에 실패했습니다: $e')),
      );
      setState(() => _saving = false);
    }
  }
}
