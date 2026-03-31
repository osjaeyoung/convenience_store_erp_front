import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../data/models/account_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
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
  AccountProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _withdrawing = false;
  Object? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  Future<void> _showPhoneDialog() async {
    final repo = context.read<AuthRepository>();
    final initial = _profile?.phoneNumber ?? '';
    final ctrl = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          '전화번호',
          style: AccountFigmaStyles.appBarTitle.copyWith(fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Firebase 전화 인증 후 서버에 반영하는 흐름에 맞춰, 인증된 번호를 입력해 주세요.',
              style: AccountFigmaStyles.fieldValue.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: AccountFigmaStyles.fieldValue,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.grey25,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                hintText: '01012345678',
                hintStyle: AccountFigmaStyles.fieldValue.copyWith(
                  color: AppColors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: AccountFigmaStyles.rowTitle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '저장',
              style: AccountFigmaStyles.rowTitle.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final digits = ctrl.text.trim();
    if (digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호 형식을 확인해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final p = await repo.patchAccount(phoneNumber: digits);
      if (mounted) {
        setState(() {
          _profile = p;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 저장되었습니다.')),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey25,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: TextField(
                              controller: _nameCtrl,
                              onEditingComplete: _saveNameIfChanged,
                              style: AccountFigmaStyles.fieldValue,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '이름을 입력해주세요.',
                                hintStyle: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14.sp,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _fieldBlock(
                          caption: '사용 유형',
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey25,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              p?.usageTypeLabelKo ?? '—',
                              style: AccountFigmaStyles.fieldValue,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _fieldBlock(
                          caption: '전화번호',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey25,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    (p?.phoneNumberMasked ?? p?.phoneNumber)
                                                ?.isNotEmpty ==
                                            true
                                        ? (p!.phoneNumberMasked ??
                                            p.phoneNumber!)
                                        : '등록된 번호 없음',
                                    style:
                                        (p?.phoneNumberMasked != null &&
                                                (p?.phoneNumberMasked ?? '')
                                                    .isNotEmpty)
                                            ? AccountFigmaStyles.fieldValueMuted
                                            : AccountFigmaStyles.fieldValue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              TextButton(
                                onPressed: _saving ? null : _showPhoneDialog,
                                style: AccountFigmaStyles.mintSmallActionStyle,
                                child: Text(
                                  '변경',
                                  style:
                                      AccountFigmaStyles.mintSmallActionLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (p?.hasPasswordLogin == true) ...[
                          SizedBox(height: 20.h),
                          _fieldBlock(
                            caption: '비밀번호',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grey25,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '**********',
                                      style:
                                          AccountFigmaStyles.fieldValueMuted,
                                    ),
                                  ),
                                  TextButton(
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
                                    style:
                                        AccountFigmaStyles.mintSmallActionStyle,
                                    child: Text(
                                      '변경',
                                      style: AccountFigmaStyles
                                          .mintSmallActionLabel,
                                    ),
                                  ),
                                ],
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
