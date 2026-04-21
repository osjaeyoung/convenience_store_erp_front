import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';
import 'worker_resume_form_screen.dart';

class WorkerApplyScreen extends StatefulWidget {
  const WorkerApplyScreen({super.key, required this.postingId});

  final int postingId;

  @override
  State<WorkerApplyScreen> createState() => _WorkerApplyScreenState();
}

class _WorkerApplyScreenState extends State<WorkerApplyScreen> {
  WorkerRecruitmentApplyOptions? _options;
  int? _selectedResumeId;
  bool _loading = true;
  bool _submitting = false;
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
      final options = await context
          .read<WorkerRecruitmentRepository>()
          .getApplyOptions(postingId: widget.postingId);
      if (!mounted) return;
      setState(() {
        _options = options;
        _selectedResumeId =
            options.selectedResumeId ??
            options.resumes
                .firstWhere(
                  (resume) => resume.isDefault,
                  orElse: () => options.resumes.isEmpty
                      ? const WorkerResumeSummary(resumeId: 0, title: '')
                      : options.resumes.first,
                )
                .resumeId;
        if (options.resumes.isEmpty) {
          _selectedResumeId = null;
        } else if (_selectedResumeId == 0) {
          _selectedResumeId = options.resumes.first.resumeId;
        }
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

  Future<void> _submit() async {
    final options = _options;
    final selectedResumeId = _selectedResumeId;
    if (options == null || selectedResumeId == null) return;
    if (options.alreadyApplied || !options.canApply) {
      final message =
          options.blockedReason ??
          (options.alreadyApplied ? '이미 지원한 공고입니다.' : '지원할 수 없습니다.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final confirmed = await showWorkerConfirmDialog(
      context,
      title: workerDisplayValue(options.confirmTitle, fallback: '알림'),
      message: workerDisplayValue(
        options.confirmMessage,
        fallback: '지원하시겠습니까?',
      ),
    );
    if (!confirmed || !mounted) return;
    setState(() => _submitting = true);
    try {
      await context.read<WorkerRecruitmentRepository>().createApplication(
        postingId: widget.postingId,
        resumeId: selectedResumeId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final actionDisabled =
        _submitting ||
        options == null ||
        !options.canApply ||
        options.alreadyApplied ||
        _selectedResumeId == null;

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: workerSubPageAppBar(context, title: '지원하기'),
      body: _loading && options == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && options == null
          ? workerErrorView(message: accountDioMessage(_error!), onRetry: _load)
          : Column(
              children: [
                Expanded(
                  child: options == null || options.resumes.isEmpty
                      ? workerEmptyView(
                          message: '선택할 이력서가 없습니다.',
                          description:
                              options?.blockedReason ?? '이력서를 먼저 등록해 주세요.',
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                          itemCount: options.resumes.length,
                          itemBuilder: (context, index) {
                            final resume = options.resumes[index];
                            final selected =
                                resume.resumeId == _selectedResumeId;
                            return _ResumeTile(
                              resume: resume,
                              selected: selected,
                              onTap: () {
                                setState(
                                  () => _selectedResumeId = resume.resumeId,
                                );
                              },
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: FilledButton(
                        onPressed: actionDisabled ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.grey100,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.grey0,
                                ),
                              )
                            : Text(
                                options?.alreadyApplied == true
                                    ? '지원완료'
                                    : '지원하기',
                                style: AppTypography.bodyLargeB.copyWith(
                                  color: AppColors.grey0,
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

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({
    required this.resume,
    required this.selected,
    required this.onTap,
  });

  final WorkerResumeSummary resume;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            children: [
              _ResumeCheck(selected: selected),
              SizedBox(width: 12.w),
              Container(
                width: 42.r,
                height: 42.r,
                decoration: const BoxDecoration(
                  color: AppColors.grey25,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 20.r,
                  color: AppColors.textDisabled,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.title,
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      workerDisplayValue(resume.resumeTypeLabel),
                      style: AppTypography.bodySmallR.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkerResumeFormScreen(resumeId: resume.resumeId),
                    ),
                  );
                },
                padding: EdgeInsets.all(8.r),
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.r,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeCheck extends StatelessWidget {
  const _ResumeCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_rounded, size: 14.r, color: AppColors.grey0),
    );
  }
}
