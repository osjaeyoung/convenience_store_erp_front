import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';

/// 메인(경영자/점장) 공통 우측 메뉴 — 로그아웃
class ManagerMenuDrawer extends StatelessWidget {
  const ManagerMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final title = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : (user?.email ?? '계정');
    final subtitle = user != null
        ? '${user.role.label} · ${user.email}'
        : '';

    return Drawer(
      backgroundColor: AppColors.grey0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLargeB.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grey50),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: AppColors.textPrimary,
              ),
              title: Text(
                '로그아웃',
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }
}

void openManagerMenuDrawer(BuildContext context) {
  final scaffold = Scaffold.maybeOf(context);
  scaffold?.openEndDrawer();
}
