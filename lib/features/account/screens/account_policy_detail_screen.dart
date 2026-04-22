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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grey0,
                        contentPadding: EdgeInsets.all(16.r),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.grey100,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.grey100,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.grey100,
                          ),
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: 360.h),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _policyBodyOnly(
                              _detail?.content,
                              _detail?.updatedAt,
                            ),
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatDate(_detail?.updatedAt),
                        style: AppTypography.bodySmallR.copyWith(
                          color: AppColors.textDisabled,
                          height: 18 / 12,
                        ),
                      ),
                    ),
                  ],
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

  /// 본문에 API가 붙인 날짜/시간 줄이 있으면 제거해 본문에는 약관 텍스트만 남깁니다.
  String _policyBodyOnly(String? content, String? updatedAt) {
    var text = (content ?? '').trimRight();
    if (text.isEmpty) return text;

    final tsLine = RegExp(
      r'^\s*('
      r'\d{4}[-./]\d{1,2}[-./]\d{1,2}'
      r'([ T]\d{1,2}:\d{2}(:\d{2})?)?'
      r'|\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?'
      r')\s*$',
    );
    var lines = text.split('\n');
    while (lines.isNotEmpty && tsLine.hasMatch(lines.last.trim())) {
      lines.removeLast();
    }
    text = lines.join('\n').trimRight();

    if (updatedAt != null) {
      final formatted = _formatDate(updatedAt);
      if (formatted != '-' && text.endsWith(formatted)) {
        text = text.substring(0, text.length - formatted.length).trimRight();
      }
    }
    return text;
  }
}

class _PolicyErrorView extends StatelessWidget {
  const _PolicyErrorView({required this.message, required this.onRetry});

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
