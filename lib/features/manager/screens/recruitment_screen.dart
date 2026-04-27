import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/hierarchical_region_picker_sheet.dart';
import '../../../widgets/recruitment_region_picker_sheet.dart';
import '../../account/account_routes.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../bloc/home_bloc.dart';
import '../bloc/recruitment_bloc.dart';
import '../bloc/selected_branch_cubit.dart';
import '../widgets/home_common_app_bar.dart';
import 'recruitment_job_seeker_detail_screen.dart';
import 'recruitment_posting_list_tab.dart';
import '../widgets/manager_recruitment_inquiry_chat_tab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const String _recentViewedHeaderIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none">
  <g clip-path="url(#clip0_2691_3742)">
    <path d="M7.26179 12.5822C10.2778 12.5822 12.7228 10.1372 12.7228 7.12116C12.7228 4.10513 10.2778 1.66016 7.26179 1.66016C4.24576 1.66016 1.80078 4.10513 1.80078 7.12116C1.80078 10.1372 4.24576 12.5822 7.26179 12.5822Z" fill="black"/>
    <path d="M7.26026 13.0448C3.9954 13.0448 1.33594 10.3884 1.33594 7.12045C1.33594 3.8525 3.9954 1.19922 7.26026 1.19922C10.5251 1.19922 13.1846 3.85559 13.1846 7.12354C13.1846 10.3915 10.5282 13.0479 7.26026 13.0479V13.0448ZM7.26026 2.12586C4.50505 2.12586 2.26258 4.36833 2.26258 7.12354C2.26258 9.87876 4.50505 12.1212 7.26026 12.1212C10.0155 12.1212 12.2579 9.87876 12.2579 7.12354C12.2579 4.36833 10.0155 2.12586 7.26026 2.12586Z" fill="black"/>
    <path d="M14.1482 14.4697C14.0308 14.4697 13.9103 14.4234 13.8208 14.3338L10.7968 11.3099C10.6146 11.1276 10.6146 10.8342 10.7968 10.6551C10.9791 10.4759 11.2725 10.4728 11.4517 10.6551L14.4756 13.679C14.6578 13.8612 14.6578 14.1547 14.4756 14.3338C14.386 14.4234 14.2656 14.4697 14.1482 14.4697Z" fill="black"/>
    <path d="M7.26144 7.24162C8.23209 7.24162 9.01896 6.45475 9.01896 5.48409C9.01896 4.51343 8.23209 3.72656 7.26144 3.72656C6.29078 3.72656 5.50391 4.51343 5.50391 5.48409C5.50391 6.45475 6.29078 7.24162 7.26144 7.24162Z" fill="white"/>
    <path d="M7.25991 7.70342C6.03675 7.70342 5.03906 6.70573 5.03906 5.48257C5.03906 4.2594 6.03675 3.26172 7.25991 3.26172C8.48308 3.26172 9.48076 4.25631 9.48076 5.48257C9.48076 6.70882 8.48617 7.70342 7.25991 7.70342ZM7.25991 4.18836C6.5464 4.18836 5.9657 4.76905 5.9657 5.48257C5.9657 6.19608 6.5464 6.77678 7.25991 6.77678C7.97343 6.77678 8.55412 6.19608 8.55412 5.48257C8.55412 4.76905 7.97343 4.18836 7.25991 4.18836Z" fill="black"/>
    <path d="M7.8618 7.24219H6.66335C5.41547 7.24219 4.40234 8.25531 4.40234 9.50319C4.40234 9.56188 4.43014 9.62057 4.47956 9.65454C5.27339 10.1982 6.22783 10.5194 7.26258 10.5194C8.29732 10.5194 9.25485 10.1982 10.0456 9.65454C10.095 9.62057 10.1228 9.56497 10.1228 9.50319C10.1228 8.25531 9.10968 7.24219 7.8618 7.24219Z" fill="white"/>
    <path d="M7.26105 10.9812C6.1707 10.9812 5.11742 10.6538 4.21549 10.0329C4.03943 9.91248 3.9375 9.7148 3.9375 9.50167C3.9375 8.00051 5.16067 6.77734 6.66182 6.77734H7.86028C9.36144 6.77734 10.5846 8.00051 10.5846 9.50167C10.5846 9.7148 10.4796 9.91248 10.3066 10.0329C9.40468 10.6538 8.3514 10.9812 7.26105 10.9812ZM4.87032 9.35341C5.58692 9.81055 6.41163 10.0515 7.26105 10.0515C8.11047 10.0515 8.93518 9.81055 9.65179 9.35341C9.57765 8.42985 8.80237 7.7009 7.86028 7.7009H6.66182C5.71974 7.7009 4.94445 8.42985 4.87032 9.35341Z" fill="black"/>
  </g>
  <defs>
    <clipPath id="clip0_2691_3742">
      <rect width="16" height="16" fill="white"/>
    </clipPath>
  </defs>
</svg>
''';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({
    super.key,
    this.initialTabIndex = 0,
    this.navigationRequestId = 0,
  });

  final int initialTabIndex;
  final int navigationRequestId;

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen>
    with SingleTickerProviderStateMixin {
  static const int _minimumRecruitmentAge = 14;
  static const int _maximumRecruitmentAge = 99;
  static const int _recruitmentPageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  late final TabController _tabController;

  int _selectedTabIndex = 0;
  int? _lastRequestedBranchId;
  String? _gender;
  int? _ageMin;
  int? _ageMax;
  List<String> _regions = const [];
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _homeScrollController.addListener(_onHomeScrolled);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    }
  }

  void _onHomeScrolled() {
    if (_selectedTabIndex != 0 || !_homeScrollController.hasClients) return;
    if (_homeScrollController.position.extentAfter > 360) return;

    final branchId = context.read<SelectedBranchCubit>().state;
    if (branchId == null) return;

    _requestNextHomePage(branchId);
  }

  void _requestNextHomePage(int branchId, {bool force = false}) {
    final state = context.read<RecruitmentBloc>().state;
    if (state.branchId != branchId ||
        !state.hasMoreSearchResults ||
        state.isLoadingMore ||
        (!force && state.paginationErrorMessage != null) ||
        state.status == RecruitmentBlocStatus.loading) {
      return;
    }

    _requestHome(branchId, page: (state.homeData?.page ?? 1) + 1, append: true);
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onHomeScrolled);
    _homeScrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RecruitmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationRequestId != widget.navigationRequestId ||
        oldWidget.initialTabIndex != widget.initialTabIndex) {
      final nextIndex = widget.initialTabIndex.clamp(0, 3);
      if (_selectedTabIndex != nextIndex) {
        setState(() => _selectedTabIndex = nextIndex);
        _tabController.animateTo(nextIndex);
      }
    }
  }

  void _requestHome(int branchId, {int page = 1, bool append = false}) {
    final (ageMin, ageMax) = _sanitizedAgeRange(_ageMin, _ageMax);
    _lastRequestedBranchId = branchId;
    context.read<RecruitmentBloc>().add(
      RecruitmentHomeRequested(
        branchId: branchId,
        keyword: _searchController.text.trim(),
        gender: _gender,
        ageMin: ageMin,
        ageMax: ageMax,
        regions: _regions.isEmpty ? null : _regions,
        minRating: _minRating,
        searchAllWorkers: true,
        append: append,
        page: page,
        pageSize: _recruitmentPageSize,
      ),
    );
  }

  void _refreshCurrentBranch() {
    final branchId = context.read<SelectedBranchCubit>().state;
    if (branchId != null) {
      _requestHome(branchId);
    }
  }

  Future<void> _openProfile(
    int branchId,
    int employeeId, {
    int? workerUserId,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RecruitmentJobSeekerDetailScreen(
          branchId: branchId,
          employeeId: employeeId,
          workerUserId: workerUserId,
        ),
      ),
    );
    if (changed == true && mounted) {
      _requestHome(branchId);
    }
  }

  Future<void> _showGenderSheet() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Widget option({required String title, required String? value}) {
          final selected = _gender == value;
          return ListTile(
            title: Text(
              title,
              style: AppTypography.bodyMediumR.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primaryDark)
                : null,
            onTap: () => Navigator.of(context).pop(value ?? '__clear__'),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 12.h),
              option(title: '전체', value: null),
              option(title: '남', value: 'male'),
              option(title: '여', value: 'female'),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _gender = result == '__clear__' ? null : result;
    });
    _refreshCurrentBranch();
  }

  Future<void> _showAgeDialog() async {
    final minController = TextEditingController(
      text: _ageMin?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _ageMax?.toString() ?? '',
    );

    final applied = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: AppColors.grey0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '연령 설정',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24.h),
                AuthInputField(
                  controller: minController,
                  hintText: '최소 연령',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
                SizedBox(height: 12.h),
                AuthInputField(
                  controller: maxController,
                  hintText: '최대 연령',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(48.h),
                          backgroundColor: AppColors.grey0,
                          foregroundColor: AppColors.textTertiary,
                          side: const BorderSide(color: AppColors.grey50),
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
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          minController.clear();
                          maxController.clear();
                          Navigator.of(dialogContext).pop(true);
                        },
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
                          '초기화',
                          style: AppTypography.bodyMediumM.copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final min = _parseAgeValue(minController.text);
                          final max = _parseAgeValue(maxController.text);
                          final message = _ageValidationMessage(min, max);
                          if (message != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                            return;
                          }
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(48.h),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '적용',
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

    if (!mounted || applied != true) return;
    setState(() {
      _ageMin = _parseAgeValue(minController.text);
      _ageMax = _parseAgeValue(maxController.text);
    });
    _refreshCurrentBranch();
  }

  Future<void> _showRegionSheet() async {
    final next = await showHierarchicalRegionPicker(
      context,
      initialSelections: _regions,
      maxSelections: 5,
    );
    if (!mounted || next == null) return;
    if (listEquals(next, _regions)) return;
    setState(() => _regions = List<String>.from(next));
    _refreshCurrentBranch();
  }

  Future<void> _showRatingSheet() async {
    final result = await showModalBottomSheet<double?>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 12.h),
              ListTile(
                title: const Text('전체'),
                trailing: _minRating == null
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryDark,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(-1.0),
              ),
              for (final value in [1, 2, 3])
                ListTile(
                  title: Text('$value점 이상'),
                  trailing: _minRating == value.toDouble()
                      ? Icon(Icons.check_rounded, color: AppColors.primaryDark)
                      : null,
                  onTap: () => Navigator.of(context).pop(value.toDouble()),
                ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _minRating = result < 0 ? null : result;
    });
    _refreshCurrentBranch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: HomeCommonAppBar(
        alarmActive: false,
        onAlarmTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('알림 기능은 곧 연결됩니다.')));
        },
        onMenuTap: () => openAccountSettingsMenu(context),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
            tabAlignment: TabAlignment.start,
            dividerColor: AppColors.grey25,
            dividerHeight: 1,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle: AppTypography.bodyLargeB,
            unselectedLabelStyle: AppTypography.bodyLargeB,
            indicatorColor: AppColors.textPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 1,
            isScrollable: true,
            tabs: const [
              Tab(text: '채용 홈'),
              Tab(text: '채용 게시판'),
              Tab(text: '내 채용 게시글'),
              Tab(text: '채팅'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BlocConsumer<SelectedBranchCubit, int?>(
                  listener: (context, branchId) {
                    if (branchId != null) {
                      _requestHome(branchId);
                    }
                  },
                  builder: (context, branchId) {
                    if (branchId == null) {
                      return Center(
                        child: Text(
                          '지점을 선택해주세요.\n홈 탭에서 지점을 먼저 선택해주세요.',
                          style: AppTypography.bodyMediumR.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return BlocBuilder<RecruitmentBloc, RecruitmentBlocState>(
                      builder: (context, state) {
                        if (state.branchId != branchId &&
                            state.status != RecruitmentBlocStatus.loading &&
                            _lastRequestedBranchId != branchId) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _requestHome(branchId);
                            }
                          });
                        }

                        return _RecruitmentHomeTab(
                          state: state,
                          scrollController: _homeScrollController,
                          searchController: _searchController,
                          genderLabel: _genderLabel,
                          ageLabel: _ageLabel,
                          regionLabel: _regionLabel,
                          ratingLabel: _ratingLabel,
                          onSubmittedSearch: _refreshCurrentBranch,
                          onTapGender: _showGenderSheet,
                          onTapAge: _showAgeDialog,
                          onTapRegion: _showRegionSheet,
                          onTapRating: _showRatingSheet,
                          onRetry: () => _requestHome(branchId),
                          onRetryLoadMore: () =>
                              _requestNextHomePage(branchId, force: true),
                          onTapProfile: (employeeId, {workerUserId}) =>
                              _openProfile(
                                branchId,
                                employeeId,
                                workerUserId: workerUserId,
                              ),
                        );
                      },
                    );
                  },
                ),
                BlocBuilder<SelectedBranchCubit, int?>(
                  builder: (context, branchId) {
                    if (branchId == null) {
                      return const _TabPlaceholderView(title: '지점을 선택해주세요.');
                    }
                    final branchName = _selectedBranchName(context, branchId);
                    return RecruitmentPostingListTab(
                      branchId: branchId,
                      branchName: branchName,
                      mine: false,
                      refreshTick: 0,
                    );
                  },
                ),
                BlocBuilder<SelectedBranchCubit, int?>(
                  builder: (context, branchId) {
                    if (branchId == null) {
                      return const _TabPlaceholderView(title: '지점을 선택해주세요.');
                    }
                    final branchName = _selectedBranchName(context, branchId);
                    return RecruitmentPostingListTab(
                      branchId: branchId,
                      branchName: branchName,
                      mine: true,
                      refreshTick: 0,
                    );
                  },
                ),
                const ManagerRecruitmentInquiryChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _genderLabel {
    switch (_gender) {
      case 'male':
        return '남';
      case 'female':
        return '여';
      default:
        return '성별';
    }
  }

  String get _ageLabel {
    if (_ageMin == null && _ageMax == null) return '연령';
    if (_ageMin != null && _ageMax != null) return '${_ageMin!}-${_ageMax!}세';
    if (_ageMin != null) return '${_ageMin!}세 이상';
    return '${_ageMax!}세 이하';
  }

  String get _regionLabel => regionFilterPillLabel(_regions);

  String get _ratingLabel {
    if (_minRating == null) return '평점';
    final isInt = _minRating! % 1 == 0;
    final value = isInt
        ? _minRating!.toStringAsFixed(0)
        : _minRating!.toStringAsFixed(1);
    return '$value점+';
  }

  int? _parseAgeValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String? _ageValidationMessage(int? min, int? max) {
    if (min != null &&
        (min < _minimumRecruitmentAge || min > _maximumRecruitmentAge)) {
      return '최소 연령은 $_minimumRecruitmentAge세 이상 $_maximumRecruitmentAge세 이하로 입력해주세요.';
    }
    if (max != null &&
        (max < _minimumRecruitmentAge || max > _maximumRecruitmentAge)) {
      return '최대 연령은 $_minimumRecruitmentAge세 이상 $_maximumRecruitmentAge세 이하로 입력해주세요.';
    }
    if (min != null && max != null && min > max) {
      return '최소 연령은 최대 연령보다 클 수 없습니다.';
    }
    return null;
  }

  (int?, int?) _sanitizedAgeRange(int? min, int? max) {
    if (_ageValidationMessage(min, max) != null) {
      return (null, null);
    }
    return (min, max);
  }

  String _selectedBranchName(BuildContext context, int branchId) {
    final state = context.read<HomeBloc>().state;
    for (final branch in state.managerBranches) {
      if (branch.id == branchId) return branch.name;
    }
    for (final branch in state.ownerBranches) {
      if (branch.id == branchId) return branch.name;
    }
    return '';
  }
}

class _RecruitmentHomeTab extends StatelessWidget {
  const _RecruitmentHomeTab({
    required this.state,
    required this.scrollController,
    required this.searchController,
    required this.genderLabel,
    required this.ageLabel,
    required this.regionLabel,
    required this.ratingLabel,
    required this.onSubmittedSearch,
    required this.onTapGender,
    required this.onTapAge,
    required this.onTapRegion,
    required this.onTapRating,
    required this.onRetry,
    required this.onRetryLoadMore,
    required this.onTapProfile,
  });

  final RecruitmentBlocState state;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final String genderLabel;
  final String ageLabel;
  final String regionLabel;
  final String ratingLabel;
  final VoidCallback onSubmittedSearch;
  final VoidCallback onTapGender;
  final VoidCallback onTapAge;
  final VoidCallback onTapRegion;
  final VoidCallback onTapRating;
  final VoidCallback onRetry;
  final VoidCallback onRetryLoadMore;
  final void Function(int employeeId, {int? workerUserId}) onTapProfile;

  @override
  Widget build(BuildContext context) {
    if (state.status == RecruitmentBlocStatus.loading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == RecruitmentBlocStatus.failure && !state.hasData) {
      return _RecruitmentErrorView(
        message: state.errorMessage ?? '오류가 발생했습니다.',
        onRetry: onRetry,
      );
    }

    final data = state.homeData;
    if (data == null) {
      return const Center(child: Text('데이터가 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (state.status == RecruitmentBlocStatus.loading &&
              !state.isLoadingMore)
            const LinearProgressIndicator(
              minHeight: 1,
              color: AppColors.primary,
              backgroundColor: AppColors.grey25,
            ),
          _RecentViewedSection(
            items: data.recentViewedJobSeekers,
            onTapProfile: onTapProfile,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
            child: _RecruitmentSearchField(
              controller: searchController,
              onSubmitted: (_) => onSubmittedSearch(),
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                RecruitmentFilterPill(
                  label: genderLabel,
                  active: genderLabel != '성별',
                  onTap: onTapGender,
                ),
                SizedBox(width: 8.w),
                RecruitmentFilterPill(
                  label: ageLabel,
                  active: ageLabel != '연령',
                  onTap: onTapAge,
                ),
                SizedBox(width: 8.w),
                RecruitmentFilterPill(
                  label: regionLabel,
                  active: regionLabel != '전체',
                  onTap: onTapRegion,
                ),
                SizedBox(width: 8.w),
                RecruitmentFilterPill(
                  label: ratingLabel,
                  active: ratingLabel != '평점',
                  onTap: onTapRating,
                ),
              ],
            ),
          ),
          if (state.status == RecruitmentBlocStatus.failure)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0.h),
              child: Text(
                state.errorMessage ?? '검색 결과를 새로 불러오지 못했습니다.',
                style: AppTypography.bodySmallR.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            child: _SearchResultsSection(
              items: data.searchResults,
              isLoadingMore: state.isLoadingMore,
              loadMoreErrorMessage: state.paginationErrorMessage,
              onRetryLoadMore: onRetryLoadMore,
              onTapProfile: onTapProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentViewedSection extends StatelessWidget {
  const _RecentViewedSection({required this.items, required this.onTapProfile});

  final List<RecentViewedJobSeeker> items;
  final void Function(int employeeId, {int? workerUserId}) onTapProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 20.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey25)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  _recentViewedHeaderIconSvg,
                  width: 16,
                  height: 16,
                ),
                SizedBox(width: 4.w),
                Text(
                  '최근 열람 구직자',
                  style: AppTypography.bodyLargeM.copyWith(
                    fontSize: 16.sp,
                    height: 20 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.only(right: 20.w),
                child: Text(
                  '최근 열람한 구직자가 없습니다.',
                  style: AppTypography.bodySmallR.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: 20.w),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _RecentViewedCard(
                        item: items[i],
                        onTap: () => onTapProfile(
                          items[i].employeeId,
                          workerUserId: items[i].workerUserId,
                        ),
                      ),
                      if (i != items.length - 1) SizedBox(width: 16.w),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentViewedCard extends StatelessWidget {
  const _RecentViewedCard({required this.item, required this.onTap});

  final RecentViewedJobSeeker item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            const _PersonAvatar(size: 60),
            SizedBox(height: 4.h),
            Text(
              item.nameWithAge,
              style: AppTypography.bodySmallR.copyWith(
                fontSize: 12.sp,
                height: 18 / 12,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecruitmentSearchField extends StatelessWidget {
  const _RecruitmentSearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14.sp,
        height: 19 / 14,
      ),
      decoration: InputDecoration(
        hintText: '검색',
        hintStyle: AppTypography.bodyMediumR.copyWith(
          color: AppColors.grey100,
          fontSize: 14.sp,
          height: 19 / 14,
        ),
        filled: true,
        fillColor: AppColors.grey0Alt,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        prefixIcon: Padding(
          padding: EdgeInsets.all(14.r),
          child: SvgPicture.asset(
            'assets/icons/svg/icon/search_mint_20.svg',
            width: 20,
            height: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.items,
    required this.isLoadingMore,
    required this.loadMoreErrorMessage,
    required this.onRetryLoadMore,
    required this.onTapProfile,
  });

  final List<JobSeekerSummary> items;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final VoidCallback onRetryLoadMore;
  final void Function(int employeeId, {int? workerUserId}) onTapProfile;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Text(
          '검색 결과가 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _SearchResultCard(
            item: items[i],
            showDivider: i != items.length - 1,
            onTap: () => onTapProfile(
              items[i].employeeId,
              workerUserId: items[i].workerUserId,
            ),
          ),
        if (isLoadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (loadMoreErrorMessage != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: TextButton(
              onPressed: onRetryLoadMore,
              child: const Text('더 불러오지 못했습니다. 다시 시도'),
            ),
          ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  final JobSeekerSummary item;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: showDivider ? AppColors.grey25 : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            const _PersonAvatar(size: 48),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.employeeName,
                    style: AppTypography.bodyLargeM.copyWith(
                      fontSize: 16.sp,
                      height: 20 / 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        item.desiredLocation ?? '-',
                        style: AppTypography.bodySmallR.copyWith(
                          fontSize: 12.sp,
                          height: 18 / 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ScoreStars(
                            filledCount: _filledStarCount(
                              item.averageRating,
                              maxStars: 3,
                            ),
                            maxStars: 3,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '(${item.reviewCount})',
                            style: AppTypography.bodySmallR.copyWith(
                              fontSize: 12.sp,
                              height: 18 / 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecruitmentErrorView extends StatelessWidget {
  const _RecruitmentErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _TabPlaceholderView extends StatelessWidget {
  const _TabPlaceholderView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title 화면은 다음 단계에서 연결됩니다.',
        style: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey25,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.62,
        color: const Color(0xFFDADBE4),
      ),
    );
  }
}

class _ScoreStars extends StatelessWidget {
  const _ScoreStars({
    required this.filledCount,
    required this.maxStars,
    required this.color,
  });

  final int filledCount;
  final int maxStars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        return Icon(
          Icons.star_rounded,
          size: 12,
          color: index < filledCount ? color : color.withValues(alpha: 0.18),
        );
      }),
    );
  }
}

int _filledStarCount(double rating, {required int maxStars}) {
  if (rating <= 0) return 0;
  return rating.round().clamp(1, maxStars);
}
