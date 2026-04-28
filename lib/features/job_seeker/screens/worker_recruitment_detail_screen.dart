import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';
import 'worker_apply_screen.dart';

class WorkerRecruitmentDetailScreen extends StatefulWidget {
  const WorkerRecruitmentDetailScreen({
    super.key,
    required this.postingId,
    this.onApplicationCreated,
  });

  final int postingId;
  final VoidCallback? onApplicationCreated;

  @override
  State<WorkerRecruitmentDetailScreen> createState() =>
      _WorkerRecruitmentDetailScreenState();
}

class _WorkerRecruitmentDetailScreenState
    extends State<WorkerRecruitmentDetailScreen> {
  WorkerRecruitmentPostingDetail? _detail;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await context
          .read<WorkerRecruitmentRepository>()
          .getPostingDetail(postingId: widget.postingId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openApply() async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerApplyScreen(postingId: widget.postingId),
      ),
    );
    if (applied != true || !mounted) return;
    widget.onApplicationCreated?.call();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지원이 완료되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final buttonLabel = detail?.isApplied == true
        ? '지원완료'
        : workerDisplayValue(detail?.applicationActionLabel, fallback: '지원하기');

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: workerSubPageAppBar(context, title: '채용정보'),
      body: _loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && detail == null
          ? workerErrorView(message: accountDioMessage(_error!), onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 8.h, 0, 120.h),
                children: [
                  Container(
                    color: AppColors.grey0,
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((detail?.badgeLabel ?? '').isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              detail!.badgeLabel!,
                              style: AppTypography.bodySmallM.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        SizedBox(height: 8.h),
                        Text(
                          workerDisplayValue(detail?.companyName),
                          style: AppTypography.bodySmallM.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          workerDisplayValue(detail?.title),
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_imageUrlOf(detail) != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                      child: _WorkerPostingImagePreview(
                        imageUrl: _imageUrlOf(detail)!,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailSection(
                          title: '근무조건',
                          child: _InfoCard(
                            children: [
                              _InfoValueRow(
                                label: '급여',
                                valueWidget: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      workerDisplayValue(detail?.payType),
                                      style: AppTypography.bodyMediumM.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      formatWorkerAmount(
                                        detail?.payAmount ?? 0,
                                      ),
                                      style: AppTypography.bodyMediumR.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _InfoValueRow(
                                label: '근무기간',
                                value: detail?.workPeriod,
                              ),
                              _InfoValueRow(
                                label: '근무요일',
                                value: detail?.workDays,
                                subValue: detail?.workDaysDetail,
                              ),
                              _InfoValueRow(
                                label: '근무시간',
                                value: detail?.workTime,
                                subValue: detail?.workTimeDetail,
                              ),
                              _InfoValueRow(
                                label: '업직종',
                                value: detail?.jobCategory,
                              ),
                              _InfoValueRow(
                                label: '고용형태',
                                value: detail?.employmentType,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _DetailSection(
                          title: '모집조건',
                          child: _InfoCard(
                            children: [
                              _InfoValueRow(
                                label: '모집마감',
                                value: detail?.recruitmentDeadline,
                              ),
                              _InfoValueRow(
                                label: '모집인원',
                                value: detail?.recruitmentHeadcount,
                                subValue: detail?.recruitmentHeadcountDetail,
                              ),
                              _InfoValueRow(
                                label: '학력',
                                value: detail?.education,
                                subValue: detail?.educationDetail,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _DetailSection(
                          title: '근무지역',
                          child: _SingleValueCard(value: detail?.address),
                        ),
                        SizedBox(height: 20.h),
                        _DetailSection(
                          title: '채용 담당자 연락처',
                          child: _InfoCard(
                            children: [
                              _InfoValueRow(
                                label: '담당자',
                                value: detail?.managerName,
                              ),
                              _InfoValueRow(
                                label: '전화',
                                value: detail?.contactPhone,
                              ),
                              if ((detail?.legalWarningMessage ?? '')
                                  .isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    detail!.legalWarningMessage!,
                                    style: AppTypography.bodySmallR.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: detail == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: AppColors.grey0,
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                child: SizedBox(
                  height: 56.h,
                  child: FilledButton(
                    onPressed: detail.isApplied ? null : _openApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.grey100,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonLabel,
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.grey0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

String? _imageUrlOf(WorkerRecruitmentPostingDetail? detail) {
  final url = detail?.profileImageUrl?.trim();
  return url == null || url.isEmpty ? null : url;
}

class _WorkerPostingImagePreview extends StatelessWidget {
  const _WorkerPostingImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: double.infinity,
        height: 146,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFD9D9D9),
            alignment: Alignment.center,
            child: Text(
              '등록된 사진',
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                height: 16 / 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        workerSectionTitle(title),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(children: children),
    );
  }
}

class _SingleValueCard extends StatelessWidget {
  const _SingleValueCard({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        workerDisplayValue(value),
        style: AppTypography.bodyMediumR.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _InfoValueRow extends StatelessWidget {
  const _InfoValueRow({
    required this.label,
    this.value,
    this.subValue,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final String? subValue;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              label,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                valueWidget ??
                    Text(
                      workerDisplayValue(value),
                      textAlign: TextAlign.right,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                if ((subValue ?? '').isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subValue!,
                    textAlign: TextAlign.right,
                    style: AppTypography.bodySmallR.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
