import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/repositories/staff_management_repository.dart';
import '../widgets/employee_profile_box.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 리뷰 작성/수정 화면 - 직원 상세에서 "리뷰작성" 탭 시 이동
/// [initialMyRating] 내가 이전에 매긴 별점 (있으면 초기값으로 사용, 없으면 3)
/// [initialComment] 기존 평가 코멘트 (리뷰 수정 시 표시)
/// [existingReviewId] 기존 리뷰 ID (있으면 수정 모드, 삭제 후 재등록)
class EmployeeReviewScreen extends StatefulWidget {
  const EmployeeReviewScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.hireDate,
    required this.contact,
    this.resignationDate,
    this.profileImageUrl,
    this.initialMyRating,
    this.initialComment,
    this.existingReviewId,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final String hireDate;
  final String contact;
  final String? resignationDate;
  final String? profileImageUrl;
  final int? initialMyRating;
  final String? initialComment;
  final int? existingReviewId;

  @override
  State<EmployeeReviewScreen> createState() => _EmployeeReviewScreenState();
}

class _EmployeeReviewScreenState extends State<EmployeeReviewScreen> {
  late int _rating;
  final _commentController = TextEditingController();

  bool get _isEditMode =>
      widget.existingReviewId != null ||
      (widget.initialComment?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _rating = (widget.initialMyRating ?? 3).clamp(1, 3);
    _commentController.text = widget.initialComment ?? '';
  }
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('평가 코멘트를 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      if (widget.existingReviewId != null) {
        await repo.deleteReview(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          reviewId: widget.existingReviewId!,
        );
      }
      await repo.createReview(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        rating: _rating,
        comment: comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? '리뷰가 수정되었습니다.' : '리뷰가 등록되었습니다.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '리뷰 수정 실패: $e' : '리뷰 등록 실패: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? '리뷰 수정' : '리뷰작성'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmployeeProfileBox(
              name: widget.employeeName,
              hireDate: widget.hireDate,
              contact: widget.contact,
              resignationDate: widget.resignationDate,
              showEditButton: false,
              profileImageUrl: widget.profileImageUrl,
              starCount: _rating, // 내가 선택한 별점 표시
            ),
            SizedBox(height: 24.h),
            Text(
              '평점',
              style: AppTypography.bodyMediumB.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                height: 16 / 14,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        filled
                            ? 'assets/icons/png/common/star_icon.png'
                            : 'assets/icons/png/common/star_empty_icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 24.h),
            Text(
              '평가 코멘트',
              style: AppTypography.bodyMediumB.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                height: 16 / 14,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _commentController,
              maxLines: 5,
              minLines: 4,
              decoration: InputDecoration(
                hintText: '근무자에 대한 평가를 작성해 주세요.',
                hintStyle: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.grey100,
                  fontSize: 14.sp,
                ),
                filled: true,
                fillColor: AppColors.grey0,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.grey50),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.grey50),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.all(16.r),
              ),
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(56.h),
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.grey0,
                      ),
                    )
                  : Text(_isEditMode ? '리뷰 수정' : '리뷰 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
