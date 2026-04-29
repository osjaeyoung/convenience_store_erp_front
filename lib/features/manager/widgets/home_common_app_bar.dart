import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/navigation/logo_navigation_bridge.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../account/screens/account_notifications_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeCommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeCommonAppBar({
    super.key,
    this.alarmActive = false,
    this.onAlarmTap,
    this.onMenuTap,
  });

  final bool alarmActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthBloc>().state.user;
    final authRepository = context.watch<AuthRepository>();
    final showUnreadAlarm = authRepository.hasLoadedNotificationUnreadCount
        ? authRepository.hasUnreadNotifications
        : alarmActive;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.grey0,
      surfaceTintColor: AppColors.grey0,
      leadingWidth: 140,
      leading: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              if (currentUser?.role.isJobSeeker == true) {
                if (JobSeekerLogoNavigation.tryHandle()) return;
                context.go(AppRouter.jobSeekerMain);
                return;
              }
              if (ManagerLogoNavigation.tryHandle()) return;
              context.go(AppRouter.managerMain);
            },
            child: Image.asset(
              AppAssets.logoMain,
              width: 72,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _openNotifications(context),
          icon: Image.asset(
            showUnreadAlarm
                ? AppAssets.alarmActiveIcon
                : AppAssets.alarmInactiveIcon,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        IconButton(
          onPressed: onMenuTap,
          icon: Image.asset(
            'assets/icons/png/common/menu_icon.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 6.w),
      ],
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    final payload = await openAccountNotificationsScreen(context);
    if (!context.mounted || payload == null) return;
    PushNotificationService.instance.handleNotificationPayload(payload);
  }
}
