import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../account/account_dio_message.dart';
import '../screens/worker_recruitment_detail_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'worker_common.dart';
import 'worker_recruitment_card.dart';
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
  String? _selectedRegion;
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
            region: _selectedRegion,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
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
    final next = await showRecruitmentRegionPickerSheet(
      context,
      selectedRegion: _selectedRegion,
    );
    if (!mounted || next == null) return;
    final region = next.trim().isEmpty ? null : next.trim();
    if (region == _selectedRegion) return;
    setState(() => _selectedRegion = region);
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
              RecruitmentFilterPill(
                label: _selectedRegion ?? '전체',
                active: _selectedRegion != null &&
                    _selectedRegion!.trim().isNotEmpty,
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
