import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../screens/worker_resume_form_screen.dart';
import 'worker_common.dart';

class WorkerResumeManagementTab extends StatefulWidget {
  const WorkerResumeManagementTab({
    super.key,
    required this.refreshToken,
    required this.onResumeChanged,
  });

  final int refreshToken;
  final VoidCallback onResumeChanged;

  @override
  State<WorkerResumeManagementTab> createState() =>
      _WorkerResumeManagementTabState();
}

class _WorkerResumeManagementTabState extends State<WorkerResumeManagementTab> {
  WorkerResumePage? _page;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkerResumeManagementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<WorkerRecruitmentRepository>()
          .getResumes();
      if (!mounted) return;
      setState(() {
        _page = page;
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

  Future<void> _openResumeForm({int? resumeId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerResumeFormScreen(resumeId: resumeId),
      ),
    );
    if (changed == true) {
      widget.onResumeChanged();
      await _load();
    }
  }

  Future<void> _confirmDelete(WorkerResumeSummary item) async {
    if (!item.canDelete) return;
    final repo = context.read<WorkerRecruitmentRepository>();
    final confirmed = await showWorkerConfirmDialog(
      context,
      title: '알림',
      message: '이력서를 삭제하시겠습니까?',
      confirmLabel: item.deleteButtonLabel ?? '삭제',
    );
    if (!confirmed) return;
    try {
      await repo.deleteResume(resumeId: item.resumeId);
      if (!mounted) return;
      widget.onResumeChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이력서를 삭제했습니다.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (_loading && page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && page == null) {
      return workerErrorView(
        message: accountDioMessage(_error!),
        onRetry: _load,
      );
    }
    if (page == null || page.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 24.h),
          children: [
            SizedBox(height: 108.h),
            _ResumeEmptyState(
              message: page?.emptyMessage ?? '작성하신 이력서가 없어요.',
              buttonLabel: page?.createButtonLabel ?? '이력서 작성',
              onCreate: () => _openResumeForm(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        itemCount: page.items.length,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          final item = page.items[index];
          return _ResumeListCard(
            item: item,
            onEdit: () => _openResumeForm(resumeId: item.resumeId),
            onDelete: () => _confirmDelete(item),
          );
        },
      ),
    );
  }
}

class _ResumeEmptyState extends StatelessWidget {
  const _ResumeEmptyState({
    required this.message,
    required this.buttonLabel,
    required this.onCreate,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120.r,
          height: 120.r,
          decoration: const BoxDecoration(
            color: AppColors.grey0Alt,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.description_rounded,
                  size: 44.r,
                  color: AppColors.grey100,
                ),
                Positioned(
                  top: -2,
                  right: -8,
                  child: Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: const BoxDecoration(
                      color: AppColors.grey150,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.question_mark_rounded,
                      size: 16.r,
                      color: AppColors.grey0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        SizedBox(height: 32.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: FilledButton(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.grey0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonLabel,
              style: AppTypography.bodyLargeB.copyWith(color: AppColors.grey0),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumeListCard extends StatelessWidget {
  const _ResumeListCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkerResumeSummary item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: const BoxDecoration(
                  color: AppColors.grey0Alt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 24.r,
                  color: AppColors.grey100,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.textPrimary,
                        height: 16 / 14,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.resumeTypeLabel ?? '이력서',
                      style: AppTypography.bodySmallR.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      backgroundColor: AppColors.grey0,
                    ),
                    child: Text(
                      item.editButtonLabel ?? '수정',
                      style: AppTypography.bodyMediumB.copyWith(
                        color: AppColors.primary,
                        height: 16 / 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: FilledButton(
                    onPressed: item.canDelete ? onDelete : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey25,
                      disabledBackgroundColor: AppColors.grey25,
                      foregroundColor: AppColors.textTertiary,
                      disabledForegroundColor: AppColors.textTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      item.deleteButtonLabel ?? '삭제',
                      style: AppTypography.bodyMediumB.copyWith(
                        color: AppColors.textTertiary,
                        height: 16 / 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
