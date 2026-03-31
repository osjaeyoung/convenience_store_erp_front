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
              branchId: widget.branchId,
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

  Future<void> _showRegionDialog() async {
    final controller = TextEditingController(text: _region ?? '');
    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('지역 설정'),
          content: AuthInputField(
            controller: controller,
            hintText: '입력해주세요.',
            fillColor: AppColors.grey0Alt,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('초기화'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );

    if (!mounted || applied != true) return;
    setState(() {
      final value = controller.text.trim();
      _region = value.isEmpty ? null : value;
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
          mineMode: widget.mine,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AuthInputField(
                  controller: _searchController,
                  hintText: '검색',
                  fillColor: AppColors.grey0Alt,
                  prefixIconWidget: Padding(
                    padding: const EdgeInsets.all(14),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _RegionChip(
                    label: _region?.trim().isNotEmpty == true ? _region! : '지역',
                    onTap: _showRegionDialog,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _PostingListErrorView(
                          message: _error!,
                          onRetry: _load,
                        )
                      : _PostingListView(
                          items: _visibleItems,
                          topPadding: widget.mine ? 0 : 10,
                          mineMode: widget.mine,
                          onTapItem: _openPosting,
                          onTapApplicants: _openApplicants,
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
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
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

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodySmallR.copyWith(
                fontSize: 12,
                height: 18 / 12,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: AppColors.grey150,
            ),
          ],
        ),
      ),
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
  });

  final List<RecruitmentPostingSummary> items;
  final double topPadding;
  final bool mineMode;
  final ValueChanged<RecruitmentPostingSummary> onTapItem;
  final ValueChanged<RecruitmentPostingSummary> onTapApplicants;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          '등록된 채용 공고가 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
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
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemCount: items.length,
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
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.grey50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey0,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.grey50),
              ),
              child: Text(
                item.badgeLabel ?? '상시모집',
                style: AppTypography.bodySmallM.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.companyName ?? '-',
              style: AppTypography.bodySmallM.copyWith(
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title ?? '-',
              style: AppTypography.bodyLargeB.copyWith(
                fontSize: 16,
                height: 24 / 16,
                color: const Color(0xFF404040),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostingListMetaRow(
                    icon: Icons.place_outlined,
                    text: item.regionSummary ?? '-',
                    textColor: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: AppColors.grey150,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.payType ?? '-',
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14,
                          height: 16 / 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _numberFormat.format(item.payAmount),
                        style: AppTypography.bodyMediumR.copyWith(
                          fontSize: 14,
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
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTapApplicants,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.grey0,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.applicantCount > 0
                            ? AppColors.primary
                            : AppColors.grey100,
                      ),
                    ),
                    child: Text(
                      item.applicantsButtonLabel ?? '지원자 ${item.applicantCount}명',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLargeB.copyWith(
                        fontSize: 16,
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
        Icon(
          icon,
          size: 16,
          color: AppColors.grey150,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMediumR.copyWith(
              fontSize: 14,
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
  const _PostingListErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
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
