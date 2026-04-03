import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../manager/widgets/home_common_app_bar.dart';
import '../widgets/worker_applications_tab.dart';
import '../widgets/worker_contract_chat_tab.dart';
import '../widgets/worker_recruitment_postings_tab.dart';
import '../widgets/worker_resume_management_tab.dart';
import 'worker_my_page_screen.dart';

/// 근로자 메인 화면
/// 경영/점장과 별개의 상단 탭 구조를 사용한다.
class JobSeekerMainScreen extends StatefulWidget {
  const JobSeekerMainScreen({super.key});

  @override
  State<JobSeekerMainScreen> createState() => _JobSeekerMainScreenState();
}

class _JobSeekerMainScreenState extends State<JobSeekerMainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _postingsRefreshToken = 0;
  int _applicationsRefreshToken = 0;
  int _resumeRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: HomeCommonAppBar(
        alarmActive: false,
        onAlarmTap: _showAlarmPlaceholder,
        onMenuTap: _openMyPage,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.grey0,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
              indicatorColor: AppColors.textPrimary,
              indicatorWeight: 1,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: AppTypography.bodyLargeB,
              unselectedLabelStyle: AppTypography.bodyLargeB,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textTertiary,
              tabs: const [
                Tab(text: '채용정보'),
                Tab(text: '지원내역'),
                Tab(text: '이력서관리'),
                Tab(text: '계약채팅'),
              ],
            ),
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
