import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/formatters/thousands_separator_input_formatter.dart';
import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/hierarchical_region_picker_sheet.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'recruitment_posting_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecruitmentPostingFormScreen extends StatefulWidget {
  const RecruitmentPostingFormScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    this.postingId,
    this.initialDetail,
  });

  final int branchId;
  final String branchName;
  final int? postingId;
  final RecruitmentPostingDetail? initialDetail;

  @override
  State<RecruitmentPostingFormScreen> createState() =>
      _RecruitmentPostingFormScreenState();
}

class _RecruitmentPostingFormScreenState
    extends State<RecruitmentPostingFormScreen> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _payAmountCtrl = TextEditingController();
  final _workPeriodCtrl = TextEditingController();
  final _workDaysCtrl = TextEditingController();
  final _workDaysDetailCtrl = TextEditingController();
  final _workTimeCtrl = TextEditingController();
  final _workTimeDetailCtrl = TextEditingController();
  final _employmentTypeCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _headcountCtrl = TextEditingController();
  final _headcountDetailCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _educationDetailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  PlatformFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _profileImageUrl;
  String? _regionPath;
  bool _saving = false;
  String _payType = '시급';
  String _jobCategory = '편의점';

  bool get _isEditing => widget.postingId != null;

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    _companyCtrl.text = detail?.companyName ?? widget.branchName;
    if (detail != null) {
      _titleCtrl.text = detail.title ?? '';
      _payAmountCtrl.text = detail.payAmount == 0
          ? ''
          : detail.payAmount.toString();
      _workPeriodCtrl.text = detail.workPeriod ?? '';
      _workDaysCtrl.text = detail.workDays ?? '';
      _workDaysDetailCtrl.text = detail.workDaysDetail ?? '';
      _workTimeCtrl.text = detail.workTime ?? '';
      _workTimeDetailCtrl.text = detail.workTimeDetail ?? '';
      _employmentTypeCtrl.text = detail.employmentType ?? '';
      _deadlineCtrl.text = detail.recruitmentDeadline ?? '';
      _headcountCtrl.text = detail.recruitmentHeadcount ?? '';
      _headcountDetailCtrl.text = detail.recruitmentHeadcountDetail ?? '';
      _educationCtrl.text = detail.education ?? '';
      _educationDetailCtrl.text = detail.educationDetail ?? '';
      _regionPath = detail.regionPath ?? detail.regionSummary;
      _addressCtrl.text = detail.address ?? '';
      _managerNameCtrl.text = detail.managerName ?? '';
      _contactPhoneCtrl.text = detail.contactPhone ?? '';
      _payType = detail.payType ?? _payType;
      _jobCategory = detail.jobCategory ?? _jobCategory;
      _profileImageUrl = detail.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _payAmountCtrl.dispose();
    _workPeriodCtrl.dispose();
    _workDaysCtrl.dispose();
    _workDaysDetailCtrl.dispose();
    _workTimeCtrl.dispose();
    _workTimeDetailCtrl.dispose();
    _employmentTypeCtrl.dispose();
    _deadlineCtrl.dispose();
    _headcountCtrl.dispose();
    _headcountDetailCtrl.dispose();
    _educationCtrl.dispose();
    _educationDetailCtrl.dispose();
    _addressCtrl.dispose();
    _managerNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = PlatformFile(
          name: image.name.trim().isEmpty
              ? 'recruitment-image.jpg'
              : image.name,
          size: bytes.length,
          bytes: bytes,
          path: image.path.isEmpty ? null : image.path,
        );
        _pickedImageBytes = bytes;
        _profileImageUrl = null;
      });
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 실행 환경에서 사진 선택 기능을 사용할 수 없습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사진 선택 실패: $e')));
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _pickedImageBytes = null;
      _profileImageUrl = null;
    });
  }

  Future<void> _pickWorkRegion() async {
    final next = await showHierarchicalRegionPicker(
      context,
      initialSelections: _regionPath == null || _regionPath!.trim().isEmpty
          ? const []
          : [_regionPath!],
      maxSelections: 1,
    );
    if (!mounted || next == null) return;
    setState(() {
      _regionPath = next.isEmpty ? null : next.first;
      _addressCtrl.clear();
    });
  }

  Future<void> _goNext() async {
    final baseRequest = _buildRequestOrNull();
    if (baseRequest == null) return;

    setState(() => _saving = true);
    try {
      final repo = context.read<ManagerHomeRepository>();
      final request = await _attachProfileImageUrl(repo, baseRequest);
      if (_isEditing) {
        await repo.patchRecruitmentPosting(
          branchId: widget.branchId,
          postingId: widget.postingId!,
          request: request,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('채용 공고가 수정되었습니다.')));
        Navigator.of(context).pop(true);
        return;
      }

      final preview = await repo.previewRecruitmentPosting(
        branchId: widget.branchId,
        request: request,
      );
      if (!mounted) return;
      final published = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => RecruitmentPostingDetailScreen(
            branchId: widget.branchId,
            postingId: preview.postingId,
            previewMode: true,
            allowPublish: true,
            initialDetail: preview,
            previewRequest: request,
          ),
        ),
      );
      if (published == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? '수정 실패: $e' : '미리보기 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  RecruitmentPostingRequest? _buildRequestOrNull() {
    String textOf(TextEditingController controller) => controller.text.trim();

    final title = textOf(_titleCtrl);
    final companyName = textOf(_companyCtrl);
    final payAmount = int.tryParse(textOf(_payAmountCtrl).replaceAll(',', ''));
    final workPeriod = textOf(_workPeriodCtrl);
    final workDays = textOf(_workDaysCtrl);
    final workTime = textOf(_workTimeCtrl);
    final employmentType = textOf(_employmentTypeCtrl);
    final deadline = textOf(_deadlineCtrl);
    final headcount = textOf(_headcountCtrl);
    final education = textOf(_educationCtrl);
    final regionPath = _regionPath?.trim() ?? '';
    final address = textOf(_addressCtrl);
    final managerName = textOf(_managerNameCtrl);
    final contactPhone = textOf(_contactPhoneCtrl);

    final missing = <String>[
      if (title.isEmpty) '공고 제목',
      if (companyName.isEmpty) '사업장',
      if (payAmount == null) '급여',
      if (workPeriod.isEmpty) '근무기간',
      if (workDays.isEmpty) '근무요일',
      if (workTime.isEmpty) '근무시간',
      if (employmentType.isEmpty) '고용형태',
      if (deadline.isEmpty) '모집마감',
      if (headcount.isEmpty) '모집인원',
      if (education.isEmpty) '학력',
      if (regionPath.isEmpty) '근무지역',
      if (managerName.isEmpty) '담당자',
      if (contactPhone.isEmpty) '연락처',
    ];

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${missing.first}을(를) 입력해주세요.')));
      return null;
    }

    return RecruitmentPostingRequest(
      profileImageUrl: _profileImageUrl,
      companyName: companyName,
      title: title,
      regionSummary: regionPath,
      regionPath: regionPath,
      address: address.isEmpty ? regionPath : address,
      payType: _payType,
      payAmount: payAmount!,
      workPeriod: workPeriod,
      workDays: workDays,
      workDaysDetail: _optionalText(_workDaysDetailCtrl),
      workTime: workTime,
      workTimeDetail: _optionalText(_workTimeDetailCtrl),
      jobCategory: _jobCategory,
      employmentType: employmentType,
      recruitmentDeadline: deadline,
      isAlwaysHiring: deadline.contains('상시'),
      recruitmentHeadcount: headcount,
      recruitmentHeadcountDetail: _optionalText(_headcountDetailCtrl),
      education: education,
      educationDetail: _optionalText(_educationDetailCtrl),
      managerName: managerName,
      contactPhone: contactPhone,
    );
  }

  Future<RecruitmentPostingRequest> _attachProfileImageUrl(
    ManagerHomeRepository repo,
    RecruitmentPostingRequest request,
  ) async {
    var profileImageUrl = _profileImageUrl?.trim();
    final pickedImage = _pickedImage;
    if (pickedImage != null &&
        (profileImageUrl == null || profileImageUrl.isEmpty)) {
      final uploaded = await repo.uploadRecruitmentFile(file: pickedImage);
      profileImageUrl = uploaded.fileUrl.trim().isEmpty
          ? null
          : uploaded.fileUrl.trim();
      if (mounted) {
        setState(() => _profileImageUrl = profileImageUrl);
      } else {
        _profileImageUrl = profileImageUrl;
      }
    }
    return request.copyWith(profileImageUrl: profileImageUrl);
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          _isEditing ? '채용 공고 수정' : '채용 공고 올리기',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionBlock(
                      contentSpacing: 20,
                      child: _SpacedColumn(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputGroup(
                            label: '업체 프로필 사진 첨부',
                            spacing: 12,
                            trailing:
                                (_pickedImageBytes != null &&
                                        _pickedImageBytes!.isNotEmpty) ||
                                    (_profileImageUrl != null &&
                                        _profileImageUrl!.trim().isNotEmpty)
                                ? _ImageDeleteIconButton(onTap: _removeImage)
                                : null,
                            child: _ImageAttachmentBox(
                              bytes: _pickedImageBytes,
                              imageUrl: _profileImageUrl,
                              onTap: _pickImage,
                            ),
                          ),
                          _InputGroup(
                            label: '공고 제목',
                            child: _textField(_titleCtrl, hint: '입력해주세요.'),
                          ),
                          _InputGroup(
                            label: '사업장',
                            child: _readonlyField(
                              controller: _companyCtrl,
                              hint: '선택해주세요.',
                              showArrow: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SectionBlock(
                      title: '근무조건',
                      child: _SpacedColumn(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputGroup(
                            label: '급여',
                            spacing: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PayTypeButton(
                                        label: '시급',
                                        selected: _payType == '시급',
                                        onTap: () =>
                                            setState(() => _payType = '시급'),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: _PayTypeButton(
                                        label: '월급',
                                        selected: _payType == '월급',
                                        onTap: () =>
                                            setState(() => _payType = '월급'),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                _textField(
                                  _payAmountCtrl,
                                  hint: '입력해주세요.',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _InputGroup(
                            label: '근무기간',
                            child: _textField(_workPeriodCtrl, hint: '입력해주세요.'),
                          ),
                          _InputGroup(
                            label: '근무요일',
                            child: Column(
                              children: [
                                _textField(
                                  _workDaysCtrl,
                                  hint: '입력해주세요. ex) 요일협의',
                                ),
                                SizedBox(height: 12.h),
                                _textField(
                                  _workDaysDetailCtrl,
                                  hint: '상세 설명을 입력해주세요.',
                                  minLines: 4,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          _InputGroup(
                            label: '근무시간',
                            child: Column(
                              children: [
                                _textField(
                                  _workTimeCtrl,
                                  hint: '입력해주세요. ex) 시간협의',
                                ),
                                SizedBox(height: 12.h),
                                _textField(
                                  _workTimeDetailCtrl,
                                  hint: '상세 설명을 입력해주세요.',
                                  minLines: 4,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          _InputGroup(
                            label: '고용형태',
                            child: _textField(
                              _employmentTypeCtrl,
                              hint: '입력해주세요.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SectionBlock(
                      title: '모집조건',
                      child: _SpacedColumn(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputGroup(
                            label: '모집마감',
                            child: _textField(_deadlineCtrl, hint: '입력해주세요.'),
                          ),
                          _InputGroup(
                            label: '모집인원',
                            child: Column(
                              children: [
                                _textField(_headcountCtrl, hint: '입력해주세요.'),
                                SizedBox(height: 12.h),
                                _textField(
                                  _headcountDetailCtrl,
                                  hint: '상세 설명을 입력해주세요.',
                                  minLines: 4,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          _InputGroup(
                            label: '학력',
                            child: Column(
                              children: [
                                _textField(_educationCtrl, hint: '입력해주세요.'),
                                SizedBox(height: 12.h),
                                _textField(
                                  _educationDetailCtrl,
                                  hint: '상세 설명을 입력해주세요.',
                                  minLines: 4,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SectionBlock(
                      title: '근무지역',
                      child: _InputGroup(
                        label: '근무지역',
                        child: _regionSelectField(),
                      ),
                    ),
                    _SectionBlock(
                      title: '채용담당자 연락처',
                      showDivider: false,
                      contentSpacing: 28,
                      child: _SpacedColumn(
                        spacing: 28,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputGroup(
                            label: '담당자',
                            child: _textField(
                              _managerNameCtrl,
                              hint: '입력해주세요.',
                            ),
                          ),
                          _InputGroup(
                            label: '연락처',
                            child: _textField(
                              _contactPhoneCtrl,
                              hint: '입력해주세요.',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9-]'),
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
            ),
            Container(
              color: AppColors.grey0,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _saving ? null : _goNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.grey0,
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
                            _isEditing ? '저장' : '다음',
                            style: AppTypography.bodyLargeB.copyWith(
                              color: AppColors.grey0,
                              fontSize: 16.sp,
                            ),
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

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? minLines,
    int? maxLines = 1,
  }) {
    return AuthInputField(
      controller: controller,
      hintText: hint,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
      fillColor: AppColors.grey0Alt,
    );
  }

  Widget _readonlyField({
    required TextEditingController controller,
    required String hint,
    bool showArrow = false,
  }) {
    return Stack(
      children: [
        AuthInputField(
          controller: controller,
          hintText: hint,
          readOnly: true,
          fillColor: AppColors.grey0Alt,
          suffix: showArrow
              ? const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.grey150,
                )
              : null,
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('현재 선택된 매장으로 등록됩니다.')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _regionSelectField() {
    final selected = _regionPath?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickWorkRegion,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 52.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.grey0Alt,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected == null || selected.isEmpty
                      ? '지역을 선택해주세요.'
                      : regionPathChevronLabel(selected),
                  style: AppTypography.bodyMediumR.copyWith(
                    color: selected == null || selected.isEmpty
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
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
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyLargeM.copyWith(
        fontSize: 18.sp,
        height: 24 / 18,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.child,
    this.title,
    this.showDivider = true,
    this.contentSpacing = 20,
  });

  final String? title;
  final Widget child;
  final bool showDivider;
  final double contentSpacing;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: hasTitle ? 20 : 0, bottom: 32.h),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.grey50, width: 1),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            _SectionLabel(title!),
            SizedBox(height: contentSpacing),
          ],
          child,
        ],
      ),
    );
  }
}

class _SpacedColumn extends StatelessWidget {
  const _SpacedColumn({
    required this.children,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: spacing),
          children[index],
        ],
      ],
    );
  }
}

class _InputGroup extends StatelessWidget {
  const _InputGroup({
    required this.label,
    required this.child,
    this.spacing = 8,
    this.trailing,
  });

  final String label;
  final Widget child;
  final double spacing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMediumM.copyWith(
                  fontSize: 14.sp,
                  height: 16 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

class _PayTypeButton extends StatelessWidget {
  const _PayTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.grey0,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey50,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            fontSize: 14.sp,
            height: 16 / 14,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ImageAttachmentBox extends StatelessWidget {
  const _ImageAttachmentBox({
    required this.bytes,
    required this.imageUrl,
    required this.onTap,
  });

  final Uint8List? bytes;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = bytes != null && bytes!.isNotEmpty;
    final hasRemoteImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasImage = hasLocalImage || hasRemoteImage;
    if (!hasImage) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary),
          ),
          child: Icon(Icons.add_rounded, size: 40.r, color: AppColors.primary),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        height: 146,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary, width: 1),
          image: hasImage
              ? DecorationImage(
                  image: hasLocalImage
                      ? MemoryImage(bytes!)
                      : NetworkImage(imageUrl!.trim()) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
      ),
    );
  }
}

class _ImageDeleteIconButton extends StatelessWidget {
  const _ImageDeleteIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: 50,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFF383C).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2.r),
        ),
        child: Text(
          '삭제',
          style: AppTypography.bodySmallB.copyWith(
            color: AppColors.grey0,
            fontSize: 12.sp,
            height: 20 / 12,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
