import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'account_password_verify_screen.dart';

class AccountChangePasswordScreen extends StatefulWidget {
  const AccountChangePasswordScreen({
    super.key,
    required this.phoneNumber,
    required this.entryPoint,
  });

  final String phoneNumber;
  final AccountPasswordEntryPoint entryPoint;

  @override
  State<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends State<AccountChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final result = await context.read<AuthRepository>().resetPasswordByPhone(
            phoneNumber: widget.phoneNumber,
            newPassword: _passwordCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty ? result.message : '비밀번호가 변경되었습니다.',
          ),
        ),
      );
      if (widget.entryPoint == AccountPasswordEntryPoint.login) {
        context.go(AppRouter.login);
        return;
      }
      final user = context.read<AuthBloc>().state.user;
      context.go(
        user?.role.isJobSeeker == true
            ? AppRouter.jobSeekerMain
            : AppRouter.managerMain,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  Widget _passwordField({
    required String caption,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: AccountFigmaStyles.fieldCaption),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 8.w, 4.h),
          decoration: BoxDecoration(
            color: AppColors.grey25,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            style: AccountFigmaStyles.fieldValue,
            validator: validator,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AccountFigmaStyles.fieldValue.copyWith(
                color: AppColors.textTertiary,
              ),
              suffixIcon: IconButton(
                onPressed: toggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(
        context: context,
        title: '비밀번호 변경',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _passwordField(
                      caption: '비밀번호',
                      controller: _passwordCtrl,
                      obscure: _obscurePassword,
                      toggleObscure: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      hint: '비밀번호를 입력해주세요.',
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return '8자 이상 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    _passwordField(
                      caption: '비밀번호 확인',
                      controller: _confirmCtrl,
                      obscure: _obscureConfirm,
                      toggleObscure: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      hint: '비밀번호를 한번 더 입력해주세요.',
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.grey0,
                        ),
                      )
                    : Text(
                        '완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
