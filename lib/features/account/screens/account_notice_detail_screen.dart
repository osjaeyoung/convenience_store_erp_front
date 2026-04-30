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

class AccountNoticeDetailScreen extends StatefulWidget {
  const AccountNoticeDetailScreen({super.key, required this.noticeId});

  final int noticeId;

  @override
  State<AccountNoticeDetailScreen> createState() =>
      _AccountNoticeDetailScreenState();
}

class _AccountNoticeDetailScreenState extends State<AccountNoticeDetailScreen> {
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');

  AccountNotice? _notice;
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
      final notice = await context.read<AuthRepository>().getNoticeDetail(
        noticeId: widget.noticeId,
      );
      if (!mounted) return;
      setState(() {
        _notice = notice;
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
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '공지사항'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _AccountSupportErrorView(
              message: accountDioMessage(_error!),
              onRetry: _load,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              children: [
                Container(
                  constraints: BoxConstraints(minHeight: 320.h),
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey0,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _notice?.title ?? '',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          height: 24 / 16,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        _notice?.content ?? '',
                        style: AppTypography.bodyMediumR.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          height: 22 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '작성일 ${_formatDate(_notice?.publishedAt)}',
                    style: AppTypography.bodySmallR.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12.sp,
                      height: 18 / 12,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '-';
    return _dateFormat.format(parsed.toLocal());
  }
}

class _AccountSupportErrorView extends StatelessWidget {
  const _AccountSupportErrorView({
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
