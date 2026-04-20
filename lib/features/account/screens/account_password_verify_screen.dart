import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'account_password_code_screen.dart';

enum AccountPasswordEntryPoint { login, settings }

class AccountPasswordVerifyScreen extends StatefulWidget {
  const AccountPasswordVerifyScreen({
    super.key,
    this.entryPoint = AccountPasswordEntryPoint.settings,
  });

  final AccountPasswordEntryPoint entryPoint;

  @override
  State<AccountPasswordVerifyScreen> createState() =>
      _AccountPasswordVerifyScreenState();
}

class _AccountPasswordVerifyScreenState
    extends State<AccountPasswordVerifyScreen> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  DateTime? _expiresAt;
  bool _loadingProfile = false;
  bool _requestingCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryPoint == AccountPasswordEntryPoint.settings) {
      _prefillProfile();
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await context.read<AuthRepository>().getAccountProfile();
      if (!mounted) return;
      _nameCtrl.text = profile.fullName;
      _phoneCtrl.text = (profile.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  bool _isKoreanMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^01[016789]\d{7,8}$').hasMatch(digits);
  }

  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+$digits';
  }

  Future<void> _requestCode() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요.')));
      return;
    }
    if (!_isKoreanMobile(phone)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 확인해주세요.')));
      return;
    }

    if (widget.entryPoint == AccountPasswordEntryPoint.settings) {
      final currentUserName = context.read<AuthBloc>().state.user?.name?.trim();
      if (currentUserName != null &&
          currentUserName.isNotEmpty &&
          currentUserName != name) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름이 현재 계정 정보와 일치하지 않습니다.')),
        );
        return;
      }
    }

    setState(() => _requestingCode = true);
    try {
      final existsResult = await context.read<AuthRepository>().checkPhoneNumberExists(
            phoneNumber: phone,
          );
      if (!mounted) return;
      if (!existsResult.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('가입된 전화번호가 없습니다.')));
        setState(() => _requestingCode = false);
        return;
      }
      if (!existsResult.hasPasswordLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 로그인을 지원하지 않는 계정입니다.')),
        );
        setState(() => _requestingCode = false);
        return;
      }

      await context.read<AuthRepository>().verifyPhoneNumber(
            phoneNumber: _toE164(phone),
            codeSent: (verificationId, resendToken) {
              if (!mounted) return;
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _expiresAt = DateTime.now().add(const Duration(minutes: 3));
                _requestingCode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('인증번호가 발송되었습니다.')),
              );
              _goNext();
            },
            verificationFailed: (error) {
              if (!mounted) return;
              setState(() => _requestingCode = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message ?? error.code)),
              );
            },
            codeAutoRetrievalTimeout: (_) {},
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _requestingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountDioMessage(error))),
      );
    }
  }

  Future<void> _goNext() async {
    if (_verificationId == null || _expiresAt == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountPasswordCodeScreen(
          phoneNumber: _phoneCtrl.text.trim(),
          verificationId: _verificationId!,
          resendToken: _resendToken,
          expiresAt: _expiresAt!,
          entryPoint: widget.entryPoint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(
        context: context,
        title: widget.entryPoint == AccountPasswordEntryPoint.login
            ? '비밀번호 찾기'
            : '비밀번호 변경',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        height: 32 / 24,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: widget.entryPoint == AccountPasswordEntryPoint.login
                              ? '비밀번호를 찾기 위해\n아래 '
                              : '비밀번호를 변경하기 위해\n아래 ',
                        ),
                        const TextSpan(
                          text: '정보',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        const TextSpan(text: '를 입력해주세요.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    '이름',
                    style: AccountFigmaStyles.fieldCaption.copyWith(
                      color: AccountFigmaStyles.titleColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AuthInputField(
                    controller: _nameCtrl,
                    enabled: !_loadingProfile && !_requestingCode,
                    hintText: '이름을 입력해주세요.',
                    fillColor: AppColors.grey0Alt,
                    focusedBorderColor: AppColors.primary,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '휴대폰 인증',
                    style: AccountFigmaStyles.fieldCaption.copyWith(
                      color: AccountFigmaStyles.titleColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AuthInputField(
                    controller: _phoneCtrl,
                    enabled: !_loadingProfile && !_requestingCode,
                    keyboardType: TextInputType.phone,
                    hintText: '번호를 입력해주세요.',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    fillColor: AppColors.grey0Alt,
                    focusedBorderColor: AppColors.primary,
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 0,
                      minWidth: 88,
                    ),
                    suffix: Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: SizedBox(
                        width: 76.w,
                        height: 28.h,
                        child: Center(
                          child: GestureDetector(
                            onTap: _requestingCode ? null : _requestCode,
                            child: Container(
                              width: 76.w,
                              height: 28.h,
                              decoration: BoxDecoration(
                                color: _verificationId != null
                                    ? AppColors.grey0
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(8.r),
                                border: _verificationId != null
                                    ? Border.all(color: AppColors.primary)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: _requestingCode
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.grey0,
                                      ),
                                    )
                                  : Text(
                                      _verificationId != null ? '재요청' : '요청',
                                      style: AppTypography.bodyMediumB.copyWith(
                                        color: _verificationId != null
                                            ? AppColors.primary
                                            : AppColors.grey0,
                                        fontSize: 11.sp,
                                        height: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: _verificationId == null || _requestingCode ? null : _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.grey0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
