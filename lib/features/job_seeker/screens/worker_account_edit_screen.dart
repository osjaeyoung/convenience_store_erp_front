import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpostal/kpostal.dart';

import '../../../data/models/account_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../../account/widgets/account_form_fields.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../widgets/worker_common.dart';

class WorkerAccountEditScreen extends StatefulWidget {
  const WorkerAccountEditScreen({super.key});

  @override
  State<WorkerAccountEditScreen> createState() =>
      _WorkerAccountEditScreenState();
}

class _WorkerAccountEditScreenState extends State<WorkerAccountEditScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  AccountProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  int? _birthYear;
  int? _birthMonth;
  int? _birthDay;
  String? _gender;
  String _originalPhoneNumber = '';
  String? _phoneConfirmedValue;
  bool _checkingPhone = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handlePhoneChanged);
    _load();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChanged);
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<AuthRepository>().getAccountProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _applyProfile(AccountProfile profile) {
    _emailController.text = profile.email;
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _addressController.text = profile.address ?? '';
    _birthYear = profile.birthYear;
    _birthMonth = profile.birthMonth;
    _birthDay = profile.birthDay;
    _gender = profile.gender;
    _originalPhoneNumber = _normalizePhoneNumber(profile.phoneNumber ?? '');
    _phoneConfirmedValue = _originalPhoneNumber;
  }

  void _handlePhoneChanged() {
    final currentPhone = _normalizePhoneNumber(_phoneController.text);
    if (_phoneConfirmedValue != null && currentPhone != _phoneConfirmedValue) {
      setState(() {
        _phoneConfirmedValue = null;
      });
    }
  }

  String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _toE164(String phone) {
    final digits = _normalizePhoneNumber(phone);
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+82${digits.substring(1)}';
    }
    return '+$digits';
  }

  bool _isValidPhoneNumber(String value) {
    return RegExp(r'^01[0-9]{8,9}$').hasMatch(value);
  }

  bool get _didPhoneChange {
    return _normalizePhoneNumber(_phoneController.text) != _originalPhoneNumber;
  }

  bool get _isCurrentPhoneVerified {
    final currentPhone = _normalizePhoneNumber(_phoneController.text);
    return currentPhone.isNotEmpty && currentPhone == _phoneConfirmedValue;
  }

  bool get _canSave {
    return !_saving &&
        !_checkingPhone &&
        (!_didPhoneChange || _isCurrentPhoneVerified);
  }

  String get _phoneActionLabel {
    final currentPhone = _normalizePhoneNumber(_phoneController.text);
    if (currentPhone.isEmpty || currentPhone == _originalPhoneNumber) {
      return '변경';
    }
    return _isCurrentPhoneVerified ? '인증완료' : '인증';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      _phoneConfirmedValue = _normalizePhoneNumber(phoneNumber);
    });
    _showMessage('휴대폰 인증이 완료되었습니다.');
  }

  Future<void> _verifyPhoneNumberChange() async {
    final candidate = _normalizePhoneNumber(_phoneController.text);
    if (candidate.isEmpty) {
      _showMessage('새 휴대폰 번호를 입력해주세요.');
      return;
    }
    if (!_isValidPhoneNumber(candidate)) {
      _showMessage('올바른 휴대폰 번호를 입력해주세요.');
      return;
    }
    if (candidate == _phoneConfirmedValue) {
      _showMessage('휴대폰 인증이 완료되었습니다.');
      return;
    }
    if (candidate == _originalPhoneNumber) {
      setState(() {
        _phoneConfirmedValue = candidate;
      });
      _showMessage('휴대폰 번호가 변경되지 않았습니다.');
      return;
    }

    setState(() => _checkingPhone = true);
    try {
      final result = await context
          .read<AuthRepository>()
          .checkPhoneNumberExists(phoneNumber: candidate);
      if (!mounted) return;
      if (result.exists) {
        setState(() {
          _checkingPhone = false;
          _phoneConfirmedValue = null;
        });
        _showMessage('이미 사용 중인 휴대폰 번호입니다.');
        return;
      }

      await context.read<AuthRepository>().verifyPhoneNumber(
            phoneNumber: _toE164(candidate),
            codeSent: (verificationId, _) {
              if (!mounted) return;
              setState(() => _checkingPhone = false);
              _showMessage('인증번호가 발송되었습니다.');
              unawaited(
                _showPhoneVerificationDialog(
                  phoneNumber: candidate,
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
                    _checkingPhone = false;
                    _phoneConfirmedValue = candidate;
                  });
                  _showMessage('휴대폰 인증이 완료되었습니다.');
                } catch (_) {
                  if (!mounted) return;
                  setState(() => _checkingPhone = false);
                  _showMessage('휴대폰 인증 처리 중 오류가 발생했습니다.');
                }
              }());
            },
            verificationFailed: (error) {
              if (!mounted) return;
              setState(() => _checkingPhone = false);
              _showMessage(error.message ?? error.code);
            },
            codeAutoRetrievalTimeout: (_) {
              if (!mounted) return;
              setState(() => _checkingPhone = false);
            },
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingPhone = false);
      _showMessage(accountDioMessage(error));
    }
  }

  Future<void> _searchAddress() async {
    final result = await Navigator.of(
      context,
    ).push<Kpostal>(MaterialPageRoute<Kpostal>(builder: (_) => KpostalView()));
    if (!mounted || result == null) return;
    final address = result.address.trim();
    if (address.isEmpty) return;
    _addressController.text = address;
    setState(() {});
  }

  Future<void> _selectBirthYear() async {
    final currentYear = DateTime.now().year;
    final years = [
      for (int year = currentYear; year >= 1950; year--)
        _PickerOption<int>(value: year, label: '$year'),
    ];
    final selected = await _showPickerSheet(
      title: '년도 선택',
      options: years,
      currentValue: _birthYear,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthYear = selected;
      final maxDay = _maxDayFor(_birthYear, _birthMonth);
      if (_birthDay != null && _birthDay! > maxDay) {
        _birthDay = maxDay;
      }
    });
  }

  Future<void> _selectBirthMonth() async {
    final months = [
      for (int month = 1; month <= 12; month++)
        _PickerOption<int>(value: month, label: '$month'),
    ];
    final selected = await _showPickerSheet(
      title: '월 선택',
      options: months,
      currentValue: _birthMonth,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthMonth = selected;
      final maxDay = _maxDayFor(_birthYear, _birthMonth);
      if (_birthDay != null && _birthDay! > maxDay) {
        _birthDay = maxDay;
      }
    });
  }

  Future<void> _selectBirthDay() async {
    final maxDay = _maxDayFor(_birthYear, _birthMonth);
    final days = [
      for (int day = 1; day <= maxDay; day++)
        _PickerOption<int>(value: day, label: '$day'),
    ];
    final selected = await _showPickerSheet(
      title: '일 선택',
      options: days,
      currentValue: _birthDay,
    );
    if (selected == null || !mounted) return;
    setState(() => _birthDay = selected);
  }

  Future<void> _selectGender() async {
    final selected = await _showPickerSheet(
      title: '성별 선택',
      options: const [
        _PickerOption<String>(value: 'male', label: '남성'),
        _PickerOption<String>(value: 'female', label: '여성'),
      ],
      currentValue: _gender,
    );
    if (selected == null || !mounted) return;
    setState(() => _gender = selected);
  }

  Future<T?> _showPickerSheet<T>({
    required String title,
    required List<_PickerOption<T>> options,
    required T? currentValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.grey0,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        title: Text(
                          option.label,
                          style: AppTypography.bodyMediumM.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: currentValue == option.value
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(option.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _maxDayFor(int? year, int? month) {
    final safeYear = year ?? 2000;
    final safeMonth = month ?? 1;
    return DateTime(safeYear, safeMonth + 1, 0).day;
  }

  String? get _genderLabel {
    switch (_gender) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      default:
        return null;
    }
  }

  Future<void> _save() async {
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);
    if (email.isEmpty) {
      _showMessage('이메일을 입력해주세요.');
      return;
    }
    if (fullName.isEmpty) {
      _showMessage('이름을 입력해주세요.');
      return;
    }
    if (phoneNumber.isNotEmpty && !_isValidPhoneNumber(phoneNumber)) {
      _showMessage('올바른 휴대폰 번호를 입력해주세요.');
      return;
    }
    if (phoneNumber != _originalPhoneNumber &&
        _phoneConfirmedValue != phoneNumber) {
      _showMessage('변경된 휴대폰 번호 인증을 완료해주세요.');
      return;
    }
    final hasPartialBirthDate = [
      _birthYear,
      _birthMonth,
      _birthDay,
    ].where((value) => value != null).isNotEmpty;
    final isBirthDateComplete =
        _birthYear != null && _birthMonth != null && _birthDay != null;
    if (hasPartialBirthDate && !isBirthDateComplete) {
      _showMessage('생년월일은 연, 월, 일을 모두 선택해주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await context.read<AuthRepository>().patchAccount(
        email: email,
        fullName: fullName,
        birthYear: _birthYear,
        birthMonth: _birthMonth,
        birthDay: _birthDay,
        gender: _gender,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );
      if (!mounted) return;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _saving = false;
      });

      if (profile.sessionRefreshRequired) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('다시 로그인 필요'),
              content: const Text('이메일이 변경되어 다시 로그인해야 합니다.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
        if (!mounted) return;
        context.read<AuthBloc>().add(const AuthLogoutRequested());
        return;
      }

      _showMessage('회원정보가 변경되었습니다.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(accountDioMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: workerSubPageAppBar(context, title: '회원정보 수정'),
      body: _loading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _profile == null
          ? workerErrorView(message: accountDioMessage(_error!), onRetry: _load)
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 112.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AccountFieldSection(
                        label: '이메일',
                        child: AccountGreyTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: '등록된 이메일을 입력해주세요.',
                        ),
                      ),
                      SizedBox(height: 20.h),
                      AccountFieldSection(
                        label: '이름',
                        child: AccountGreyTextField(
                          controller: _nameController,
                          hintText: '이름을 입력해주세요.',
                        ),
                      ),
                      SizedBox(height: 20.h),
                      AccountFieldSection(
                        label: '생년월일',
                        child: Column(
                          children: [
                            AccountGreySelectField(
                              label: _birthYear?.toString() ?? '년도',
                              hasValue: _birthYear != null,
                              onTap: _selectBirthYear,
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: AccountGreySelectField(
                                    label: _birthMonth?.toString() ?? '월',
                                    hasValue: _birthMonth != null,
                                    onTap: _selectBirthMonth,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Expanded(
                                  child: AccountGreySelectField(
                                    label: _birthDay?.toString() ?? '일',
                                    hasValue: _birthDay != null,
                                    onTap: _selectBirthDay,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      AccountFieldSection(
                        label: '성별',
                        child: AccountGreySelectField(
                          label: _genderLabel ?? '성별을 입력해주세요.',
                          hasValue: _genderLabel != null,
                          onTap: _selectGender,
                          showArrow: false,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      AccountFieldSection(
                        label: '휴대폰',
                        child: AccountGreyActionField(
                          controller: _phoneController,
                          placeholder: '휴대폰 번호를 입력해주세요.',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          actionLabel: _phoneActionLabel,
                          onActionTap: _verifyPhoneNumberChange,
                          onChanged: (_) => setState(() {}),
                          enabled: !_checkingPhone && !_saving,
                        ),
                      ),
                      if (_didPhoneChange && !_isCurrentPhoneVerified) ...[
                        SizedBox(height: 8.h),
                        Text(
                          '전화번호가 변경되어 인증이 필요합니다.',
                          style: AppTypography.bodySmallM.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      AccountFieldSection(
                        label: '주소',
                        child: AccountGreyActionField(
                          controller: _addressController,
                          placeholder: '주소를 입력해주세요.',
                          actionLabel: '검색',
                          onActionTap: _searchAddress,
                          readOnly: true,
                          enabled: !_saving,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.grey0,
                            disabledBackgroundColor: AppColors.grey100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 22.r,
                                  height: 22.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.grey0,
                                  ),
                                )
                              : Text(
                                  '변경',
                                  style: AppTypography.bodyLargeB.copyWith(
                                    color: AppColors.grey0,
                                  ),
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

class _PickerOption<T> {
  const _PickerOption({required this.value, required this.label});

  final T value;
  final String label;
}
