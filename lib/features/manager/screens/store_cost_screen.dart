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
      final months = await repo.getMonths(branchId: branchId, year: _monthsYear);
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
    final created = await Navigator.of(context).push<StoreExpenseMonthSummary>(
      MaterialPageRoute<StoreExpenseMonthSummary>(
        builder: (_) => StoreExpenseAddMonthScreen(
          branchId: branchId,
          initialYear: _monthsYear,
        ),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      _monthsYear = created.year;
    });
    await _loadMonths(branchId);
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
        ),
      ),
    );
    if (ok == true && mounted) {
      await _loadMonths(branchId);
      _loadDashboard(branchId);
    }
  }

  Future<void> _deleteMonth(int branchId, int expenseMonthId) async {
    final sure = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              content: const Text('이 월 데이터를 삭제할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!sure) return;
    if (!mounted) return;
    try {
      final repo = context.read<StoreExpenseRepository>();
      await repo.deleteMonth(branchId: branchId, expenseMonthId: expenseMonthId);
      if (!mounted) return;
      await _loadMonths(branchId);
      _loadDashboard(branchId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했습니다: $e')),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 기능은 곧 연결됩니다.')),
            );
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
                          onDeleteMonth: (monthId) =>
                              _deleteMonth(branchId, monthId),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey25)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        dividerColor: AppColors.grey50,
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
        return RefreshIndicator(
          onRefresh: () async {
            context.read<StoreExpenseBloc>().add(
                  StoreExpenseDashboardRequested(
                    branchId: context.read<SelectedBranchCubit>().state,
                    year: year,
                    month: month,
                  ),
                );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  _YearMonthDrop(
                    text: '$year',
                    onTap: () => _pickYear(context),
                  ),
                  const SizedBox(width: 8),
                  Text('년', style: AppTypography.bodyLargeM.copyWith(fontSize: 16)),
                  const SizedBox(width: 8),
                  _YearMonthDrop(
                    text: '$month',
                    onTap: () => _pickMonth(context),
                  ),
                  const SizedBox(width: 8),
                  Text('월', style: AppTypography.bodyLargeM.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppColors.textPrimary),
                  Text(
                    '${d.month}월 ${d.baseDay}일 기준 예상 점내 비용',
                    style: AppTypography.bodyLargeM.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.35, 0.2),
                    end: Alignment(1, 1),
                    colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 ${_StoreCostScreenState.won(d.currentMonthToDateTotal).replaceAll('원', ' 원')}',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '전월 대비 총 $ratio% ${wentUp ? '올랐어요' : '내렸어요'}',
                      style: AppTypography.bodyMediumM.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: d.categoryCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, i) {
                  final c = d.categoryCards[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey0Alt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          c.categoryLabel,
                          style: AppTypography.bodyMediumR.copyWith(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _StoreCostScreenState.won(c.monthAmount),
                          style: AppTypography.heading3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          c.summaryLabel ?? '${c.transactionCount}회',
                          style: AppTypography.bodyMediumR.copyWith(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
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
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final y in years)
                ListTile(
                  title: Text('$y년'),
                  onTap: () => Navigator.pop(ctx, y),
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
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var m = 1; m <= 12; m++)
                ListTile(
                  title: Text('$m월'),
                  onTap: () => Navigator.pop(ctx, m),
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
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 76,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyLargeM.copyWith(fontSize: 16),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
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
    required this.onDeleteMonth,
  });

  final bool monthsLoading;
  final String? monthsError;
  final List<StoreExpenseMonthSummary> months;
  final Map<int, StoreExpenseMonthDetail> monthDetails;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddMonth;
  final ValueChanged<StoreExpenseMonthSummary> onAddItem;
  final ValueChanged<int> onDeleteMonth;

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          InkWell(
            onTap: onAddMonth,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '월별 점내 비용 추가',
                    style: AppTypography.bodyLargeB.copyWith(
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final month in months) ...[
            _MonthExpenseCard(
              month: month,
              detail: monthDetails[month.expenseMonthId],
              onAddItem: () => onAddItem(month),
              onDelete: () => onDeleteMonth(month.expenseMonthId),
            ),
            const SizedBox(height: 12),
          ],
          if (months.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12),
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
    required this.onDelete,
  });

  final StoreExpenseMonthSummary month;
  final StoreExpenseMonthDetail? detail;
  final VoidCallback onAddItem;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final items = detail?.items ?? const <StoreExpenseItem>[];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey25),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                month.periodLabel,
                style: AppTypography.bodyLargeB.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.grey150,
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onAddItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_circle, size: 16),
              label: Text(
                '항목 추가',
                style: AppTypography.bodyMediumM.copyWith(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    _toMmDd(item.expenseDate),
                    style: AppTypography.bodyMediumR.copyWith(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: item.categoryLabel,
                    categoryCode: item.categoryCode,
                  ),
                  const Spacer(),
                  Text(
                    _StoreCostScreenState.won(item.amount),
                    style: AppTypography.bodyLargeB.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Text(
                '합계',
                style: AppTypography.bodyMediumR.copyWith(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
                      Text(
                _StoreCostScreenState.won(detail?.totalAmount ?? month.totalAmount),
                style: AppTypography.heading3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
  const _CategoryChip({
    required this.label,
    required this.categoryCode,
  });

  final String label;
  final String categoryCode;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(categoryCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmallM.copyWith(
          fontSize: 12,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        week[i],
                        style: AppTypography.bodyMediumM.copyWith(
                          fontSize: 14,
                          color: i == 0
                              ? Colors.redAccent
                              : i == 6
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - firstWeekdayMon0 + 1;
              final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
              final label = inMonth
                  ? '$dayNum'
                  : dayNum <= 0
                      ? '${prevMonthDays + dayNum}'
                      : '${dayNum - daysInMonth}';
              final expense = inMonth ? dateMap[dayNum] : null;
              return Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        label,
                        style: AppTypography.bodyMediumR.copyWith(
                          fontSize: 14,
                          color: inMonth ? AppColors.textPrimary : AppColors.grey100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (expense != null && expense.items.isNotEmpty)
                      ...expense.items.take(2).map(
                            (it) => Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _categoryColor(it.categoryCode),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${it.categoryLabel} ${_StoreCostScreenState.won(it.amount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyXSmallM.copyWith(
                                  fontSize: 10,
                                  color: AppColors.grey0,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int? _dayOf(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return null;
    return int.tryParse(parts[2]);
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

class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message});

  final String message;

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
                        textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
                      ),
                      const SizedBox(height: 16),
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
