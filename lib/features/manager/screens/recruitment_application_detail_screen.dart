import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import 'recruitment_review_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecruitmentApplicationDetailScreen extends StatefulWidget {
  const RecruitmentApplicationDetailScreen({
    super.key,
    required this.branchId,
    required this.applicationId,
  });

  final int branchId;
  final int applicationId;

  @override
  State<RecruitmentApplicationDetailScreen> createState() =>
      _RecruitmentApplicationDetailScreenState();
}

class _RecruitmentApplicationDetailScreenState
    extends State<RecruitmentApplicationDetailScreen> {
  JobSeekerProfile? _profile;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await context.read<ManagerHomeRepository>().getRecruitmentApplicationDetail(
            branchId: widget.branchId,
            applicationId: widget.applicationId,
          );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openReviews() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecruitmentReviewScreen(
          branchId: widget.branchId,
          employeeId: profile.employeeId,
          initialEmployeeName: profile.employeeName,
          initialDesiredLocation:
              profile.desiredLocations.isNotEmpty ? profile.desiredLocations.first : null,
          initialAverageRating: profile.averageRating,
          initialReviewCount: profile.reviewCount,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '이 지원자를 삭제할까요?',
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<ManagerHomeRepository>().deleteRecruitmentApplication(
            branchId: widget.branchId,
            applicationId: widget.applicationId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지원자가 삭제되었습니다.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '지원현황',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ApplicationErrorView(
                  message: _error!,
                  onRetry: _load,
                )
              : _profile == null
                  ? const Center(child: Text('데이터를 불러올 수 없습니다.'))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ApplicationHeroCard(
                                  profile: _profile!,
                                  onViewReviews: _openReviews,
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  '근무 이력',
                                  style: AppTypography.heading3.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                _ApplicationWorkHistoryCard(
                                  histories: _profile!.workHistories,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Container(
                            color: AppColors.grey0,
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
                            child: SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: _deleting ? null : _delete,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.grey150,
                                  foregroundColor: AppColors.grey0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: _deleting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.grey0,
                                        ),
                                      )
                                    : Text(
                                        _profile!.contactActionLabel ?? '삭제',
                                        style: AppTypography.bodyLargeB.copyWith(
                                          color: AppColors.grey0,
                                          height: 24 / 16,
                                        ),
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

class _ApplicationHeroCard extends StatelessWidget {
  const _ApplicationHeroCard({
    required this.profile,
    required this.onViewReviews,
  });

  final JobSeekerProfile profile;
  final VoidCallback onViewReviews;

  @override
  Widget build(BuildContext context) {
    final locations =
        profile.desiredLocations.isEmpty ? const ['-'] : profile.desiredLocations;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF9FEFD4),
            Color(0xFFE1F0B8),
          ],
        ),
      ),
      child: Column(
        children: [
          const _ApplicantAvatar(size: 80),
          SizedBox(height: 20.h),
          _ApplicationInfoRow(
            label: '근무자명',
            value: _valueText(profile.employeeName),
          ),
          _ApplicationInfoRow(
            label: '연락처',
            value: _valueText(profile.contactPhone ?? '-'),
          ),
          _ApplicationInfoRow(
            label: '근무 경력',
            value: _valueText(profile.careerLabel ?? '-'),
          ),
          _ApplicationInfoRow(
            label: '희망 근무지',
            crossAxisAlignment: CrossAxisAlignment.start,
            value: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < locations.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == locations.length - 1 ? 0 : 8),
                    child: _valueText(locations[i]),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          _ApplicationInfoRow(
            label: '평점',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ApplicantStars(
                  filledCount: _filledApplicantStarCount(
                    profile.averageRating,
                    maxStars: 3,
                  ),
                  maxStars: 3,
                  color: AppColors.grey0,
                ),
                SizedBox(width: 4.w),
                Text(
                  '(${profile.reviewCount})',
                  style: AppTypography.bodySmallR.copyWith(
                    fontSize: 12.sp,
                    height: 18 / 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: onViewReviews,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '리뷰보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.grey0,
                      height: 16 / 12,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.grey0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueText(String text) {
    return Text(
      text,
      style: AppTypography.bodyMediumR.copyWith(
        fontSize: 14.sp,
        height: 19 / 14,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.right,
    );
  }
}

class _ApplicationInfoRow extends StatelessWidget {
  const _ApplicationInfoRow({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String label;
  final Widget value;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            label,
            style: AppTypography.bodyMediumM.copyWith(
              fontSize: 14.sp,
              height: 16 / 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationWorkHistoryCard extends StatelessWidget {
  const _ApplicationWorkHistoryCard({required this.histories});

  final List<JobSeekerWorkHistory> histories;

  @override
  Widget build(BuildContext context) {
    final items = histories.isEmpty ? const [JobSeekerWorkHistory()] : histories;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.grey25),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      items[i].periodLabel ?? '-',
                      style: AppTypography.bodyMediumR.copyWith(
                        fontSize: 14.sp,
                        height: 19 / 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          items[i].companyName ?? '-',
                          style: AppTypography.bodyLargeM.copyWith(
                            fontSize: 16.sp,
                            height: 20 / 16,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          items[i].roleLabel ?? '-',
                          style: AppTypography.bodySmallR.copyWith(
                            fontSize: 12.sp,
                            height: 18 / 12,
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplicationErrorView extends StatelessWidget {
  const _ApplicationErrorView({
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

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({required this.size});

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

class _ApplicantStars extends StatelessWidget {
  const _ApplicantStars({
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
          color: index < filledCount ? color : color.withValues(alpha: 0.28),
        );
      }),
    );
  }
}

int _filledApplicantStarCount(double rating, {required int maxStars}) {
  if (rating <= 0) return 0;
  return rating.round().clamp(1, maxStars);
}
