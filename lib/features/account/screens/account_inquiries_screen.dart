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
import 'account_inquiry_detail_screen.dart';
import 'account_inquiry_form_screen.dart';

class AccountInquiriesScreen extends StatefulWidget {
  const AccountInquiriesScreen({super.key});

  @override
  State<AccountInquiriesScreen> createState() => _AccountInquiriesScreenState();
}

class _AccountInquiriesScreenState extends State<AccountInquiriesScreen> {
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');

  List<AccountInquiry> _items = const [];
  bool _loading = true;
  Object? _error;

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
      final page = await context.read<AuthRepository>().getInquiries();
      if (!mounted) return;
      setState(() {
        _items = page.items;
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

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<AccountInquiry>(
      MaterialPageRoute<AccountInquiry>(
        builder: (_) => const AccountInquiryFormScreen(),
      ),
    );
    if (created != null && mounted) {
      await _load();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AccountInquiryDetailScreen(
            inquiryId: created.inquiryId,
          ),
        ),
      );
      if (mounted) {
        _load();
      }
    }
  }

  Future<void> _openDetail(AccountInquiry item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountInquiryDetailScreen(inquiryId: item.inquiryId),
      ),
    );
    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '문의하기'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.grey0,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('문의 등록'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _InquiryListErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : _items.isEmpty
                  ? _InquiryEmptyView(onCreate: _openForm, onRefresh: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 96.h),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Material(
                            color: AppColors.grey0,
                            borderRadius: BorderRadius.circular(16.r),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () => _openDetail(item),
                              child: Container(
                                padding: EdgeInsets.all(18.r),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _InquiryStatusChip(
                                          answered: item.isAnswered,
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatDate(item.createdAt),
                                          style:
                                              AppTypography.bodySmallR.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      item.title,
                                      style: AppTypography.bodyMediumB.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      item.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmallR.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 18 / 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '-';
    return _dateFormat.format(parsed.toLocal());
  }
}

class _InquiryStatusChip extends StatelessWidget {
  const _InquiryStatusChip({required this.answered});

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

class _InquiryListErrorView extends StatelessWidget {
  const _InquiryListErrorView({
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

class _InquiryEmptyView extends StatelessWidget {
  const _InquiryEmptyView({
    required this.onCreate,
    required this.onRefresh,
  });

  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 120.h, 20.w, 120.h),
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 36.r,
            color: AppColors.grey150,
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              '등록한 문의가 없습니다.',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Center(
            child: OutlinedButton(
              onPressed: onCreate,
              child: const Text('문의 작성하기'),
            ),
          ),
        ],
      ),
    );
  }
}
