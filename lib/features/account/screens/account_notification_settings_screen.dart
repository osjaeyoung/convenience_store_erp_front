import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/push/push_notification_service.dart';
import '../../../data/models/push_notification_settings.dart';
import '../../../data/repositories/push_repository.dart';
import '../../../theme/app_colors.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';

class AccountNotificationSettingsScreen extends StatefulWidget {
  const AccountNotificationSettingsScreen({super.key});

  @override
  State<AccountNotificationSettingsScreen> createState() =>
      _AccountNotificationSettingsScreenState();
}

class _AccountNotificationSettingsScreenState
    extends State<AccountNotificationSettingsScreen> {
  PushNotificationSettings? _settings;
  Object? _error;
  bool _loading = true;
  bool _updating = false;

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
      final settings = await context.read<PushRepository>().getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _togglePush(bool nextValue) async {
    if (_updating) return;
    final pushRepository = context.read<PushRepository>();
    setState(() => _updating = true);

    try {
      if (nextValue) {
        final permission =
            await PushNotificationService.instance.requestFcmPermission();
        final authorized =
            permission.authorizationStatus == AuthorizationStatus.authorized ||
            permission.authorizationStatus == AuthorizationStatus.provisional;
        if (!authorized) {
          await openAppSettings();
          throw const _NotificationPermissionDeniedException();
        }
      }

      final updated = await pushRepository.updateNotificationSettings(
        pushEnabled: nextValue,
      );

      if (nextValue) {
        await PushNotificationService.instance.onUserAuthenticated();
      }

      if (!mounted) return;
      setState(() {
        _settings = updated;
        _updating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextValue ? '알림을 켰습니다.' : '알림을 껐습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      final message = e is _NotificationPermissionDeniedException
          ? '기기 알림 권한이 꺼져 있어요. 시스템 설정에서 알림 권한을 허용해주세요.'
          : accountDioMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _settings?.pushEnabled ?? false;

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '알림 설정'),
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
              : ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey0,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 18.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '푸시 알림 받기',
                                  style: AccountFigmaStyles.rowTitle.copyWith(
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  '채용, 계약, 승인 등 주요 변경사항을 앱 알림으로 받아볼 수 있어요.',
                                  style: AccountFigmaStyles.fieldCaption.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 20 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Switch.adaptive(
                            value: enabled,
                            onChanged: _updating ? null : _togglePush,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _NotificationPermissionDeniedException implements Exception {
  const _NotificationPermissionDeniedException();
}
