import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/models/user.dart';
import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import 'home_alerts_screen.dart';
import 'add_branch_screen.dart';
import 'manager_registration_screen.dart';
import 'recruitment_posting_detail_screen.dart';
import '../widgets/home_common_app_bar.dart';
import '../../account/account_routes.dart';
import '../widgets/home_shared_sections.dart';
import '../widgets/branch_select_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const String _registeredManagerIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
  <g clip-path="url(#clip0_2437_29560)">
    <path d="M15.4574 1.95801H4.54618C3.59251 1.95801 2.82031 2.73407 2.82031 3.68388V16.3171C2.82031 17.2707 3.59637 18.0429 4.54618 18.0429H15.4574C16.411 18.0429 17.1832 17.2669 17.1832 16.3171V3.68388C17.1832 2.73021 16.4072 1.95801 15.4574 1.95801ZM10.052 4.8499C11.4188 4.8499 12.5346 5.96187 12.5346 7.33253C12.5346 8.70318 11.4226 9.81515 10.052 9.81515C8.68132 9.81515 7.56935 8.70318 7.56935 7.33253C7.56935 5.96187 8.68132 4.8499 10.052 4.8499ZM13.8396 13.9271L13.7122 14.6221C13.6543 14.9271 13.3879 15.1511 13.079 15.1511H7.02108C6.70834 15.1511 6.44193 14.9271 6.38788 14.6221L6.26047 13.9271C6.12147 13.1742 6.3261 12.4059 6.81645 11.819C7.3068 11.2321 8.02495 10.8962 8.78942 10.8962H11.3107C12.0751 10.8962 12.7933 11.2321 13.2836 11.819C13.774 12.4059 13.9748 13.1742 13.8396 13.9271Z" fill="black"/>
  </g>
  <defs>
    <clipPath id="clip0_2437_29560">
      <rect width="20" height="20" fill="white"/>
    </clipPath>
  </defs>
</svg>
''';

/// 경영주/점장 공용 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenManagementTab,
    required this.onOpenLaborCostTab,
    required this.onOpenRecruitmentTab,
  });

  final VoidCallback onOpenManagementTab;
  final ValueChanged<int> onOpenLaborCostTab;
  final ValueChanged<int> onOpenRecruitmentTab;

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
              onAlarmTap: selectedBranch == null
                  ? null
                  : () => _openAlerts(
                      context,
                      branchId: selectedBranch.id,
                      role: user?.role,
                    ),
              onMenuTap: () => openAccountSettingsMenu(context),
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
            SizedBox(height: 14.h),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BranchSelectCard(
            selectedName: selectedBranch?.name,
            branches: branches
                .map((b) => (id: b.id, name: b.name, status: b.status))
                .toList(),
            isExpanded: _isBranchListExpanded,
            isOwner:
                user?.role == UserRole.manager ||
                user?.role == UserRole.storeManager,
            onHeaderTap: () {
              if (branches.isEmpty) return;
              setState(() => _isBranchListExpanded = !_isBranchListExpanded);
            },
            onBranchTap: (branchId) {
              context.read<SelectedBranchCubit>().select(branchId);
              _lastDetailRequestedBranchId = branchId;
              setState(() => _isBranchListExpanded = false);
            },
            onAddTap:
                (user?.role == UserRole.manager ||
                    user?.role == UserRole.storeManager)
                ? () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const AddBranchScreen(),
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
          SizedBox(height: 28.h),
          if (selectedBranch == null)
            _EmptyBranchView(hasBranches: branches.isNotEmpty)
          else
            _SelectedBranchOverview(
              role: user?.role,
              branchId: selectedBranch.id,
              branchName: selectedBranch.name,
              managerName:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.managerName
                  : selectedBranch.managerName,
              waitingInterview:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.waitingInterview
                  : selectedBranch.waitingInterview,
              newApplicants:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.newApplicants
                  : selectedBranch.newApplicants,
              newContacts:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail!.newContacts
                  : selectedBranch.newContacts,
              alertCount:
                  state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? selectedBranch.alertCount
                  : selectedBranch.alertCount,
              detail: state.selectedBranchDetail?.branchId == selectedBranch.id
                  ? state.selectedBranchDetail
                  : null,
              detailLoading: state.detailLoading,
              onTapTodayWorkerStatus: (row) =>
                  _showWorkStatusModal(context, row),
              onTapTodayWorkerMemo: (row) {
                final homeBloc = context.read<HomeBloc>();
                if ((row.memo ?? '').trim().isNotEmpty) {
                  _showMemoDetailModal(context, row, homeBloc: homeBloc);
                  return;
                }
                _showMemoModal(context, row, row.status, homeBloc: homeBloc);
              },
              onOpenManagementTab: widget.onOpenManagementTab,
              onOpenLaborCostTab: widget.onOpenLaborCostTab,
              onOpenRecruitmentTab: widget.onOpenRecruitmentTab,
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

  Future<void> _openAlerts(
    BuildContext context, {
    required int branchId,
    required UserRole? role,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HomeAlertsScreen(
          branchId: branchId,
          isOwner: role == UserRole.manager,
        ),
      ),
    );
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
                            homeBloc: homeBloc,
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
                              _saveTodayWorkerStatus(
                                homeBloc,
                                row: row,
                                status: selectedStatus,
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
    HomeWorkerRow row,
    String status, {
    required HomeBloc homeBloc,
  }) async {
    final controller = TextEditingController();
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
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 8.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(row.time, textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text(row.workerName, textAlign: TextAlign.start),
                      ),
                      const Expanded(
                        child: Center(
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.grey150,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.r),
                              border: status == '완료'
                                  ? null
                                  : Border.all(color: AppColors.primary),
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
                          _saveTodayWorkerStatus(
                            homeBloc,
                            row: row,
                            status: status,
                            memo: memoText,
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
    HomeWorkerRow row, {
    required HomeBloc homeBloc,
  }) async {
    final controller = TextEditingController(text: row.memo ?? '');
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
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 8.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(row.time, textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text(row.workerName, textAlign: TextAlign.start),
                      ),
                      const Expanded(
                        child: Center(
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.grey150,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.r),
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
                          _deleteTodayWorkerMemo(homeBloc, row: row);
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

  void _deleteTodayWorkerMemo(HomeBloc homeBloc, {required HomeWorkerRow row}) {
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
      padding: EdgeInsets.only(top: 56.h),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/png/home/market.png',
            width: 124,
            height: 124,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20.h),
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
    required this.onOpenManagementTab,
    required this.onOpenLaborCostTab,
    required this.onOpenRecruitmentTab,
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
  final VoidCallback onOpenManagementTab;
  final ValueChanged<int> onOpenLaborCostTab;
  final ValueChanged<int> onOpenRecruitmentTab;

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
        : const <
            ({
              HomeWorkerRow row,
              String time,
              String workerName,
              String status,
              bool hasMemo,
            })
          >[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (role == UserRole.manager) ...[
          _RegisteredManagerCard(
            managerName: managerName,
            onDetailTap: () => _openManagerRegistration(context),
          ),
          SizedBox(height: 24.h),
        ],
        _RecruitmentStatusCard(
          waitingInterview: waitingInterview,
          newApplicants: newApplicants,
          newContacts: newContacts,
          onTapWaitingInterviewDetail: () => _openRecruitmentStatusDetail(
            context,
            target: _RecruitmentHomeDetailTarget.posting,
          ),
          onTapNewApplicantsDetail: () => _openRecruitmentStatusDetail(
            context,
            target: _RecruitmentHomeDetailTarget.applicants,
          ),
          onTapNewContactsDetail: () => _openRecruitmentStatusDetail(
            context,
            target: _RecruitmentHomeDetailTarget.posting,
          ),
          onOpenRecruitment: _openRecruitment,
        ),
        SizedBox(height: 24.h),
        _TodayAlertCard(
          alertCount: alertCount,
          alertTitle: detail?.alertTitle,
          todayAlertTitles: detail?.todayAlertTitles ?? const [],
          onDetailTap: () => _openAlerts(context),
        ),
        SizedBox(height: 28.h),
        if (detailLoading)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Center(child: CircularProgressIndicator()),
          ),
        HomeTodayWorkersSection(
          dateLabel: detail?.dateLabel ?? _todayDateLabel(),
          onTapHeader: onOpenManagementTab,
          alwaysShowMemoIcon: true,
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
        SizedBox(height: 28.h),
        const Divider(height: 1, color: AppColors.grey50),
        SizedBox(height: 28.h),
        HomeMonthlyLaborCostCard(
          totalAmountText: detail?.expectedTotalAmountText ?? '총 - 원',
          changeText: detail?.expectedChangeText ?? '전월 대비 데이터가 없습니다',
          onDetailTap: _openLaborCost,
        ),
        SizedBox(height: 32.h),
        HomeLaborSavingPointCard(
          points: _buildSavingPointSpans(),
          onDetailTap: _openLaborSaving,
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
      return const [TextSpan(text: '절감 포인트 데이터가 없습니다.')];
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
      context.read<HomeBloc>().add(
        HomeBranchDetailRequested(branchId: branchId),
      );
      context.read<HomeBloc>().add(const HomeBranchesRequested());
    }
  }

  void _openRecruitment() {
    onOpenRecruitmentTab(2);
  }

  Future<void> _openAlerts(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HomeAlertsScreen(
          branchId: branchId,
          isOwner: role == UserRole.manager,
        ),
      ),
    );
  }

  void _openLaborCost() {
    onOpenLaborCostTab(0);
  }

  void _openLaborSaving() {
    onOpenLaborCostTab(2);
  }

  Future<void> _openRecruitmentStatusDetail(
    BuildContext context, {
    required _RecruitmentHomeDetailTarget target,
  }) async {
    final repo = context.read<ManagerHomeRepository>();
    final page = await repo.getMyRecruitmentPostings(
      branchId: branchId,
      pageSize: 50,
    );
    if (!context.mounted) return;

    final candidates = _candidateRecruitmentPostings(
      page.items,
      target: target,
    );
    if (candidates.isEmpty) {
      final message = target == _RecruitmentHomeDetailTarget.applicants
          ? '확인할 지원자 채용 공고가 없습니다.'
          : '열어볼 채용 공고가 없습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final selected = candidates.length == 1
        ? candidates.first
        : await _showRecruitmentPostingPicker(
            context,
            candidates,
            target: target,
          );
    if (selected == null || !context.mounted) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentPostingDetailScreen(
          branchId: branchId,
          postingId: selected.postingId,
          mineMode: true,
          initialTabIndex: target == _RecruitmentHomeDetailTarget.applicants
              ? 1
              : 0,
        ),
      ),
    );
    if (changed == true && context.mounted) {
      context.read<HomeBloc>().add(const HomeBranchesRequested());
      context.read<HomeBloc>().add(
        HomeBranchDetailRequested(branchId: branchId),
      );
    }
  }

  List<RecruitmentPostingSummary> _candidateRecruitmentPostings(
    List<RecruitmentPostingSummary> items, {
    required _RecruitmentHomeDetailTarget target,
  }) {
    final validItems = items.where((item) => item.postingId > 0).toList();
    final publishedItems = validItems.where((item) => !item.isDraft).toList();

    if (target == _RecruitmentHomeDetailTarget.applicants) {
      final applicantsItems = publishedItems
          .where((item) => item.applicantCount > 0)
          .toList();
      if (applicantsItems.isNotEmpty) return applicantsItems;
    }

    if (publishedItems.isNotEmpty) return publishedItems;

    if (target == _RecruitmentHomeDetailTarget.applicants) {
      final applicantsItems = validItems
          .where((item) => item.applicantCount > 0)
          .toList();
      if (applicantsItems.isNotEmpty) return applicantsItems;
    }

    return validItems;
  }

  Future<RecruitmentPostingSummary?> _showRecruitmentPostingPicker(
    BuildContext context,
    List<RecruitmentPostingSummary> items, {
    required _RecruitmentHomeDetailTarget target,
  }) {
    final title = target == _RecruitmentHomeDetailTarget.applicants
        ? '지원 현황을 볼 채용 공고를 선택해주세요.'
        : '열어볼 채용 공고를 선택해주세요.';

    return showModalBottomSheet<RecruitmentPostingSummary>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  title,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.grey50),
                    itemBuilder: (itemContext, index) {
                      final item = items[index];
                      final titleText = item.title?.trim().isNotEmpty == true
                          ? item.title!.trim()
                          : '제목 없는 채용 공고';
                      final subtitleParts = <String>[
                        if (item.companyName?.trim().isNotEmpty == true)
                          item.companyName!.trim(),
                        if (item.regionSummary?.trim().isNotEmpty == true)
                          item.regionSummary!.trim(),
                      ];
                      final trailingText =
                          target == _RecruitmentHomeDetailTarget.applicants
                          ? '지원자 ${item.applicantCount}명'
                          : (item.badgeLabel?.trim().isNotEmpty == true
                                ? item.badgeLabel!.trim()
                                : '공고 상세');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          titleText,
                          style: AppTypography.bodyMediumM.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: subtitleParts.isEmpty
                            ? null
                            : Text(
                                subtitleParts.join(' · '),
                                style: AppTypography.bodySmallR.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                        trailing: Text(
                          trailingText,
                          style: AppTypography.bodySmallM.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _RecruitmentHomeDetailTarget { posting, applicants }

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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary),
        color: AppColors.grey0,
      ),
      child: Row(
        children: [
          SvgPicture.string(
            _registeredManagerIconSvg,
            width: 20.w,
            height: 20.h,
          ),
          SizedBox(width: 10.w),
          Text(
            '등록된 점장',
            style: AppTypography.bodySmallM.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
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
    required this.onTapWaitingInterviewDetail,
    required this.onTapNewApplicantsDetail,
    required this.onTapNewContactsDetail,
    required this.onOpenRecruitment,
  });

  final int waitingInterview;
  final int newApplicants;
  final int newContacts;
  final VoidCallback onTapWaitingInterviewDetail;
  final VoidCallback onTapNewApplicantsDetail;
  final VoidCallback onTapNewContactsDetail;
  final VoidCallback onOpenRecruitment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
              SizedBox(width: 6.w),
              Text(
                '채용 현황',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _RecruitmentRow(
            label: '새로운 지원자 ',
            value: '$newApplicants명',
            onDetailTap: onTapNewApplicantsDetail,
            valueColor: const Color(0xFFFF453A),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey50),
              color: AppColors.grey0,
            ),
            child: TextButton(
              onPressed: onOpenRecruitment,
              style: TextButton.styleFrom(
                minimumSize: Size.fromHeight(46.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '열어보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.grey150,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  SizedBox(width: 6.w),
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
    this.valueColor = AppColors.primary,
  });

  final String label;
  final String value;
  final VoidCallback onDetailTap;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: value,
                  style: TextStyle(color: valueColor),
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
    required this.todayAlertTitles,
    required this.onDetailTap,
  });

  final int alertCount;
  final String? alertTitle;
  final List<String> todayAlertTitles;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    final visibleAlertTitles = todayAlertTitles
        .map((title) => title.trim())
        .where((title) => title.isNotEmpty)
        .toList();
    final fallbackText = alertTitle?.trim().isNotEmpty == true
        ? alertTitle!.trim()
        : (alertCount > 0 ? '주의 알림 $alertCount건' : '오늘 등록된 알림이 없습니다.');

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
              SizedBox(width: 6.w),
              Text(
                '오늘의 알림',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (visibleAlertTitles.isEmpty)
            Text(
              fallbackText,
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
              ),
            )
          else
            ...visibleAlertTitles.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleAlertTitles.length - 1 ? 0 : 10.h,
                ),
                child: _AlertSummaryRow(
                  title: entry.value,
                  onDetailTap: onDetailTap,
                ),
              ),
            ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey50),
              color: AppColors.grey0,
            ),
            child: TextButton(
              onPressed: onDetailTap,
              style: TextButton.styleFrom(
                minimumSize: Size.fromHeight(46.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '열어보기',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.grey150,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  SizedBox(width: 6.w),
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
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
          side: const BorderSide(color: AppColors.primary),
          backgroundColor: const Color(0xFFE2F6F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
        child: Center(
          child: Text(
            '상세 보기',
            textAlign: TextAlign.center,
            style: AppTypography.bodyXSmallM.copyWith(
              color: AppColors.primary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              height: 16 / 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertSummaryRow extends StatelessWidget {
  const _AlertSummaryRow({required this.title, required this.onDetailTap});

  final String title;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLargeM.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _OutlineDetailButton(onTap: onDetailTap),
      ],
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
