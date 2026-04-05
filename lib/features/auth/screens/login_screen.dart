import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../account/screens/account_password_verify_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_input_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 로그인 페이지
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _onGoogleLogin() {
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  void _onAppleLogin() {
    context.read<AuthBloc>().add(const AuthAppleLoginRequested());
  }

  void _onLogin() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _pwController.text,
      ),
    );
  }

  void _goHomeFromLogo() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      context.go(AppRouter.login);
      return;
    }
    context.go(
      user.role.isJobSeeker ? AppRouter.jobSeekerMain : AppRouter.managerMain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 142.h),
                    Center(
                      child: GestureDetector(
                        onTap: _goHomeFromLogo,
                        child: Image.asset(AppAssets.logoMain, width: 180),
                      ),
                    ),
                    SizedBox(height: 56.h),
                    AuthInputField(
                      controller: _emailController,
                      prefixIconPath: AppAssets.loginFieldEmail,
                      hintText: '이메일을 입력해주세요.',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => _validateEmail(v ?? ''),
                      autovalidateMode: _submitted
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      onChanged: (_) {
                        if (_submitted) setState(() {});
                      },
                    ),
                    SizedBox(height: AppSpacing.xl),
                    AuthInputField(
                      controller: _pwController,
                      prefixIconPath: AppAssets.loginFieldPassword,
                      hintText: '비밀번호를 입력해주세요.',
                      obscureText: true,
                      validator: (v) => _validatePassword(v ?? ''),
                      autovalidateMode: _submitted
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      onChanged: (_) {
                        if (_submitted) setState(() {});
                      },
                    ),
                    if (state.status == AuthStatus.failure &&
                        (state.errorMessage?.isNotEmpty ?? false)) ...[
                      SizedBox(height: 8.h),
                      Text(
                        _formatLoginError(state.errorMessage!),
                        style: AppTypography.bodySmallR.copyWith(
                          color: const Color(0xFFFF4834),
                          height: 18 / 12,
                        ),
                      ),
                    ],
                    SizedBox(height: 48.h),
                    FilledButton(
                      onPressed: state.status == AuthStatus.loading
                          ? null
                          : _onLogin,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(56.h),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '로그인',
                              style: AppTypography.bodyLargeB.copyWith(
                                color: AppColors.grey0,
                                height: 24 / 16,
                              ),
                            ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const AccountPasswordVerifyScreen(
                                  entryPoint: AccountPasswordEntryPoint.login,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            '비밀번호 찾기',
                            style: AppTypography.bodyMediumM.copyWith(
                              color: AppColors.grey150,
                              height: 16 / 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.grey100,
                        ),
                        SizedBox(width: 14.w),
                        GestureDetector(
                          onTap: () async {
                            await context
                                .read<AuthRepository>()
                                .clearSignupDraft();
                            if (!context.mounted) return;
                            context.push(AppRouter.signup);
                          },
                          child: Text(
                            '회원가입',
                            style: AppTypography.bodyMediumM.copyWith(
                              color: AppColors.grey150,
                              height: 16 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.grey50)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            'SNS 로그인',
                            style: AppTypography.bodySmallR.copyWith(
                              color: AppColors.grey150,
                              height: 16 / 12,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.grey50)),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          assetPath: AppAssets.loginSocialGoogle,
                          onTap: _onGoogleLogin,
                        ),
                        SizedBox(width: 16.w),
                        _SocialButton(
                          assetPath: AppAssets.loginSocialApple,
                          onTap: _onAppleLogin,
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    const invalidMsg = '*올바른 이메일 주소를 입력해주세요.';
    if (email.isEmpty) return invalidMsg;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return invalidMsg;
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return '*비밀번호를 입력해주세요.';
    return null;
  }

  String _formatLoginError(String message) {
    return '*올바른 이메일과 비밀번호를 입력해주세요.';
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 52, height: 52, child: Image.asset(assetPath)),
    );
  }
}
