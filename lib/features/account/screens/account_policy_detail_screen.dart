import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/account_support_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';

class AccountPolicyDetailScreen extends StatefulWidget {
  const AccountPolicyDetailScreen({
    super.key,
    required this.policyType,
    this.fallbackTitle,
  });

  final String policyType;
  final String? fallbackTitle;

  @override
  State<AccountPolicyDetailScreen> createState() =>
      _AccountPolicyDetailScreenState();
}

class _AccountPolicyDetailScreenState extends State<AccountPolicyDetailScreen> {
  static final DateFormat _dateTimeFormat = DateFormat(
    'yyyy.MM.dd HH:mm:ss',
    'ko_KR',
  );

  AccountPolicyDetail? _detail;
  Object? _error;
  bool _loading = true;

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
      final detail = await context.read<AuthRepository>().getPolicyDetail(
            policyType: widget.policyType,
          );
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  @override
  Widget build(BuildContext context) {
    final title = _detail?.title ?? widget.fallbackTitle ?? _titleForType();
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _PolicyErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                  children: [
                    Container(
                      constraints: BoxConstraints(minHeight: 360.h),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.grey0,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _detail?.content ?? '',
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                              height: 20 / 14,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(_detail?.updatedAt),
                            style: AppTypography.bodySmallR.copyWith(
                              color: AppColors.textDisabled,
                              height: 18 / 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _titleForType() {
    switch (widget.policyType) {
      case 'privacy':
        return '개인정보처리방침';
      case 'terms':
      default:
        return '이용약관';
    }
  }

  String _formatDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '-';
    return _dateTimeFormat.format(parsed.toLocal());
  }
}

class _PolicyErrorView extends StatelessWidget {
  const _PolicyErrorView({
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
