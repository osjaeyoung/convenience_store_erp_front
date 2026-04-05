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

class AccountInquiryDetailScreen extends StatefulWidget {
  const AccountInquiryDetailScreen({
    super.key,
    required this.inquiryId,
  });

  final int inquiryId;

  @override
  State<AccountInquiryDetailScreen> createState() =>
      _AccountInquiryDetailScreenState();
}

class _AccountInquiryDetailScreenState extends State<AccountInquiryDetailScreen> {
  static final DateFormat _dateTimeFormat = DateFormat(
    'yyyy.MM.dd HH:mm',
    'ko_KR',
  );

  AccountInquiry? _inquiry;
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
    final repo = context.read<AuthRepository>();
    try {
      final inquiry = await repo.getInquiryDetail(
            inquiryId: widget.inquiryId,
          );
      if (inquiry.isAnswered && !inquiry.isAnswerChecked) {
        await repo.checkInquiryAnswer(
              inquiryId: widget.inquiryId,
            );
      }
      if (!mounted) return;
      setState(() {
        _inquiry = inquiry;
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
      appBar: accountFigmaAppBar(context: context, title: '문의 내역'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _InquiryErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusChip(answered: _inquiry?.isAnswered == true),
                          SizedBox(height: 12.h),
                          Text(
                            _inquiry?.title ?? '',
                            style: AppTypography.bodyLargeB.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(_inquiry?.createdAt),
                            style: AppTypography.bodySmallR.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _inquiry?.content ?? '',
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                              height: 22 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '답변',
                            style: AppTypography.bodyMediumB.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _inquiry?.isAnswered == true
                                ? (_inquiry?.answer ?? '답변이 등록되었습니다.')
                                : '아직 답변이 등록되지 않았습니다.',
                            style: AppTypography.bodyMediumR.copyWith(
                              color: _inquiry?.isAnswered == true
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              height: 22 / 14,
                            ),
                          ),
                          if (_inquiry?.answeredAt != null) ...[
                            SizedBox(height: 12.h),
                            Text(
                              _formatDate(_inquiry?.answeredAt),
                              style: AppTypography.bodySmallR.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '-';
    return _dateTimeFormat.format(parsed.toLocal());
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.answered});

  final bool answered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: answered ? AppColors.primaryLight : AppColors.grey25,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        answered ? '답변 완료' : '답변 대기',
        style: AppTypography.bodySmallM.copyWith(
          color: answered ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InquiryErrorView extends StatelessWidget {
  const _InquiryErrorView({
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
