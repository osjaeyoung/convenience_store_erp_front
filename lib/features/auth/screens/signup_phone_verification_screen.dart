import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_input_field.dart';

class SignupPhoneVerificationScreen extends StatefulWidget {
  const SignupPhoneVerificationScreen({super.key});

  @override
  State<SignupPhoneVerificationScreen> createState() =>
      _SignupPhoneVerificationScreenState();
}

class _SignupPhoneVerificationScreenState
    extends State<SignupPhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  DateTime? _expiresAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  void _restoreSession() {
    final session = context.read<AuthRepository>().phoneVerificationSession;
    if (session == null) {
      context.go(AppRouter.signup);
      return;
    }
    _expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAtMillis);
    _startTicker();
    if (mounted) {
      setState(() {});
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_isExpired) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  bool get _isExpired =>
      _expiresAt != null && !DateTime.now().isBefore(_expiresAt!);

  String get _countdownLabel {
    final exp = _expiresAt;
    if (exp == null) return '';
    final left = exp.difference(DateTime.now());
    if (left.inSeconds <= 0) {
      return '인증 시간이 만료되었습니다. 재발송을 눌러 주세요.';
    }
    final total = left.inSeconds;
    final mm = total ~/ 60;
    final ss = total % 60;
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')} 내에 입력해주세요.';
  }

  String _formatPhoneForDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return raw.trim().isNotEmpty ? raw.trim() : '—';
  }

  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('82') && digits.length >= 11) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.length >= 9 && digits.length <= 11) {
      return '+82$digits';
    }
    if (digits.isNotEmpty) {
      return '+$digits';
    }
    return '';
  }

  bool _isKoreanMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^01[016789]\d{7,8}$').hasMatch(digits);
  }

  Future<void> _finalizePhoneVerified(PhoneAuthCredential credential) async {
    final repo = context.read<AuthRepository>();
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();
      await repo.completePhoneVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 인증이 완료되었습니다.')));
      context.go(AppRouter.signup);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증 처리 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _onResendCode() async {
    if (kIsWeb) return;
    final repo = context.read<AuthRepository>();
    final draft = repo.signupDraft;
    final session = repo.phoneVerificationSession;
    if (draft == null || session == null) {
      if (mounted) context.go(AppRouter.signup);
      return;
    }

    final rawPhone = draft.phoneNumber.trim();
    if (!_isKoreanMobile(rawPhone)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 다시 확인해주세요.')));
      return;
    }

    final phone = _toE164(rawPhone);
    setState(() => _submitting = true);
    try {
      await repo.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: session.forceResendingToken,
        verificationCompleted: (credential) {
          unawaited(_finalizePhoneVerified(credential));
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _submitting = false);
          final msg = e.message ?? e.code;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg.isEmpty ? '인증번호 재발송에 실패했습니다.' : msg)),
          );
        },
        codeSent: (verificationId, resendToken) {
          unawaited(_handleCodeSent(phone, verificationId, resendToken));
        },
        codeAutoRetrievalTimeout: (_) {
          if (mounted) setState(() => _submitting = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증번호 재발송에 실패했습니다: $e')));
    }
  }

  Future<void> _handleCodeSent(
    String phone,
    String verificationId,
    int? resendToken,
  ) async {
    await context.read<AuthRepository>().savePhoneVerificationSession(
      PhoneVerificationSession(
        verificationId: verificationId,
        phoneE164: phone,
        forceResendingToken: resendToken,
        expiresAtMillis: DateTime.now()
            .add(const Duration(minutes: 3))
            .millisecondsSinceEpoch,
      ),
    );
    if (!mounted) return;
    _codeController.clear();
    _expiresAt = DateTime.now().add(const Duration(minutes: 3));
    _startTicker();
    setState(() => _submitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증번호를 다시 보냈습니다.')));
  }

  Future<void> _onSubmit() async {
    final session = context.read<AuthRepository>().phoneVerificationSession;
    final code = _codeController.text.trim();
    if (session == null || code.length != 6 || _isExpired) return;

    setState(() => _submitting = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: session.verificationId,
        smsCode: code,
      );
      await _finalizePhoneVerified(credential);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호가 올바르지 않습니다.')));
    }
  }

  Future<void> _onBack() async {
    await context.read<AuthRepository>().clearPhoneVerificationSession();
    if (!mounted) return;
    context.go(AppRouter.signup);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AuthRepository>().signupDraft;
    final displayPhone = _formatPhoneForDisplay(draft?.phoneNumber ?? '');

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _onBack,
        ),
        title: const Text('인증번호 확인'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w400,
                          height: 32 / 24,
                          color: const Color(0xFF1D1D1F),
                        ),
                        children: [
                          TextSpan(text: '$displayPhone로 전송된\n'),
                          const TextSpan(text: '인증번호 '),
                          const TextSpan(text: '6자리'),
                          const TextSpan(text: '를 입력해 주세요.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),
                    AuthInputField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      hintText: '인증번호를 입력해주세요.',
                      focusedBorderColor: AppColors.primary,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _countdownLabel,
                      style: AppTypography.bodySmallR.copyWith(
                        color: AppColors.error,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                29.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '인증번호가 오지 않았나요? ',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.3,
                      color: AppColors.grey200,
                    ),
                  ),
                  GestureDetector(
                    onTap: _submitting ? null : _onResendCode,
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
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                8,
                AppSpacing.xl,
                (MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 20),
              ),
              child: FilledButton(
                onPressed:
                    _submitting ||
                        _codeController.text.trim().length != 6 ||
                        _isExpired
                    ? null
                    : _onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(56.h),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '다음',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: Colors.white,
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
