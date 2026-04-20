import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../data/models/account_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/screens/signup_phone_code_screen.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../account_dio_message.dart';
import '../widgets/account_confirm_dialogs.dart';
import '../widgets/account_figma_styles.dart';
import 'account_password_verify_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 내 정보 변경 (Figma 2634:16280 / 소셜 2634:16329)
class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usageTypeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '**********');
  AccountProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _withdrawing = false;
  Object? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usageTypeCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

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
      final p = await context.read<AuthRepository>().getAccountProfile();
      if (mounted) {
        _nameCtrl.text = p.fullName;
        _emailCtrl.text = p.email;
        _usageTypeCtrl.text = p.usageTypeLabelKo;
        _phoneCtrl.text = p.phoneNumber ?? '';
        setState(() {
          _profile = p;
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

  Future<void> _saveNameIfChanged() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요.')),
      );
      return;
    }
    if (name == (_profile?.fullName ?? '').trim()) return;
    setState(() => _saving = true);
    try {
      final p = await context.read<AuthRepository>().patchAccount(
            fullName: name,
          );
      if (mounted) {
        setState(() {
          _profile = p;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('82') && digits.length >= 11) return '+$digits';
    if (digits.startsWith('0') && digits.length >= 10) return '+82${digits.substring(1)}';
    return '+$digits';
  }

  Future<void> _requestPhoneVerification() async {
    final phoneNumber = _phoneCtrl.text.trim();
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 휴대폰 번호를 입력해주세요.')),
      );
      return;
    }
    
    final currentPhone = _profile?.phoneNumber ?? '';
    if (phoneNumber == currentPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기존 번호와 동일합니다.')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<AuthRepository>();
    
    try {
      final result = await repo.checkPhoneNumberExists(phoneNumber: phoneNumber);
      if (!mounted) return;
      if (result.exists) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 가입된 전화번호입니다.')),
        );
        return;
      }
      
      await repo.verifyPhoneNumber(
        phoneNumber: _toE164(phoneNumber),
        codeSent: (verificationId, resendToken) async {
          if (!mounted) return;
          setState(() => _saving = false);
          final expiresAt = DateTime.now().add(const Duration(minutes: 3));
          
          final verified = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => SignupPhoneCodeScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
                expiresAt: expiresAt,
              ),
            ),
          );
          
          if (verified == true && mounted) {
            _updatePhoneNumberOnServer(phoneNumber);
          }
        },
        verificationCompleted: (credential) async {
          if (!mounted) return;
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            await FirebaseAuth.instance.signOut();
            _updatePhoneNumberOnServer(phoneNumber);
          } catch (_) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('자동 인증 처리 중 오류가 발생했습니다.')),
            );
          }
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? '인증번호 요청에 실패했습니다.')),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  Future<void> _updatePhoneNumberOnServer(String phoneNumber) async {
    setState(() => _saving = true);
    try {
      final p = await context.read<AuthRepository>().patchAccount(phoneNumber: phoneNumber);
      if (mounted) {
        setState(() {
          _profile = p;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 성공적으로 변경되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  Future<void> _onWithdraw() async {
    if (!mounted) return;
    final ok = await showWithdrawConfirmDialog(context);
    if (!ok || !mounted) return;
    setState(() => _withdrawing = true);
    try {
      await context.read<AuthRepository>().withdrawAccount();
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    } catch (e) {
      if (mounted) {
        setState(() => _withdrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  Widget _fieldBlock({
    required String caption,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: AccountFigmaStyles.fieldCaption),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(context: context, title: '내 정보 설정'),
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
                          style: AccountFigmaStyles.fieldValue.copyWith(
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
              : Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 32.h),
                      children: [
                        _fieldBlock(
                          caption: '이름',
                          child: AuthInputField(
                            controller: _nameCtrl,
                            hintText: '이름을 입력해주세요.',
                            onEditingComplete: _saveNameIfChanged,
                            fillColor: AppColors.grey0Alt,
                            focusedBorderColor: AppColors.grey50,
                            contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                            textStyle: AccountFigmaStyles.fieldValue,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _fieldBlock(
                          caption: '이메일',
                          child: AuthInputField(
                            controller: _emailCtrl,
                            hintText: '',
                            readOnly: true,
                            fillColor: AppColors.grey0Alt,
                            focusedBorderColor: AppColors.grey50,
                            contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                            textStyle: AccountFigmaStyles.fieldValueMuted,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _fieldBlock(
                          caption: '사용 유형',
                          child: AuthInputField(
                            controller: _usageTypeCtrl,
                            hintText: '',
                            readOnly: true,
                            fillColor: AppColors.grey0Alt,
                            focusedBorderColor: AppColors.grey50,
                            contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                            textStyle: AccountFigmaStyles.fieldValue,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _fieldBlock(
                          caption: '전화번호',
                          child: AuthInputField(
                            controller: _phoneCtrl,
                            hintText: '휴대폰 번호 (- 제외)',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            fillColor: AppColors.grey0Alt,
                            focusedBorderColor: AppColors.grey50,
                            contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                            textStyle: AccountFigmaStyles.fieldValue,
                    suffixIconConstraints: BoxConstraints(
                      minHeight: 0,
                      minWidth: 88.w,
                    ),
                    suffix: Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: SizedBox(
                        width: 76.w,
                        height: 28.h,
                        child: Center(
                          child: GestureDetector(
                            onTap: _saving ? null : _requestPhoneVerification,
                            child: Container(
                              width: 76.w,
                              height: 28.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              alignment: Alignment.center,
                              child: _saving
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.grey0,
                                      ),
                                    )
                                  : Text(
                                      '요청',
                                      style: AppTypography.bodyMediumB.copyWith(
                                        color: AppColors.grey0,
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
                        ),
                        if (p?.hasPasswordLogin == true) ...[
                          SizedBox(height: 20.h),
                          _fieldBlock(
                            caption: '비밀번호',
                            child: AuthInputField(
                              controller: _passwordCtrl,
                              hintText: '',
                              readOnly: true,
                              obscureText: true,
                              fillColor: AppColors.grey0Alt,
                              focusedBorderColor: AppColors.grey50,
                              contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                              textStyle: AccountFigmaStyles.fieldValueMuted,
                              suffixIconConstraints: BoxConstraints(minWidth: 63.w),
                              suffix: Padding(
                                padding: EdgeInsets.only(right: 12.w),
                                child: SizedBox(
                                  height: 24.h,
                                  child: TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            Navigator.of(context).push<void>(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const AccountPasswordVerifyScreen(),
                                              ),
                                            );
                                          },
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.grey0,
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
                                      minimumSize: Size(43.w, 24.h),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                    ),
                                    child: Text(
                                      '변경',
                                      style: AppTypography.bodySmallB.copyWith(
                                        color: AppColors.grey0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 40.h),
                        Center(
                          child: TextButton(
                            onPressed: _withdrawing ? null : _onWithdraw,
                            style: TextButton.styleFrom(
                              foregroundColor: AccountFigmaStyles.footerMutedColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '탈퇴하기',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                height: 20 / 14,
                                decoration: TextDecoration.underline,
                                decorationColor: AccountFigmaStyles.footerMutedColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_saving || _withdrawing)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
