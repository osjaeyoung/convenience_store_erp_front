import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/branch.dart';
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

  Branch? _selectedBranch;

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
        if (_selectedBranch == null) {
          _showBranchNotSelectedDialog();
          return;
        }
        context.read<AuthBloc>().add(
              AuthSignupStep2ManagerRequested(
                requestedBranchId: _selectedBranch!.id,
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
                                _buildRoleFields(),
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

  Widget _buildRoleFields() {
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
              hintText: '회사를 검색해주세요.',
              focusedBorderColor: AppColors.primary,
              prefixIconWidget: Padding(
                padding: EdgeInsets.all(14.r),
                child: SvgPicture.asset(
                  'assets/icons/svg/icon/search_mint_20.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              onChanged: (q) {
                if (q.trim().isNotEmpty) {
                  context
                      .read<AuthBloc>()
                      .add(AuthBranchesSearchRequested(query: q.trim()));
                }
              },
            ),
            SizedBox(height: 10.h),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (a, b) =>
                  b.status == AuthStatus.branchesLoaded ||
                  b.status == AuthStatus.signupStep1Completed,
              builder: (context, state) {
                return Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey50),
                    color: AppColors.grey0Alt,
                  ),
                  child: state.branches.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: state.branches.map((b) {
                            final selected = _selectedBranch?.id == b.id;
                            return ListTile(
                              dense: true,
                              title: Text(
                                b.name,
                                style: AppTypography.bodyMediumM.copyWith(
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: b.code != null ? Text(b.code!) : null,
                              selected: selected,
                              onTap: () => setState(() => _selectedBranch = b),
                            );
                          }).toList(),
                        ),
                );
              },
            ),
            SizedBox(height: 20.h),
            const MintAddButton(),
            if (_selectedBranch != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '선택: ${_selectedBranch!.name}',
                  style: AppTypography.bodySmallM.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
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
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '알림',
                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
              ),
              SizedBox(height: 20.h),
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF2C94C),
                size: 56,
              ),
              SizedBox(height: 16.h),
              Text(
                '해당 지점에 점장으로\n등록되지 않았습니다.',
                style: AppTypography.bodyLargeB.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        backgroundColor: AppColors.grey25,
                        foregroundColor: AppColors.grey150,
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                      ),
                      child: const Text('확인'),
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
