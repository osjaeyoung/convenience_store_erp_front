import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_input_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum _SignupStep { terms, basicInfo, role }

/// 회원가입 1차 페이지 (3단계)
/// 1) 약관 동의 → 2) 기본 정보 입력 → 3) 회원 유형 선택
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Set<String> _phoneVerificationBypassNumbers = {
    '01012345678', '01087654321',
  };
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  _SignupStep _currentStep = _SignupStep.terms;
  UserRole _selectedRole = UserRole.manager;
  bool _isCheckingPhoneNumber = false;
  bool _isSendingPhoneVerification = false;
  bool _isCheckingEmailDuplicate = false;
  bool _isEmailChecked = false;
  bool _isEmailAvailable = false;
  String _lastCheckedEmail = '';
  String? _verifiedPhoneDigits;
  bool _agreeTerms = false;
  bool _agreeAge = false;
  bool _agreePrivacy = false;
  bool _agreeThirdParty = false;
  bool _agreeMarketing = false;
  bool _submittedBasicInfo = false;
  bool _isAccountCompletionFlow = false;
  static const String _checkActiveIcon =
      'assets/icons/png/common/check_active.png';
  static const String _checkInactiveIcon =
      'assets/icons/png/common/check_inactive.png';

  @override
  void initState() {
    super.initState();
    final repo = context.read<AuthRepository>();
    _isAccountCompletionFlow = repo.isLoggedIn && repo.needsSignupCompletion;
    if (_isAccountCompletionFlow) {
      _prefillCompletionAccount(repo);
      _currentStep = _SignupStep.terms;
    }
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goNextStep() {
    if (_currentStep == _SignupStep.terms) {
      if (!_agreeTerms || !_agreeAge || !_agreePrivacy || !_agreeThirdParty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요.')));
        return;
      }
      setState(() => _currentStep = _SignupStep.basicInfo);
      return;
    }

    if (_currentStep == _SignupStep.basicInfo) {
      unawaited(_completeBasicInfoAndGoToRole());
    }
  }

  Future<void> _completeBasicInfoAndGoToRole() async {
    setState(() => _submittedBasicInfo = true);
    if (!_formKey.currentState!.validate()) return;
    if (!_isAccountCompletionFlow && (!_isEmailChecked || !_isEmailAvailable)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 중복 검사를 완료해주세요.')));
      return;
    }
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 인증을 완료해주세요.')));
      return;
    }

    final repo = context.read<AuthRepository>();
    final phoneNumber = _phoneController.text.trim();
    final currentPhoneDigits = _digitsOnly(repo.currentPhoneNumber);
    final nextPhoneDigits = _digitsOnly(phoneNumber);
    final bypassVerification = _isPhoneVerificationBypassed;
    setState(() => _isCheckingPhoneNumber = true);
    try {
      if (bypassVerification && currentPhoneDigits != nextPhoneDigits) {
        final result = await repo.checkPhoneNumberExists(phoneNumber: phoneNumber);
        if (!mounted) return;
        if (result.exists) {
          final message = result.hasPasswordLogin
              ? '이미 가입된 전화번호입니다.'
              : '이미 가입된 전화번호입니다. 소셜 계정으로 가입된 번호인지 확인해주세요.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          return;
        }
      }

      if (_isAccountCompletionFlow) {
        await repo.signupSocialProfile(
          fullName: _nameController.text.trim(),
          phoneNumber: phoneNumber,
          agreeTermsRequired: _agreeTerms,
          agreeAgeRequired: _agreeAge,
          agreePrivacyRequired: _agreePrivacy && _agreeThirdParty,
          agreeMarketingOptional: _agreeMarketing,
        );
        if (!mounted) return;
      }
      setState(() => _currentStep = _SignupStep.role);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isCheckingPhoneNumber = false);
    }
  }

  void _onSignupSubmit() {
    if (_isAccountCompletionFlow) {
      _proceedToSignupStep2();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_isEmailChecked || !_isEmailAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 중복 검사를 완료해주세요.')));
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignupStep1Requested(
        email: _emailController.text.trim(),
        password: _pwController.text,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        agreeTermsRequired: _agreeTerms,
        agreeAgeRequired: _agreeAge,
        agreePrivacyRequired: _agreePrivacy && _agreeThirdParty,
        agreeMarketingOptional: _agreeMarketing,
      ),
    );
  }

  void _proceedToSignupStep2() {
    if (_selectedRole == UserRole.jobSeeker) {
      context.read<AuthBloc>().add(const AuthSignupStep2WorkerRequested());
      return;
    }
    context.push(AppRouter.signupComplete, extra: _selectedRole);
  }

  void _prefillCompletionAccount(AuthRepository repo) {
    final email = repo.currentEmail;
    if (email != null) {
      _emailController.text = email;
      _isEmailChecked = true;
      _isEmailAvailable = true;
      _lastCheckedEmail = email;
    }
    final fullName = repo.currentFullName;
    if (fullName != null) {
      _nameController.text = fullName;
    }
    final phoneNumber = repo.currentPhoneNumber;
    if (phoneNumber != null) {
      _phoneController.text = phoneNumber;
    }
  }

  Future<void> _exitIncompleteSignup() async {
    await context.read<AuthRepository>().logout();
    if (!mounted) return;
    context.go(AppRouter.login);
  }

  bool get _isPhoneVerified {
    final current = _digitsOnly(_phoneController.text);
    if (current.isEmpty) return false;
    return current == _verifiedPhoneDigits || _phoneVerificationBypassNumbers.contains(current);
  }

  bool get _isPhoneVerificationBypassed =>
      _phoneVerificationBypassNumbers.contains(_digitsOnly(_phoneController.text));

  String get _phoneActionLabel {
    if (_isSendingPhoneVerification) return '';
    return _isPhoneVerified ? '인증완료' : '인증';
  }

  Future<void> _requestPhoneVerification() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 인증은 Android/iOS 앱에서 진행해 주세요.')),
      );
      return;
    }

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 입력해주세요.')));
      return;
    }
    if (!_isKoreanMobile(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 휴대폰 번호를 입력해주세요. (010 등)')),
      );
      return;
    }
    if (_isPhoneVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _isPhoneVerificationBypassed
                ? '테스트 번호는 인증 없이 진행됩니다.'
                : '휴대폰 인증이 완료되었습니다.',
          ),
        ),
      );
      return;
    }

    final repo = context.read<AuthRepository>();
    final currentPhoneDigits = _digitsOnly(repo.currentPhoneNumber);
    final nextPhoneDigits = _digitsOnly(phoneNumber);

    setState(() => _isSendingPhoneVerification = true);
    try {
      if (currentPhoneDigits != nextPhoneDigits) {
        final result = await repo.checkPhoneNumberExists(phoneNumber: phoneNumber);
        if (!mounted) return;
        if (result.exists) {
          final message = result.hasPasswordLogin
              ? '이미 가입된 전화번호입니다.'
              : '이미 가입된 전화번호입니다. 소셜 계정으로 가입된 번호인지 확인해주세요.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          return;
        }
      }

      await repo.verifyPhoneNumber(
        phoneNumber: _toE164(phoneNumber),
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() => _isSendingPhoneVerification = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('인증번호가 발송되었습니다.')));
          unawaited(
            _showPhoneVerificationDialog(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
            ),
          );
        },
        verificationCompleted: (credential) {
          unawaited(() async {
            try {
              await FirebaseAuth.instance.signInWithCredential(credential);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              setState(() {
                _isSendingPhoneVerification = false;
                _verifiedPhoneDigits = nextPhoneDigits;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('휴대폰 인증이 완료되었습니다.')));
            } catch (_) {
              if (!mounted) return;
              setState(() => _isSendingPhoneVerification = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('휴대폰 인증 처리 중 오류가 발생했습니다.')),
              );
            }
          }());
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => _isSendingPhoneVerification = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(content: Text(_friendlyFirebaseErrorMessage(error))),
          );
        },
        codeAutoRetrievalTimeout: (_) {
          if (!mounted) return;
          setState(() => _isSendingPhoneVerification = false);
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSendingPhoneVerification = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErrorMessage(error))));
    }
  }

  Future<void> _showPhoneVerificationDialog({
    required String phoneNumber,
    required String verificationId,
  }) async {
    final codeController = TextEditingController();
    String? errorText;
    var submitting = false;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitCode() async {
              if (submitting) return;
              final code = codeController.text.trim();
              if (code.length != 6) {
                setDialogState(() {
                  errorText = '인증번호 6자리를 입력해주세요.';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                errorText = null;
              });

              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: code,
                );
                await FirebaseAuth.instance.signInWithCredential(credential);
                await FirebaseAuth.instance.signOut();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (_) {
                setDialogState(() {
                  submitting = false;
                  errorText = '인증번호가 올바르지 않습니다.';
                });
              }
            }

            return AlertDialog(
              title: Text(
                '휴대폰 인증',
                style: AppTypography.bodyLargeB.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$phoneNumber 번호로 전송된 인증번호를 입력해주세요.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: codeController,
                    enabled: !submitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: '인증번호 6자리',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submitCode,
                  child: submitting
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.grey0,
                          ),
                        )
                      : const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();

    if (verified != true || !mounted) return;
    setState(() {
      _verifiedPhoneDigits = _digitsOnly(phoneNumber);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('휴대폰 인증이 완료되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? '회원가입에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state.isAuthenticated && state.user != null) {
          final repo = context.read<AuthRepository>();
          if (repo.needsSignupCompletion) return;
          final role = state.user!.role;
          context.go(
            role.isJobSeeker ? AppRouter.jobSeekerMain : AppRouter.managerMain,
          );
        }
        if (state.isSignupStep1Completed) {
          _proceedToSignupStep2();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.grey0,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (_currentStep == _SignupStep.terms) {
                  if (_isAccountCompletionFlow) {
                    unawaited(_exitIncompleteSignup());
                    return;
                  }
                  context.go(AppRouter.login);
                } else if (_currentStep == _SignupStep.basicInfo) {
                  if (_isAccountCompletionFlow) {
                    unawaited(_exitIncompleteSignup());
                    return;
                  }
                  setState(() => _currentStep = _SignupStep.terms);
                } else {
                  setState(() => _currentStep = _SignupStep.basicInfo);
                }
              },
            ),
            title: const Text('회원가입'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingXl,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStepHeader(),
                          SizedBox(height: 28.h),
                          _buildStepBody(),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
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
                    onPressed: state.status == AuthStatus.loading ||
                            _isCheckingPhoneNumber
                        ? null
                        : (_currentStep == _SignupStep.role
                              ? _onSignupSubmit
                              : _goNextStep),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(56.h),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: state.status == AuthStatus.loading ||
                            _isCheckingPhoneNumber
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _SignupStep.terms ? '회원가입' : '다음',
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
      },
    );
  }

  Widget _buildStepHeader() {
    switch (_currentStep) {
      case _SignupStep.terms:
        return Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24.sp,
              fontWeight: FontWeight.w400,
              height: 32 / 24,
              color: AppColors.textPrimary,
            ),
            children: const [
              TextSpan(text: '아래 약관에 동의 후\n'),
              TextSpan(
                text: '회원가입',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: ' 하실 수 있습니다.'),
            ],
          ),
        );
      case _SignupStep.basicInfo:
        return Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24.sp,
              fontWeight: FontWeight.w400,
              height: 32 / 24,
              color: AppColors.textPrimary,
            ),
            children: const [
              TextSpan(text: '가입을 위해\n아래 '),
              TextSpan(
                text: '정보',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: '를 입력해주세요.'),
            ],
          ),
        );
      case _SignupStep.role:
        return Text(
          '사용 목적을\n선택해주세요.',
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        );
    }
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case _SignupStep.terms:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.grey25),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final v =
                          !(_agreeTerms &&
                              _agreeAge &&
                              _agreePrivacy &&
                              _agreeThirdParty &&
                              _agreeMarketing);
                      setState(() {
                        _agreeTerms = v;
                        _agreeAge = v;
                        _agreePrivacy = v;
                        _agreeThirdParty = v;
                        _agreeMarketing = v;
                      });
                    },
                    child: Image.asset(
                      (_agreeTerms &&
                              _agreeAge &&
                              _agreePrivacy &&
                              _agreeThirdParty &&
                              _agreeMarketing)
                          ? _checkActiveIcon
                          : _checkInactiveIcon,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '전체 동의',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            _buildTermsRow(
              tag: '[필수]',
              title: '만 N세 이상',
              value: _agreeAge,
              onChanged: (v) => setState(() => _agreeAge = v),
            ),
            SizedBox(height: 10.h),
            _buildTermsRow(
              tag: '[필수]',
              title: '서비스 이용 약관',
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v),
            ),
            SizedBox(height: 10.h),
            _buildTermsRow(
              tag: '[필수]',
              title: '개인정보 수집 및 처리 방침',
              value: _agreePrivacy,
              onChanged: (v) => setState(() => _agreePrivacy = v),
            ),
            SizedBox(height: 10.h),
            _buildTermsRow(
              tag: '[필수]',
              title: '개인정보 제3자 제공 동의',
              value: _agreeThirdParty,
              onChanged: (v) => setState(() => _agreeThirdParty = v),
            ),
            SizedBox(height: 10.h),
            _buildTermsRow(
              tag: '[선택]',
              title: '마케팅 정보 수신 동의',
              value: _agreeMarketing,
              onChanged: (v) => setState(() => _agreeMarketing = v),
            ),
          ],
        );
      case _SignupStep.basicInfo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isAccountCompletionFlow) ...[
              _buildFieldLabel('이메일'),
              AuthInputField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: _submittedBasicInfo
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                hintText: '이메일을 입력해주세요.',
                focusedBorderColor: AppColors.primary,
                suffixIconConstraints: BoxConstraints(
                  minHeight: 0,
                  minWidth: 84.w,
                ),
                suffix: Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: SizedBox(
                    width: 72.w,
                    height: 28.h,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isCheckingEmailDuplicate
                            ? null
                            : _onCheckEmailDuplicate,
                        child: Container(
                          width: 72.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          alignment: Alignment.center,
                          child: _isCheckingEmailDuplicate
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.grey0,
                                  ),
                                )
                              : Text(
                                  '중복검사',
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
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return '*이메일을 입력해주세요.';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return '*올바른 이메일을 입력해주세요.';
                  }
                  if (_submittedBasicInfo &&
                      (!_isEmailChecked || !_isEmailAvailable)) {
                    return '*이메일 중복 검사를 완료해주세요.';
                  }
                  return null;
                },
              ),
            ],
            if (!_isAccountCompletionFlow && _isEmailChecked) ...[
              SizedBox(height: 6.h),
              Text(
                _isEmailAvailable
                    ? '사용 가능한 이메일입니다.'
                    : '이미 가입된 이메일입니다.',
                style: AppTypography.bodySmallR.copyWith(
                  color: _isEmailAvailable ? AppColors.primary : const Color(0xFFFF4834),
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _buildFieldLabel('이름'),
            AuthInputField(
              controller: _nameController,
              autovalidateMode: _submittedBasicInfo
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              hintText: '이름을 입력해주세요.',
              focusedBorderColor: AppColors.primary,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '*이름을 입력해주세요.' : null,
            ),
            if (_isAccountCompletionFlow &&
                _emailController.text.trim().isNotEmpty) ...[
              SizedBox(height: 20.h),
              _buildFieldLabel('이메일'),
              Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.grey0Alt,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey50),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  _emailController.text.trim(),
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textPrimary,
                    height: 19 / 14,
                  ),
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _buildFieldLabel('휴대폰 번호'),
            AuthInputField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              autovalidateMode: _submittedBasicInfo
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              hintText: '휴대폰 번호를 입력해주세요.',
              focusedBorderColor: AppColors.primary,
              suffixIconConstraints: BoxConstraints(
                minHeight: 0,
                minWidth: 72.w,
              ),
              suffix: Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: SizedBox(
                  width: 60.w,
                  height: 28.h,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isSendingPhoneVerification
                          ? null
                          : _requestPhoneVerification,
                      child: Container(
                        width: 60.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: _isPhoneVerified
                              ? AppColors.grey100
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: _isSendingPhoneVerification
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.grey0,
                                ),
                              )
                            : Text(
                                _phoneActionLabel,
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
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '*휴대폰 번호를 입력해주세요.';
                if (!_isKoreanMobile(t)) {
                  return '*올바른 휴대폰 번호를 입력해주세요. (010 등)';
                }
                return null;
              },
            ),
            if (_isPhoneVerified) ...[
              SizedBox(height: 6.h),
              Text(
                '휴대폰 인증이 완료되었습니다.',
                style: AppTypography.bodySmallR.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            if (!_isAccountCompletionFlow) ...[
              SizedBox(height: 20.h),
              _buildFieldLabel('비밀번호'),
              AuthInputField(
                controller: _pwController,
                obscureText: true,
                autovalidateMode: _submittedBasicInfo
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                hintText: '비밀번호를 입력해주세요.',
                focusedBorderColor: AppColors.primary,
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return '*비밀번호를 입력해주세요.';
                  final hasAlpha = RegExp(r'[A-Za-z]').hasMatch(value);
                  final hasNumber = RegExp(r'[0-9]').hasMatch(value);
                  final hasSpecial = RegExp(
                    r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]',
                  ).hasMatch(value);
                  if (value.length < 8 ||
                      !hasAlpha ||
                      !hasNumber ||
                      !hasSpecial) {
                    return '*영어, 숫자, 특수문자 중 2가지 이상을 포함해 8~16자를 입력해주세요.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              _buildFieldLabel('비밀번호 확인'),
              AuthInputField(
                controller: _pwConfirmController,
                obscureText: true,
                autovalidateMode: _submittedBasicInfo
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                hintText: '비밀번호를 한번 더 입력해주세요.',
                focusedBorderColor: AppColors.primary,
                validator: (v) {
                  if ((v ?? '').isEmpty) return '*비밀번호가 일치하지 않습니다.';
                  if (v != _pwController.text) return '*비밀번호가 일치하지 않습니다.';
                  return null;
                },
              ),
            ],
          ],
        );
      case _SignupStep.role:
        return Column(
          children: [
            _buildRoleTile(UserRole.manager, '사업주로 가입'),
            SizedBox(height: 12.h),
            _buildRoleTile(UserRole.storeManager, '점장으로 가입'),
            SizedBox(height: 12.h),
            _buildRoleTile(UserRole.jobSeeker, '근무자로 가입'),
          ],
        );
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: AppTypography.bodyMediumM.copyWith(
          color: AppColors.textPrimary,
          height: 16 / 14,
        ),
      ),
    );
  }

  String _digitsOnly(String? raw) {
    return (raw ?? '').replaceAll(RegExp(r'[^\d]'), '');
  }

  String _toE164(String phone) {
    final digits = _digitsOnly(phone);
    if (digits.startsWith('82') && digits.length >= 11) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+82${digits.substring(1)}';
    }
    if (digits.isNotEmpty) {
      return '+$digits';
    }
    return '';
  }

  /// 한국 휴대전화 (010, 011, 016~019)
  bool _isKoreanMobile(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^01[016789]\d{7,8}$').hasMatch(d);
  }

  bool _isValidEmailFormat(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  void _onEmailChanged() {
    final current = _emailController.text.trim();
    if (current == _lastCheckedEmail) return;
    if (!_isEmailChecked && !_isEmailAvailable) return;
    if (!mounted) return;
    setState(() {
      _isEmailChecked = false;
      _isEmailAvailable = false;
    });
  }

  Future<void> _onCheckEmailDuplicate() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      return;
    }
    if (!_isValidEmailFormat(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')));
      return;
    }

    setState(() => _isCheckingEmailDuplicate = true);
    try {
      final result = await context.read<AuthRepository>().checkEmailExists(
        email: email,
      );
      if (!mounted) return;
      final available = !result.exists;
      setState(() {
        _isEmailChecked = true;
        _isEmailAvailable = available;
        _lastCheckedEmail = email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            available ? '사용 가능한 이메일입니다.' : '이미 가입된 이메일입니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isCheckingEmailDuplicate = false);
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return _friendlyFirebaseErrorMessage(error);
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      String rawMessage;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map) {
            final loc = (first['loc'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .join('.');
            if (loc.contains('email')) return '이메일 정보를 다시 확인해주세요.';
            if (loc.contains('phone_number')) return '휴대폰 번호를 다시 확인해주세요.';
            if (loc.contains('password')) return '비밀번호를 다시 확인해주세요.';
          }
        }
        rawMessage =
            (data['message'] ?? data['detail'] ?? data['error'])?.toString() ??
            '';
      } else {
        rawMessage = error.message ?? '';
      }

      final normalized = rawMessage.toLowerCase();
      if (normalized.contains('email already registered')) {
        return '이미 가입된 이메일입니다.';
      }
      if (normalized.contains('manager') &&
          (normalized.contains('registration') ||
              normalized.contains('pre-registered') ||
              normalized.contains('not registered'))) {
        return '사업주가 사전 등록한 점장 정보와 일치하지 않습니다.';
      }
      if (RegExp(r'[가-힣]').hasMatch(rawMessage)) {
        return rawMessage;
      }
      switch (statusCode) {
        case 400:
          return '입력한 정보를 다시 확인해주세요.';
        case 401:
          return '인증 정보가 올바르지 않습니다.';
        case 403:
          return '접근 권한이 없습니다.';
        case 404:
          return '요청한 정보를 찾을 수 없습니다.';
        case 409:
          return '이미 등록된 정보입니다.';
        case 422:
          return '입력한 형식을 다시 확인해주세요.';
        default:
          return '요청 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (RegExp(r'[가-힣]').hasMatch(message)) return message;
    return '처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }

  String _friendlyFirebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return '올바른 휴대폰 번호를 입력해주세요.';
      case 'invalid-verification-code':
        return '인증번호가 올바르지 않습니다.';
      case 'session-expired':
        return '인증 시간이 만료되었습니다. 다시 시도해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'captcha-check-failed':
        return '휴대폰 인증 검증에 실패했습니다. 다시 시도해주세요.';
      default:
        final message = error.message?.trim();
        if (message != null && RegExp(r'[가-힣]').hasMatch(message)) {
          return message;
        }
        return '휴대폰 인증 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  Widget _buildTermsRow({
    required String tag,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            children: [
              Image.asset(
                value ? _checkActiveIcon : _checkInactiveIcon,
                width: 20,
                height: 20,
              ),
              SizedBox(width: 10.w),
              Text(
                tag,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 16 / 14,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(UserRole role, String label) {
    final selected = _selectedRole == role;
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey50,
          ),
          color: selected ? AppColors.primaryLight : AppColors.grey0,
        ),
        child: Row(
          children: [
            Image.asset(
              selected ? _checkActiveIcon : _checkInactiveIcon,
              width: 20,
              height: 20,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: AppTypography.bodyLargeM.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
