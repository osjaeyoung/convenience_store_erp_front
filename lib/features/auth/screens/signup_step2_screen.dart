import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/branch.dart';
import '../../../data/models/manager_registration_lookup_item.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/mint_add_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 회원가입 2차 - 역할별 추가 정보
/// 경영주: 지점명, 점장: 지점 검색/선택 또는 사전등록, 근무자: 없음
class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _branchSearchController = TextEditingController();
  final List<_OwnerBranchForm> _ownerBranchForms = [_OwnerBranchForm()];
  List<ManagerRegistrationLookupItem> _managerRegistrations = const [];
  final List<Branch> _addedBranches = [];
  final Map<int, Branch> _checkedSearchBranches = {};
  bool _loadingManagerRegistrations = false;
  String _managerName = '';
  String _managerPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    if (widget.role == UserRole.storeManager) {
      final repo = context.read<AuthRepository>();
      _managerName = repo.currentFullName ?? '';
      _managerPhoneNumber = repo.currentPhoneNumber ?? '';
      unawaited(_loadManagerRegistrations());
    }
  }

  @override
  void dispose() {
    for (final form in _ownerBranchForms) {
      form.dispose();
    }
    _branchSearchController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    switch (widget.role) {
      case UserRole.manager:
        final branches = _ownerBranchForms
            .map(
              (form) => <String, String?>{
                'branch_name': form.companyNameController.text.trim(),
                'business_number': form.businessNumberController.text.trim(),
              },
            )
            .where((b) => (b['branch_name'] ?? '').isNotEmpty)
            .toList();
        if (branches.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('점포명을 1개 이상 입력해주세요.')),
          );
          return;
        }
        context.read<AuthBloc>().add(
              AuthSignupStep2OwnerRequested(
                branches: branches,
              ),
            );
        break;
      case UserRole.storeManager:
        if (_loadingManagerRegistrations) return;
        if (_managerName.isEmpty || _managerPhoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 시 입력한 이름과 휴대폰 번호를 확인해주세요.')),
          );
          return;
        }
        if (_addedBranches.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('지점을 1개 이상 추가해주세요.')),
          );
          return;
        }
        final registrationIds = _selectedRegistrationIds;
        if (registrationIds.length != _addedBranches.length) {
          _showBranchNotSelectedDialog();
          return;
        }
        context.read<AuthBloc>().add(
              AuthSignupStep2ManagerRequested(
                registrationIds: registrationIds,
                managerPhoneNumber: _managerPhoneNumber,
              ),
            );
        break;
      case UserRole.jobSeeker:
        context.read<AuthBloc>().add(const AuthSignupStep2WorkerRequested());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? '오류가 발생했습니다.')),
          );
        }
        if (state.isAuthenticated && state.user != null) {
          final role = state.user!.role;
          context.go(
            role.isJobSeeker ? AppRouter.jobSeekerMain : AppRouter.managerMain,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.grey0,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(widget.role == UserRole.manager ? '사업주 회원가입' : '회원가입'),
          ),
          body: state.status == AuthStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: AppSpacing.paddingXl,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                SizedBox(height: 28.h),
                                _buildRoleFields(state),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          8.h,
                          AppSpacing.xl,
                          20.h,
                        ),
                        child: FilledButton(
                          onPressed:
                              state.status == AuthStatus.loading ? null : _onSubmit,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(56.h),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            widget.role == UserRole.manager ? '완료' : '다음',
                            style: AppTypography.bodyLargeB.copyWith(
                              color: AppColors.grey0,
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

  Widget _buildHeader() {
    if (widget.role == UserRole.manager) {
      return Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24.sp,
            fontWeight: FontWeight.w400,
            height: 32 / 24,
            color: AppColors.textPrimary,
          ),
          children: const [
            TextSpan(text: '사업주 회원가입을 위해\n아래 '),
            TextSpan(
              text: '정보',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '를 입력해주세요.'),
          ],
        ),
      );
    }

    if (widget.role == UserRole.storeManager) {
      return Text(
        '점장 회원가입을 위해\n지점을 등록해주세요.',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 24.sp,
          fontWeight: FontWeight.w400,
          height: 32 / 24,
          color: AppColors.textPrimary,
        ),
      );
    }

    return Text(
      '근무자로 가입을 완료합니다.',
      style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildRoleFields(AuthState state) {
    switch (widget.role) {
      case UserRole.manager:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._buildOwnerBranchFields(),
            SizedBox(height: 20.h),
            MintAddButton(
              onPressed: () {
                setState(() {
                  _ownerBranchForms.add(_OwnerBranchForm());
                });
              },
            ),
          ],
        );
      case UserRole.storeManager:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFieldLabel('회사명'),
            AuthInputField(
              controller: _branchSearchController,
              hintText: '회사명을 검색해주세요',
              focusedBorderColor: AppColors.primary,
              prefixIconWidget: Padding(
                padding: EdgeInsets.all(14.r),
                child: SvgPicture.asset(
                  'assets/icons/svg/icon/search_mint_20.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              onChanged: (query) {
                final normalized = query.trim();
                if (normalized.isNotEmpty) {
                  context.read<AuthBloc>().add(
                    AuthBranchesSearchRequested(query: normalized),
                  );
                }
              },
            ),
            SizedBox(height: 8.h),
            _buildManagerSelectionCard(state.branches),
            SizedBox(height: 28.h),
            _buildManagerAddButton(),
          ],
        );
      case UserRole.jobSeeker:
        return Text(
          '추가 정보 없이 가입을 완료합니다.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        );
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildManagerSelectionCard(List<Branch> searchResults) {
    final query = _branchSearchController.text.trim();
    final showSearchResults = query.isNotEmpty;

    return Container(
      constraints: BoxConstraints(minHeight: 56.h),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: showSearchResults
          ? _buildSearchResults(searchResults)
          : _buildAddedBranchesList(),
    );
  }

  Widget _buildSearchResults(List<Branch> searchResults) {
    if (searchResults.isEmpty) {
      return SizedBox(height: 56.h);
    }

    return Column(
      children: [
        for (var index = 0; index < searchResults.length; index++) ...[
          _buildSearchResultTile(searchResults[index]),
          if (index != searchResults.length - 1)
            Divider(height: 1, color: AppColors.grey50),
        ],
      ],
    );
  }

  Widget _buildSearchResultTile(Branch branch) {
    final selected = _isBranchChecked(branch);
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () {
        setState(() {
          if (_checkedSearchBranches.containsKey(branch.id)) {
            _checkedSearchBranches.remove(branch.id);
          } else {
            _checkedSearchBranches[branch.id] = branch;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        color: selected ? AppColors.primaryLight : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    branch.name,
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if ((branch.code ?? '').isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      branch.code!,
                      style: AppTypography.bodySmallR.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 18.r,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedBranchesList() {
    if (_addedBranches.isEmpty) {
      return SizedBox(height: 56.h);
    }

    return Column(
      children: [
        for (var index = 0; index < _addedBranches.length; index++) ...[
          _buildAddedBranchTile(_addedBranches[index]),
          if (index != _addedBranches.length - 1)
            Divider(height: 1, color: AppColors.grey50),
        ],
      ],
    );
  }

  Widget _buildAddedBranchTile(Branch branch) {
    final isRegistered = _matchingRegistrationFor(branch) != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  branch.name,
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isRegistered ? '사전 등록된 지점입니다.' : '사전 등록되지 않은 지점입니다.',
                  style: AppTypography.bodySmallR.copyWith(
                    color: isRegistered ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _addedBranches.removeWhere((item) => item.id == branch.id);
              });
            },
            icon: Icon(
              Icons.close_rounded,
              size: 18.r,
              color: AppColors.grey150,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerAddButton() {
    return OutlinedButton(
      onPressed: _addSelectedBranch,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 36.h),
        side: const BorderSide(color: AppColors.primary),
        backgroundColor: const Color(0xFFE2F6F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '추가하기',
            style: AppTypography.bodySmallM.copyWith(
              color: AppColors.primary,
              height: 16 / 12,
            ),
          ),
          SizedBox(width: 8.w),
          SvgPicture.asset(
            'assets/icons/svg/icon/plus_mint_20.svg',
            width: 20,
            height: 20,
          ),
        ],
      ),
    );
  }

  void _addSelectedBranch() {
    if (_checkedSearchBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가할 지점을 선택해주세요.')),
      );
      return;
    }

    final selectedBranches = _checkedSearchBranches.values.toList();
    final newBranches = selectedBranches
        .where((branch) => !_addedBranches.any((item) => item.id == branch.id))
        .toList();

    if (newBranches.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 추가한 지점입니다.')));
      return;
    }

    setState(() {
      _addedBranches.addAll(newBranches);
      for (final branch in newBranches) {
        _checkedSearchBranches.remove(branch.id);
      }
      _branchSearchController.clear();
    });

    if (newBranches.length != selectedBranches.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 추가한 지점은 제외하고 추가했습니다.')));
    }
  }

  Future<void> _loadManagerRegistrations() async {
    if (_managerName.isEmpty || _managerPhoneNumber.isEmpty) return;
    setState(() => _loadingManagerRegistrations = true);
    try {
      final items = await context.read<AuthRepository>().lookupManagerRegistrations(
        managerName: _managerName,
        managerPhoneNumber: _managerPhoneNumber,
      );
      if (!mounted) return;
      setState(() {
        _managerRegistrations = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _managerRegistrations = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingManagerRegistrations = false);
      }
    }
  }

  ManagerRegistrationLookupItem? _matchingRegistrationFor(Branch branch) {
    for (final item in _managerRegistrations) {
      if (item.branchId == branch.id) return item;
    }
    return null;
  }

  List<int> get _selectedRegistrationIds {
    return _addedBranches
        .map(_matchingRegistrationFor)
        .whereType<ManagerRegistrationLookupItem>()
        .map((item) => item.registrationId)
        .toSet()
        .toList();
  }

  bool _isBranchChecked(Branch branch) {
    if (_checkedSearchBranches.containsKey(branch.id)) return true;
    return _addedBranches.any((item) => item.id == branch.id);
  }

  List<Widget> _buildOwnerBranchFields() {
    final widgets = <Widget>[];
    for (var index = 0; index < _ownerBranchForms.length; index++) {
      final form = _ownerBranchForms[index];
      widgets.add(_buildFieldLabel('회사명'));
      widgets.add(
        AuthInputField(
          controller: form.companyNameController,
          hintText: '회사명을 입력해주세요.',
          focusedBorderColor: AppColors.primary,
        ),
      );
      widgets.add(SizedBox(height: 20.h));
      widgets.add(_buildFieldLabel('사업자 등록 번호'));
      widgets.add(
        AuthInputField(
          controller: form.businessNumberController,
          hintText: '사업자 등록 번호를 입력해주세요.',
          keyboardType: TextInputType.number,
          focusedBorderColor: AppColors.primary,
        ),
      );
      if (_ownerBranchForms.length > 1) {
        widgets.add(
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  final removed = _ownerBranchForms.removeAt(index);
                  removed.dispose();
                });
              },
              child: const Text('점포 삭제'),
            ),
          ),
        );
      }
      if (index != _ownerBranchForms.length - 1) {
        widgets.add(SizedBox(height: 8.h));
        widgets.add(const Divider(color: AppColors.grey25, height: 1));
        widgets.add(SizedBox(height: 12.h));
      }
    }
    return widgets;
  }

  void _showBranchNotSelectedDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.grey0,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '알림',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  height: 24 / 18,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 80.r,
                height: 80.r,
                decoration: const BoxDecoration(
                  color: AppColors.grey0Alt,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFFFD159),
                  size: 48.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '해당 지점에 점장으로\n등록되지 않았습니다.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey150,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '확인',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerBranchForm {
  _OwnerBranchForm()
      : companyNameController = TextEditingController(),
        businessNumberController = TextEditingController();

  final TextEditingController companyNameController;
  final TextEditingController businessNumberController;

  void dispose() {
    companyNameController.dispose();
    businessNumberController.dispose();
  }
}
