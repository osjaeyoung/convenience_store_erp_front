import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';

class WorkerResumeFormScreen extends StatefulWidget {
  const WorkerResumeFormScreen({super.key, this.resumeId});

  final int? resumeId;

  @override
  State<WorkerResumeFormScreen> createState() => _WorkerResumeFormScreenState();
}

class _WorkerResumeFormScreenState extends State<WorkerResumeFormScreen> {
  final TextEditingController _selfIntroductionController =
      TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool _deleting = false;
  Object? _error;

  WorkerResumeFormData? _formData;
  String? _educationLevel;
  String? _educationStatus;
  String? _careerType;
  List<_CareerEntryDraft> _careerDrafts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _selfIntroductionController.dispose();
    for (final draft in _careerDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<WorkerRecruitmentRepository>();
      final data = widget.resumeId == null
          ? await repo.getResumeTemplate()
          : await repo.getResumeDetail(resumeId: widget.resumeId!);
      if (!mounted) return;
      _applyFormData(data);
      setState(() {
        _formData = data;
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

  void _applyFormData(WorkerResumeFormData data) {
    for (final draft in _careerDrafts) {
      draft.dispose();
    }
    _educationLevel = data.educationLevel;
    _educationStatus = data.educationStatus;
    _careerType =
        data.careerType ??
        (data.careerTypeOptions.isNotEmpty
            ? data.careerTypeOptions.first.value
            : 'entry');
    _selfIntroductionController.text = data.selfIntroduction ?? '';
    _careerDrafts = data.careerEntries
        .map(_CareerEntryDraft.fromModel)
        .toList(growable: true);
    if (_isExperienced && _careerDrafts.isEmpty) {
      _careerDrafts = [_CareerEntryDraft.empty()];
    }
  }

  bool get _isExperienced => _careerType == 'experienced';

  Future<void> _selectOption({
    required String title,
    required List<WorkerResumeOption> options,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    if (options.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.grey0,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  title: Text(
                    option.label,
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: currentValue == option.value
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() => onSelected(selected));
  }

  Future<String?> _pickYearMonth(String? initialValue) async {
    final initial = _parseYearMonth(initialValue) ?? DateTime.now();
    DateTime selected = initial;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.grey0,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 280.h,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: Text(
                      '확인',
                      style: AppTypography.bodyMediumB.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    initialDateTime: initial,
                    minimumYear: 1980,
                    maximumYear: 2100,
                    onDateTimeChanged: (value) {
                      selected = DateTime(value.year, value.month);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null) return null;
    return '${result.year.toString().padLeft(4, '0')}-${result.month.toString().padLeft(2, '0')}';
  }

  DateTime? _parseYearMonth(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }

  String _formatYearMonth(String? value) {
    final date = _parseYearMonth(value);
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}';
  }

  String _optionLabel(List<WorkerResumeOption> options, String? value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return '';
  }

  void _setCareerType(String value) {
    setState(() {
      _careerType = value;
      if (_isExperienced && _careerDrafts.isEmpty) {
        _careerDrafts = [_CareerEntryDraft.empty()];
      }
    });
  }

  void _addCareerDraft() {
    setState(() {
      _careerDrafts = [..._careerDrafts, _CareerEntryDraft.empty()];
    });
  }

  void _removeCareerDraft(_CareerEntryDraft target) {
    target.dispose();
    setState(() {
      _careerDrafts = _careerDrafts.where((draft) => draft != target).toList();
      if (_isExperienced && _careerDrafts.isEmpty) {
        _careerDrafts = [_CareerEntryDraft.empty()];
      }
    });
  }

  List<Map<String, dynamic>> _buildCareerPayload() {
    if (!_isExperienced) return const [];
    return _careerDrafts
        .map((draft) => draft.toPayload())
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  List<_WorkHistoryPreview> _buildHistoryPreview() {
    return _careerDrafts
        .map((draft) => draft.toPreview(_formatYearMonth))
        .whereType<_WorkHistoryPreview>()
        .toList();
  }

  Future<void> _submit() async {
    final data = _formData;
    if (data == null) return;
    final careerEntries = _buildCareerPayload();
    if (_isExperienced && careerEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('경력사항을 한 건 이상 입력해주세요.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<WorkerRecruitmentRepository>();
      final isEdit = widget.resumeId != null;
      if (!isEdit) {
        await repo.createResume(
          educationLevel: _educationLevel,
          educationStatus: _educationStatus,
          careerType: _careerType,
          selfIntroduction: _selfIntroductionController.text,
          careerEntries: careerEntries,
        );
      } else {
        await repo.updateResume(
          resumeId: widget.resumeId!,
          educationLevel: _educationLevel,
          educationStatus: _educationStatus,
          careerType: _careerType,
          selfIntroduction: _selfIntroductionController.text,
          careerEntries: careerEntries,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? '이력서가 성공적으로 수정되었습니다.' : '이력서가 성공적으로 등록되었습니다.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  Future<void> _deleteResume() async {
    if (widget.resumeId == null || _formData == null || !_formData!.canDelete) {
      return;
    }
    final repo = context.read<WorkerRecruitmentRepository>();
    final confirmed = await showWorkerConfirmDialog(
      context,
      title: '알림',
      message: '이력서를 삭제하시겠습니까?',
      confirmLabel: _formData!.deleteButtonLabel ?? '삭제',
    );
    if (!confirmed) return;
    setState(() => _deleting = true);
    try {
      await repo.deleteResume(resumeId: widget.resumeId!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _formData;

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: workerSubPageAppBar(
        context,
        title: data?.headerTitle ?? '이력서 작성',
      ),
      body: Builder(
        builder: (context) {
          if (_loading && data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null && data == null) {
            return workerErrorView(
              message: accountDioMessage(_error!),
              onRetry: _load,
            );
          }
          if (data == null) {
            return workerErrorView(message: '이력서를 불러오지 못했습니다.', onRetry: _load);
          }

          final profile = data.profileSummary;
          final historyPreview = _buildHistoryPreview();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE1F0B8), Color(0xFF9FE9D4)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80.r,
                            height: 80.r,
                            decoration: const BoxDecoration(
                              color: AppColors.grey0,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.grey100,
                              size: 46.r,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _ProfileRow(label: '성명', value: profile?.fullName),
                          _ProfileRow(label: '성별', value: profile?.genderLabel),
                          _ProfileRow(label: '나이', value: profile?.ageLabel),
                          _ProfileRow(label: '주소', value: profile?.address),
                          _ProfileRow(label: '이메일', value: profile?.email),
                          _ProfileRow(
                            label: '휴대폰',
                            value: profile?.phoneNumber,
                          ),
                        ],
                      ),
                    ),
                    if (data.isEditMode) ...[
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48.h,
                              child: FilledButton(
                                onPressed: (_submitting || _deleting)
                                    ? null
                                    : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: AppColors.grey0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  data.editButtonLabel ?? '수정',
                                  style: AppTypography.bodyLargeB.copyWith(
                                    color: AppColors.grey0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: SizedBox(
                              height: 48.h,
                              child: FilledButton(
                                onPressed:
                                    (_submitting ||
                                        _deleting ||
                                        !data.canDelete)
                                    ? null
                                    : _deleteResume,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  disabledBackgroundColor:
                                      AppColors.textDisabled,
                                  foregroundColor: AppColors.grey0,
                                  disabledForegroundColor: AppColors.grey0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: _deleting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.grey0,
                                        ),
                                      )
                                    : Text(
                                        data.deleteButtonLabel ?? '삭제',
                                        style: AppTypography.bodyLargeB
                                            .copyWith(color: AppColors.grey0),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 20.h),
                    _Section(
                      title: '학력사항',
                      child: Row(
                        children: [
                          Expanded(
                            child: _SelectorField(
                              label: '학교',
                              value: _optionLabel(
                                data.educationLevelOptions,
                                _educationLevel,
                              ),
                              hint: '선택해주세요.',
                              onTap: () => _selectOption(
                                title: '학교',
                                options: data.educationLevelOptions,
                                currentValue: _educationLevel,
                                onSelected: (value) => _educationLevel = value,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SelectorField(
                              label: '상태',
                              value: _optionLabel(
                                data.educationStatusOptions,
                                _educationStatus,
                              ),
                              hint: '선택해주세요.',
                              onTap: () => _selectOption(
                                title: '상태',
                                options: data.educationStatusOptions,
                                currentValue: _educationStatus,
                                onSelected: (value) => _educationStatus = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: '근무사항',
                      child: Column(
                        children: [
                          _CareerTypeToggle(
                            options: data.careerTypeOptions,
                            selectedValue: _careerType,
                            onChanged: _setCareerType,
                          ),
                          if (_isExperienced) ...[
                            SizedBox(height: 16.h),
                            for (var i = 0; i < _careerDrafts.length; i++) ...[
                              _CareerEntryEditor(
                                draft: _careerDrafts[i],
                                index: i,
                                durationOptions: data.durationTypeOptions,
                                onChanged: () => setState(() {}),
                                onPickStarted: () async {
                                  final picked = await _pickYearMonth(
                                    _careerDrafts[i].startedYearMonth,
                                  );
                                  if (picked == null) return;
                                  setState(() {
                                    _careerDrafts[i].startedYearMonth = picked;
                                  });
                                },
                                onPickEnded: () async {
                                  final picked = await _pickYearMonth(
                                    _careerDrafts[i].endedYearMonth,
                                  );
                                  if (picked == null) return;
                                  setState(() {
                                    _careerDrafts[i].endedYearMonth = picked;
                                  });
                                },
                                onRemove: _careerDrafts.length > 1
                                    ? () => _removeCareerDraft(_careerDrafts[i])
                                    : null,
                                formatYearMonth: _formatYearMonth,
                              ),
                              if (i != _careerDrafts.length - 1)
                                SizedBox(height: 16.h),
                            ],
                            SizedBox(height: 20.h),
                            GestureDetector(
                              onTap: _addCareerDraft,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 16.r,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      data.addCareerButtonLabel ?? '경력사항 추가',
                                      style: AppTypography.bodyMediumB.copyWith(
                                        color: AppColors.primary,
                                        height: 16 / 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isExperienced)
                      _Section(
                        title: '근무 이력',
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.grey0,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: historyPreview.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.all(20.r),
                                  child: Text(
                                    '입력한 경력사항이 여기에 표시됩니다.',
                                    style: AppTypography.bodyMediumR.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < historyPreview.length;
                                      i++
                                    )
                                      _HistoryItem(
                                        item: historyPreview[i],
                                        showDivider:
                                            i != historyPreview.length - 1,
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    _Section(
                      title: '자기소개',
                      showBottomBorder: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.grey0Alt,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _selfIntroductionController,
                          minLines: 8,
                          maxLines: 8,
                          style: AppTypography.bodyMediumR.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '자기소개를 입력하세요.',
                            hintStyle: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                  color: AppColors.grey0,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: FilledButton(
                      onPressed: (_submitting || _deleting) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        disabledBackgroundColor: AppColors.textDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              data.submitButtonLabel ??
                                  (data.isEditMode ? '수정하기' : '이력서 작성'),
                              style: AppTypography.bodyLargeB.copyWith(
                                color: AppColors.grey0,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.showBottomBorder = true,
  });

  final String title;
  final Widget child;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 16.h, 0, 20.h),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMediumM.copyWith(
              color: AppColors.textSecondary,
              height: 16 / 14,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              workerDisplayValue(value),
              textAlign: TextAlign.right,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            height: 16 / 14,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.grey0Alt,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CareerTypeToggle extends StatelessWidget {
  const _CareerTypeToggle({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<WorkerResumeOption> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedOptions = options.isNotEmpty
        ? options
        : const [
            WorkerResumeOption(value: 'entry', label: '신입'),
            WorkerResumeOption(value: 'experienced', label: '경력'),
          ];
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          for (final option in resolvedOptions)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.value),
                child: Container(
                  height: 34.h,
                  decoration: BoxDecoration(
                    color: selectedValue == option.value
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Center(
                    child: Text(
                      option.label,
                      style: AppTypography.bodyMediumM.copyWith(
                        color: selectedValue == option.value
                            ? AppColors.grey0
                            : AppColors.textDisabled,
                        height: 16 / 14,
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

class _CareerEntryEditor extends StatelessWidget {
  const _CareerEntryEditor({
    required this.draft,
    required this.index,
    required this.durationOptions,
    required this.onChanged,
    required this.onPickStarted,
    required this.onPickEnded,
    required this.formatYearMonth,
    this.onRemove,
  });

  final _CareerEntryDraft draft;
  final int index;
  final List<WorkerResumeOption> durationOptions;
  final VoidCallback onChanged;
  final VoidCallback onPickStarted;
  final VoidCallback onPickEnded;
  final String Function(String?) formatYearMonth;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final options = durationOptions.isNotEmpty
        ? durationOptions
        : const [
            WorkerResumeOption(value: 'over_one_month', label: '1개월 이상 근무'),
            WorkerResumeOption(value: 'under_one_month', label: '1개월 미만 근무'),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '경력 ${index + 1}',
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (onRemove != null)
              TextButton(
                onPressed: onRemove,
                child: Text(
                  '삭제',
                  style: AppTypography.bodySmallB.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        _LabeledField(
          label: '회사명',
          child: _TextInputBox(
            controller: draft.companyController,
            hintText: '회사명을 입력해주세요.',
            onChanged: (_) => onChanged(),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          '근무기간',
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            height: 16 / 14,
          ),
        ),
        SizedBox(height: 8.h),
        for (final option in options) ...[
          _DurationTypeRow(
            label: option.label,
            selected: draft.durationType == option.value,
            startedLabel: formatYearMonth(draft.startedYearMonth),
            endedLabel: formatYearMonth(draft.endedYearMonth),
            onSelect: () {
              draft.durationType = option.value;
              onChanged();
            },
            onPickStarted: onPickStarted,
            onPickEnded: onPickEnded,
          ),
          if (option != options.last) SizedBox(height: 8.h),
        ],
        SizedBox(height: 16.h),
        _LabeledField(
          label: '담당업무',
          child: _TextInputBox(
            controller: draft.dutyController,
            hintText: '담당업무를 입력해주세요.',
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

class _DurationTypeRow extends StatelessWidget {
  const _DurationTypeRow({
    required this.label,
    required this.selected,
    required this.startedLabel,
    required this.endedLabel,
    required this.onSelect,
    required this.onPickStarted,
    required this.onPickEnded,
  });

  final String label;
  final bool selected;
  final String startedLabel;
  final String endedLabel;
  final VoidCallback onSelect;
  final VoidCallback onPickStarted;
  final VoidCallback onPickEnded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            height: 16 / 14,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            GestureDetector(
              onTap: onSelect,
              child: Container(
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.grey25,
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14.r,
                        color: AppColors.grey0,
                      )
                    : null,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _MonthSelector(
                value: startedLabel,
                hint: '입사연월',
                enabled: selected,
                onTap: onPickStarted,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _MonthSelector(
                value: endedLabel,
                hint: '퇴사연월',
                enabled: selected,
                onTap: onPickEnded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.value,
    required this.hint,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.grey0Alt,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: AppTypography.bodyMediumR.copyWith(
                  color: enabled
                      ? (hasValue
                            ? AppColors.textPrimary
                            : AppColors.textDisabled)
                      : AppColors.textDisabled,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? AppColors.textTertiary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            height: 16 / 14,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _TextInputBox extends StatelessWidget {
  const _TextInputBox({
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMediumR.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textDisabled,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.r),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.showDivider});

  final _WorkHistoryPreview item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderLight))
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.periodLabel,
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.companyName,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyLargeM.copyWith(
                    color: AppColors.textPrimary,
                    height: 20 / 16,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.duty,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmallR.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerEntryDraft {
  _CareerEntryDraft({
    required this.companyController,
    required this.dutyController,
    this.careerId,
    this.durationType,
    this.startedYearMonth,
    this.endedYearMonth,
  });

  final int? careerId;
  final TextEditingController companyController;
  final TextEditingController dutyController;
  String? durationType;
  String? startedYearMonth;
  String? endedYearMonth;

  factory _CareerEntryDraft.empty() {
    return _CareerEntryDraft(
      companyController: TextEditingController(),
      dutyController: TextEditingController(),
      durationType: 'over_one_month',
    );
  }

  factory _CareerEntryDraft.fromModel(WorkerResumeCareerEntry model) {
    return _CareerEntryDraft(
      careerId: model.careerId,
      companyController: TextEditingController(text: model.companyName),
      dutyController: TextEditingController(text: model.duty ?? ''),
      durationType: model.durationType,
      startedYearMonth: model.startedYearMonth,
      endedYearMonth: model.endedYearMonth,
    );
  }

  Map<String, dynamic>? toPayload() {
    final companyName = companyController.text.trim();
    final duty = dutyController.text.trim();
    if (companyName.isEmpty ||
        (durationType ?? '').isEmpty ||
        (startedYearMonth ?? '').isEmpty ||
        (endedYearMonth ?? '').isEmpty) {
      return null;
    }

    return {
      'company_name': companyName,
      'duration_type': durationType,
      'started_year_month': startedYearMonth,
      'ended_year_month': endedYearMonth,
      'duty': duty,
    };
  }

  _WorkHistoryPreview? toPreview(String Function(String?) formatYearMonth) {
    final companyName = companyController.text.trim();
    if (companyName.isEmpty) return null;
    final start = formatYearMonth(startedYearMonth);
    final end = formatYearMonth(endedYearMonth);
    final periodLabel = (start.isEmpty && end.isEmpty)
        ? '-'
        : '${start.isEmpty ? '-' : start} ~ ${end.isEmpty ? '-' : end}';
    return _WorkHistoryPreview(
      periodLabel: periodLabel,
      companyName: companyName,
      duty: dutyController.text.trim().isEmpty
          ? '-'
          : dutyController.text.trim(),
    );
  }

  void dispose() {
    companyController.dispose();
    dutyController.dispose();
  }
}

class _WorkHistoryPreview {
  const _WorkHistoryPreview({
    required this.periodLabel,
    required this.companyName,
    required this.duty,
  });

  final String periodLabel;
  final String companyName;
  final String duty;
}
