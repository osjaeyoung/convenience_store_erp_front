import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  _SignupStep _currentStep = _SignupStep.terms;
  UserRole _selectedRole = UserRole.manager;
  bool _isPhoneVerified = false;
  bool _isSendingPhoneCode = false;
  bool _agreeTerms = false;
  bool _agreeAge = false;
  bool _agreePrivacy = false;
  bool _agreeThirdParty = false;
  bool _agreeMarketing = false;
  bool _submittedBasicInfo = false;
  bool _isResumedFromStep1 = false;
  static const String _checkActiveIcon =
      'assets/icons/png/common/check_active.png';
  static const String _checkInactiveIcon =
      'assets/icons/png/common/check_inactive.png';
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = context.read<AuthRepository>();
    _restoreSignupDraft(_authRepository.signupDraft);
    _authRepository.addListener(_onAuthRepositoryChanged);
    if (_authRepository.shouldStartAtRoleSelection) {
      _currentStep = _SignupStep.role;
      _isResumedFromStep1 = true;
    }
  }

  void _onAuthRepositoryChanged() {
    if (!mounted) return;
    final draft = _authRepository.signupDraft;
    if (draft == null) return;
    final formattedPhone = _formatPhoneForInput(draft.phoneNumber);
    var needsRebuild = false;

    if (draft.phoneVerified &&
        formattedPhone.isNotEmpty &&
        _phoneController.text.trim() != formattedPhone) {
      // 인증 완료로 readOnly가 되는 순간 iOS 컨텍스트 메뉴 충돌을 피하기 위해 먼저 포커스를 해제합니다.
      FocusManager.instance.primaryFocus?.unfocus();
      _phoneController.value = TextEditingValue(
        text: formattedPhone,
        selection: TextSelection.collapsed(offset: formattedPhone.length),
      );
    }

    if (_isPhoneVerified != draft.phoneVerified) {
      if (draft.phoneVerified) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _isPhoneVerified = draft.phoneVerified;
      needsRebuild = true;
    }

    if (needsRebuild) {
      setState(() {});
    }
  }

  void _restoreSignupDraft(SignupDraft? draft) {
    if (draft == null) return;
    _emailController.text = draft.email;
    _pwController.text = draft.password;
    _pwConfirmController.text = draft.password;
    _nameController.text = draft.fullName;
    _phoneController.text = _formatPhoneForInput(draft.phoneNumber);
    _agreeTerms = draft.agreeTerms;
    _agreeAge = draft.agreeAge;
    _agreePrivacy = draft.agreePrivacy;
    _agreeThirdParty = draft.agreeThirdParty;
    _agreeMarketing = draft.agreeMarketing;
    _isPhoneVerified = draft.phoneVerified;
    switch (draft.currentStep) {
      case 'role':
        _currentStep = _SignupStep.role;
        break;
      case 'basicInfo':
      case 'phone_verification':
        _currentStep = _SignupStep.basicInfo;
        break;
      default:
        _currentStep = _SignupStep.terms;
    }
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthRepositoryChanged);
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
      unawaited(_persistSignupDraft(currentStep: 'basicInfo'));
      return;
    }

    if (_currentStep == _SignupStep.basicInfo) {
      setState(() => _submittedBasicInfo = true);
      if (!_formKey.currentState!.validate()) return;
      if (!_isPhoneVerified) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('휴대폰 문자 인증을 완료해주세요.')));
        return;
      }
      setState(() => _currentStep = _SignupStep.role);
      unawaited(_persistSignupDraft(currentStep: 'role', phoneVerified: true));
      return;
    }
  }

  void _onSignupSubmit() {
    if (_isResumedFromStep1) {
      _proceedToSignupStep2();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

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

  Future<void> _persistSignupDraft({
    String? currentStep,
    bool? phoneVerified,
  }) async {
    await context.read<AuthRepository>().saveSignupDraft(
      SignupDraft(
        email: _emailController.text.trim(),
        password: _pwController.text,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        agreeTerms: _agreeTerms,
        agreeAge: _agreeAge,
        agreePrivacy: _agreePrivacy,
        agreeThirdParty: _agreeThirdParty,
        agreeMarketing: _agreeMarketing,
        currentStep: currentStep ?? _currentStep.name,
        phoneVerified: phoneVerified ?? _isPhoneVerified,
      ),
    );
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
                  context.go(AppRouter.login);
                } else if (_currentStep == _SignupStep.basicInfo) {
                  setState(() => _currentStep = _SignupStep.terms);
                  unawaited(_persistSignupDraft(currentStep: 'terms'));
                } else {
                  if (_isResumedFromStep1) {
                    context.pop();
                  } else {
                    setState(() => _currentStep = _SignupStep.basicInfo);
                    unawaited(_persistSignupDraft(currentStep: 'basicInfo'));
                  }
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
                    onPressed: state.status == AuthStatus.loading
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
                    child: state.status == AuthStatus.loading
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
            _buildFieldLabel('이메일'),
            AuthInputField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: _submittedBasicInfo
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              hintText: '이메일을 입력해주세요.',
              focusedBorderColor: AppColors.primary,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return '*이메일을 입력해주세요.';
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value)) {
                  return '*올바른 이메일을 입력해주세요.';
                }
                return null;
              },
            ),
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
            SizedBox(height: 20.h),
            _buildFieldLabel('휴대폰 인증'),
            _isPhoneVerified
                ? Container(
                    height: 52.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey0Alt,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey50),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _resolvedVerifiedPhoneText(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                              height: 19 / 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '인증완료',
                          style: AppTypography.bodySmallB.copyWith(
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                : AuthInputField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: _submittedBasicInfo
                        ? AutovalidateMode.always
                        : AutovalidateMode.disabled,
                    hintText: '휴대폰 번호를 입력해주세요.',
                    focusedBorderColor: AppColors.primary,
                    suffixIconConstraints: BoxConstraints(
                      minHeight: 0,
                      minWidth: 55.w,
                    ),
                    suffix: Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: SizedBox(
                        width: 43.w,
                        height: 24.h,
                        child: Center(
                          child: GestureDetector(
                            onTap: _isSendingPhoneCode
                                ? null
                                : _onRequestPhoneVerification,
                            child: Container(
                              width: 43.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              alignment: Alignment.center,
                              child: _isSendingPhoneCode
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
                                        fontSize: 12.sp,
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

  String _formatPhoneForInput(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('82') && digits.length >= 11) {
      final local = '0${digits.substring(2)}';
      if (local.length == 11) {
        return '${local.substring(0, 3)}-${local.substring(3, 7)}-${local.substring(7)}';
      }
      if (local.length == 10) {
        return '${local.substring(0, 3)}-${local.substring(3, 6)}-${local.substring(6)}';
      }
    }
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone.trim();
  }

  String _resolvedVerifiedPhoneText() {
    final fromController = _phoneController.text.trim();
    if (fromController.isNotEmpty) return fromController;
    final fromDraft = _authRepository.signupDraft?.phoneNumber ?? '';
    return _formatPhoneForInput(fromDraft);
  }

  /// 한국 휴대전화 (010, 011, 016~019)
  bool _isKoreanMobile(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^01[016789]\d{7,8}$').hasMatch(d);
  }

  Future<void> _onRequestPhoneVerification() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 문자 인증은 Android/iOS 앱에서 진행해 주세요.')),
      );
      return;
    }

    final raw = _phoneController.text.trim();
    if (!_isKoreanMobile(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 번호를 확인해 주세요. (예: 01012345678)')),
      );
      return;
    }

    final phone = _toE164(raw);
    if (phone.length < 12) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 전화번호를 입력해주세요.')));
      return;
    }

    final repo = context.read<AuthRepository>();
    setState(() => _isSendingPhoneCode = true);
    try {
      final existsResult = await repo.checkPhoneNumberExists(
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      if (existsResult.exists) {
        final message = existsResult.hasPasswordLogin
            ? '이미 가입된 전화번호입니다.'
            : '이미 가입된 전화번호입니다. 소셜 계정으로 가입된 번호인지 확인해주세요.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _isSendingPhoneCode = false);
        return;
      }

      await repo.clearPhoneVerificationSession(notify: false);
      await repo.saveSignupDraft(
        SignupDraft(
          email: _emailController.text.trim(),
          password: _pwController.text,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          agreeTerms: _agreeTerms,
          agreeAge: _agreeAge,
          agreePrivacy: _agreePrivacy,
          agreeThirdParty: _agreeThirdParty,
          agreeMarketing: _agreeMarketing,
          currentStep: 'phone_verification',
          phoneVerified: false,
        ),
      );
      if (!mounted) return;
      setState(() => _isSendingPhoneCode = false);
      context.go(AppRouter.signupPhoneVerification);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSendingPhoneCode = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
