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
    final requestedRecruitmentTab = widget.initialRecruitmentTabIndex.clamp(0, 2);
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
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
    setState(() => _currentIndex = 0);
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
      final moveHome =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('매장을 선택해주세요'),
                content: const Text(
                  '직원관리, 인건비, 매장·비용, 구인·채용 페이지는\n홈에서 매장을 선택한 뒤 이용할 수 있어요.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('닫기'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('홈으로 이동'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (moveHome && mounted) {
        setState(() => _currentIndex = 0);
      }
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
