import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/account_figma_styles.dart';
import 'account_change_password_screen.dart';
import 'account_password_verify_screen.dart';

class AccountPasswordCodeScreen extends StatefulWidget {
  const AccountPasswordCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.expiresAt,
    required this.entryPoint,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final DateTime expiresAt;
  final AccountPasswordEntryPoint entryPoint;

  @override
  State<AccountPasswordCodeScreen> createState() =>
      _AccountPasswordCodeScreenState();
}

class _AccountPasswordCodeScreenState extends State<AccountPasswordCodeScreen> {
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

  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+$digits';
  }

  Future<void> _resendCode() async {
    setState(() => _submitting = true);
    try {
      await context.read<AuthRepository>().verifyPhoneNumber(
            phoneNumber: _toE164(widget.phoneNumber),
            forceResendingToken: _resendToken,
            codeSent: (verificationId, resendToken) {
              if (!mounted) return;
              _codeController.clear();
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _expiresAt = DateTime.now().add(const Duration(minutes: 3));
                _submitting = false;
              });
              _startTicker();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('인증번호를 다시 보냈습니다.')),
              );
            },
            verificationFailed: (error) {
              if (!mounted) return;
              setState(() => _submitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message ?? error.code)),
              );
            },
            codeAutoRetrievalTimeout: (_) {},
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().length != 6 || _isExpired) return;
    setState(() => _submitting = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() => _submitting = false);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AccountChangePasswordScreen(
            phoneNumber: widget.phoneNumber,
            entryPoint: widget.entryPoint,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호가 올바르지 않습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(context: context, title: '인증번호 확인'),
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
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        height: 32 / 24,
                      ),
                      children: [
                        TextSpan(text: '${widget.phoneNumber}로 전송된\n'),
                        TextSpan(
                          text: '인증번호 6자리',
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400,
                            height: 32 / 24,
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '인증번호를 입력해주세요.',
                      filled: true,
                      fillColor: AppColors.grey0,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _countdownLabel,
                    style: AppTypography.bodySmallR.copyWith(
                      color: const Color(0xFFF4001D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 22.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '인증번호가 오지 않았나요? ',
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textSecondary,
                    height: 20 / 14,
                  ),
                ),
                GestureDetector(
                  onTap: _submitting ? null : _resendCode,
                  child: Text(
                    '재발송',
                    style: AppTypography.bodyMediumB.copyWith(
                      color: AppColors.primary,
                      height: 22 / 14,
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
                      : const Text('다음'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
