import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/models/user.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import '../bloc/staff_management_bloc.dart';
import '../widgets/branch_select_card.dart';
import '../widgets/home_common_app_bar.dart';
import '../widgets/home_shared_sections.dart';
import '../widgets/schedule_date_selector.dart';
import '../widgets/work_status_badge.dart';
import '../widgets/work_assignment_tab.dart';
import 'add_branch_screen.dart';
import 'employee_detail_screen.dart';
import 'worker_registration_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef _DayScheduleRow =
    ({
      String startTime,
      String endTime,
      String displayTime,
      List<String> timeLabels,
      String workerName,
      String status,
      bool hasMemo,
      String memo,
    });

/// 직원관리 화면
class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  bool _isBranchListExpanded = false;
  bool _isWorkAssignmentDragMode = false;
  DateTime _selectedDate = DateTime.now();
  int? _loadedBranchId;
  bool _employeeInfoShowActive = true; // true: 현근무자, false: 퇴직자

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, User?>((b) => b.state.user);
    final selectedBranchId = context.select<SelectedBranchCubit, int?>(
      (cubit) => cubit.state,
    );
    final homeState = context.select<HomeBloc, HomeState>((bloc) => bloc.state);
    final hasAlarm = _hasAlarm(homeState, selectedBranchId);
    return Scaffold(
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
      body: BlocConsumer<SelectedBranchCubit, int?>(
        listener: (context, branchId) {
          if (branchId != null && _loadedBranchId != branchId) {
            _loadedBranchId = branchId;
            context.read<StaffManagementBloc>().add(
              StaffManagementInitialized(
                branchId: branchId,
                date: _toIsoDate(_selectedDate),
              ),
            );
          }
        },
        builder: (context, branchId) {
          return BlocBuilder<HomeBloc, HomeState>(
            builder: (context, homeState) {
              final branches = _toBranchItems(homeState);
              final selectedBranch = branches
                  .where((b) => b.id == branchId)
                  .cast<
                    ({int id, String name, String? status, int alertCount})?
                  >()
                  .firstWhere((b) => b != null, orElse: () => null);
              return BlocBuilder<StaffManagementBloc, StaffManagementBlocState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      if (state.isLoading)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (state.status == StaffManagementBlocStatus.failure)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.all(16.r),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            state.errorMessage ?? '오류가 발생했습니다.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                        child: BranchSelectCard(
                          selectedName: selectedBranch?.name,
                          branches: branches
                              .map(
                                (e) =>
                                    (id: e.id, name: e.name, status: e.status),
                              )
                              .toList(),
                          isExpanded: _isBranchListExpanded,
                          isOwner:
                              user?.role == UserRole.manager ||
                              user?.role == UserRole.storeManager,
                          onHeaderTap: () {
                            if (branches.isEmpty) return;
                            setState(
                              () => _isBranchListExpanded =
                                  !_isBranchListExpanded,
                            );
                          },
                          onBranchTap: (id) {
                            context.read<SelectedBranchCubit>().select(id);
                            setState(() => _isBranchListExpanded = false);
                          },
                          onAddTap:
                              (user?.role == UserRole.manager ||
                                  user?.role == UserRole.storeManager)
                              ? () async {
                                  final changed = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute<bool>(
                                          builder: (_) =>
                                              const AddBranchScreen(),
                                        ),
                                      );
                                  if (changed == true && context.mounted) {
                                    context.read<HomeBloc>().add(
                                      const HomeBranchesRequested(),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                      _buildTabs(),
                      Expanded(
                        child: branchId == null
                            ? Center(
                                child: Text(
                                  '점포를 선택하면 직원관리 데이터를 확인할 수 있어요.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : TabBarView(
                                controller: _tabController,
                                physics: _isWorkAssignmentDragMode
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                children: [
                                  _buildDayScheduleTab(
                                    context,
                                    branchId,
                                    state,
                                  ),
                                  _buildWeekScheduleTab(
                                    context,
                                    branchId,
                                    state,
                                  ),
                                  _buildEmployeeInfoTab(
                                    context,
                                    branchId,
                                    state,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      padding: EdgeInsets.zero,
      labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
      tabAlignment: TabAlignment.start,
      dividerColor: AppColors.grey50,
      dividerHeight: 1,
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.grey150,
      labelStyle: AppTypography.bodyLargeB,
      unselectedLabelStyle: AppTypography.bodyLargeB,
      indicatorColor: AppColors.textPrimary,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 1,
      isScrollable: true,
      tabs: const [
        Tab(text: '근무일정'),
        Tab(text: '근무배정'),
        Tab(text: '직원정보'),
      ],
    );
  }

  void _requestDaySchedule(BuildContext context, int branchId, DateTime date) {
    context.read<StaffManagementBloc>().add(
      StaffManagementDayScheduleRequested(
        branchId: branchId,
        date: _toIsoDate(date),
      ),
    );
  }

  void _requestWeekSchedule(
    BuildContext context,
    int branchId,
    String weekStartDate,
  ) {
    context.read<StaffManagementBloc>().add(
      StaffManagementWeekScheduleRequested(
        branchId: branchId,
        weekStartDate: weekStartDate,
      ),
    );
  }

  Future<void> _refreshDayScheduleTab(
    BuildContext context,
    int branchId,
  ) async {
    _requestDaySchedule(context, branchId, _selectedDate);
  }

  Future<void> _refreshWorkAssignmentTab(
    BuildContext context,
    int branchId,
    String weekStartDate,
  ) async {
    _requestDaySchedule(context, branchId, DateTime.now());
    _requestWeekSchedule(context, branchId, weekStartDate);
  }

  Future<void> _refreshEmployeeInfoTab(
    BuildContext context,
    int branchId,
  ) async {
    final query = _searchController.text.trim();
    context.read<StaffManagementBloc>().add(
      StaffManagementEmployeesCompareRequested(
        branchId: branchId,
        q: query.isEmpty ? null : query,
      ),
    );
  }

  Widget _buildDayScheduleTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final slots = ((state.daySchedule?['slots'] as List?) ?? const []).whereType<Map>();
    final scheduleRows = _buildMergedDayScheduleRows(slots);
    final rows = scheduleRows
        .map(
          (row) => (
            time: row.displayTime,
            workerName: row.workerName,
            status: row.status,
            hasMemo: row.hasMemo,
          ),
        )
        .toList();
    final workDate =
        state.daySchedule?['work_date']?.toString() ??
        _toIsoDate(_selectedDate);

    return RefreshIndicator(
      onRefresh: () => _refreshDayScheduleTab(context, branchId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0.w, 12.h, 12.w, 16.h),
        children: [
          ScheduleDateSelector(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
              _requestDaySchedule(context, branchId, date);
            },
          ),
          SizedBox(height: 30.h),
          HomeTodayWorkersSection(
            dateLabel: _formatDateLabel(workDate),
            rows: rows,
            showHeader: false,
            tableHorizontalPadding: 4,
            alwaysShowMemoIcon: true,
            onTapStatus: scheduleRows.isEmpty
                ? null
                : (index, row) {
                    final selectedRow = scheduleRows[index];
                    _showWorkStatusModal(
                      context,
                      selectedRow,
                      branchId: branchId,
                      workDate: workDate,
                    );
                  },
            onTapMemo: scheduleRows.isEmpty
                ? null
                : (index, row) {
                    final selectedRow = scheduleRows[index];
                    if (selectedRow.hasMemo) {
                      _showMemoDetailModal(
                        context,
                        selectedRow,
                        memo: selectedRow.memo,
                        branchId: branchId,
                        workDate: workDate,
                      );
                      return;
                    }
                    _showMemoModal(
                      context,
                      selectedRow,
                      selectedRow.status,
                      branchId: branchId,
                      workDate: workDate,
                    );
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _showWorkStatusModal(
    BuildContext context,
    _DayScheduleRow row, {
    required int branchId,
    required String workDate,
  }) async {
    final bloc = context.read<StaffManagementBloc>();
    final screenContext = context;

    String normalizeStatus(String value) {
      if (value == '완료' || value == '근무완료') return '근무완료';
      if (value == '예정' || value == '근무예정') return '근무예정';
      return value;
    }

    var selectedStatus = normalizeStatus(row.status);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Widget statusButton(String label) {
              final selected = selectedStatus == label;
              return Expanded(
                child: OutlinedButton(
                  onPressed: () => setModalState(() => selectedStatus = label),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(56.h),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.grey50,
                    ),
                    backgroundColor: selected
                        ? const Color(0xFFE2F6F0)
                        : AppColors.grey0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.bodyLargeM.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '근무 상태를\n선택하여 변경해 주세요.',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        statusButton('근무완료'),
                        SizedBox(width: 12.w),
                        statusButton('근무예정'),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        statusButton('결근'),
                        SizedBox(width: 12.w),
                        statusButton('미정'),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _showMemoModal(
                            screenContext,
                            row,
                            selectedStatus,
                            branchId: branchId,
                            workDate: workDate,
                          );
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(56.h),
                        side: const BorderSide(color: AppColors.primary),
                        backgroundColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/svg/icon/plus_circle_mint_16.svg',
                            width: 16,
                            height: 16,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '메모 함께 기재하기',
                            style: AppTypography.bodyMediumB.copyWith(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              height: 16 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(56.h),
                              backgroundColor: AppColors.grey25,
                              foregroundColor: AppColors.grey150,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _saveWorkerStatus(
                                bloc,
                                workDate: workDate,
                                timeLabels: row.timeLabels,
                                workerName: row.workerName,
                                status: selectedStatus,
                                branchId: branchId,
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(56.h),
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.grey0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('확인'),
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
  }

  Future<void> _showMemoModal(
    BuildContext context,
    _DayScheduleRow row,
    String status, {
    required int branchId,
    required String workDate,
  }) async {
    final controller = TextEditingController();
    final bloc = context.read<StaffManagementBloc>();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '근무 상태 메모를\n입력해 주세요.',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey25,
                    border: Border(
                      top: BorderSide(color: Color(0xFF666874), width: 1),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                  child: const _MemoInfoHeaderRow(),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 8.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: _MemoInfoDataRow(
                    time: row.displayTime,
                    workerName: row.workerName,
                    statusLabel: _toDisplayStatus(status),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  '메모',
                  style: AppTypography.bodyLargeB.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '입력해주세요.',
                    filled: true,
                    fillColor: AppColors.grey0Alt,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(56.h),
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final memoText = controller.text.trim();
                          Navigator.of(dialogContext).pop();
                          _saveWorkerStatus(
                            bloc,
                            workDate: workDate,
                            timeLabels: row.timeLabels,
                            workerName: row.workerName,
                            status: status,
                            memo: memoText.isNotEmpty ? memoText : null,
                            branchId: branchId,
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(56.h),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('확인'),
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
  }

  Future<void> _showMemoDetailModal(
    BuildContext context,
    _DayScheduleRow row, {
    required String memo,
    required int branchId,
    required String workDate,
  }) async {
    final bloc = context.read<StaffManagementBloc>();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '근무 상태 메모',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey25,
                    border: Border(
                      top: BorderSide(color: Color(0xFF666874), width: 1),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                  child: const _MemoInfoHeaderRow(),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 8.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: _MemoInfoDataRow(
                    time: row.displayTime,
                    workerName: row.workerName,
                    statusLabel: _toDisplayStatus(row.status),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  '메모',
                  style: AppTypography.bodyLargeB.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: TextEditingController(text: memo),
                  readOnly: true,
                  minLines: 3,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '입력해주세요.',
                    filled: true,
                    fillColor: AppColors.grey0Alt,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _saveWorkerStatus(
                            bloc,
                            workDate: workDate,
                            timeLabels: row.timeLabels,
                            workerName: row.workerName,
                            status: row.status,
                            memo: null,
                            branchId: branchId,
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(56.h),
                          backgroundColor: const Color(0xFFFF453A),
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(56.h),
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: const Text('닫기'),
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
  }

  void _saveWorkerStatus(
    StaffManagementBloc bloc, {
    required String workDate,
    required List<String> timeLabels,
    required String workerName,
    required String status,
    String? memo,
    required int branchId,
  }) {
    for (final timeLabel in timeLabels) {
      bloc.add(
        StaffManagementWorkerStatusSaveRequested(
          branchId: branchId,
          workDate: workDate,
          timeLabel: timeLabel,
          workerName: workerName,
          status: status,
          memo: memo,
        ),
      );
    }
  }

  List<_DayScheduleRow> _buildMergedDayScheduleRows(Iterable<Map> slots) {
    final rows = <_DayScheduleRow>[];
    final openSegments =
        <String, ({String startTime, List<String> timeLabels, String workerName, String status, String memo})>{};

    _DayScheduleRow closeSegment(
      ({String startTime, List<String> timeLabels, String workerName, String status, String memo}) segment,
    ) {
      final labels = List<String>.from(segment.timeLabels);
      final endTime = labels.isEmpty
          ? _slotEndTime(segment.startTime)
          : _slotEndTime(labels.last);
      return (
        startTime: segment.startTime,
        endTime: endTime,
        displayTime: '${segment.startTime}\n$endTime',
        timeLabels: labels,
        workerName: segment.workerName,
        status: segment.status,
        hasMemo: segment.memo.isNotEmpty,
        memo: segment.memo,
      );
    }

    for (final slot in slots) {
      final time = slot['time']?.toString().trim() ?? '';
      if (time.isEmpty) continue;

      final employees = ((slot['employees'] as List?) ?? const []).whereType<Map>();
      final activeKeys = <String>{};

      for (final employee in employees) {
        final workerName = employee['worker_name']?.toString().trim() ?? '-';
        final status = _toDisplayStatus(employee['status']?.toString() ?? '');
        final memo = employee['memo']?.toString().trim() ?? '';
        final employeeId = employee['employee_id']?.toString().trim();
        final identityKey = (employeeId != null && employeeId.isNotEmpty)
            ? employeeId
            : workerName;

        activeKeys.add(identityKey);

        final existing = openSegments[identityKey];
        final isContinuous =
            existing != null &&
            existing.timeLabels.isNotEmpty &&
            _slotEndTime(existing.timeLabels.last) == time &&
            existing.status == status &&
            existing.memo == memo;

        if (isContinuous) {
          existing.timeLabels.add(time);
          continue;
        }

        if (existing != null) {
          rows.add(closeSegment(existing));
        }

        openSegments[identityKey] = (
          startTime: time,
          timeLabels: [time],
          workerName: workerName,
          status: status,
          memo: memo,
        );
      }

      for (final key in openSegments.keys.toList()) {
        if (activeKeys.contains(key)) continue;
        rows.add(closeSegment(openSegments.remove(key)!));
      }
    }

    for (final segment in openSegments.values) {
      rows.add(closeSegment(segment));
    }

    rows.sort((a, b) {
      final byStart = a.startTime.compareTo(b.startTime);
      if (byStart != 0) return byStart;
      return a.workerName.compareTo(b.workerName);
    });
    return rows;
  }

  String _slotEndTime(String time) {
    final parts = time.split(':');
    var hour = int.tryParse(parts.first) ?? 0;
    var minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    minute += 30;
    if (minute >= 60) {
      minute -= 60;
      hour += 1;
    }
    if (hour >= 24) hour = 24;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildWeekScheduleTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final today = DateTime.now();
    return WorkAssignmentTab(
      branchId: branchId,
      daySchedule: state.daySchedule,
      weekSchedule: state.weekSchedule,
      employeesCompare: state.employeesCompare,
      today: today,
      onPullToRefresh: (weekStartDate) =>
          _refreshWorkAssignmentTab(context, branchId, weekStartDate),
      onRefreshToday: () {
        _requestDaySchedule(context, branchId, today);
      },
      onRefreshWeek: (weekStartDate) {
        _requestWeekSchedule(context, branchId, weekStartDate);
      },
      onDragModeChanged: (isDragMode) {
        if (_isWorkAssignmentDragMode != isDragMode) {
          setState(() => _isWorkAssignmentDragMode = isDragMode);
        }
      },
    );
  }

  Widget _buildEmployeeInfoTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final active =
        ((state.employeesCompare?['active_workers'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final retired =
        ((state.employeesCompare?['retired_workers'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final list = _employeeInfoShowActive ? active : retired;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refreshEmployeeInfoTab(context, branchId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
            children: [
              _buildEmployeeInfoSelector(),
              SizedBox(height: 12.h),
              _buildEmployeeSearchInput(context, branchId),
              SizedBox(height: 16.h),
              ...list.map((employee) {
                final avg = employee['average_rating'];
                final starCount = avg != null
                    ? (avg is num ? avg.round() : 0).clamp(0, 3)
                    : 0;
                return _buildEmployeeListTile(
                  context,
                  branchId,
                  employee,
                  state.selectedEmployeeId,
                  starCount,
                );
              }),
              if (list.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Text(
                      _employeeInfoShowActive ? '현근무자 없음' : '퇴직자 없음',
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: _buildEmployeeInfoFab(context, branchId),
        ),
      ],
    );
  }

  Widget _buildEmployeeInfoSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<bool>(
        offset: const Offset(0, 40),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem<bool>(value: true, child: Text('현직자')),
          const PopupMenuItem<bool>(value: false, child: Text('퇴직자')),
        ],
        onSelected: (value) => setState(() => _employeeInfoShowActive = value),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.grey0,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.grey50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _employeeInfoShowActive ? '현직자' : '퇴직자',
                style: AppTypography.bodyMediumR.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 19 / 14,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
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

  Widget _buildEmployeeSearchInput(BuildContext context, int branchId) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '검색',
        hintStyle: AppTypography.bodyMediumR.copyWith(
          color: AppColors.grey100,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          height: 19 / 14,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.r),
          child: SvgPicture.asset(
            'assets/icons/svg/icon/search_mint_20.svg',
            width: 20,
            height: 20,
          ),
        ),
        filled: true,
        fillColor: AppColors.grey0Alt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      onSubmitted: (q) => context.read<StaffManagementBloc>().add(
        StaffManagementEmployeesCompareRequested(
          branchId: branchId,
          q: q.trim().isEmpty ? null : q.trim(),
        ),
      ),
    );
  }

  Widget _buildEmployeeListTile(
    BuildContext context,
    int branchId,
    Map<String, dynamic> employee,
    int? selectedEmployeeId,
    int starCount, // average_rating 기반 (0~3, 0이면 미표시)
  ) {
    final employeeId = (employee['employee_id'] as num?)?.toInt();
    final name = employee['name'] as String? ?? '-';
    final role = employee['role'] as String?;
    final isManager = role == 'manager' || role == '점장';

    return InkWell(
      onTap: employeeId == null
          ? null
          : () async {
              context.read<StaffManagementBloc>().add(
                StaffManagementEmployeeDetailRequested(
                  branchId: branchId,
                  employeeId: employeeId,
                ),
              );
              final myRating = (employee['my_rating'] as num?)?.round();
              final shouldRefresh = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EmployeeDetailScreen(
                    branchId: branchId,
                    employeeId: employeeId,
                    initialMyRating:
                        myRating != null && myRating >= 1 && myRating <= 3
                        ? myRating
                        : null,
                  ),
                ),
              );
              if (shouldRefresh == true && context.mounted) {
                context.read<StaffManagementBloc>().add(
                  StaffManagementEmployeesCompareRequested(
                    branchId: branchId,
                    q: _searchController.text.trim().isEmpty
                        ? null
                        : _searchController.text.trim(),
                  ),
                );
              }
            },
      child: Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: starCount > 0
                  ? _buildStarBadge(starCount)
                  : const SizedBox(),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 16 / 14,
                    ),
                  ),
                  if (isManager) ...[
                    SizedBox(width: 4.w),
                    Text(
                      '[점장]',
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 16 / 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.grey100,
            ),
          ],
        ),
      ),
    );
  }

  /// 별 영역: 1개=큰 별, 2개=작은 별 2개(같은 넓이), 3개=삼각형(1 위, 2 아래)
  Widget _buildStarBadge(int count) {
    if (count == 1) {
      return Center(
        child: Image.asset(
          'assets/icons/png/common/star_green_icon.png',
          width: 16,
          height: 16,
        ),
      );
    }
    if (count == 2) {
      const size = 10.0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/png/common/star_green_icon.png',
            width: size,
            height: size,
          ),
          SizedBox(width: 2.w),
          Image.asset(
            'assets/icons/png/common/star_green_icon.png',
            width: size,
            height: size,
          ),
        ],
      );
    }
    if (count == 3) {
      const size = 8.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/png/common/star_green_icon.png',
            width: size,
            height: size,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/png/common/star_green_icon.png',
                width: size,
                height: size,
              ),
              SizedBox(width: 2.w),
              Image.asset(
                'assets/icons/png/common/star_green_icon.png',
                width: size,
                height: size,
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmployeeInfoFab(BuildContext context, int? branchId) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(28.r),
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (branchId == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkerRegistrationScreen(
                branchId: branchId,
                onRegistered: () {
                  context.read<StaffManagementBloc>().add(
                    StaffManagementEmployeesCompareRequested(
                      branchId: branchId,
                      q: null,
                    ),
                  );
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(28.r),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add, color: AppColors.grey0, size: 28),
        ),
      ),
    );
  }

  static String _toIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _hasAlarm(HomeState homeState, int? branchId) {
    if (branchId == null) return false;
    final branches = _toBranchItems(homeState);
    final selected = branches
        .where((b) => b.id == branchId)
        .cast<({int id, String name, String? status, int alertCount})?>()
        .firstWhere((b) => b != null, orElse: () => null);
    return (selected?.alertCount ?? 0) > 0;
  }

  List<({int id, String name, String? status, int alertCount})> _toBranchItems(
    HomeState state,
  ) {
    if (state.ownerBranches.isNotEmpty) {
      return state.ownerBranches
          .map(
            (branch) => (
              id: branch.id,
              name: branch.name,
              status: branch.reviewStatus,
              alertCount: 0,
            ),
          )
          .toList();
    }
    return state.managerBranches
        .map(
          (branch) => (
            id: branch.id,
            name: branch.name,
            status: branch.reviewStatus,
            alertCount: branch.openAlertCount,
          ),
        )
        .toList();
  }

  /// API 상태(scheduled|done|absent|unset) → 화면 표시
  String _toDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case '완료':
      case '근무완료':
        return '완료';
      case 'absent':
      case '결근':
        return '결근';
      case 'unset':
      case '미정':
        return '미정';
      case 'scheduled':
      case '예정':
      case '근무예정':
      default:
        return '예정';
    }
  }

  String _formatDateLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day(${weekdays[date.weekday - 1]})';
  }
}

class _MemoInfoHeaderRow extends StatelessWidget {
  const _MemoInfoHeaderRow();

  static const int _timeFlex = 22;
  static const int _workerFlex = 30;
  static const int _memoFlex = 16;
  static const int _statusFlex = 32;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySmallB.copyWith(
      color: AppColors.textSecondary,
      fontSize: 12.sp,
      height: 16 / 12,
    );
    return Row(
      children: [
        Expanded(
          flex: _timeFlex,
          child: Text('시간', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: _workerFlex,
          child: Text('근무자', textAlign: TextAlign.start, style: style),
        ),
        Expanded(
          flex: _memoFlex,
          child: Text('메모', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: _statusFlex,
          child: Text('상태', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _MemoInfoDataRow extends StatelessWidget {
  const _MemoInfoDataRow({
    required this.time,
    required this.workerName,
    required this.statusLabel,
  });

  final String time;
  final String workerName;
  final String statusLabel;

  static const int _timeFlex = 22;
  static const int _workerFlex = 30;
  static const int _memoFlex = 16;
  static const int _statusFlex = 32;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.textPrimary,
      fontSize: 14.sp,
      height: 19 / 14,
    );
    return Row(
      children: [
        Expanded(
          flex: _timeFlex,
          child: Text(
            time,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: _workerFlex,
          child: Text(
            workerName,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
        const Expanded(
          flex: _memoFlex,
          child: Center(
            child: Icon(
              Icons.edit_outlined,
              color: AppColors.grey150,
            ),
          ),
        ),
        Expanded(
          flex: _statusFlex,
          child: Center(
            child: WorkStatusBadge(
              status: statusLabel,
              compact: true,
            ),
          ),
        ),
      ],
    );
  }
}
