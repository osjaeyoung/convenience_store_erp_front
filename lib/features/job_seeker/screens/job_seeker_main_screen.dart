import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user.dart';
import '../../../core/router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';

/// 구직자 메인 화면
/// 경영자/점장과 전혀 다른 화면 구조 (바텀바 없음)
class JobSeekerMainScreen extends StatelessWidget {
  const JobSeekerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, User?>((b) => b.state.user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '구직자',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go(AppRouter.login);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '구직자 전용 화면',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '경영자/점장과 다른 화면 구조',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 16),
              Text(
                user.email,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
