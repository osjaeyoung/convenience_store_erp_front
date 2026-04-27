import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'recruitment_inquiry_chat_screen.dart';
import 'recruitment_review_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecruitmentJobSeekerDetailScreen extends StatefulWidget {
  const RecruitmentJobSeekerDetailScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    this.workerUserId,
  });

  final int branchId;
  final int employeeId;
  final int? workerUserId;

  @override
  State<RecruitmentJobSeekerDetailScreen> createState() =>
      _RecruitmentJobSeekerDetailScreenState();
}

class _RecruitmentJobSeekerDetailScreenState
    extends State<RecruitmentJobSeekerDetailScreen> {
  JobSeekerProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final repo = context.read<ManagerHomeRepository>();
    try {
      await repo.openJobSeekerProfile(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
    } catch (_) {
      // 최근 열람 저장 실패 시에도 상세는 보여준다.
    }

    try {
      final profile = await repo.getJobSeekerProfile(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _isLoading = false;
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
          employeeId: widget.employeeId,
          workerUserId: profile.workerUserId ?? widget.workerUserId,
          initialEmployeeName: profile.employeeName,
          initialDesiredLocation: profile.desiredLocations.isNotEmpty
              ? profile.desiredLocations.first
              : null,
          initialAverageRating: profile.averageRating,
          initialReviewCount: profile.reviewCount,
        ),
      ),
    );
  }

  Future<void> _openInquiryChat() async {
    final profile = _profile;
    try {
      final repository = context.read<ManagerHomeRepository>();
      var employeeId = _effectiveEmployeeIdForChat(profile);
      if (employeeId < 0) {
        final contact = await repository.postJobSeekerContact(
          branchId: widget.branchId,
          employeeId: employeeId,
          message: null,
        );
        employeeId = contact.employeeId;
      }
      final chat = await repository.createOrGetRecruitmentChat(
        branchId: widget.branchId,
        employeeId: employeeId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => ManagerRecruitmentInquiryChatScreen(
            chatId: chat.chatId,
            branchId: chat.branchId,
            employeeId: chat.employeeId,
            employeeName: chat.counterpartyName.isNotEmpty
                ? chat.counterpartyName
                : profile?.employeeName,
            profileImageUrl:
                chat.counterpartyProfileImageUrl ?? profile?.profileImageUrl,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방을 열 수 없습니다: $error')));
    }
  }

  int _effectiveEmployeeIdForChat(JobSeekerProfile? profile) {
    final profileEmployeeId = profile?.employeeId;
    if (profileEmployeeId != null && profileEmployeeId > 0) {
      return profileEmployeeId;
    }
    return widget.employeeId;
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
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: Text(
          '최근 열람 회원',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _DetailErrorView(message: _error!, onRetry: _loadProfile)
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
                        _ProfileHeroCard(
                          profile: _profile!,
                          onViewReviews: _openReviews,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          '근무 이력',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 24 / 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _WorkHistoryCard(histories: _profile!.workHistories),
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
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _openInquiryChat,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          '문의하기',
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile, required this.onViewReviews});

  final JobSeekerProfile profile;
  final VoidCallback onViewReviews;

  @override
  Widget build(BuildContext context) {
    final locations = profile.desiredLocations.isEmpty
        ? const ['-']
        : profile.desiredLocations;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF9FEFD4), Color(0xFFE1F0B8)],
        ),
      ),
      child: Column(
        children: [
          const _PersonAvatar(size: 80),
          SizedBox(height: 20.h),
          _ProfileInfoRow(
            label: '근무자명',
            value: Text(
              profile.employeeName,
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14.sp,
                height: 19 / 14,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          _ProfileInfoRow(
            label: '근무 경력',
            value: Text(
              profile.careerLabel ?? '-',
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14.sp,
                height: 19 / 14,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          _ProfileInfoRow(
            label: '희망 근무지',
            crossAxisAlignment: CrossAxisAlignment.start,
            value: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < locations.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == locations.length - 1 ? 0 : 8,
                    ),
                    child: Text(
                      locations[i],
                      style: AppTypography.bodyMediumR.copyWith(
                        fontSize: 14.sp,
                        height: 19 / 14,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          _ProfileInfoRow(
            label: '평점',
            value: _ScoreStars(
              filledCount: _filledStarCount(profile.averageRating, maxStars: 3),
              maxStars: 3,
              color: const Color(0xFFFFD464),
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
                      fontSize: 12.sp,
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
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
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
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

class _WorkHistoryCard extends StatelessWidget {
  const _WorkHistoryCard({required this.histories});

  final List<JobSeekerWorkHistory> histories;

  @override
  Widget build(BuildContext context) {
    final items = histories.isEmpty
        ? const [JobSeekerWorkHistory()]
        : histories;
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

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.message, required this.onRetry});

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
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
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
