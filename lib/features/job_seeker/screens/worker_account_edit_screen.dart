import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/account_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
  }

  Future<void> _editPhoneNumber() async {
    final changed = await _showTextEditDialog(
      title: '휴대폰 번호',
      initialValue: _phoneController.text,
      hintText: '휴대폰 번호를 입력해주세요.',
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
    );
    if (changed == null || !mounted) return;
    setState(() => _phoneController.text = changed);
  }

  Future<void> _editAddress() async {
    final changed = await _showTextEditDialog(
      title: '주소',
      initialValue: _addressController.text,
      hintText: '주소를 입력해주세요.',
      confirmLabel: '완료',
    );
    if (changed == null || !mounted) return;
    setState(() => _addressController.text = changed);
  }

  Future<String?> _showTextEditDialog({
    required String title,
    required String initialValue,
    required String hintText,
    String confirmLabel = '저장',
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: AppTypography.bodyLargeB.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
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
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      return;
    }
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요.')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일은 연, 월, 일을 모두 선택해주세요.')),
      );
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
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원정보가 변경되었습니다.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
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
                      _EditableField(
                        label: '이메일',
                        child: _InputBox(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: _inputDecoration('등록된 이메일을 입력해주세요.'),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _EditableField(
                        label: '이름',
                        child: _InputBox(
                          child: TextField(
                            controller: _nameController,
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: _inputDecoration('이름을 입력해주세요.'),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _EditableField(
                        label: '생년월일',
                        child: Column(
                          children: [
                            _SelectBox(
                              label: _birthYear?.toString() ?? '년도',
                              hasValue: _birthYear != null,
                              onTap: _selectBirthYear,
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _SelectBox(
                                    label: _birthMonth?.toString() ?? '월',
                                    hasValue: _birthMonth != null,
                                    onTap: _selectBirthMonth,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Expanded(
                                  child: _SelectBox(
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
                      _EditableField(
                        label: '성별',
                        child: _SelectLikeBox(
                          label: _genderLabel ?? '성별을 입력해주세요.',
                          hasValue: _genderLabel != null,
                          onTap: _selectGender,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      _EditableField(
                        label: '휴대폰',
                        child: _ActionFieldBox(
                          value: _phoneController.text,
                          placeholder: '휴대폰 번호를 입력해주세요.',
                          actionLabel: '변경',
                          onActionTap: _editPhoneNumber,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _EditableField(
                        label: '주소',
                        child: _ActionFieldBox(
                          value: _addressController.text,
                          placeholder: '주소를 입력해주세요.',
                          actionLabel: '검색',
                          onActionTap: _editAddress,
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
                          onPressed: _saving ? null : _save,
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      border: InputBorder.none,
      hintText: hintText,
      hintStyle: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textDisabled,
      ),
      isDense: true,
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: child,
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.grey0Alt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectLikeBox extends StatelessWidget {
  const _SelectLikeBox({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.grey0Alt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMediumR.copyWith(
              color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionFieldBox extends StatelessWidget {
  const _ActionFieldBox({
    required this.value,
    required this.placeholder,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String value;
  final String placeholder;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasValue ? value : placeholder,
              style: AppTypography.bodyMediumR.copyWith(
                color: hasValue
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 32.h,
            child: FilledButton(
              onPressed: onActionTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.grey0,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: AppTypography.bodySmallB.copyWith(
                  color: AppColors.grey0,
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
