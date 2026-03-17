import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/models/user.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import 'add_branch_screen.dart';
import 'manager_registration_screen.dart';
import '../widgets/home_common_app_bar.dart';
import '../widgets/home_shared_sections.dart';
import '../widgets/branch_select_card.dart';

/// 경영주/점장 공용 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBranchListExpanded = false;
  int? _lastDetailRequestedBranchId;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, User?>((b) => b.state.user);
    return BlocListener<SelectedBranchCubit, int?>(
      listener: (context, selectedBranchId) {
        if (selectedBranchId != null) {
          context.read<HomeBloc>().add(
                HomeBranchDetailRequested(branchId: selectedBranchId),
              );
        }
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final branchItems = _toBranchItems(state);
          final selectedBranchId = context.select<SelectedBranchCubit, int?>(
            (cubit) => cubit.state,
          );
          final selectedBranch = branchItems
              .where((b) => b.id == selectedBranchId)
              .cast<_BranchItem?>()
              .firstWhere((b) => b != null, orElse: () => null);

          if (selectedBranch != null &&
              !state.detailLoading &&
              state.selectedBranchDetail?.branchId != selectedBranch.id &&
              _lastDetailRequestedBranchId != selectedBranch.id) {
            _lastDetailRequestedBranchId = selectedBranch.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<HomeBloc>().add(
                    HomeBranchDetailRequested(branchId: selectedBranch.id),
                  );
            });
          }

          final hasAlarm = (selectedBranch?.alertCount ?? 0) > 0;

          return Scaffold(
            backgroundColor: AppColors.grey0,
            appBar: HomeCommonAppBar(
              alarmActive: hasAlarm,
              onAlarmTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 곧 연결됩니다.')),
                );
              },
              onMenuTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('메뉴 기능은 곧 연결됩니다.')),
                );
              },
            ),
            body: _buildBody(
              context: context,
              user: user,
              state: state,
              branches: branchItems,
              selectedBranch: selectedBranch,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required User? user,
    required HomeState state,
    required List<_BranchItem> branches,
    required _BranchItem? selectedBranch,
  }) {
    if (state.status == HomeStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == HomeStatus.failure) {
      return Center(
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
            const SizedBox(height: 14),
            TextButton(
              onPressed: () =>
                  context.read<HomeBloc>().add(const HomeBranchesRequested()),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BranchSelectCard(
            selectedName: selectedBranch?.name,
            branches: branches
                .map((b) => (id: b.id, name: b.name, status: b.status))
                .toList(),
            isExpanded: _isBranchListExpanded,
            isOwner: user?.role == UserRole.manager || user?.role == UserRole.storeManager,
            onHeaderTap: () {
              if (branches.isEmpty) return;
              setState(() => _isBranchListExpanded = !_isBranchListExpanded);
            },
            onBranchTap: (branchId) {
              context.read<SelectedBranchCubit>().select(branchId);
              _lastDetailRequestedBranchId = branchId;
              setState(() => _isBranchListExpanded = false);
            },
            onAddTap: (user?.role == UserRole.manager ||
                    user?.role == UserRole.storeManager)
                ? () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const AddBranchScreen(),
                      ),
                    );
                    if (changed == true && context.mounted) {
                      context.read<HomeBloc>().add(const HomeBranchesRequested());
                    }
                  }
                : null,
          ),
          const SizedBox(height: 28),
          if (selectedBranch == null)
            _EmptyBranchView(
              hasBranches: branches.isNotEmpty,
            )
          else
            _SelectedBranchOverview(
              role: user?.role,
              branchId: selectedBranch.id,
              branchName: selectedBranch.name,
              managerName: state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.managerName
                  : selectedBranch.managerName,
              waitingInterview:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                      ? state.selectedBranchDetail!.waitingInterview
                      : selectedBranch.waitingInterview,
              newApplicants: state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.newApplicants
                  : selectedBranch.newApplicants,
              newContacts: state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.newContacts
                  : selectedBranch.newContacts,
              alertCount: state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? selectedBranch.alertCount
                  : selectedBranch.alertCount,
              detail:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                      ? state.selectedBranchDetail
                      : null,
              detailLoading: state.detailLoading,
              onTapTodayWorkerStatus: (row) => _showWorkStatusModal(context, row),
              onTapTodayWorkerMemo: (row) => _showMemoDetailModal(
                context,
                row,
                homeBloc: context.read<HomeBloc>(),
              ),
            ),
        ],
      ),
    );
  }

  List<_BranchItem> _toBranchItems(HomeState state) {
    if (state.ownerBranches.isNotEmpty) {
      return state.ownerBranches
          .map(
            (b) => _BranchItem(
              id: b.id,
              name: b.name,
              status: b.reviewStatus,
              managerName: b.manager?.fullName ?? '',
              waitingInterview: 0,
              newApplicants: 0,
              newContacts: 0,
              alertCount: 0,
              workerCount: 0,
            ),
          )
          .toList();
    }
    return state.managerBranches
        .map(
          (b) => _BranchItem(
            id: b.id,
            name: b.name,
            status: b.reviewStatus,
            managerName: '',
            waitingInterview: b.recruitment?.waitingInterviews ?? 0,
            newApplicants: b.recruitment?.newApplicants ?? 0,
            newContacts: b.recruitment?.newContacts ?? 0,
            alertCount: b.openAlertCount,
            workerCount: b.todayWorkerCount,
          ),
        )
        .toList();
  }

  Future<void> _showWorkStatusModal(
    BuildContext context,
    HomeWorkerRow row,
  ) async {
    final homeBloc = context.read<HomeBloc>();
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
                            homeBloc: homeBloc,
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
                              _saveTodayWorkerStatus(
                                homeBloc,
                                row: row,
                                status: selectedStatus,
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
    HomeWorkerRow row,
    String status,
    {required HomeBloc homeBloc}
  ) async {
    final controller = TextEditingController();
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
                      Expanded(child: Text('근무자', textAlign: TextAlign.center)),
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
                      Expanded(child: Text(row.workerName, textAlign: TextAlign.center)),
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.edit_outlined, color: AppColors.grey150),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  status == '완료' ? null : Border.all(color: AppColors.primary),
                              color: status == '완료'
                                  ? const Color(0xFF666874)
                                  : AppColors.primaryLight,
                            ),
                            child: Text(
                              status == '근무완료' || status == '완료' ? '완료' : '예정',
                              style: AppTypography.bodySmallB.copyWith(
                                color: status == '근무완료' || status == '완료'
                                    ? AppColors.grey0
                                    : AppColors.primary,
                              ),
                            ),
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
                          _saveTodayWorkerStatus(
                            homeBloc,
                            row: row,
                            status: status,
                            memo: memoText,
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
    HomeWorkerRow row, {
    required HomeBloc homeBloc,
  }) async {
    final controller = TextEditingController(text: row.memo ?? '');
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
                      Expanded(child: Text('근무자', textAlign: TextAlign.center)),
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
                      Expanded(child: Text(row.workerName, textAlign: TextAlign.center)),
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.edit_outlined, color: AppColors.grey150),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: _displayStatusLabel(row.status) == '완료'
                                  ? null
                                  : Border.all(color: AppColors.primary),
                              color: _displayStatusLabel(row.status) == '완료'
                                  ? const Color(0xFF666874)
                                  : AppColors.primaryLight,
                            ),
                            child: Text(
                              _displayStatusLabel(row.status),
                              style: AppTypography.bodySmallB.copyWith(
                                color: _displayStatusLabel(row.status) == '완료'
                                    ? AppColors.grey0
                                    : AppColors.primary,
                              ),
                            ),
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
                          _deleteTodayWorkerMemo(homeBloc, row: row);
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

  void _saveTodayWorkerStatus(
    HomeBloc homeBloc, {
    required HomeWorkerRow row,
    required String status,
    String? memo,
  }) {
    final detail = homeBloc.state.selectedBranchDetail;
    if (detail == null) return;
    homeBloc.add(
          HomeWorkerStatusSaveRequested(
            branchId: detail.branchId,
            workDate: detail.workDate,
            timeLabel: row.time,
            workerName: row.workerName,
            status: status,
            memo: (memo != null && memo.isNotEmpty) ? memo : null,
          ),
        );
  }

  void _deleteTodayWorkerMemo(
    HomeBloc homeBloc, {
    required HomeWorkerRow row,
  }) {
    final detail = homeBloc.state.selectedBranchDetail;
    if (detail == null) return;
    homeBloc.add(
      HomeWorkerMemoDeleteRequested(
        branchId: detail.branchId,
        workDate: detail.workDate,
        timeLabel: row.time,
        workerName: row.workerName,
        status: row.status,
        statusId: row.statusId,
      ),
    );
  }

  String _displayStatusLabel(String status) {
    if (status == '완료' || status == '근무완료') return '완료';
    if (status == '예정' || status == '근무예정') return '예정';
    return status;
  }
}

class _EmptyBranchView extends StatelessWidget {
  const _EmptyBranchView({required this.hasBranches});

  final bool hasBranches;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/png/home/market.png',
            width: 124,
            height: 124,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            hasBranches ? '점포를 선택해주세요!' : '등록된 점포가 없습니다.',
            style: AppTypography.bodyLargeM.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedBranchOverview extends StatelessWidget {
  const _SelectedBranchOverview({
    required this.role,
    required this.branchId,
    required this.branchName,
    required this.managerName,
    required this.waitingInterview,
    required this.newApplicants,
    required this.newContacts,
    required this.alertCount,
    required this.detail,
    required this.detailLoading,
    required this.onTapTodayWorkerStatus,
    required this.onTapTodayWorkerMemo,
  });

  final UserRole? role;
  final int branchId;
  final String branchName;
  final String managerName;
  final int waitingInterview;
  final int newApplicants;
  final int newContacts;
  final int alertCount;
  final HomeBranchDetail? detail;
  final bool detailLoading;
  final void Function(HomeWorkerRow row) onTapTodayWorkerStatus;
  final void Function(HomeWorkerRow row) onTapTodayWorkerMemo;

  @override
  Widget build(BuildContext context) {
    final workerRows = detail != null
        ? detail!.rows
            .map(
              (row) => (
                row: row,
                time: row.time,
                workerName: row.workerName,
                status: row.status,
                hasMemo: (row.memo ?? '').trim().isNotEmpty,
              ),
            )
            .toList()
        : const <({
            HomeWorkerRow row,
            String time,
            String workerName,
            String status,
            bool hasMemo,
          })>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegisteredManagerCard(
          managerName: managerName,
          onDetailTap: () => _openManagerRegistration(context),
        ),
        const SizedBox(height: 24),
        _RecruitmentStatusCard(
          waitingInterview: waitingInterview,
          newApplicants: newApplicants,
          newContacts: newContacts,
          onDetailTap: () {},
        ),
        const SizedBox(height: 24),
        _TodayAlertCard(
          alertCount: alertCount,
          alertTitle: detail?.alertTitle,
          onDetailTap: () {},
        ),
        const SizedBox(height: 28),
        if (detailLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        HomeTodayWorkersSection(
          dateLabel: detail?.dateLabel ?? _todayDateLabel(),
          rows: workerRows
              .map(
                (e) => (
                  time: e.time,
                  workerName: e.workerName,
                  status: e.status,
                  hasMemo: e.hasMemo,
                ),
              )
              .toList(),
          onTapMemo: workerRows.isEmpty
              ? null
              : (index, row) {
                  if (index >= 0 && index < workerRows.length) {
                    onTapTodayWorkerMemo(workerRows[index].row);
                  }
                },
          onTapStatus: workerRows.isEmpty
              ? null
              : (index, row) {
                  if (index >= 0 && index < workerRows.length) {
                    onTapTodayWorkerStatus(workerRows[index].row);
                  }
                },
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, color: AppColors.grey50),
        const SizedBox(height: 28),
        HomeMonthlyLaborCostCard(
          totalAmountText: detail?.expectedTotalAmountText ?? '총 - 원',
          changeText: detail?.expectedChangeText ?? '전월 대비 데이터가 없습니다',
        ),
        const SizedBox(height: 32),
        HomeLaborSavingPointCard(
          points: _buildSavingPointSpans(),
        ),
      ],
    );
  }

  String _todayDateLabel() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}.$mm.$dd($weekday)';
  }

  List<TextSpan> _buildSavingPointSpans() {
    final raw = detail?.savingPointTexts ?? const [];
    if (raw.isEmpty) {
      return const [
        TextSpan(text: '절감 포인트 데이터가 없습니다.'),
      ];
    }
    return raw.map((e) => TextSpan(text: e)).toList();
  }

  Future<void> _openManagerRegistration(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManagerRegistrationScreen(branchId: branchId),
      ),
    );
    if (changed == true && context.mounted) {
      context.read<HomeBloc>().add(HomeBranchDetailRequested(branchId: branchId));
      context.read<HomeBloc>().add(const HomeBranchesRequested());
    }
  }
}

class _RegisteredManagerCard extends StatelessWidget {
  const _RegisteredManagerCard({
    required this.managerName,
    required this.onDetailTap,
  });

  final String managerName;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
        color: AppColors.grey0Alt,
      ),
      child: Row(
        children: [
          const Icon(Icons.account_box_outlined, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(
            '등록된 점장',
            style: AppTypography.bodySmallM.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
            ),
          ),
          _OutlineDetailButton(onTap: onDetailTap),
        ],
      ),
    );
  }
}

class _RecruitmentStatusCard extends StatelessWidget {
  const _RecruitmentStatusCard({
    required this.waitingInterview,
    required this.newApplicants,
    required this.newContacts,
    required this.onDetailTap,
  });

  final int waitingInterview;
  final int newApplicants;
  final int newContacts;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.grey0Alt,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/png/common/find_person_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                '채용 현황',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RecruitmentRow(
            label: '구인게시물 ',
            value: '${waitingInterview}건',
            onDetailTap: onDetailTap,
          ),
          const SizedBox(height: 8),
          _RecruitmentRow(
            label: '새로운 지원자 ',
            value: '${newApplicants}명',
            onDetailTap: onDetailTap,
          ),
          const SizedBox(height: 8),
          _RecruitmentRow(
            label: '새로운 연락 ',
            value: '${newContacts}건',
            onDetailTap: onDetailTap,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey50),
              color: AppColors.grey0,
            ),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '열어보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.grey150,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    'assets/icons/svg/icon/chevron_down_grey_14.svg',
                    width: 14,
                    height: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecruitmentRow extends StatelessWidget {
  const _RecruitmentRow({
    required this.label,
    required this.value,
    required this.onDetailTap,
  });

  final String label;
  final String value;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        _OutlineDetailButton(onTap: onDetailTap),
      ],
    );
  }
}

class _TodayAlertCard extends StatelessWidget {
  const _TodayAlertCard({
    required this.alertCount,
    required this.alertTitle,
    required this.onDetailTap,
  });

  final int alertCount;
  final String? alertTitle;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.grey0Alt,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/png/common/alarm_black_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                '오늘의 알림',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alertTitle ??
                (alertCount > 0 ? '주의 알림 ${alertCount}건' : '퇴직금 발생'),
            style: AppTypography.bodyLargeM.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey50),
              color: AppColors.grey0,
            ),
            child: TextButton(
              onPressed: onDetailTap,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '열어보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.grey150,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    'assets/icons/svg/icon/chevron_down_grey_14.svg',
                    width: 14,
                    height: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineDetailButton extends StatelessWidget {
  const _OutlineDetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(78, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
          side: const BorderSide(color: AppColors.primary),
          backgroundColor: const Color(0xFFE2F6F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Center(
          child: Text(
            '상세보기',
            textAlign: TextAlign.center,
            style: AppTypography.bodyXSmallM.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 16 / 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchItem {
  const _BranchItem({
    required this.id,
    required this.name,
    required this.status,
    required this.managerName,
    required this.waitingInterview,
    required this.newApplicants,
    required this.newContacts,
    required this.alertCount,
    required this.workerCount,
  });

  final int id;
  final String name;
  final String? status;
  final String managerName;
  final int waitingInterview;
  final int newApplicants;
  final int newContacts;
  final int alertCount;
  final int workerCount;
}
