import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../bloc/selected_branch_cubit.dart';
import '../bloc/staff_management_bloc.dart';

/// 직원관리 화면
class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '직원관리',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: BlocConsumer<SelectedBranchCubit, int?>(
        listener: (context, branchId) {
          if (branchId != null) {
            final now = DateTime.now();
            final date =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            context.read<StaffManagementBloc>().add(
                  StaffManagementDayScheduleRequested(
                    branchId: branchId,
                    date: date,
                  ),
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
          return BlocBuilder<StaffManagementBloc, StaffManagementBlocState>(
            builder: (context, state) {
              if (state.status == StaffManagementBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == StaffManagementBlocStatus.failure) {
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
                        onPressed: () {
                          final now = DateTime.now();
                          final date =
                              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                          context.read<StaffManagementBloc>().add(
                                StaffManagementDayScheduleRequested(
                                  branchId: branchId,
                                  date: date,
                                ),
                              );
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              final schedule = state.daySchedule;
              if (schedule == null) {
                return const Center(child: Text('데이터 없음'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '근무 일정',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '일정 데이터를 불러왔습니다.',
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
