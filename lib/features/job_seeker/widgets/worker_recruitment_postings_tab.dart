import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/region/region_api_query.dart';
import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../account/account_dio_message.dart';
import '../screens/worker_recruitment_detail_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'worker_common.dart';
import 'worker_recruitment_card.dart';
import '../../../widgets/hierarchical_region_picker_sheet.dart';
import '../../../widgets/recruitment_region_picker_sheet.dart';

class WorkerRecruitmentPostingsTab extends StatefulWidget {
  const WorkerRecruitmentPostingsTab({
    super.key,
    required this.refreshToken,
    required this.onApplicationCreated,
  });

  final int refreshToken;
  final VoidCallback onApplicationCreated;

  @override
  State<WorkerRecruitmentPostingsTab> createState() =>
      _WorkerRecruitmentPostingsTabState();
}

class _WorkerRecruitmentPostingsTabState
    extends State<WorkerRecruitmentPostingsTab> {
  final TextEditingController _searchController = TextEditingController();

  List<WorkerRecruitmentPostingSummary> _items =
      const <WorkerRecruitmentPostingSummary>[];
  List<String> _selectedRegions = const [];
  List<String> _regionQuickOptions = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkerRecruitmentPostingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
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
      final page = await context
          .read<WorkerRecruitmentRepository>()
          .getPostings(
            keyword: _searchController.text,
            regions: _selectedRegions.isEmpty ? null : _selectedRegions,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _regionQuickOptions =
            dedupeNormalizedRegionOptions(page.regionOptions);
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

  Future<void> _selectRegion() async {
    final next = await showHierarchicalRegionPicker(
      context,
      initialSelections: _selectedRegions,
      maxSelections: 5,
    );
    if (!mounted || next == null) return;
    final normalized = prepareRegionQueryList(next);
    if (listEquals(normalized, _selectedRegions)) return;
    setState(() => _selectedRegions = normalized);
    await _load();
  }

  Future<void> _onQuickRegionTap(String? sidoLabel) async {
    final next = sidoLabel == null || sidoLabel.isEmpty
        ? const <String>[]
        : prepareRegionQueryList([sidoLabel]);
    if (listEquals(next, _selectedRegions)) return;
    setState(() => _selectedRegions = next);
    await _load();
  }

  Future<void> _openDetail(WorkerRecruitmentPostingSummary item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkerRecruitmentDetailScreen(
          postingId: item.postingId,
          onApplicationCreated: widget.onApplicationCreated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey0Alt,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '검색',
                    hintStyle: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(height: 12.h),
              if (_regionQuickOptions.isNotEmpty) ...[
                SizedBox(
                  height: 36.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1 + _regionQuickOptions.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final sel = _selectedRegions.isEmpty;
                        return _WorkerRegionQuickChip(
                          label: '전체',
                          selected: sel,
                          onTap: () => _onQuickRegionTap(null),
                        );
                      }
                      final label = _regionQuickOptions[index - 1];
                      final sel = _selectedRegions.length == 1 &&
                          regionQueryKeysEqual(_selectedRegions.single, label);
                      return _WorkerRegionQuickChip(
                        label: label,
                        selected: sel,
                        onTap: () => _onQuickRegionTap(label),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              RecruitmentFilterPill(
                label: regionFilterPillLabel(_selectedRegions),
                active: _selectedRegions.any((e) => e.trim().isNotEmpty),
                onTap: _selectRegion,
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_loading && _items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_error != null && _items.isEmpty) {
                return workerErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                );
              }
              if (_items.isEmpty) {
                return workerEmptyView(
                  message: '등록된 채용정보가 없습니다.',
                  description: '검색어나 지역을 바꿔 다시 확인해 주세요.',
                );
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return WorkerRecruitmentCard(
                      topSpacing: index == 0 ? 0 : 18.h,
                      badgeLabel: item.badgeLabel,
                      companyName: item.companyName,
                      title: item.title,
                      regionSummary: item.regionSummary,
                      payType: item.payType,
                      payAmount: item.payAmount,
                      onTap: () => _openDetail(item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// `region_options` 빠른 필터 — 명세 `docs/api_spec_recruitment.md` 2-1).
class _WorkerRegionQuickChip extends StatelessWidget {
  const _WorkerRegionQuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.grey0,
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.bodySmallR.copyWith(
              fontSize: 12.sp,
              height: 18 / 12,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
