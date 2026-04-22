import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/store_expense/store_expense_dashboard.dart';
import '../../../data/models/store_expense/store_expense_month.dart';
import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_routes.dart';
import '../bloc/home_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import '../bloc/store_expense_bloc.dart';
import '../widgets/home_common_app_bar.dart';
import 'store_expense_add_item_screen.dart';
import 'store_expense_add_month_screen.dart';
import 'store_expense_edit_item_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 매장·비용 화면 (월간 표시 / 월별 점내 비용 내역)
class StoreCostScreen extends StatefulWidget {
  const StoreCostScreen({super.key});

  @override
  State<StoreCostScreen> createState() => _StoreCostScreenState();
}

class _StoreCostScreenState extends State<StoreCostScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late int _dashboardYear;
  late int _dashboardMonth;
  late int _monthsYear;

  bool _monthsLoading = false;
  String? _monthsError;
  List<StoreExpenseMonthSummary> _months = const [];
  final Map<int, StoreExpenseMonthDetail> _monthDetails =
      <int, StoreExpenseMonthDetail>{};

  static final NumberFormat _won = NumberFormat('#,###', 'ko_KR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _dashboardYear = now.year;
    _dashboardMonth = now.month;
    _monthsYear = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId = context.read<SelectedBranchCubit>().state;
      if (branchId != null) {
        _loadDashboard(branchId);
        _loadMonths(branchId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _hasAlarm(HomeState state, int? branchId) {
    if (branchId == null) return false;
    for (final b in state.managerBranches) {
      if (b.id == branchId && b.openAlertCount > 0) return true;
    }
    return false;
  }

  void _loadDashboard(int branchId) {
    context.read<StoreExpenseBloc>().add(
      StoreExpenseDashboardRequested(
        branchId: branchId,
        year: _dashboardYear,
        month: _dashboardMonth,
      ),
    );
  }

  Future<void> _loadMonths(int branchId) async {
    setState(() {
      _monthsLoading = true;
      _monthsError = null;
    });
    try {
      final repo = context.read<StoreExpenseRepository>();
      final months = await repo.getMonths(
        branchId: branchId,
        year: _monthsYear,
      );
      final details = await Future.wait(
        months.map((m) async {
          final d = await repo.getMonthDetail(
            branchId: branchId,
            expenseMonthId: m.expenseMonthId,
          );
          return MapEntry<int, StoreExpenseMonthDetail>(m.expenseMonthId, d);
        }),
      );
      if (!mounted) return;
      setState(() {
        _months = months;
        _monthDetails
          ..clear()
          ..addEntries(details);
        _monthsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monthsError = e.toString();
        _monthsLoading = false;
      });
    }
  }

  Future<void> _openAddMonth(int branchId) async {
    final selectedYear = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => StoreExpenseAddMonthScreen(
          branchId: branchId,
          initialYear: _monthsYear,
        ),
      ),
    );
    if (selectedYear == null || !mounted) return;
    setState(() {
      _monthsYear = selectedYear;
    });
    await _loadMonths(branchId);
    _loadDashboard(branchId);
  }

  Future<void> _openAddItem(
    int branchId,
    StoreExpenseMonthSummary month,
  ) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StoreExpenseAddItemScreen(
          branchId: branchId,
          expenseMonthId: month.expenseMonthId,
          periodLabel: month.periodLabel,
          year: month.year,
          month: month.month,
        ),
      ),
    );
    if (ok == true && mounted) {
      await _loadMonths(branchId);
      _loadDashboard(branchId);
      // 추가 후 월별 점내 비용 내역 탭으로 이동 (index 1)
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    }
  }

  Future<void> _editMonthOrItem(
    int branchId,
    StoreExpenseMonthSummary month,
  ) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.h),
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  '수정할 대상을 선택해주세요',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              InkWell(
                onTap: () => Navigator.pop(ctx, 'month'),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '해당 월 변경',
                        style: AppTypography.bodyMediumR.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(ctx, 'items'),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '항목 정보 수정',
                        style: AppTypography.bodyMediumR.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );

    if (selection == 'month') {
      await _editMonth(branchId, month);
    } else if (selection == 'items') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정할 항목을 아래 목록에서 직접 터치해주세요.')),
        );
      }
    }
  }

  Future<void> _openEditItem(
    int branchId,
    StoreExpenseMonthSummary month,
    StoreExpenseItem item,
  ) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StoreExpenseEditItemScreen(
          branchId: branchId,
          periodLabel: month.periodLabel,
          item: item,
        ),
      ),
    );
    if (ok == true && mounted) {
      await _loadMonths(branchId);
      _loadDashboard(branchId);
      // 수정 후 월별 점내 비용 내역 탭으로 이동 (index 1)
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    }
  }

  Future<void> _editMonth(int branchId, StoreExpenseMonthSummary month) async {
    var year = month.year;
    var monthNum = month.month;
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '월 변경',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        height: 24 / 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now().year;
                        final years = List<int>.generate(7, (i) => now - 3 + i);
                        final y = await showModalBottomSheet<int>(
                          context: context,
                          backgroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                          ),
                          builder: (sheetCtx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 16.h),
                                Container(
                                  width: 40.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Flexible(
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      for (final yy in years)
                                        ListTile(
                                          title: Text('$yy년', textAlign: TextAlign.center),
                                          onTap: () => Navigator.pop(sheetCtx, yy),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (y != null) setDialogState(() => year = y);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey0Alt,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.grey50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${year}년',
                              style: AppTypography.bodyMediumR.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.grey150,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    InkWell(
                      onTap: () async {
                        final m = await showModalBottomSheet<int>(
                          context: context,
                          backgroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                          ),
                          builder: (sheetCtx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 16.h),
                                Container(
                                  width: 40.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Flexible(
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      for (var mm = 1; mm <= 12; mm++)
                                        ListTile(
                                          title: Text('$mm월', textAlign: TextAlign.center),
                                          onTap: () => Navigator.pop(sheetCtx, mm),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (m != null) setDialogState(() => monthNum = m);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey0Alt,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.grey50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${monthNum}월',
                              style: AppTypography.bodyMediumR.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.grey150,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.fromHeight(48.h),
                              backgroundColor: AppColors.grey0,
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: AppTypography.bodyMediumM.copyWith(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(48.h),
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.grey0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              '저장',
                              style: AppTypography.bodyMediumB.copyWith(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (changed != true || !mounted) return;
    if (year == month.year && monthNum == month.month) return;

    try {
      final repo = context.read<StoreExpenseRepository>();
      await repo.patchMonth(
        branchId: branchId,
        expenseMonthId: month.expenseMonthId,
        year: year,
        month: monthNum,
      );
      if (!mounted) return;
      if (_monthsYear != year) {
        setState(() => _monthsYear = year);
      }
      await _loadMonths(branchId);
      if (!mounted) return;
      _loadDashboard(branchId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('월 정보가 변경되었습니다.')));
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      if (code == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 연·월에 이미 다른 월 묶음이 있습니다.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('월 변경에 실패했습니다: ${e.message ?? e}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('월 변경에 실패했습니다: $e')));
    }
  }

  Future<void> _deleteMonth(int branchId, int expenseMonthId) async {
    final sure =
        await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '이 월 데이터를 삭제할까요?',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      height: 24 / 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                            backgroundColor: AppColors.grey0,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            '취소',
                            style: AppTypography.bodyMediumM.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.grey0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            '삭제',
                            style: AppTypography.bodyMediumB.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!sure) return;
    if (!mounted) return;
    try {
      final repo = context.read<StoreExpenseRepository>();
      await repo.deleteMonth(
        branchId: branchId,
        expenseMonthId: expenseMonthId,
      );
      if (!mounted) return;
      await _loadMonths(branchId);
      _loadDashboard(branchId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = context.select<SelectedBranchCubit, int?>((c) => c.state);
    final homeState = context.watch<HomeBloc>().state;
    final hasAlarm = _hasAlarm(homeState, branchId);

    return BlocListener<SelectedBranchCubit, int?>(
      listener: (_, id) {
        if (id != null) {
          _loadDashboard(id);
          _loadMonths(id);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey0,
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
                child: Text(
                  '지점을 선택해주세요.\n홈 탭에서 지점을 먼저 선택해주세요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  _StoreExpenseTopTabs(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _DashboardTab(
                          year: _dashboardYear,
                          month: _dashboardMonth,
                          onYearChanged: (v) {
                            setState(() => _dashboardYear = v);
                            _loadDashboard(branchId);
                          },
                          onMonthChanged: (v) {
                            setState(() => _dashboardMonth = v);
                            _loadDashboard(branchId);
                          },
                        ),
                        _MonthlyExpenseTab(
                          monthsLoading: _monthsLoading,
                          monthsError: _monthsError,
                          months: _months,
                          monthDetails: _monthDetails,
                          onRefresh: () => _loadMonths(branchId),
                          onAddMonth: () => _openAddMonth(branchId),
                          onAddItem: (month) => _openAddItem(branchId, month),
                          onEditMonth: (m) => _editMonthOrItem(branchId, m),
                          onDeleteMonth: (monthId) =>
                              _deleteMonth(branchId, monthId),
                          onEditItem: (item, monthId) {
                            final month = _months.firstWhere((m) => m.expenseMonthId == monthId);
                            _openEditItem(branchId, month, item);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String won(int v) => '${_won.format(v)}원';
}

class _StoreExpenseTopTabs extends StatelessWidget {
  const _StoreExpenseTopTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey0,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
        dividerColor: AppColors.grey25,
        dividerHeight: 1,
        indicatorColor: AppColors.textPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 1,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.grey150,
        labelStyle: AppTypography.bodyLargeB,
        unselectedLabelStyle: AppTypography.bodyLargeB,
        tabs: const [
          Tab(text: '월간 표시'),
          Tab(text: '월별 점내 비용 내역'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.year,
    required this.month,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  final int year;
  final int month;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreExpenseBloc, StoreExpenseBlocState>(
      builder: (context, state) {
        if (state.status == StoreExpenseBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == StoreExpenseBlocStatus.failure) {
          return _ErrorRetryView(message: state.errorMessage ?? '오류가 발생했습니다.');
        }
        final d = state.dashboard;
        if (d == null) {
          return const Center(child: Text('데이터 없음'));
        }

        final ratio = d.changeRatePercent.toStringAsFixed(1);
        final wentUp = d.changeRatePercent >= 100;
        final categoryCards = d.categoryCards.take(4).toList();

        return RefreshIndicator(
          onRefresh: () async {
            final branchId = context.read<SelectedBranchCubit>().state;
            if (branchId == null) return;
            context.read<StoreExpenseBloc>().add(
              StoreExpenseDashboardRequested(
                branchId: branchId,
                year: year,
                month: month,
              ),
            );
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            children: [
              Row(
                children: [
                  _YearMonthDrop(
                    text: '$year',
                    width: 88,
                    onTap: () => _pickYear(context),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '년',
                    style: AppTypography.bodyMediumR.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  _YearMonthDrop(
                    text: '$month',
                    width: 66,
                    onTap: () => _pickMonth(context),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '월',
                    style: AppTypography.bodyMediumR.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  const _DashboardMoneyIcon(),
                  SizedBox(width: 2.w),
                  Text(
                    '${d.month}월 ${d.baseDay}일 기준 예상 점내 비용',
                    style: AppTypography.bodyLargeM.copyWith(
                      fontSize: 16.sp,
                      height: 20 / 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.35, 0.2),
                    end: Alignment(1, 1),
                    colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(29, 29, 31, 0.12),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 ${_StoreCostScreenState.won(d.currentMonthToDateTotal).replaceAll('원', ' 원')}',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        height: 32 / 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14.sp,
                          height: 16 / 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: '전월 대비 총 '),
                          TextSpan(text: '$ratio%'),
                          TextSpan(text: ' ${wentUp ? '올랐어요' : '내렸어요'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.54,
                ),
                itemBuilder: (context, i) {
                  final c = categoryCards[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey0Alt,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.categoryLabel,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmallM.copyWith(
                            fontSize: 12.sp,
                            height: 16 / 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _compactAmountLabel(c.monthAmount),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLargeB.copyWith(
                            fontSize: 16.sp,
                            height: 20 / 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          c.summaryLabel ?? '${c.transactionCount}회',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmallR.copyWith(
                            fontSize: 12.sp,
                            height: 16 / 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
              _ExpenseCalendar(dashboard: d),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final cur = DateTime.now().year;
    final years = List<int>.generate(7, (i) => cur - 3 + i);
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final y in years)
                      ListTile(
                        title: Text('$y년', textAlign: TextAlign.center),
                        onTap: () => Navigator.pop(ctx, y),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) onYearChanged(selected);
  }

  Future<void> _pickMonth(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      ListTile(
                        title: Text('$m월', textAlign: TextAlign.center),
                        onTap: () => Navigator.pop(ctx, m),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) onMonthChanged(selected);
  }
}

class _YearMonthDrop extends StatelessWidget {
  const _YearMonthDrop({
    required this.text,
    required this.width,
    required this.onTap,
  });

  final String text;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: width,
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMediumR.copyWith(
                  fontSize: 14.sp,
                  height: 19 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyExpenseTab extends StatelessWidget {
  const _MonthlyExpenseTab({
    required this.monthsLoading,
    required this.monthsError,
    required this.months,
    required this.monthDetails,
    required this.onRefresh,
    required this.onAddMonth,
    required this.onAddItem,
    required this.onEditMonth,
    required this.onDeleteMonth,
    required this.onEditItem,
  });

  final bool monthsLoading;
  final String? monthsError;
  final List<StoreExpenseMonthSummary> months;
  final Map<int, StoreExpenseMonthDetail> monthDetails;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddMonth;
  final ValueChanged<StoreExpenseMonthSummary> onAddItem;
  final ValueChanged<StoreExpenseMonthSummary> onEditMonth;
  final ValueChanged<int> onDeleteMonth;
  final void Function(StoreExpenseItem item, int monthId) onEditItem;

  @override
  Widget build(BuildContext context) {
    if (monthsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (monthsError != null) {
      return _ErrorRetryView(message: monthsError!);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        children: [
          InkWell(
            onTap: onAddMonth,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                  SizedBox(height: 8.h),
                  Text(
                    '월별 점내 비용 추가',
                    style: AppTypography.bodyMediumB.copyWith(
                      fontSize: 14.sp,
                      height: 16 / 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          for (final month in months) ...[
            _MonthExpenseCard(
              month: month,
              detail: monthDetails[month.expenseMonthId],
              onAddItem: () => onAddItem(month),
              onEdit: () => onEditMonth(month),
              onDelete: () => onDeleteMonth(month.expenseMonthId),
              onEditItem: (item) => onEditItem(item, month.expenseMonthId),
            ),
            SizedBox(height: 20.h),
          ],
          if (months.isEmpty)
            Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '생성된 월별 점내 비용이 없습니다.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthExpenseCard extends StatelessWidget {
  const _MonthExpenseCard({
    required this.month,
    required this.detail,
    required this.onAddItem,
    required this.onEdit,
    required this.onDelete,
    required this.onEditItem,
  });

  final StoreExpenseMonthSummary month;
  final StoreExpenseMonthDetail? detail;
  final VoidCallback onAddItem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(StoreExpenseItem item) onEditItem;

  @override
  Widget build(BuildContext context) {
    final items = detail?.items ?? const <StoreExpenseItem>[];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 0.w, 12.h),
                child: Text(
                  month.periodLabel,
                  style: AppTypography.bodyLargeB.copyWith(
                    fontSize: 16.sp,
                    height: 24 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(2.r),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(2.r),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 24,
                          color: AppColors.grey150,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            color: AppColors.grey0Alt,
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              children: [
                InkWell(
                  onTap: onAddItem,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '항목 추가',
                          style: AppTypography.bodyMediumB.copyWith(
                            fontSize: 14.sp,
                            height: 16 / 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final item in items) ...[
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () => onEditItem(item),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey0,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey25),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _toMmDd(item.expenseDate),
                            style: AppTypography.bodyMediumR.copyWith(
                              fontSize: 14.sp,
                              height: 19 / 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CategoryChip(
                                label: item.categoryLabel,
                                categoryCode: item.categoryCode,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                _StoreCostScreenState.won(item.amount),
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
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Text(
                  '합계',
                  style: AppTypography.bodyMediumM.copyWith(
                    fontSize: 14.sp,
                    height: 16 / 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  _wonWithoutSuffix(detail?.totalAmount ?? month.totalAmount),
                  style: AppTypography.bodyLargeB.copyWith(
                    fontSize: 16.sp,
                    height: 24 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _toMmDd(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length == 3) {
      return '${parts[1]}.${parts[2]}';
    }
    return yyyyMmDd;
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.categoryCode});

  final String label;
  final String categoryCode;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(categoryCode);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmallM.copyWith(
          fontSize: 12.sp,
          color: AppColors.grey0,
        ),
      ),
    );
  }

  Color _categoryColor(String code) {
    switch (code) {
      case 'rent':
        return const Color(0xFFB570D2);
      case 'management_fee':
        return const Color(0xFF8FD270);
      case 'supplies':
        return const Color(0xFF70D2B3);
      case 'repair':
        return const Color(0xFF707DD2);
      default:
        return AppColors.grey150;
    }
  }
}

class _ExpenseCalendar extends StatelessWidget {
  const _ExpenseCalendar({required this.dashboard});

  final StoreExpenseDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final dateMap = <int, CalendarExpense>{};
    for (final c in dashboard.calendarExpenses) {
      final day = _dayOf(c.date);
      if (day != null) dateMap[day] = c;
    }
    final firstDay = DateTime(dashboard.year, dashboard.month, 1);
    final firstWeekdayMon0 = (firstDay.weekday + 6) % 7;
    final daysInMonth = DateTime(dashboard.year, dashboard.month + 1, 0).day;
    final prevMonthDays = DateTime(dashboard.year, dashboard.month, 0).day;
    final totalCells = ((firstWeekdayMon0 + daysInMonth + 6) ~/ 7) * 7;

    const week = ['일', '월', '화', '수', '목', '금', '토'];
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.grey25)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      week[i],
                      style: AppTypography.bodyMediumR.copyWith(
                        fontSize: 14.sp,
                        height: 20 / 14,
                        color: i == 0
                            ? const Color(0xFFFF4834)
                            : i == 6
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Column(
          children: [
            for (var weekIndex = 0; weekIndex < totalCells ~/ 7; weekIndex++)
              Builder(
                builder: (context) {
                  final rowStart = weekIndex * 7;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var offset = 0; offset < 7; offset++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final index = rowStart + offset;
                              final dayNum = index - firstWeekdayMon0 + 1;
                              final inMonth =
                                  dayNum >= 1 && dayNum <= daysInMonth;
                              final label = inMonth
                                  ? '$dayNum'
                                  : dayNum <= 0
                                  ? '${prevMonthDays + dayNum}'
                                  : '${dayNum - daysInMonth}';
                              final expense = inMonth ? dateMap[dayNum] : null;
                              final weekDayIndex = index % 7;
                              final dayColor = !inMonth
                                  ? AppColors.grey50
                                  : weekDayIndex == 0
                                  ? const Color(0xFFFF4834)
                                  : AppColors.textPrimary;

                              final visibleItems =
                                  expense?.items.take(2).toList() ??
                                  const <ExpenseItem>[];

                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 72,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      child: Center(
                                        child: Text(
                                          label.padLeft(2, '0'),
                                          style: AppTypography.bodySmallR
                                              .copyWith(
                                                fontSize: 12.sp,
                                                height: 18 / 12,
                                                color: dayColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    if (visibleItems.isNotEmpty)
                                      ...visibleItems.asMap().entries.map(
                                        (entry) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom:
                                                entry.key ==
                                                    visibleItems.length - 1
                                                ? 0
                                                : 5.h,
                                          ),
                                          child: _CalendarExpenseBadge(
                                            item: entry.value,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  int? _dayOf(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return null;
    return int.tryParse(parts[2]);
  }
}

class _DashboardMoneyIcon extends StatelessWidget {
  const _DashboardMoneyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '\$',
        style: AppTypography.bodyXSmallM.copyWith(
          fontSize: 10.sp,
          height: 16 / 10,
          color: AppColors.grey0,
        ),
      ),
    );
  }
}

class _CalendarExpenseBadge extends StatelessWidget {
  const _CalendarExpenseBadge({required this.item});

  final ExpenseItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: SizedBox(
        width: 43,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              color: _categoryColor(item.categoryCode),
              alignment: Alignment.center,
              child: Text(
                item.categoryLabel,
                style: AppTypography.bodyXSmallM.copyWith(
                  fontSize: 10.sp,
                  height: 16 / 10,
                  color: AppColors.grey0,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.grey25,
              padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 4.h),
              alignment: Alignment.center,
              child: Text(
                _compactAmountLabel(item.amount),
                style: AppTypography.bodyXSmallM.copyWith(
                  fontSize: 10.sp,
                  height: 16 / 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(String code) {
  switch (code) {
    case 'rent':
      return const Color(0xFFB570D2);
    case 'management_fee':
      return const Color(0xFF8FD270);
    case 'supplies':
      return const Color(0xFF70D2B3);
    case 'repair':
      return const Color(0xFF707DD2);
    default:
      return AppColors.grey150;
  }
}

String _wonWithoutSuffix(int amount) =>
    _StoreCostScreenState._won.format(amount);

String _compactAmountLabel(int amount) {
  if (amount >= 10000) {
    final manWon = amount / 10000;
    final hasDecimal = amount % 10000 != 0;
    final text = hasDecimal
        ? manWon.toStringAsFixed(1)
        : manWon.toStringAsFixed(0);
    return '$text만원';
  }
  return '${_StoreCostScreenState._won.format(amount)}원';
}

class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message});

  final String message;

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
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: () {
                final branchId = context.read<SelectedBranchCubit>().state;
                if (branchId == null) return;
                final now = DateTime.now();
                context.read<StoreExpenseBloc>().add(
                  StoreExpenseDashboardRequested(
                    branchId: branchId,
                    year: now.year,
                    month: now.month,
                  ),
                );
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
