import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/logo_navigation_bridge.dart';
import '../../../core/router/app_router.dart';
import '../../../core/enums/user_role.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../data/repositories/owner_home_repository.dart';
import '../../../data/repositories/staff_management_repository.dart';
import '../../../data/repositories/store_expense_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/labor_cost_bloc.dart';
import '../bloc/recruitment_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import '../bloc/staff_management_bloc.dart';
import '../bloc/store_expense_bloc.dart';
import '../widgets/manager_bottom_bar.dart';
import 'home_screen.dart';
import 'labor_cost_screen.dart';
import 'management_screen.dart';
import 'recruitment_screen.dart';
import 'store_cost_screen.dart';

/// 경영자/점장 메인 화면
/// 바텀바로 5개 탭 전환
class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialLaborCostTabIndex = 0,
    this.initialRecruitmentTabIndex = 0,
  });

  final int initialTabIndex;
  final int initialLaborCostTabIndex;
  final int initialRecruitmentTabIndex;

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  late final VoidCallback _logoTapHandler;

  int _currentIndex = 0;
  int _laborCostInitialTabIndex = 0;
  int _laborCostNavigationRequestId = 0;
  int _recruitmentInitialTabIndex = 0;
  int _recruitmentNavigationRequestId = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, 4);
    _laborCostInitialTabIndex = widget.initialLaborCostTabIndex.clamp(0, 2);
    _recruitmentInitialTabIndex = widget.initialRecruitmentTabIndex.clamp(0, 2);
    _logoTapHandler = _onLogoGoHome;
    ManagerLogoNavigation.register(_logoTapHandler);
  }

  @override
  void dispose() {
    ManagerLogoNavigation.unregister(_logoTapHandler);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ManagerMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requestedTab = widget.initialTabIndex.clamp(0, 4);
    final requestedLaborCostTab = widget.initialLaborCostTabIndex.clamp(0, 2);
    final requestedRecruitmentTab = widget.initialRecruitmentTabIndex.clamp(
      0,
      2,
    );
    if (requestedTab == _currentIndex &&
        requestedLaborCostTab == _laborCostInitialTabIndex &&
        requestedRecruitmentTab == _recruitmentInitialTabIndex) {
      return;
    }

    setState(() {
      _currentIndex = requestedTab;
      _laborCostInitialTabIndex = requestedLaborCostTab;
      _recruitmentInitialTabIndex = requestedRecruitmentTab;
      _laborCostNavigationRequestId += 1;
      _recruitmentNavigationRequestId += 1;
    });
  }

  void _onLogoGoHome() {
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    setState(() => _currentIndex = 0);
  }

  bool _isPendingBranchStatus(String? status) {
    return (status ?? '').trim().toLowerCase() == 'pending';
  }

  bool _isSelectedBranchPendingFromState(
    int? selectedBranchId,
    HomeState homeState,
  ) {
    if (selectedBranchId == null) return false;

    for (final branch in homeState.ownerBranches) {
      if (branch.id == selectedBranchId) {
        return _isPendingBranchStatus(branch.reviewStatus);
      }
    }
    for (final branch in homeState.managerBranches) {
      if (branch.id == selectedBranchId) {
        return _isPendingBranchStatus(branch.reviewStatus);
      }
    }
    return false;
  }

  bool _isSelectedBranchPending(BuildContext context) {
    final selectedBranchId = context.read<SelectedBranchCubit>().state;
    final homeState = context.read<HomeBloc>().state;
    return _isSelectedBranchPendingFromState(selectedBranchId, homeState);
  }

  Future<void> _showHomeAccessDialog(
    BuildContext context, {
    required String title,
    required String description,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLargeB.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    height: 24 / 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '닫기',
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.grey0,
                        fontSize: 16,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPendingBranchAccessDialog(BuildContext context) async {
    await _showHomeAccessDialog(
      context,
      title: '점포 심사 대기 중이에요.',
      description:
          '직원관리, 인건비, 매장 비용, 구인·채용은\n승인 후 이용 가능합니다.',
    );
  }

  Future<void> _handleBottomTap(BuildContext context, int index) async {
    await _navigateToTab(context, index);
  }

  Future<void> _navigateToTab(
    BuildContext context,
    int index, {
    int? laborCostTabIndex,
    int? recruitmentTabIndex,
  }) async {
    if (index == _currentIndex &&
        laborCostTabIndex == null &&
        recruitmentTabIndex == null) {
      return;
    }

    final selectedBranchId = context.read<SelectedBranchCubit>().state;
    final requiresBranchSelection = index != 0;

    if (requiresBranchSelection && selectedBranchId == null) {
      await _showHomeAccessDialog(
        context,
        title: '매장을 먼저 선택해 주세요.',
        description:
            '직원관리, 인건비, 매장 비용, 구인·채용은\n'
            '홈에서 매장을 선택한 뒤 이용할 수 있어요.',
      );
      return;
    }

    if (index != 0 && _isSelectedBranchPending(context)) {
      await _showPendingBranchAccessDialog(context);
      return;
    }

    setState(() {
      _currentIndex = index;
      if (laborCostTabIndex != null) {
        _laborCostInitialTabIndex = laborCostTabIndex.clamp(0, 2);
        _laborCostNavigationRequestId += 1;
      }
      if (recruitmentTabIndex != null) {
        _recruitmentInitialTabIndex = recruitmentTabIndex.clamp(0, 2);
        _recruitmentNavigationRequestId += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser?.role.isJobSeeker == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRouter.jobSeekerMain);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }

    final ownerHomeRepo = context.read<OwnerHomeRepository>();
    final managerHomeRepo = context.read<ManagerHomeRepository>();
    final laborCostRepo = context.read<LaborCostRepository>();
    final storeExpenseRepo = context.read<StoreExpenseRepository>();
    final staffManagementRepo = context.read<StaffManagementRepository>();
    final isOwner = currentUser?.role == UserRole.manager;
    final userStorageKey = currentUser?.id ?? 'unknown';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SelectedBranchCubit(userId: userStorageKey),
        ),
        BlocProvider(
          create: (_) => HomeBloc(
            ownerHomeRepo,
            managerHomeRepo,
            laborCostRepo,
            staffManagementRepo,
            isOwner: isOwner,
          )..add(const HomeBranchesRequested()),
        ),
        BlocProvider(create: (_) => LaborCostBloc(laborCostRepo)),
        BlocProvider(create: (_) => StoreExpenseBloc(storeExpenseRepo)),
        BlocProvider(
          create: (_) => StaffManagementBloc(
            staffManagementRepo,
            managerHomeRepo,
            ownerHomeRepo,
            isOwner: isOwner,
          ),
        ),
        BlocProvider(create: (_) => RecruitmentBloc(managerHomeRepo)),
      ],
      child: Builder(
        builder: (context) {
          final selectedBranchId = context.select<SelectedBranchCubit, int?>(
            (cubit) => cubit.state,
          );
          final homeState = context.select<HomeBloc, HomeState>(
            (bloc) => bloc.state,
          );
          final selectedBranchPending = _isSelectedBranchPendingFromState(
            selectedBranchId,
            homeState,
          );
          if (selectedBranchPending && _currentIndex != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _currentIndex == 0) return;
              setState(() => _currentIndex = 0);
            });
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onOpenManagementTab: () => _navigateToTab(context, 1),
                  onOpenLaborCostTab: (tabIndex) =>
                      _navigateToTab(context, 2, laborCostTabIndex: tabIndex),
                  onOpenRecruitmentTab: (tabIndex) =>
                      _navigateToTab(context, 4, recruitmentTabIndex: tabIndex),
                ),
                const ManagementScreen(),
                LaborCostScreen(
                  initialTabIndex: _laborCostInitialTabIndex,
                  navigationRequestId: _laborCostNavigationRequestId,
                ),
                const StoreCostScreen(),
                RecruitmentScreen(
                  initialTabIndex: _recruitmentInitialTabIndex,
                  navigationRequestId: _recruitmentNavigationRequestId,
                ),
              ],
            ),
            bottomNavigationBar: ManagerBottomBar(
              currentIndex: _currentIndex,
              onTap: (index) => _handleBottomTap(context, index),
            ),
          );
        },
      ),
    );
  }
}
