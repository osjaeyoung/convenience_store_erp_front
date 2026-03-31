import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'store_expense_add_item_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoreExpenseAddMonthScreen extends StatefulWidget {
  const StoreExpenseAddMonthScreen({
    super.key,
    required this.branchId,
    this.initialYear,
    this.initialMonth,
  });

  final int branchId;
  final int? initialYear;
  final int? initialMonth;

  @override
  State<StoreExpenseAddMonthScreen> createState() =>
      _StoreExpenseAddMonthScreenState();
}

class _StoreExpenseAddMonthScreenState extends State<StoreExpenseAddMonthScreen> {
  int? _year;
  int? _month;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
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
        title: Text('월별 점내 비용 추가', style: AppTypography.appBarTitle),
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
                      '구체적인 년도 및\n월일을 선택해주세요.',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 44 / 2,
                        fontWeight: FontWeight.w400,
                        height: 32 / 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _label('년도'),
                    SizedBox(height: 8.h),
                    _selectorTile(
                      value: _year?.toString(),
                      hint: '선택해주세요.',
                      onTap: () => _pickYear(context),
                    ),
                    SizedBox(height: 20.h),
                    _label('월'),
                    SizedBox(height: 8.h),
                    _selectorTile(
                      value: _month?.toString(),
                      hint: '선택해주세요.',
                      onTap: () => _pickMonth(context),
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
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.grey0,
                          ),
                        )
                      : Text(
                          '다음',
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
    required VoidCallback onTap,
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

  Future<void> _pickYear(BuildContext context) async {
    final current = DateTime.now().year;
    final years = List<int>.generate(7, (i) => current - 3 + i);
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final y in years)
                ListTile(
                  title: Text('$y년'),
                  onTap: () => Navigator.pop(ctx, y),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _year = selected);
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var m = 1; m <= 12; m++)
                ListTile(
                  title: Text('$m월'),
                  onTap: () => Navigator.pop(ctx, m),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _month = selected);
    }
  }

  Future<void> _submit() async {
    final year = _year;
    final month = _month;
    if (year == null || month == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('년도와 월을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<StoreExpenseRepository>();
      final created = await repo.createStep1(
        branchId: widget.branchId,
        year: year,
        month: month,
      );
      if (!mounted) return;
      if (!created.isNewMonthCreated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기존 월별 점내 비용 내역에 이어서 추가합니다.')),
        );
      }

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => StoreExpenseAddItemScreen(
            branchId: widget.branchId,
            expenseMonthId: created.expenseMonthId,
            periodLabel: created.periodLabel,
          ),
        ),
      );
      if (!mounted) return;
      if (saved == true) {
        Navigator.pop<int>(context, created.year);
        return;
      }
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('월 추가에 실패했습니다: $e')),
      );
      setState(() => _submitting = false);
    }
  }
}

