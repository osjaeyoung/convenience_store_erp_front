import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class SignupPhoneCodeScreen extends StatefulWidget {
  const SignupPhoneCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.expiresAt,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final DateTime expiresAt;
  final int? resendToken;

  @override
  State<SignupPhoneCodeScreen> createState() => _SignupPhoneCodeScreenState();
}

class _SignupPhoneCodeScreenState extends State<SignupPhoneCodeScreen> {
  static const Color _timerColor = Color(0xFFF4001D);

  final _codeController = TextEditingController();
  Timer? _ticker;
  late String _verificationId;
  int? _resendToken;
  late DateTime _expiresAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _expiresAt = widget.expiresAt;
    _codeController.addListener(_onCodeChanged);
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_isExpired) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  bool get _isExpired => !DateTime.now().isBefore(_expiresAt);

  String get _countdownLabel {
    final left = _expiresAt.difference(DateTime.now());
    if (left.inSeconds <= 0) {
      return '인증 시간이 만료되었습니다. 재발송을 눌러 주세요.';
    }
    final total = left.inSeconds;
    final mm = total ~/ 60;
    final ss = total % 60;
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')} 내에 입력해주세요.';
  }

  String get _formattedPhoneNumber {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return widget.phoneNumber;
  }

  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('82') && digits.length >= 11) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+82${digits.substring(1)}';
    }
    return '+$digits';
  }

  Future<void> _persistSession({
    required String verificationId,
    int? resendToken,
    DateTime? expiresAt,
  }) {
    return context.read<AuthRepository>().savePhoneVerificationSession({
      'phone_number': widget.phoneNumber,
      'verification_id': verificationId,
      'resend_token': resendToken,
      'expires_at': (expiresAt ?? _expiresAt).toIso8601String(),
    });
  }

  Future<void> _resendCode() async {
    setState(() => _submitting = true);
    try {
      await context.read<AuthRepository>().verifyPhoneNumber(
            phoneNumber: _toE164(widget.phoneNumber),
            forceResendingToken: _resendToken,
            codeSent: (verificationId, resendToken) async {
              if (!mounted) return;
              final nextExpiresAt = DateTime.now().add(const Duration(minutes: 3));
              _codeController.clear();
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _expiresAt = nextExpiresAt;
                _submitting = false;
              });
              await _persistSession(
                verificationId: verificationId,
                resendToken: resendToken,
                expiresAt: nextExpiresAt,
              );
              _startTicker();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('인증번호를 다시 보냈습니다.')),
              );
            },
            verificationFailed: (error) {
              if (!mounted) return;
              setState(() => _submitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_friendlyFirebaseErrorMessage(error))),
              );
            },
            codeAutoRetrievalTimeout: (_) {},
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호 재발송에 실패했습니다.')));
    }
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().length != 6 || _isExpired) return;
    setState(() => _submitting = true);
    final repo = context.read<AuthRepository>();
    final navigator = Navigator.of(context);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();
      await repo.clearPhoneVerificationSession();
      if (!mounted) return;
      navigator.pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyFirebaseErrorMessage(error))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호 확인에 실패했습니다.')));
    }
  }

  String _friendlyFirebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return '인증번호가 올바르지 않습니다.';
      case 'session-expired':
        return '인증 시간이 만료되었습니다. 다시 요청해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        final message = error.message?.trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return '인증번호 확인 중 오류가 발생했습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        toolbarHeight: 60,
        leadingWidth: 48,
        leading: IconButton(
          padding: EdgeInsets.only(left: 20.w),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        titleSpacing: 8,
        title: Text(
          '인증번호 확인',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            height: 26 / 18,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
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
                        TextSpan(text: '$_formattedPhoneNumber로 전송된\n'),
                        TextSpan(
                          text: '인증번호 6자리',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w400,
                            height: 32 / 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(text: '를 입력해 주세요.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  TextField(
                    controller: _codeController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '인증번호를 입력해주세요.',
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: -0.3,
                        color: AppColors.grey150,
                      ),
                      filled: true,
                      fillColor: AppColors.grey0,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _countdownLabel,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                      color: _timerColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '인증번호가 오지 않았나요?',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: -0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: _submitting ? null : _resendCode,
                  child: Text(
                    '재발송',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 22 / 14,
                      letterSpacing: -0.3,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: _submitting ||
                          _codeController.text.trim().length != 6 ||
                          _isExpired
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.grey0,
                    disabledBackgroundColor: AppColors.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '다음',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                          ),
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
