import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../account_dio_message.dart';
import '../widgets/account_confirm_dialogs.dart';
import '../widgets/account_figma_styles.dart';
import 'account_my_info_settings_screen.dart';
import 'account_notices_screen.dart';
import 'account_policies_screen.dart';
import 'account_support_center_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 설정 (Figma 2634:16151)
class AccountSettingsMenuScreen extends StatefulWidget {
  const AccountSettingsMenuScreen({super.key});

  @override
  State<AccountSettingsMenuScreen> createState() =>
      _AccountSettingsMenuScreenState();
}

class _AccountSettingsMenuScreenState extends State<AccountSettingsMenuScreen> {
  Object? _error;
  bool _loading = true;

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
      await context.read<AuthRepository>().getAccountProfile();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onLogout() async {
    if (!mounted) return;
    final ok = await showLogoutConfirmDialog(context);
    if (!ok || !mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '설정'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          accountDioMessage(_error!),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 16.h),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey0,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _row(
                                  '내 정보 설정',
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccountMyInfoSettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _row(
                                  '고객센터',
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccountSupportCenterScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _row(
                                  '공지사항',
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccountNoticesScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _row(
                                  '이용 정책',
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccountPoliciesScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: Center(
                            child: TextButton(
                              onPressed: _onLogout,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AccountFigmaStyles.footerMutedColor,
                                textStyle: AccountFigmaStyles.footerAction,
                              ),
                              child: const Text('로그아웃'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String title, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AccountFigmaStyles.rowTitle),
              ),
              AccountFigmaStyles.chevronNext16(),
            ],
          ),
        ),
      ),
    );
  }
}
