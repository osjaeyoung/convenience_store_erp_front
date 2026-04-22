import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'recruitment_posting_detail_screen.dart';
import 'recruitment_posting_form_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/recruitment_region_picker_sheet.dart';

class RecruitmentPostingListTab extends StatefulWidget {
  const RecruitmentPostingListTab({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.mine,
    required this.refreshTick,
  });

  final int branchId;
  final String branchName;
  final bool mine;
  final int refreshTick;

  @override
  State<RecruitmentPostingListTab> createState() =>
      _RecruitmentPostingListTabState();
}

class _RecruitmentPostingListTabState extends State<RecruitmentPostingListTab> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String? _region;
  List<RecruitmentPostingSummary> _visibleItems = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecruitmentPostingListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId ||
        oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.mine != widget.mine) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ManagerHomeRepository>();
      final page = widget.mine
          ? await repo.getMyRecruitmentPostings(branchId: widget.branchId)
          : await repo.getRecruitmentPostings(
              branchId: widget.branchId, // 점포와 무관하게 전역 공고를 불러오지만 API 시그니처 유지
              keyword: _searchController.text.trim(),
              region: _region,
            );

      if (!mounted) return;
      setState(() {
        _visibleItems = _applyLocalFilter(page.items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _visibleItems = const [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<RecruitmentPostingSummary> _applyLocalFilter(
    List<RecruitmentPostingSummary> source,
  ) {
    if (!widget.mine) return source;
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return source;
    return source.where((item) {
      final title = item.title?.toLowerCase() ?? '';
      final companyName = item.companyName?.toLowerCase() ?? '';
      return title.contains(keyword) || companyName.contains(keyword);
    }).toList();
  }

  Future<void> _showRegionSheet() async {
    final next = await showRecruitmentRegionPickerSheet(
      context,
      selectedRegion: _region,
    );
    if (!mounted || next == null) return;
    setState(() {
      _region = next.trim().isEmpty ? null : next.trim();
    });
    _load();
  }

  Future<void> _openPosting(RecruitmentPostingSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentPostingDetailScreen(
          branchId: widget.branchId,
          postingId: item.postingId,
          previewMode: false,
          allowPublish: false,
          mineMode: false, // 항상 일반 모드로 열기 (지원하기 버튼이 보이도록)
        ),
      ),
    );
    if (changed == true && mounted) {
      _load();
    }
  }

  Future<void> _openApplicants(RecruitmentPostingSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentPostingDetailScreen(
          branchId: widget.branchId,
          postingId: item.postingId,
          mineMode: true,
          initialTabIndex: 1,
        ),
      ),
    );
    if (changed == true && mounted) {
      _load();
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentPostingFormScreen(
          branchId: widget.branchId,
          branchName: widget.branchName,
        ),
      ),
    );
    if (changed == true && mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (!widget.mine)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0.h),
                child: AuthInputField(
                  controller: _searchController,
                  hintText: '검색',
                  fillColor: AppColors.grey0Alt,
                  prefixIconWidget: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: SvgPicture.asset(
                      'assets/icons/svg/icon/search_mint_20.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  suffix: IconButton(
                    onPressed: _load,
                    icon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.grey150,
                    ),
                  ),
                ),
              ),
            if (!widget.mine)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0.h),
                  child: RecruitmentFilterPill(
                    label: _region?.trim().isNotEmpty == true ? _region! : '전체',
                    active: _region?.trim().isNotEmpty == true,
                    onTap: _showRegionSheet,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _PostingListErrorView(message: _error!, onRetry: _load)
                  : _PostingListView(
                      items: _visibleItems,
                      topPadding: widget.mine ? 0 : 10,
                      mineMode: widget.mine,
                      onTapItem: _openPosting,
                      onTapApplicants: _openApplicants,
                      onRefresh: _load,
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openCreate,
              borderRadius: BorderRadius.circular(100.r),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.grey0,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PostingListView extends StatelessWidget {
  const _PostingListView({
    required this.items,
    required this.topPadding,
    required this.mineMode,
    required this.onTapItem,
    required this.onTapApplicants,
    required this.onRefresh,
  });

  final List<RecruitmentPostingSummary> items;
  final double topPadding;
  final bool mineMode;
  final ValueChanged<RecruitmentPostingSummary> onTapItem;
  final ValueChanged<RecruitmentPostingSummary> onTapApplicants;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
            Center(
              child: Text(
                '등록된 채용 공고가 없습니다.',
                style: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 96),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PostingListCard(
            item: item,
            mineMode: mineMode,
            onTap: () => onTapItem(item),
            onTapApplicants: () => onTapApplicants(item),
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 0.h),
        itemCount: items.length,
      ),
    );
  }
}

class _PostingListCard extends StatelessWidget {
  const _PostingListCard({
    required this.item,
    required this.mineMode,
    required this.onTap,
    required this.onTapApplicants,
  });

  static final NumberFormat _numberFormat = NumberFormat('#,###');

  final RecruitmentPostingSummary item;
  final bool mineMode;
  final VoidCallback onTap;
  final VoidCallback onTapApplicants;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.grey50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 16.h),
              height: 24,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.grey0,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: AppColors.grey50),
              ),
              child: Text(
                item.badgeLabel ?? '상시모집',
                style: AppTypography.bodySmallM.copyWith(
                  fontSize: 12.sp,
                  height: 16 / 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.companyName ?? '-',
              style: AppTypography.bodySmallM.copyWith(
                fontSize: 12.sp,
                height: 16 / 12,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              item.title ?? '-',
              style: AppTypography.bodyLargeB.copyWith(
                fontSize: 16.sp,
                height: 24 / 16,
                color: const Color(0xFF404040),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostingListMetaRow(
                    icon: Icons.place_outlined,
                    text: item.regionSummary ?? '-',
                    textColor: AppColors.textPrimary,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: AppColors.grey150,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        item.payType ?? '-',
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14.sp,
                          height: 16 / 14,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _numberFormat.format(item.payAmount),
                        style: AppTypography.bodyMediumR.copyWith(
                          fontSize: 14.sp,
                          height: 19 / 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (mineMode) ...[
              SizedBox(height: 20.h),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTapApplicants,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.grey0,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: item.applicantCount > 0
                            ? AppColors.primary
                            : AppColors.grey100,
                      ),
                    ),
                    child: Text(
                      item.applicantsButtonLabel ??
                          '지원자 ${item.applicantCount}명',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLargeB.copyWith(
                        fontSize: 16.sp,
                        height: 24 / 16,
                        color: item.applicantCount > 0
                            ? AppColors.primary
                            : AppColors.grey150,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostingListMetaRow extends StatelessWidget {
  const _PostingListMetaRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey150),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMediumR.copyWith(
              fontSize: 14.sp,
              height: 19 / 14,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PostingListErrorView extends StatelessWidget {
  const _PostingListErrorView({required this.message, required this.onRetry});

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
