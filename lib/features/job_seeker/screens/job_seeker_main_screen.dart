import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/logo_navigation_bridge.dart';
import '../../../core/router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../manager/widgets/home_common_app_bar.dart';
import '../widgets/worker_applications_tab.dart';
import '../widgets/worker_contract_chat_tab.dart';
import '../widgets/worker_recruitment_postings_tab.dart';
import '../widgets/worker_resume_management_tab.dart';
import 'worker_my_page_screen.dart';

/// 근로자 메인 화면
/// 경영/점장과 별개의 상단 탭 구조를 사용한다.
class JobSeekerMainScreen extends StatefulWidget {
  const JobSeekerMainScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<JobSeekerMainScreen> createState() => _JobSeekerMainScreenState();
}

class _JobSeekerMainScreenState extends State<JobSeekerMainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;
  int _postingsRefreshToken = 0;
  int _applicationsRefreshToken = 0;
  int _resumeRefreshToken = 0;

  late final VoidCallback _logoTapHandler;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex.clamp(0, 3);
    _logoTapHandler = _onLogoGoToRecruitment;
    JobSeekerLogoNavigation.register(_logoTapHandler);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.index = _currentTabIndex;
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant JobSeekerMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTab = widget.initialTabIndex.clamp(0, 3);
    if (nextTab == _currentTabIndex) return;
    _tabController.animateTo(nextTab);
    setState(() => _currentTabIndex = nextTab);
  }

  void _onLogoGoToRecruitment() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    setState(() => _currentTabIndex = 0);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && _currentTabIndex != _tabController.index) {
      setState(() => _currentTabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    JobSeekerLogoNavigation.unregister(_logoTapHandler);
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleApplicationCreated() {
    setState(() {
      _postingsRefreshToken++;
      _applicationsRefreshToken++;
    });
  }

  void _handleResumeChanged() {
    setState(() {
      _resumeRefreshToken++;
    });
  }

  Future<void> _openMyPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const WorkerMyPageScreen()),
    );
  }

  void _showAlarmPlaceholder() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림 기능은 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser != null && !currentUser.role.isJobSeeker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRouter.managerMain);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.grey0,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: HomeCommonAppBar(
        alarmActive: false,
        onAlarmTap: _showAlarmPlaceholder,
        onMenuTap: _openMyPage,
      ),
      body: Column(
        children: [
          _WorkerTopTabs(
            selectedIndex: _currentTabIndex,
            onSelected: (index) {
              if (_currentTabIndex == index) return;
              _tabController.animateTo(index);
              setState(() => _currentTabIndex = index);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WorkerRecruitmentPostingsTab(
                  refreshToken: _postingsRefreshToken,
                  onApplicationCreated: _handleApplicationCreated,
                ),
                WorkerApplicationsTab(
                  refreshToken: _applicationsRefreshToken,
                  onApplicationCreated: _handleApplicationCreated,
                ),
                WorkerResumeManagementTab(
                  refreshToken: _resumeRefreshToken,
                  onResumeChanged: _handleResumeChanged,
                ),
                const WorkerContractChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerTopTabs extends StatelessWidget {
  const _WorkerTopTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = ['채용정보', '지원내역', '이력서관리', '계약채팅'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.grey0,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                _WorkerTopTabItem(
                  label: tabs[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerTopTabItem extends StatelessWidget {
  const _WorkerTopTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              width: selected ? 2 : 0,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyLargeB.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
