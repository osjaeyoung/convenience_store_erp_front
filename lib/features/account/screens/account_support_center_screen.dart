import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/account_support_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';

/// Figma 고객센터 이메일 (서버 `support_email` 미사용)
const String _kSupportCenterEmail = 'abcd@google.com';

/// Figma 링크 색 `color: #548AFF`
const Color _kSupportEmailLinkColor = Color(0xFF548AFF);

class AccountSupportCenterScreen extends StatefulWidget {
  const AccountSupportCenterScreen({super.key});

  @override
  State<AccountSupportCenterScreen> createState() =>
      _AccountSupportCenterScreenState();
}

class _AccountSupportCenterScreenState extends State<AccountSupportCenterScreen> {
  AccountSupportCenterData? _data;
  Object? _error;
  bool _loading = true;
  int? _expandedFaqId;

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
      final data = await context.read<AuthRepository>().getSupportCenter();
      if (!mounted) return;
      setState(() {
        _data = data;
        _expandedFaqId = data.faqs.isNotEmpty ? data.faqs.first.faqId : null;
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

  Future<void> _openSupportEmail() async {
    final trimmed = _kSupportCenterEmail.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: trimmed,
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 앱을 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final faqBlock = _loading && data == null
        ? Padding(
            padding: EdgeInsets.only(top: 48.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        : _error != null && data == null
            ? Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: _SupportErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자주 묻는 질문',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                      height: 24 / 16,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  if ((data?.faqs ?? const []).isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Center(
                        child: Text(
                          '등록된 FAQ가 없습니다.',
                          style: AppTypography.bodyMediumR.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...data!.faqs.map(
                      (faq) => _FaqTile(
                        faq: faq,
                        expanded: _expandedFaqId == faq.faqId,
                        onTap: () {
                          setState(() {
                            _expandedFaqId =
                                _expandedFaqId == faq.faqId ? null : faq.faqId;
                          });
                        },
                      ),
                    ),
                ],
              );

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '고객센터'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          children: [
            SizedBox(height: 16.h),
            _SupportEmailCard(
              onTap: _openSupportEmail,
            ),
            SizedBox(height: 28.h),
            faqBlock,
          ],
        ),
      ),
    );
  }
}

class _SupportEmailCard extends StatelessWidget {
  const _SupportEmailCard({required this.onTap});

  final VoidCallback onTap;

  /// Body medium_R / 14 Regular / line-height 20px, color #548AFF
  static TextStyle get _emailStyle => AppTypography.bodyMediumR.copyWith(
        color: _kSupportEmailLinkColor,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey25,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
          decoration: BoxDecoration(
            color: AppColors.grey25,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '고객센터',
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textSecondary,
                    height: 20 / 14,
                  ),
                ),
              ),
              Text(
                _kSupportCenterEmail,
                style: _emailStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  final AccountFaq faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textPrimary,
                      height: 20 / 14,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20.r,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            color: AppColors.grey25,
            child: Text(
              faq.answer,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                height: 24 / 14,
              ),
            ),
          ),
        Divider(color: AppColors.border, height: 1.h),
      ],
    );
  }
}

class _SupportErrorView extends StatelessWidget {
  const _SupportErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
