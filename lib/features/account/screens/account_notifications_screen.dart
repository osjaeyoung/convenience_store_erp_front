import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/push/push_notification_service.dart';
import '../../../data/models/account_notification_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../account_dio_message.dart';
import '../widgets/account_confirm_dialogs.dart';

Future<String?> openAccountNotificationsScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => const AccountNotificationsScreen(),
    ),
  );
}

class AccountNotificationsScreen extends StatefulWidget {
  const AccountNotificationsScreen({super.key});

  @override
  State<AccountNotificationsScreen> createState() =>
      _AccountNotificationsScreenState();
}

class _AccountNotificationsScreenState
    extends State<AccountNotificationsScreen> {
  static const _backIconAsset = 'assets/icons/svg/icon/back.svg';
  static const _deleteIconAsset = 'assets/icons/svg/icon/trash.svg';

  List<AccountNotificationItem> _items = const [];
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
      final page = await context.read<AuthRepository>().getNotifications(
        pageSize: 100,
      );
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

  Future<void> _handleNotificationTap(AccountNotificationItem item) async {
    final repo = context.read<AuthRepository>();
    final route = PushNotificationService.resolveRoute(item.toRoutePayload());
    Object? readError;

    if (!item.isRead) {
      try {
        final result = await repo.setNotificationRead(
          notificationId: item.notificationId,
          isRead: true,
          wasRead: item.isRead,
        );
        if (!mounted) return;
        _replaceNotification(
          item.copyWith(isRead: result.isRead, readAt: result.readAt),
        );
      } catch (error) {
        readError = error;
      }
    }

    if (!mounted) return;
    if (route != null) {
      Navigator.of(context).pop(route);
      return;
    }

    if (readError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(readError))));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이동할 화면 정보가 없습니다.')));
  }

  Future<void> _deleteNotification(AccountNotificationItem item) async {
    final confirmed = await showNotificationDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;

    try {
      await context.read<AuthRepository>().deleteNotification(
        notificationId: item.notificationId,
        wasUnread: !item.isRead,
      );
      if (!mounted) return;
      setState(() {
        _items = _items
            .where(
              (candidate) => candidate.notificationId != item.notificationId,
            )
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  void _replaceNotification(AccountNotificationItem item) {
    setState(() {
      _items = _items
          .map(
            (candidate) => candidate.notificationId == item.notificationId
                ? item
                : candidate,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        toolbarHeight: 60,
        leadingWidth: 48.w,
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          padding: EdgeInsets.only(left: 20.w),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: SvgPicture.asset(_backIconAsset, width: 20.w, height: 20.w),
        ),
        titleSpacing: 10.w,
        title: Text(
          '알림',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            height: 26 / 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _NotificationsErrorView(
              message: accountDioMessage(_error!),
              onRetry: _load,
            )
          : _items.isEmpty
          ? _NotificationsEmptyView(onRefresh: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24.h),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _NotificationRow(
                    item: item,
                    deleteIconAsset: _deleteIconAsset,
                    onTap: () => _handleNotificationTap(item),
                    onDeleteTap: () => _deleteNotification(item),
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.deleteIconAsset,
    required this.onTap,
    required this.onDeleteTap,
  });

  final AccountNotificationItem item;
  final String deleteIconAsset;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yy.MM.dd. a hh:mm', 'ko_KR');
    final dateStr = item.createdAt != null ? dateFormat.format(item.createdAt!) : '';
    
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 60.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.summaryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMediumM.copyWith(
                        color: item.isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        dateStr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12.sp,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              InkWell(
                borderRadius: BorderRadius.circular(11.r),
                onTap: onDeleteTap,
                child: Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: SvgPicture.asset(
                      deleteIconAsset,
                      width: 22.w,
                      height: 22.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsErrorView extends StatelessWidget {
  const _NotificationsErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ),
        ],
      ),
    );
  }
}

class _NotificationsEmptyView extends StatelessWidget {
  const _NotificationsEmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Text(
                    '알림 내역이 없습니다.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
