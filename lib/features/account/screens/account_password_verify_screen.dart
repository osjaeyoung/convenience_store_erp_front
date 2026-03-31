import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../widgets/account_figma_styles.dart';
import 'account_change_password_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 비밀번호 변경 전 본인 확인 (Figma 2634:16196)
class AccountPasswordVerifyScreen extends StatefulWidget {
  const AccountPasswordVerifyScreen({super.key});

  @override
  State<AccountPasswordVerifyScreen> createState() =>
      _AccountPasswordVerifyScreenState();
}

class _AccountPasswordVerifyScreenState
    extends State<AccountPasswordVerifyScreen> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<AuthRepository>();
      repo.getAccountProfile().then((p) {
        if (!mounted) return;
        _nameCtrl.text = p.fullName;
        final raw = p.phoneNumber ?? '';
        _phoneCtrl.text = raw.replaceAll(RegExp(r'\D'), '');
      });
    });
  }

  void _onSendSms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증번호 전송은 Firebase 연동 후 사용할 수 있습니다.')),
    );
  }

  Future<void> _onComplete() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요.')),
      );
      return;
    }
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 확인해주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final p = await context.read<AuthRepository>().getAccountProfile();
      if (!mounted) return;
      if (p.fullName.trim() != name) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름이 계정 정보와 일치하지 않습니다.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const AccountChangePasswordScreen(),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(context: context, title: '비밀번호 변경'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이용하실 회원정보를\n입력해주세요.',
                    style: AccountFigmaStyles.verifyHeadline,
                  ),
                  SizedBox(height: 28.h),
                  Text('전화번호', style: AccountFigmaStyles.fieldCaption.copyWith(color: AccountFigmaStyles.titleColor)),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 12.w, 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.grey25,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+82',
                          style: AccountFigmaStyles.fieldValue,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.grey25,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: AccountFigmaStyles.fieldValue,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "'-'를 제외하고 입력",
                                    hintStyle: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16.sp,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _onSendSms,
                                style: AccountFigmaStyles.mintSmallActionStyle,
                                child: Text(
                                  '전송',
                                  style:
                                      AccountFigmaStyles.mintSmallActionLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text('이름', style: AccountFigmaStyles.fieldCaption.copyWith(color: AccountFigmaStyles.titleColor)),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.grey25,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      style: AccountFigmaStyles.fieldValue.copyWith(fontSize: 14.sp, height: 24 / 14),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.grey0,
                        ),
                      )
                    : Text(
                        '완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
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
