import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_routes.dart';
import '../bloc/recruitment_bloc.dart';
import '../bloc/selected_branch_cubit.dart';

/// 구인·채용 화면
class RecruitmentScreen extends StatelessWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구인·채용'),
        actions: [
          IconButton(
            onPressed: () => openAccountSettingsMenu(context),
            icon: Image.asset(
              'assets/icons/png/common/menu_icon.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocConsumer<SelectedBranchCubit, int?>(
        listener: (context, branchId) {
          if (branchId != null) {
            context.read<RecruitmentBloc>().add(
                  RecruitmentStatusRequested(branchId: branchId),
                );
          }
        },
        builder: (context, branchId) {
          if (branchId == null) {
            return Center(
              child: Text(
                '지점을 선택해주세요.\n홈 탭에서 지점을 먼저 선택해주세요.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          return BlocBuilder<RecruitmentBloc, RecruitmentBlocState>(
            builder: (context, state) {
              if (state.status == RecruitmentBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == RecruitmentBlocStatus.failure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessage ?? '오류가 발생했습니다.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.read<RecruitmentBloc>().add(
                              RecruitmentStatusRequested(branchId: branchId),
                            ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              final status = state.recruitmentStatus;
              if (status == null) {
                return const Center(child: Text('데이터 없음'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '채용 현황',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '채용 데이터를 불러왔습니다.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
