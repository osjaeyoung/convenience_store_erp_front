import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 비밀번호 재설정 (Figma 2634:16243) — `POST /me/account/password`
class AccountChangePasswordScreen extends StatefulWidget {
  const AccountChangePasswordScreen({super.key});

  @override
  State<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends State<AccountChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthRepository>().changeAccountPassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  Widget _pwdField({
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
                    _pwdField(
                      caption: '현재 비밀번호',
                      controller: _currentCtrl,
                      obscure: _obscureCurrent,
                      toggleObscure: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
                      hint: '현재 비밀번호를 입력해주세요.',
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return '현재 비밀번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    _pwdField(
                      caption: '새 비밀번호',
                      controller: _newCtrl,
                      obscure: _obscureNew,
                      toggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      hint: '새 비밀번호를 입력해주세요.',
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return '8자 이상 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    _pwdField(
                      caption: '새 비밀번호 확인',
                      controller: _confirmCtrl,
                      obscure: _obscureConfirm,
                      toggleObscure: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      hint: '새 비밀번호를 다시 입력해주세요.',
                      validator: (v) {
                        if (v != _newCtrl.text) {
                          return '새 비밀번호가 일치하지 않습니다.';
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
                    borderRadius: BorderRadius.circular(12.r),
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
