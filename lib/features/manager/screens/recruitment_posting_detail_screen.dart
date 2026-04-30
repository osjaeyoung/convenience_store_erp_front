import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import 'recruitment_application_detail_screen.dart';
import 'recruitment_posting_form_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const String _postingDeleteIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <g clip-path="url(#clip0_2691_10195)">
    <path d="M20.031 9.00204H3.97232C3.58777 9.00204 3.27734 8.69161 3.27734 8.30706V4.80436C3.27734 4.4198 3.58777 4.10938 3.97232 4.10938H20.031C20.4156 4.10938 20.726 4.4198 20.726 4.80436V8.30706C20.726 8.69161 20.4156 9.00204 20.031 9.00204ZM4.6673 7.61208H19.336V5.49934H4.6673V7.61208Z" fill="#A3A4AF"/>
    <path d="M14.1409 5.49925H9.85514C9.47058 5.49925 9.16016 5.18883 9.16016 4.80427V4.70697C9.16016 3.19655 10.388 1.96875 11.8984 1.96875H12.0976C13.608 1.96875 14.8358 3.19655 14.8358 4.70697V4.80427C14.8358 5.18883 14.5254 5.49925 14.1409 5.49925ZM10.6891 4.10929H13.3069C13.0891 3.6645 12.6258 3.35871 12.0976 3.35871H11.8984C11.3702 3.35871 10.9069 3.6645 10.6891 4.10929Z" fill="#A3A4AF"/>
    <path d="M17.3876 22.0325H6.61075C6.25399 22.0325 5.95746 21.7638 5.9204 21.4071L4.5814 8.37849C4.56287 8.18389 4.6231 7.9893 4.75746 7.84104C4.88719 7.69277 5.07716 7.60938 5.27175 7.60938H18.7266C18.9212 7.60938 19.1111 7.69277 19.2409 7.84104C19.3752 7.9893 19.4355 8.18389 19.4169 8.37849L18.0779 21.4071C18.0409 21.7592 17.7443 22.0325 17.3876 22.0325ZM7.23623 20.6426H16.7575L17.9528 9.00397H6.04086L7.23623 20.6426Z" fill="#A3A4AF"/>
    <path d="M10.0387 18.0425C9.65417 18.0425 9.34375 17.732 9.34375 17.3475V11.695C9.34375 11.3104 9.65417 11 10.0387 11C10.4233 11 10.7337 11.3104 10.7337 11.695V17.3475C10.7337 17.732 10.4233 18.0425 10.0387 18.0425Z" fill="#A3A4AF"/>
    <path d="M13.9606 18.0425C13.576 18.0425 13.2656 17.732 13.2656 17.3475V11.695C13.2656 11.3104 13.576 11 13.9606 11C14.3452 11 14.6556 11.3104 14.6556 11.695V17.3475C14.6556 17.732 14.3452 18.0425 13.9606 18.0425Z" fill="#A3A4AF"/>
  </g>
  <defs>
    <clipPath id="clip0_2691_10195">
      <rect width="24" height="24" fill="white"/>
    </clipPath>
  </defs>
</svg>
''';

const String _postingEditIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <g clip-path="url(#clip0_2534_16088)">
    <path d="M3.23367 21.5368C3.03444 21.5368 2.83521 21.4581 2.69158 21.3098C2.49699 21.1152 2.41822 20.828 2.49235 20.5592L3.94718 15.3145C3.97961 15.1986 4.03984 15.0921 4.12324 15.0087L16.0537 3.08743C16.5727 2.56851 17.263 2.28125 17.9951 2.28125C18.7271 2.28125 19.4174 2.56851 19.9364 3.08743L20.914 4.06503C21.9842 5.1353 21.9842 6.87739 20.914 7.94766L8.98811 19.8689C8.90471 19.9523 8.79814 20.0172 8.68231 20.045L3.43753 21.4998C3.36803 21.5183 3.30316 21.5276 3.23367 21.5276V21.5368ZM5.23984 15.8658L4.12787 19.8735L8.1356 18.7616L19.9317 6.96542C20.4599 6.43723 20.4599 5.57546 19.9317 5.04727L18.9541 4.06967C18.4445 3.56001 17.5503 3.55538 17.036 4.06967L5.23984 15.8658Z" fill="#70D2B3"/>
    <path d="M16.0024 4.11481L15.0195 5.09766L18.8985 8.97664L19.8814 7.99379L16.0024 4.11481Z" fill="#70D2B3"/>
    <path d="M5.15863 14.9625L4.17578 15.9453L8.05477 19.8243L9.03762 18.8414L5.15863 14.9625Z" fill="#70D2B3"/>
  </g>
  <defs>
    <clipPath id="clip0_2534_16088">
      <rect width="24" height="24" fill="white"/>
    </clipPath>
  </defs>
</svg>
''';

class RecruitmentPostingDetailScreen extends StatefulWidget {
  const RecruitmentPostingDetailScreen({
    super.key,
    required this.branchId,
    required this.postingId,
    this.previewMode = false,
    this.allowPublish = false,
    this.mineMode = false,
    this.initialTabIndex = 0,
    this.initialDetail,
    this.previewRequest,
  });

  final int branchId;
  final int postingId;
  final bool previewMode;
  final bool allowPublish;
  final bool mineMode;
  final int initialTabIndex;
  final RecruitmentPostingDetail? initialDetail;
  final RecruitmentPostingRequest? previewRequest;

  @override
  State<RecruitmentPostingDetailScreen> createState() =>
      _RecruitmentPostingDetailScreenState();
}

class _RecruitmentPostingDetailScreenState
    extends State<RecruitmentPostingDetailScreen> {
  static final NumberFormat _numberFormat = NumberFormat('#,###');

  RecruitmentPostingDetail? _detail;
  RecruitmentApplicationPage? _applicationPage;
  bool _loading = true;
  bool _loadingApplications = false;
  bool _publishing = false;
  bool _deleting = false;
  String? _error;
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 1);
    final initialDetail = widget.initialDetail;
    if (initialDetail != null) {
      _detail = initialDetail;
      _loading = false;
      _error = null;
      if (widget.mineMode && _selectedTabIndex == 1) {
        _loadApplications();
      }
      return;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await context
          .read<ManagerHomeRepository>()
          .getRecruitmentPostingDetail(
            branchId: widget.branchId,
            postingId: widget.postingId,
          );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _error = null;
      });
      if (widget.mineMode && _selectedTabIndex == 1) {
        await _loadApplications();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
        _error = userFriendlyErrorMessage(e);
      });
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _loadingApplications = true);
    try {
      final page = await context
          .read<ManagerHomeRepository>()
          .getRecruitmentApplications(
            branchId: widget.branchId,
            postingId: widget.postingId,
          );
      if (!mounted) return;
      setState(() {
        _applicationPage = page;
        _loadingApplications = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applicationPage = null;
        _loadingApplications = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지원현황을 불러오지 못했습니다: ${userFriendlyErrorMessage(e)}'),
        ),
      );
    }
  }

  Future<void> _onBottomTap() async {
    if (widget.allowPublish) {
      setState(() => _publishing = true);
      try {
        final repo = context.read<ManagerHomeRepository>();
        var postingId = widget.postingId;
        final shouldCreateDraftFirst =
            widget.previewRequest != null &&
            (postingId <= 0 || (_detail?.status == 'preview'));
        if (shouldCreateDraftFirst) {
          final created = await repo.createRecruitmentPosting(
            branchId: widget.branchId,
            request: widget.previewRequest!,
          );
          postingId = created.postingId;
        }
        if (postingId <= 0) {
          throw StateError('게시할 채용 공고가 없습니다.');
        }
        await repo.publishRecruitmentPosting(
          branchId: widget.branchId,
          postingId: postingId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('채용 공고가 게시되었습니다.')));
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시 실패: ${userFriendlyErrorMessage(e)}')),
        );
      } finally {
        if (mounted) {
          setState(() => _publishing = false);
        }
      }
      return;
    }

    // manager or owner applying logic (not officially supported but user wants button to work or at least show toast)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('점장/경영주는 지원할 수 없습니다.')));
  }

  Future<void> _deletePosting() async {
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '이 채용 공고를 삭제할까요?',
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<ManagerHomeRepository>().deleteRecruitmentPosting(
        branchId: widget.branchId,
        postingId: widget.postingId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('채용 공고가 삭제되었습니다.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${userFriendlyErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _editPosting() async {
    final detail = _detail;
    if (detail == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentPostingFormScreen(
          branchId: widget.branchId,
          branchName: detail.companyName ?? '',
          postingId: widget.postingId,
          initialDetail: detail,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
      await _load();
    }
  }

  Future<void> _deletePostingImage() async {
    final detail = _detail;
    if (detail == null || (_imageUrlOf(detail) == null)) return;
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '등록된 사진을 삭제할까요?',
    );
    if (ok != true || !mounted) return;

    try {
      final updated = await context
          .read<ManagerHomeRepository>()
          .patchRecruitmentPosting(
            branchId: widget.branchId,
            postingId: widget.postingId,
            request: _requestFromDetail(detail, profileImageUrl: null),
          );
      if (!mounted) return;
      setState(() => _detail = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진이 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 삭제 실패: ${userFriendlyErrorMessage(e)}')),
      );
    }
  }

  RecruitmentPostingRequest _requestFromDetail(
    RecruitmentPostingDetail detail, {
    required String? profileImageUrl,
  }) {
    return RecruitmentPostingRequest(
      profileImageUrl: profileImageUrl,
      companyName: detail.companyName ?? '',
      title: detail.title ?? '',
      regionSummary: detail.regionSummary ?? detail.regionPath ?? '',
      regionPath: detail.regionPath,
      address:
          detail.address ?? detail.regionSummary ?? detail.regionPath ?? '',
      payType: detail.payType ?? '시급',
      payAmount: detail.payAmount,
      workPeriod: detail.workPeriod ?? '',
      workDays: detail.workDays ?? '',
      workDaysDetail: detail.workDaysDetail,
      workTime: detail.workTime ?? '',
      workTimeDetail: detail.workTimeDetail,
      jobCategory: detail.jobCategory ?? '편의점',
      employmentType: detail.employmentType ?? '',
      recruitmentDeadline: detail.recruitmentDeadline ?? '',
      isAlwaysHiring: (detail.recruitmentDeadline ?? '').contains('상시'),
      recruitmentHeadcount: detail.recruitmentHeadcount ?? '',
      recruitmentHeadcountDetail: detail.recruitmentHeadcountDetail,
      education: detail.education ?? '',
      educationDetail: detail.educationDetail,
      managerName: detail.managerName ?? '',
      contactPhone: detail.contactPhone ?? '',
    );
  }

  Future<void> _openApplication(RecruitmentApplicationSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentApplicationDetailScreen(
          branchId: widget.branchId,
          applicationId: item.applicationId,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
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
          widget.mineMode ? '내 채용 게시글' : '채용 게시판 상세',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
        actions: [
          if (widget.mineMode)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _loading || _deleting ? null : _editPosting,
                    tooltip: '수정',
                    icon: SvgPicture.string(
                      _postingEditIconSvg,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: _loading || _deleting ? null : _deletePosting,
                    tooltip: '삭제',
                    icon: SvgPicture.string(
                      _postingDeleteIconSvg,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.previewMode)
            Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: Center(
                child: Container(
                  height: 24,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '미리보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _PostingErrorView(message: _error!, onRetry: _load)
          : _detail == null
          ? const Center(child: Text('공고를 불러올 수 없습니다.'))
          : Column(
              children: [
                if (widget.mineMode)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey0,
                      border: Border(
                        bottom: BorderSide(color: AppColors.grey50),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DetailTopTab(
                            label: '내 채용 게시글',
                            selected: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _DetailTopTab(
                            label: '지원현황',
                            selected: _selectedTabIndex == 1,
                            onTap: () {
                              setState(() => _selectedTabIndex = 1);
                              if (_applicationPage == null &&
                                  !_loadingApplications) {
                                _loadApplications();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _selectedTabIndex == 1 && widget.mineMode
                      ? _ApplicationsTabBody(
                          applicationPage: _applicationPage,
                          loading: _loadingApplications,
                          onTapApplication: _openApplication,
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PostingSummaryHeader(detail: _detail!),
                              if (_imageUrlOf(_detail!) != null)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    20.w,
                                    16.h,
                                    20.w,
                                    0,
                                  ),
                                  child: _PostingImagePreview(
                                    imageUrl: _imageUrlOf(_detail!)!,
                                    showDelete: widget.mineMode,
                                    onDelete: _deletePostingImage,
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20.w,
                                  20.h,
                                  20.w,
                                  0.h,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _PostingSection(
                                      title: '근무조건',
                                      child: _PostingInfoCard(
                                        rows: [
                                          _PostingInfoRowData(
                                            label: '급여',
                                            primaryValue:
                                                _detail!.payType ?? '-',
                                            primaryColor: AppColors.primary,
                                            value: _formattedAmount(
                                              _detail!.payAmount,
                                            ),
                                          ),
                                          _PostingInfoRowData(
                                            label: '근무기간',
                                            value: _detail!.workPeriod ?? '-',
                                          ),
                                          _PostingInfoRowData(
                                            label: '근무요일',
                                            value: _detail!.workDays ?? '-',
                                            detail: _detail!.workDaysDetail,
                                          ),
                                          _PostingInfoRowData(
                                            label: '근무시간',
                                            value: _detail!.workTime ?? '-',
                                            detail: _detail!.workTimeDetail,
                                          ),
                                          _PostingInfoRowData(
                                            label: '업직종',
                                            value: _detail!.jobCategory ?? '-',
                                          ),
                                          _PostingInfoRowData(
                                            label: '고용형태',
                                            value:
                                                _detail!.employmentType ?? '-',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    _PostingSection(
                                      title: '모집조건',
                                      child: _PostingInfoCard(
                                        rows: [
                                          _PostingInfoRowData(
                                            label: '모집마감',
                                            value:
                                                _detail!.recruitmentDeadline ??
                                                '-',
                                          ),
                                          _PostingInfoRowData(
                                            label: '모집인원',
                                            value:
                                                _detail!.recruitmentHeadcount ??
                                                '-',
                                            detail: _detail!
                                                .recruitmentHeadcountDetail,
                                          ),
                                          _PostingInfoRowData(
                                            label: '학력',
                                            value: _detail!.education ?? '-',
                                            detail: _detail!.educationDetail,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    _PostingSection(
                                      title: '근무지역',
                                      child: _SingleLineInfoCard(
                                        text:
                                            _detail!.address ??
                                            _detail!.regionSummary ??
                                            '-',
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    _PostingSection(
                                      title: '채용 담당자 연락처',
                                      child: _ContactInfoCard(detail: _detail!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                if (!widget.mineMode)
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      color: AppColors.grey0,
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _publishing ? null : _onBottomTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.grey0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.grey0,
                                  ),
                                )
                              : Text(
                                  widget.allowPublish ? '게시' : '지원하기',
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

  String _formattedAmount(int amount) => _numberFormat.format(amount);
}

String? _imageUrlOf(RecruitmentPostingDetail detail) {
  final url = detail.profileImageUrl?.trim();
  return url == null || url.isEmpty ? null : url;
}

class _DetailTopTab extends StatelessWidget {
  const _DetailTopTab({
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
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.textPrimary : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyLargeB.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }
}

class _ApplicationsTabBody extends StatelessWidget {
  const _ApplicationsTabBody({
    required this.applicationPage,
    required this.loading,
    required this.onTapApplication,
  });

  final RecruitmentApplicationPage? applicationPage;
  final bool loading;
  final ValueChanged<RecruitmentApplicationSummary> onTapApplication;

  @override
  Widget build(BuildContext context) {
    final page = applicationPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page != null)
          _PostingSummaryHeader(
            detail: RecruitmentPostingDetail(
              postingId: page.postingId,
              badgeLabel: page.badgeLabel,
              companyName: page.companyName,
              title: page.title,
            ),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : page == null || page.items.isEmpty
              ? Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      '지원자가 없습니다.',
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                  children: [
                    Text(
                      '지원자',
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    for (var i = 0; i < page.items.length; i++) ...[
                      _ApplicationCard(
                        item: page.items[i],
                        onTap: () => onTapApplication(page.items[i]),
                      ),
                      if (i != page.items.length - 1) SizedBox(height: 12.h),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.item, required this.onTap});

  final RecruitmentApplicationSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              decoration: BoxDecoration(
                color: AppColors.grey25,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text(
                item.appliedDateLabel ?? '-',
                style: AppTypography.bodySmallR.copyWith(
                  fontSize: 12.sp,
                  height: 18 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              child: Row(
                children: [
                  const _ApplicantAvatar(size: 48),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.employeeName,
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
                              item.desiredLocation ?? '-',
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
                                _ApplicantRatingStars(
                                  filledCount: _filledApplicationStarCount(
                                    item.averageRating,
                                    maxStars: 3,
                                  ),
                                  maxStars: 3,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '(${item.reviewCount})',
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PostingSummaryHeader extends StatelessWidget {
  const _PostingSummaryHeader({required this.detail});

  final RecruitmentPostingDetail detail;

  String get _badgeText {
    final badgeLabel = detail.badgeLabel?.trim();
    if (badgeLabel != null && badgeLabel.isNotEmpty) return badgeLabel;

    final deadline = detail.recruitmentDeadline?.trim();
    if (deadline != null && deadline.isNotEmpty) {
      return deadline.contains('상시') ? '상시모집' : deadline;
    }

    return '상시모집';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        border: Border(bottom: BorderSide(color: AppColors.grey50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: AppColors.grey50),
            ),
            child: Text(
              _badgeText,
              style: AppTypography.bodySmallM.copyWith(
                fontSize: 12.sp,
                height: 16 / 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            detail.companyName ?? '-',
            style: AppTypography.bodySmallM.copyWith(
              fontSize: 12.sp,
              height: 16 / 12,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            detail.title ?? '-',
            style: AppTypography.bodyLargeB.copyWith(
              fontSize: 16.sp,
              height: 24 / 16,
              color: const Color(0xFF404040),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostingImagePreview extends StatelessWidget {
  const _PostingImagePreview({
    required this.imageUrl,
    this.showDelete = false,
    this.onDelete,
  });

  final String imageUrl;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showDelete && onDelete != null) ...[
          _PostingImageDeleteBadge(onTap: onDelete!),
          SizedBox(height: 4.h),
        ],
        Container(
          width: double.infinity,
          height: 146,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFD9D9D9),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '사진을 불러오는 중입니다.',
                        style: AppTypography.bodySmallM.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        ),
      ],
    );
  }
}

class _PostingImageDeleteBadge extends StatelessWidget {
  const _PostingImageDeleteBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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

class _PostingSection extends StatelessWidget {
  const _PostingSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _PostingInfoCard extends StatelessWidget {
  const _PostingInfoCard({required this.rows});

  final List<_PostingInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: _PostingInfoRow(row: row),
            ),
        ],
      ),
    );
  }
}

class _PostingInfoRowData {
  const _PostingInfoRowData({
    required this.label,
    this.primaryValue,
    this.primaryColor,
    required this.value,
    this.detail,
  });

  final String label;
  final String? primaryValue;
  final Color? primaryColor;
  final String value;
  final String? detail;
}

class _PostingInfoRow extends StatelessWidget {
  const _PostingInfoRow({required this.row});

  final _PostingInfoRowData row;

  @override
  Widget build(BuildContext context) {
    final detail = row.detail?.trim();
    return Row(
      crossAxisAlignment: detail != null && detail.isNotEmpty
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            row.label,
            style: AppTypography.bodyMediumM.copyWith(
              fontSize: 14.sp,
              height: 16 / 14,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  if (row.primaryValue != null &&
                      row.primaryValue!.trim().isNotEmpty)
                    Text(
                      row.primaryValue!,
                      style: AppTypography.bodyMediumM.copyWith(
                        fontSize: 14.sp,
                        height: 16 / 14,
                        color: row.primaryColor ?? AppColors.textPrimary,
                      ),
                    ),
                  Text(
                    row.value,
                    style: AppTypography.bodyMediumR.copyWith(
                      fontSize: 14.sp,
                      height: 19 / 14,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              if (detail != null && detail.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  detail,
                  style: AppTypography.bodySmallR.copyWith(
                    fontSize: 12.sp,
                    height: 18 / 12,
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SingleLineInfoCard extends StatelessWidget {
  const _SingleLineInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Text(
        text,
        style: AppTypography.bodyMediumR.copyWith(
          fontSize: 14.sp,
          height: 19 / 14,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.detail});

  final RecruitmentPostingDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostingInfoRow(
            row: _PostingInfoRowData(
              label: '담당자',
              value: detail.managerName ?? '-',
            ),
          ),
          SizedBox(height: 8.h),
          _PostingInfoRow(
            row: _PostingInfoRowData(
              label: '전화',
              value: detail.contactPhone ?? '-',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            detail.legalWarningMessage ?? '-',
            style: AppTypography.bodySmallR.copyWith(
              fontSize: 12.sp,
              height: 18 / 12,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostingErrorView extends StatelessWidget {
  const _PostingErrorView({required this.message, required this.onRetry});

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

class _ApplicantRatingStars extends StatelessWidget {
  const _ApplicantRatingStars({
    required this.filledCount,
    required this.maxStars,
  });

  final int filledCount;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final filled = index < filledCount;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: AppColors.primary,
        );
      }),
    );
  }
}

int _filledApplicationStarCount(double rating, {required int maxStars}) {
  if (rating <= 0) return 0;
  return rating.round().clamp(1, maxStars);
}
