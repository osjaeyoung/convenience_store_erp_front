import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  State<StoreExpenseEditItemScreen> createState() =>
      _StoreExpenseEditItemScreenState();
}

class _StoreExpenseEditItemScreenState
    extends State<StoreExpenseEditItemScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _memoCtrl = TextEditingController();
  DateTime? _expenseDate;
  StoreExpenseCategory? _selectedCategory;
  List<StoreExpenseCategory> _categories = const [];
  final List<PlatformFile> _pickedFiles = <PlatformFile>[];
  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _expenseDate = DateTime.tryParse(widget.item.expenseDate);
    _amountCtrl.text = NumberFormat(
      '#,###',
      'ko_KR',
    ).format(widget.item.amount);
    _memoCtrl.text = widget.item.memo ?? '';
    // 기존 파일들을 _pickedFiles에 넣어두기 (이름만 표시되도록)
    if (widget.item.files.isNotEmpty) {
      _pickedFiles.addAll(
        widget.item.files.map(
          (f) => PlatformFile(name: f.fileName, size: 0, path: f.fileUrl),
        ),
      );
    }
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
        _selectedCategory = _categories
            .where((e) => e.categoryCode == widget.item.categoryCode)
            .firstOrNull;
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
                      value:
                          _selectedCategory?.categoryLabel ??
                          widget.item.categoryLabel,
                      hint: _loadingCategories ? '불러오는 중...' : '선택해주세요.',
                      onTap: _loadingCategories ? null : _pickCategory,
                    ),
                    SizedBox(height: 20.h),
                    _label('금액'),
                    SizedBox(height: 8.h),
                    AuthInputField(
                      controller: _amountCtrl,
                      hintText: '입력해주세요.',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                    ),
                    SizedBox(height: 20.h),
                    _label('메모 (선택)'),
                    SizedBox(height: 8.h),
                    AuthInputField(
                      controller: _memoCtrl,
                      hintText: '메모를 입력해주세요.',
                      keyboardType: TextInputType.text,
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

  Widget _fileArea() {
    if (_pickedFiles.isEmpty) {
    return InkWell(
      onTap: _pickFiles,
        borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
          height: 132,
        decoration: BoxDecoration(
            color: AppColors.grey0Alt,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.grey50),
          ),
          child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(height: 10.h),
                  Text(
                    '파일을 첨부해주세요.',
                    style: AppTypography.bodyMediumB.copyWith(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                    ),
                  ),
              SizedBox(height: 4.h),
              Text(
                '영수증 사진 또는 PDF를 업로드할 수 있어요.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
        Row(
                        children: [
            Expanded(
              child: Text(
                '첨부파일',
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: _pickFiles,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '다시 선택',
                style: AppTypography.bodySmallB.copyWith(
                  color: AppColors.primary,
                  fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
        SizedBox(height: 8.h),
        for (final f in _pickedFiles) ...[
          _attachedFileCard(f),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }

  Widget _attachedFileCard(PlatformFile file) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: _buildInlinePreview(file),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.black.withValues(alpha: 0.56),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _pickedFiles.remove(file)),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.grey0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePreview(PlatformFile f) {
    final path = f.path;
    final isRemoteOrS3 =
        path != null &&
        (path.startsWith('http') ||
            path.contains('amazonaws.com') ||
            path.startsWith('expenses/'));
    
    if (isRemoteOrS3) {
      return EtcRecordInlineFilePreview(
        fileUrl: path,
        height: 260,
        displayFileName: f.name,
        showFileName: false,
      );
    }
    
    return PickedFileInlinePreview(
      key: ValueKey<String>('${f.name}_${f.size}'),
      file: f,
      height: 260,
      showFileName: false,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = DateTime.tryParse(widget.item.expenseDate) ?? now;
    final firstDayOfMonth = DateTime(d.year, d.month, 1);
    final lastDayOfMonth = DateTime(d.year, d.month + 1, 0);

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
      helpText: '${d.year}년 ${d.month}월의 일자를 선택해주세요',
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
                        title: Text(
                          c.categoryLabel,
                          textAlign: TextAlign.center,
                        ),
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
    if (date == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일자/항목/금액을 올바르게 입력해 주세요.')));
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

      // 수정된 파일이 기존 파일과 다를 수 있지만,
      // 현재 API에서 '수정 시 파일만 부분 업데이트'를 처리하는 방법은 `appendItemFiles`뿐입니다.
      // 새로 선택된 파일이 있을 때만 append 합니다 (삭제는 스펙상 아직 지원되지 않거나 append만 가능한 것으로 가정).
      final newFiles = _pickedFiles
          .where(
            (f) =>
                f.bytes != null ||
                (f.path != null && !f.path!.startsWith('http')),
          )
          .toList();
      if (newFiles.isNotEmpty) {
        await repo.appendItemFiles(
          branchId: widget.branchId,
          expenseItemId: widget.item.expenseItemId,
          files: newFiles,
        );
      }

      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('항목 수정에 실패했습니다: $e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final sure =
        await showDialog<bool>(
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
        ) ??
        false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('항목 삭제에 실패했습니다: $e')));
      setState(() => _saving = false);
    }
  }
}
