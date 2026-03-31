import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecruitmentReviewScreen extends StatefulWidget {
  const RecruitmentReviewScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    this.initialEmployeeName,
    this.initialDesiredLocation,
    this.initialAverageRating,
    this.initialReviewCount,
  });

  final int branchId;
  final int employeeId;
  final String? initialEmployeeName;
  final String? initialDesiredLocation;
  final double? initialAverageRating;
  final int? initialReviewCount;

  @override
  State<RecruitmentReviewScreen> createState() => _RecruitmentReviewScreenState();
}

class _RecruitmentReviewScreenState extends State<RecruitmentReviewScreen> {
  JobSeekerReviewPage? _reviewPage;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final page = await context.read<ManagerHomeRepository>().getJobSeekerReviews(
            branchId: widget.branchId,
            employeeId: widget.employeeId,
          );
      if (!mounted) return;
      setState(() {
        _reviewPage = page;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewPage = null;
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _reviewPage;
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '리뷰보기',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ReviewErrorView(
                  message: _error!,
                  onRetry: _loadReviews,
                )
              : Column(
                  children: [
                    _ReviewSummaryHeader(
                      employeeName: page?.employeeName ?? widget.initialEmployeeName ?? '-',
                      desiredLocation:
                          page?.desiredLocation ?? widget.initialDesiredLocation ?? '-',
                      averageRating:
                          page?.averageRating ?? widget.initialAverageRating ?? 0,
                      reviewCount: page?.reviewCount ?? widget.initialReviewCount ?? 0,
                    ),
                    Expanded(
                      child: (page == null || page.items.isEmpty)
                          ? Center(
                              child: Text(
                                '등록된 리뷰가 없습니다.',
                                style: AppTypography.bodyMediumR.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                              itemBuilder: (context, index) {
                                return _ReviewCard(review: page.items[index]);
                              },
                              separatorBuilder: (_, __) => SizedBox(height: 16.h),
                              itemCount: page.items.length,
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ReviewSummaryHeader extends StatelessWidget {
  const _ReviewSummaryHeader({
    required this.employeeName,
    required this.desiredLocation,
    required this.averageRating,
    required this.reviewCount,
  });

  final String employeeName;
  final String desiredLocation;
  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        border: Border(
          bottom: BorderSide(color: AppColors.grey25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _PersonAvatar(size: 48),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: AppTypography.bodyLargeM.copyWith(
                    fontSize: 16.sp,
                    height: 20 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      desiredLocation,
                      style: AppTypography.bodySmallR.copyWith(
                        fontSize: 12.sp,
                        height: 18 / 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScoreStars(
                          filledCount: _filledStarCount(averageRating, maxStars: 3),
                          maxStars: 3,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '($reviewCount)',
                          style: AppTypography.bodySmallR.copyWith(
                            fontSize: 12.sp,
                            height: 18 / 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final JobSeekerReview review;

  @override
  Widget build(BuildContext context) {
    final createdAt =
        (review.createdAt ?? '').trim().isNotEmpty ? _formatDateTime(review.createdAt!) : '-';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PersonAvatar(size: 32),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        review.managerName ?? '-',
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14.sp,
                          height: 16 / 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      createdAt,
                      style: AppTypography.bodySmallR.copyWith(
                        fontSize: 12.sp,
                        height: 18 / 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _ReviewScoreChip(
                rating: review.rating,
                maxRating: review.maxRating == 0 ? 3 : review.maxRating,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.grey50),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              (review.comment ?? '').trim().isEmpty ? '-' : review.comment!.trim(),
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14.sp,
                height: 20 / 14,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewScoreChip extends StatelessWidget {
  const _ReviewScoreChip({
    required this.rating,
    required this.maxRating,
  });

  final int rating;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 4.h, 8.w, 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: Color(0xFFFFD464),
          ),
          SizedBox(width: 2.w),
          Text(
            '$rating / $maxRating',
            style: AppTypography.bodySmallM.copyWith(
              fontSize: 12.sp,
              height: 16 / 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewErrorView extends StatelessWidget {
  const _ReviewErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey25,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.62,
        color: const Color(0xFFDADBE4),
      ),
    );
  }
}

class _ScoreStars extends StatelessWidget {
  const _ScoreStars({
    required this.filledCount,
    required this.maxStars,
    required this.color,
  });

  final int filledCount;
  final int maxStars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        return Icon(
          Icons.star_rounded,
          size: 16,
          color: index < filledCount ? color : color.withValues(alpha: 0.18),
        );
      }),
    );
  }
}

int _filledStarCount(double rating, {required int maxStars}) {
  if (rating <= 0) return 0;
  return rating.round().clamp(1, maxStars);
}

String _formatDateTime(String value) {
  try {
    final parsed = DateTime.parse(value);
    return DateFormat('yyyy.MM.dd HH:mm:ss').format(parsed.toLocal());
  } catch (_) {
    return value;
  }
}
