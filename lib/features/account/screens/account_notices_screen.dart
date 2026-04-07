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
import 'account_notice_detail_screen.dart';

class AccountNoticesScreen extends StatefulWidget {
  const AccountNoticesScreen({super.key});

  @override
  State<AccountNoticesScreen> createState() => _AccountNoticesScreenState();
}

class _AccountNoticesScreenState extends State<AccountNoticesScreen> {
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');

  List<AccountNotice> _items = const [];
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
      final page = await context.read<AuthRepository>().getNotices();
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

  Future<void> _openDetail(AccountNotice item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountNoticeDetailScreen(noticeId: item.noticeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '공지사항'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _NoticeErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : _items.isEmpty
                  ? _NoticeEmptyView(onRefresh: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.border,
                          height: 1.h,
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return InkWell(
                            onTap: () => _openDetail(item),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.bodyLargeM.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 18.sp,
                                      height: 24 / 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _formatDate(item.publishedAt),
                                    style: AppTypography.bodySmallR.copyWith(
                                      color: AppColors.textDisabled,
                                      fontSize: 12.sp,
                                      height: 18 / 12,
                                    ),
                                  ),
                                ],
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

class _NoticeErrorView extends StatelessWidget {
  const _NoticeErrorView({
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

class _NoticeEmptyView extends StatelessWidget {
  const _NoticeEmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          Icon(Icons.campaign_outlined, size: 36.r, color: AppColors.grey150),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              '등록된 공지사항이 없습니다.',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
