import 'package:firebase_auth/firebase_auth.dart';
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

enum _SignupStep {
  terms,
  basicInfo,
  role,
}

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
  final _phoneCodeController = TextEditingController();

  _SignupStep _currentStep = _SignupStep.terms;
  UserRole _selectedRole = UserRole.manager;
  String? _phoneVerificationId;
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

  @override
  void initState() {
    super.initState();
    final authRepository = context.read<AuthRepository>();
    if (authRepository.shouldStartAtRoleSelection) {
      _currentStep = _SignupStep.role;
      _isResumedFromStep1 = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  void _goNextStep() {
    if (_currentStep == _SignupStep.terms) {
      if (!_agreeTerms || !_agreeAge || !_agreePrivacy || !_agreeThirdParty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 약관에 동의해주세요.')),
        );
        return;
      }
      setState(() => _currentStep = _SignupStep.basicInfo);
      return;
    }

    if (_currentStep == _SignupStep.basicInfo) {
      setState(() => _submittedBasicInfo = true);
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = _SignupStep.role);
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_currentStep == _SignupStep.terms) {
                  context.pop();
                } else if (_currentStep == _SignupStep.basicInfo) {
                  setState(() => _currentStep = _SignupStep.terms);
                } else {
                  if (_isResumedFromStep1) {
                    context.pop();
                  } else {
                    setState(() => _currentStep = _SignupStep.basicInfo);
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
                          const SizedBox(height: 28),
                          _buildStepBody(),
                          const SizedBox(height: 16),
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
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24,
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
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.grey0Alt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey25),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final v = !(_agreeTerms &&
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
                  const SizedBox(width: 10),
                  const Text(
                    '전체 동의',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildTermsRow(
              tag: '[필수]',
              title: '만 N세 이상',
              value: _agreeAge,
              onChanged: (v) => setState(() => _agreeAge = v),
            ),
            const SizedBox(height: 10),
            _buildTermsRow(
              tag: '[필수]',
              title: '서비스 이용 약관',
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v),
            ),
            const SizedBox(height: 10),
            _buildTermsRow(
              tag: '[필수]',
              title: '개인정보 수집 및 처리 방침',
              value: _agreePrivacy,
              onChanged: (v) => setState(() => _agreePrivacy = v),
            ),
            const SizedBox(height: 10),
            _buildTermsRow(
              tag: '[필수]',
              title: '개인정보 제3자 제공 동의',
              value: _agreeThirdParty,
              onChanged: (v) => setState(() => _agreeThirdParty = v),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _buildFieldLabel('휴대폰 인증'),
            AuthInputField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autovalidateMode: _submittedBasicInfo
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              hintText: '휴대폰 번호를 입력해주세요.',
              focusedBorderColor: AppColors.primary,
              enabled: !_isPhoneVerified,
              suffix: _isPhoneVerified
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        '인증완료',
                        style: AppTypography.bodySmallB.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6),
                      child: FilledButton(
                        onPressed: _isSendingPhoneCode
                            ? null
                            : (_phoneVerificationId == null
                                ? _onRequestPhoneVerification
                                : _onVerifyPhoneCode),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 34),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSendingPhoneCode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.grey0,
                                ),
                              )
                            : Text(
                                _phoneVerificationId == null
                                    ? '인증번호 요청'
                                    : '인증',
                                style: AppTypography.bodySmallB.copyWith(
                                  color: AppColors.grey0,
                                ),
                              ),
                      ),
                    ),
              validator: (v) {
                if (_isPhoneVerified) return null;
                if (_phoneVerificationId == null) {
                  return (v == null || v.trim().isEmpty)
                      ? '*휴대폰 번호를 입력해주세요.'
                      : null;
                }
                return '*인증을 완료해주세요.';
              },
            ),
            if (_phoneVerificationId != null && !_isPhoneVerified) ...[
              const SizedBox(height: 12),
              AuthInputField(
                controller: _phoneCodeController,
                keyboardType: TextInputType.number,
                autovalidateMode: _submittedBasicInfo
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                hintText: '인증번호 6자리를 입력해주세요.',
                focusedBorderColor: AppColors.primary,
                validator: (v) {
                  if (_isPhoneVerified) return null;
                  final code = (v ?? '').trim();
                  if (code.isEmpty) return '*인증번호를 입력해주세요.';
                  if (code.length != 6) return '*인증번호 6자리를 입력해주세요.';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
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
                final hasSpecial =
                    RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]').hasMatch(value);
                if (value.length < 8 || !hasAlpha || !hasNumber || !hasSpecial) {
                  return '*영어, 숫자, 특수문자 중 2가지 이상을 포함해 8~16자를 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            _buildRoleTile(UserRole.storeManager, '점장으로 가입'),
            const SizedBox(height: 12),
            _buildRoleTile(UserRole.jobSeeker, '근무자로 가입'),
          ],
        );
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.length == 10 || digits.length == 11) {
      return '+82$digits';
    }
    if (!digits.startsWith('82')) {
      return '+82$digits';
    }
    return '+$digits';
  }

  Future<void> _onRequestPhoneVerification() async {
    final phone = _toE164(_phoneController.text.trim());
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 전화번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _isSendingPhoneCode = true);
    try {
      await context.read<AuthRepository>().verifyPhoneNumber(
            phoneNumber: phone,
            codeSent: (verificationId, _) {
              if (mounted) {
                setState(() {
                  _phoneVerificationId = verificationId;
                  _isSendingPhoneCode = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('인증번호가 발송되었습니다.')),
                );
              }
            },
            verificationFailed: (e) {
              if (mounted) {
                setState(() => _isSendingPhoneCode = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.message ?? '인증번호 발송에 실패했습니다.',
                    ),
                  ),
                );
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingPhoneCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호 발송에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _onVerifyPhoneCode() async {
    final code = _phoneCodeController.text.trim();
    if (code.isEmpty || _phoneVerificationId == null) return;
    setState(() => _isSendingPhoneCode = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _phoneVerificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _isPhoneVerified = true;
          _isSendingPhoneCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('휴대폰 인증이 완료되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingPhoneCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 일치하지 않습니다.')),
        );
      }
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Image.asset(
                value ? _checkActiveIcon : _checkInactiveIcon,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tag,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 16 / 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey100,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(UserRole role, String label) {
    final selected = _selectedRole == role;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 10),
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
