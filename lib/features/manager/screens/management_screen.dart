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

/// 직원관리 화면
class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  late final TabController _tabController;
  bool _isBranchListExpanded = false;
  bool _isWorkAssignmentDragMode = false;
  DateTime _selectedDate = DateTime.now();
  String? _contractStatus;
  String? _templateVersion;
  int _reviewRating = 3;
  int? _loadedBranchId;
  bool _employeeInfoShowActive = true; // true: 현근무자, false: 퇴직자

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _reviewController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 기능은 곧 연결됩니다.')),
          );
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
                  .cast<({int id, String name, String? status, int alertCount})?>()
                  .firstWhere((b) => b != null, orElse: () => null);
          return BlocBuilder<StaffManagementBloc, StaffManagementBlocState>(
            builder: (context, state) {
                  return Column(
                    children: [
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (state.status == StaffManagementBlocStatus.failure)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                        state.errorMessage ?? '오류가 발생했습니다.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: BranchSelectCard(
                          selectedName: selectedBranch?.name,
                          branches: branches
                              .map((e) => (id: e.id, name: e.name, status: e.status))
                              .toList(),
                          isExpanded: _isBranchListExpanded,
                          isOwner: user?.role == UserRole.manager ||
                              user?.role == UserRole.storeManager,
                          onHeaderTap: () {
                            if (branches.isEmpty) return;
                            setState(
                              () => _isBranchListExpanded = !_isBranchListExpanded,
                            );
                          },
                          onBranchTap: (id) {
                            context.read<SelectedBranchCubit>().select(id);
                            setState(() => _isBranchListExpanded = false);
                          },
                          onAddTap: (user?.role == UserRole.manager ||
                                  user?.role == UserRole.storeManager)
                              ? () async {
                                  final changed = await Navigator.of(context)
                                      .push<bool>(
                                    MaterialPageRoute<bool>(
                                      builder: (_) => const AddBranchScreen(),
                                    ),
                                  );
                                  if (changed == true && context.mounted) {
                                    context
                                        .read<HomeBloc>()
                                        .add(const HomeBranchesRequested());
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
                                  _buildDayScheduleTab(context, branchId, state),
                                  _buildWeekScheduleTab(context, branchId, state),
                                  _buildEmployeeInfoTab(
                                    context,
                                    branchId,
                                    state,
                                  ),
                                  _buildContractsTab(context, branchId, state),
                                  _buildReviewsTab(context, branchId, state),
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
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        Tab(text: '계약서'),
        Tab(text: '근무자 평가'),
      ],
    );
  }

  Widget _buildDayScheduleTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final slots =
        ((state.daySchedule?['slots'] as List?) ?? const []).whereType<Map>();
    final rows = <({
      String time,
      String workerName,
      String status,
      bool hasMemo,
    })>[];
    final memoMap = <String, String>{};
    for (final slot in slots) {
      final time = slot['time']?.toString() ?? '-';
      final employees = ((slot['employees'] as List?) ?? const []).whereType<Map>();
      for (final employee in employees) {
        final workerName = employee['worker_name']?.toString() ?? '-';
        final memo = employee['memo']?.toString().trim();
        rows.add(
          (
            time: time,
            workerName: workerName,
            status: _toDisplayStatus(employee['status']?.toString() ?? ''),
            hasMemo: memo != null && memo.isNotEmpty,
          ),
        );
        if (memo != null && memo.isNotEmpty) {
          memoMap['${rows.length - 1}'] = memo;
        }
      }
    }
    final workDate = state.daySchedule?['work_date']?.toString() ??
        _toIsoDate(_selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 16),
      children: [
        ScheduleDateSelector(
          selectedDate: _selectedDate,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
                          context.read<StaffManagementBloc>().add(
                                StaffManagementDayScheduleRequested(
                                  branchId: branchId,
                    date: _toIsoDate(date),
                                ),
                              );
                        },
        ),
        const SizedBox(height: 30),
        HomeTodayWorkersSection(
          dateLabel: _formatDateLabel(workDate),
          rows: rows,
          showHeader: false,
          tableHorizontalPadding: 4,
          onTapStatus: rows.isEmpty
              ? null
              : (index, row) {
                  _showWorkStatusModal(
                    context,
                    row,
                    branchId: branchId,
                    workDate: workDate,
                  );
                },
          onTapMemo: rows.isEmpty
              ? null
              : (index, row) {
                  _showMemoDetailModal(
                    context,
                    row,
                    memo: memoMap['$index'] ?? '',
                    branchId: branchId,
                    workDate: workDate,
                  );
                },
        ),
      ],
    );
  }

  Future<void> _showWorkStatusModal(
    BuildContext context,
    ({String time, String workerName, String status, bool hasMemo}) row, {
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
                    minimumSize: const Size.fromHeight(56),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.grey50,
                    ),
                    backgroundColor: selected ? const Color(0xFFE2F6F0) : AppColors.grey0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.bodyLargeM.copyWith(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  ),
                );
              }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        statusButton('근무완료'),
                        const SizedBox(width: 12),
                        statusButton('근무예정'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        statusButton('결근'),
                        const SizedBox(width: 12),
                        statusButton('미정'),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: AppColors.primary),
                        backgroundColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
                          Text(
                            '메모 함께 기재하기',
                            style: AppTypography.bodyMediumB.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 16 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: AppColors.grey25,
                              foregroundColor: AppColors.grey150,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _saveWorkerStatus(
                            bloc,
                            workDate: workDate,
                            timeLabel: row.time,
                            workerName: row.workerName,
                            status: selectedStatus,
                            branchId: branchId,
                          );
                        },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.grey0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
    ({String time, String workerName, String status, bool hasMemo}) row,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '근무 상태 메모를\n입력해 주세요.',
                  style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.grey25,
                    border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: const [
                      Expanded(child: Text('시간', textAlign: TextAlign.center)),
                      Expanded(child: Text('근무자', textAlign: TextAlign.start)),
                      Expanded(child: Text('메모', textAlign: TextAlign.center)),
                      Expanded(child: Text('상태', textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.time, textAlign: TextAlign.center)),
                      Expanded(child: Text(row.workerName, textAlign: TextAlign.start)),
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.edit_outlined, color: AppColors.grey150),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: WorkStatusBadge(
                            status: _toDisplayStatus(status),
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('메모', style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '입력해주세요.',
                    filled: true,
                    fillColor: AppColors.grey0Alt,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final memoText = controller.text.trim();
                          Navigator.of(dialogContext).pop();
                          _saveWorkerStatus(
                            bloc,
                            workDate: workDate,
                            timeLabel: row.time,
                            workerName: row.workerName,
                            status: status,
                            memo: memoText.isNotEmpty ? memoText : null,
                            branchId: branchId,
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    ({String time, String workerName, String status, bool hasMemo}) row, {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    Text(
                  '근무 상태 메모',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.grey25,
                    border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: const [
                      Expanded(child: Text('시간', textAlign: TextAlign.center)),
                      Expanded(child: Text('근무자', textAlign: TextAlign.start)),
                      Expanded(child: Text('메모', textAlign: TextAlign.center)),
                      Expanded(child: Text('상태', textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.time, textAlign: TextAlign.center)),
                      Expanded(child: Text(row.workerName, textAlign: TextAlign.start)),
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.edit_outlined, color: AppColors.grey150),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: WorkStatusBadge(
                            status: _toDisplayStatus(row.status),
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('메모', style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
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
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grey50),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _saveWorkerStatus(
                            bloc,
                            workDate: workDate,
                            timeLabel: row.time,
                            workerName: row.workerName,
                            status: row.status,
                            memo: null,
                            branchId: branchId,
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFFFF453A),
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
    required String timeLabel,
    required String workerName,
    required String status,
    String? memo,
    required int branchId,
  }) {
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
      onRefreshToday: () {
        context.read<StaffManagementBloc>().add(
              StaffManagementDayScheduleRequested(
                branchId: branchId,
                date: _toIsoDate(today),
              ),
            );
      },
      onRefreshWeek: (weekStartDate) {
        context.read<StaffManagementBloc>().add(
              StaffManagementWeekScheduleRequested(
                branchId: branchId,
                weekStartDate: weekStartDate,
                ),
              );
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
    final active = ((state.employeesCompare?['active_workers'] as List?) ??
            const [])
        .cast<Map<String, dynamic>>();
    final retired = ((state.employeesCompare?['retired_workers'] as List?) ??
            const [])
        .cast<Map<String, dynamic>>();
    final list = _employeeInfoShowActive ? active : retired;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _buildEmployeeInfoSelector(),
            const SizedBox(height: 12),
            _buildEmployeeSearchInput(context, branchId),
            const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(vertical: 24),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        const PopupMenuItem<bool>(
          value: true,
          child: Text('현직자'),
        ),
        const PopupMenuItem<bool>(
          value: false,
          child: Text('퇴직자'),
        ),
      ],
      onSelected: (value) => setState(() => _employeeInfoShowActive = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _employeeInfoShowActive ? '현직자' : '퇴직자',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
            ),
            const SizedBox(width: 4),
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
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 19 / 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/icons/svg/icon/search_mint_20.svg',
            width: 20,
            height: 20,
          ),
        ),
        filled: true,
        fillColor: AppColors.grey0Alt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    initialMyRating: myRating != null && myRating >= 1 && myRating <= 3
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
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: starCount > 0 ? _buildStarBadge(starCount) : const SizedBox(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 16 / 14,
                    ),
                  ),
                  if (isManager) ...[
                    const SizedBox(width: 4),
                    Text(
                      '[점장]',
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.primary,
                        fontSize: 14,
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
          const SizedBox(width: 2),
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
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/png/common/star_green_icon.png',
                width: size,
                height: size,
              ),
              const SizedBox(width: 2),
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
      borderRadius: BorderRadius.circular(28),
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
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add, color: AppColors.grey0, size: 28),
        ),
      ),
    );
  }

  Widget _buildContractsTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final employeeId = state.selectedEmployeeId;
    final contracts = ((state.employmentContracts?['items'] as List?) ??
            const [])
        .cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('근로계약서'),
        const SizedBox(height: 8),
        Text(
          employeeId == null
              ? '직원정보 탭에서 직원을 먼저 선택해주세요.'
              : '선택된 직원 ID: $employeeId',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _contractStatus,
          decoration: const InputDecoration(labelText: '상태 필터'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('전체')),
            DropdownMenuItem<String?>(value: 'draft', child: Text('임시저장')),
            DropdownMenuItem<String?>(
              value: 'completed',
              child: Text('완료'),
            ),
          ],
          onChanged: (value) => setState(() => _contractStatus = value),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _templateVersion,
          decoration: const InputDecoration(labelText: '템플릿 필터'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('전체')),
            DropdownMenuItem<String?>(value: 'standard_v1', child: Text('표준')),
            DropdownMenuItem<String?>(
              value: 'minor_standard_v1',
              child: Text('연소'),
            ),
            DropdownMenuItem<String?>(
              value: 'guardian_consent_v1',
              child: Text('친권자 동의서'),
            ),
          ],
          onChanged: (value) => setState(() => _templateVersion = value),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: employeeId == null
              ? null
              : () => context.read<StaffManagementBloc>().add(
                    StaffManagementEmploymentContractsRequested(
                      branchId: branchId,
                      employeeId: employeeId,
                      status: _contractStatus,
                      templateVersion: _templateVersion,
                    ),
                  ),
          child: const Text('계약서 조회'),
        ),
        const SizedBox(height: 12),
        ...contracts.map(
          (contract) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(contract['title']?.toString() ?? '-'),
              subtitle: Text(
                '상태: ${contract['status']} / 템플릿: ${contract['template_version']}',
              ),
            ),
          ),
        ),
        if (contracts.isEmpty) const Text('표시할 계약서가 없습니다.'),
      ],
    );
  }

  Widget _buildReviewsTab(
    BuildContext context,
    int branchId,
    StaffManagementBlocState state,
  ) {
    final employeeId = state.selectedEmployeeId;
    final reviews = ((state.employeeDetail?['reviews'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('근무자 평가'),
        const SizedBox(height: 8),
        Text(
          employeeId == null
              ? '직원정보 탭에서 직원을 먼저 선택해주세요.'
              : '선택된 직원 ID: $employeeId',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _reviewRating,
          decoration: const InputDecoration(labelText: '평점 (1~3)'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1점')),
            DropdownMenuItem(value: 2, child: Text('2점')),
            DropdownMenuItem(value: 3, child: Text('3점')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _reviewRating = value);
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: '평가 코멘트 입력'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: employeeId == null
              ? null
              : () {
                  final comment = _reviewController.text.trim();
                  if (comment.isEmpty) return;
                  context.read<StaffManagementBloc>().add(
                        StaffManagementReviewCreated(
                          branchId: branchId,
                          employeeId: employeeId,
                          rating: _reviewRating,
                          comment: comment,
                        ),
                      );
                  _reviewController.clear();
                },
          child: const Text('평가 등록'),
        ),
        const SizedBox(height: 12),
        ...reviews.map(
          (review) {
            final reviewId = (review['review_id'] as num?)?.toInt();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title:
                    Text('${review['rating']}점 - ${review['author_name'] ?? '-'}'),
                subtitle: Text(review['comment']?.toString() ?? '-'),
                trailing: employeeId == null || reviewId == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context.read<StaffManagementBloc>().add(
                              StaffManagementReviewDeleted(
                                branchId: branchId,
                                employeeId: employeeId,
                                reviewId: reviewId,
                              ),
                            ),
                      ),
              ),
            );
          },
        ),
        if (reviews.isEmpty) const Text('등록된 평가가 없습니다.'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary),
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
