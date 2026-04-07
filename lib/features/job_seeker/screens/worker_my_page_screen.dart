import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/account_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../../account/screens/account_notices_screen.dart';
import '../../account/screens/account_password_verify_screen.dart';
import '../../account/screens/account_policies_screen.dart';
import '../../account/screens/account_settings_menu_screen.dart';
import '../../account/screens/account_support_center_screen.dart';
import '../../account/widgets/account_confirm_dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../manager/widgets/home_common_app_bar.dart';
import '../widgets/worker_common.dart';
import 'worker_account_edit_screen.dart';

class WorkerMyPageScreen extends StatefulWidget {
  const WorkerMyPageScreen({super.key});

  @override
  State<WorkerMyPageScreen> createState() => _WorkerMyPageScreenState();
}

class _WorkerMyPageScreenState extends State<WorkerMyPageScreen> {
  AccountProfile? _profile;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<AuthRepository>().getAccountProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutConfirmDialog(context);
    if (!confirmed || !mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  void _showAlarmPlaceholder() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림 기능은 준비 중입니다.')));
  }

  Future<void> _openPasswordFlow() async {
    final profile = _profile;
    if (profile?.hasPasswordLogin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('소셜 로그인 계정은 비밀번호 변경을 지원하지 않습니다.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AccountPasswordVerifyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: HomeCommonAppBar(
        alarmActive: false,
        onAlarmTap: _showAlarmPlaceholder,
        onMenuTap: () => Navigator.of(context).maybePop(),
      ),
      body: _loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && profile == null
          ? workerErrorView(message: accountDioMessage(_error!), onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey0,
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        _MenuRow(
                          icon: Icons.settings_outlined,
                          iconColor: AppColors.primary,
                          title: '설정',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AccountSettingsMenuScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.person_outline_rounded,
                          title: '회원정보 관리',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const WorkerAccountEditScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.lock_outline_rounded,
                          title: '비밀번호 변경',
                          onTap: _openPasswordFlow,
                        ),
                        _MenuRow(
                          icon: Icons.campaign_outlined,
                          title: '공지사항',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const AccountNoticesScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: '고객센터',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AccountSupportCenterScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.article_outlined,
                          title: '이용 정책',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const AccountPoliciesScreen(),
                              ),
                            );
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 36.h),
                  Center(
                    child: TextButton(
                      onPressed: _logout,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textTertiary,
                      ),
                      child: Text(
                        '로그아웃',
                        style: AppTypography.bodyMediumM.copyWith(
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.r,
                color: iconColor ?? AppColors.textTertiary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMediumB.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.r,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
