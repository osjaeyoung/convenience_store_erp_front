import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_routes.dart';
import '../bloc/home_bloc.dart';
import '../bloc/labor_cost_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import '../labor/labor_cost_formatters.dart';
import '../widgets/home_common_app_bar.dart';
import '../widgets/labor_cost/labor_cost_overview_widgets.dart';
import 'labor_cost_monthly_list_screen.dart';
import 'labor_cost_saving_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 인건비 탭 — Figma: 홈 앱바 + 서브탭(예상/월별/절감)
class LaborCostScreen extends StatefulWidget {
  const LaborCostScreen({
    super.key,
    this.initialTabIndex = 0,
    this.navigationRequestId = 0,
  });

  final int initialTabIndex;
  final int navigationRequestId;

  @override
  State<LaborCostScreen> createState() => _LaborCostScreenState();
}

class _LaborCostScreenState extends State<LaborCostScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _rangeType = 'this_month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final branchId = context.read<SelectedBranchCubit>().state;
      if (branchId != null) {
        _dispatchExpected(branchId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LaborCostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationRequestId != widget.navigationRequestId ||
        oldWidget.initialTabIndex != widget.initialTabIndex) {
      final nextIndex = widget.initialTabIndex.clamp(0, 2);
      if (_tabController.index != nextIndex) {
        _tabController.animateTo(nextIndex);
      }
    }
  }

  void _dispatchExpected(int branchId) {
    context.read<LaborCostBloc>().add(
      LaborCostExpectedRequested(branchId: branchId, rangeType: _rangeType),
    );
  }

  bool _hasAlarm(HomeState homeState, int? branchId) {
    if (branchId == null) return false;
    for (final b in homeState.managerBranches) {
      if (b.id == branchId && b.openAlertCount > 0) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final branchId = context.select<SelectedBranchCubit, int?>((c) => c.state);
    final homeState = context.watch<HomeBloc>().state;
    final hasAlarm = _hasAlarm(homeState, branchId);

    return BlocListener<SelectedBranchCubit, int?>(
      listener: (context, id) {
        if (id != null) {
          context.read<LaborCostBloc>().add(
            LaborCostExpectedRequested(branchId: id, rangeType: _rangeType),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey0Alt,
        appBar: HomeCommonAppBar(
          alarmActive: hasAlarm,
          onAlarmTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('알림 기능은 곧 연결됩니다.')));
          },
          onMenuTap: () => openAccountSettingsMenu(context),
        ),
        body: branchId == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    '지점을 선택해주세요.\n홈 탭에서 지점을 먼저 선택해주세요.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LaborCostSubTabsBar(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ExpectedLaborTabView(
                          branchId: branchId,
                          rangeType: _rangeType,
                          onRangeChanged: (v) {
                            setState(() => _rangeType = v);
                            _dispatchExpected(branchId);
                          },
                          onOpenSavingTab: () => _tabController.animateTo(2),
                        ),
                        LaborCostMonthlyListScreen(
                          branchId: branchId,
                          embedded: true,
                        ),
                        LaborCostSavingDetailScreen(
                          branchId: branchId,
                          embedded: true,
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

class _ExpectedLaborTabView extends StatelessWidget {
  const _ExpectedLaborTabView({
    required this.branchId,
    required this.rangeType,
    required this.onRangeChanged,
    required this.onOpenSavingTab,
  });

  final int branchId;
  final String rangeType;
  final ValueChanged<String> onRangeChanged;
  final VoidCallback onOpenSavingTab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LaborCostBloc, LaborCostBlocState>(
      builder: (context, state) {
        if (state.status == LaborCostBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == LaborCostBlocStatus.failure) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? '오류가 발생했습니다.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  FilledButton(
                    onPressed: () => context.read<LaborCostBloc>().add(
                      LaborCostExpectedRequested(
                        branchId: branchId,
                        rangeType: rangeType,
                      ),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }
        final expected = state.expected;
        if (expected == null) {
          return const Center(child: Text('데이터 없음'));
        }

        final ratioText =
            '${expected.changeRatePercent.abs().toStringAsFixed(1)}%';
        final wentUp = expected.changeRatePercent >= 0;
        final totalLine =
            '총 ${LaborCostFormatters.won(expected.currentTotalCost).replaceAll('원', ' 원')}';

        return ColoredBox(
          color: AppColors.grey0Alt,
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<LaborCostBloc>().add(
                LaborCostExpectedRequested(
                  branchId: branchId,
                  rangeType: rangeType,
                ),
              );
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 32.h),
              children: [
                const LaborCostSectionTitleRow(),
                LaborCostFigmaSummaryCard(
                  totalWonText: totalLine,
                  ratioPercentText: ratioText,
                  ratioWentUp: wentUp,
                ),
                SizedBox(height: 8.h),
                LaborCostPeriodDropdown(
                  rangeType: rangeType,
                  onChanged: onRangeChanged,
                ),
                SizedBox(height: 20.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '총 근로자 인원수',
                      style: AppTypography.bodyLargeM.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '(명)',
                      style: AppTypography.bodySmallR.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                LaborCostHeadcountCompareCard(
                  leftLabel: rangeType == 'six_months' ? '6개월 전' : '전월',
                  rightLabel: '금월',
                  leftCount: expected.headcountPrevious,
                  rightCount: expected.headcountCurrent,
                ),
                SizedBox(height: 28.h),
                LaborCostDualBarChartSection(
                  rangeType: rangeType,
                  components: expected.componentComparisons,
                  monthlyTrend: expected.monthlyTrend,
                ),
                SizedBox(height: 28.h),
                LaborCostSavingPointsFigma(
                  points: expected.savingPoints,
                  onDetailTap: onOpenSavingTab,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
