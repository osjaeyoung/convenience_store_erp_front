import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/manager_menu_drawer.dart';
import '../bloc/labor_cost_bloc.dart';
import '../bloc/selected_branch_cubit.dart';

/// 인건비 화면
class LaborCostScreen extends StatelessWidget {
  const LaborCostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const ManagerMenuDrawer(),
      appBar: AppBar(
        title: Text(
          '인건비',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => openManagerMenuDrawer(context),
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
            context.read<LaborCostBloc>().add(
                  LaborCostExpectedRequested(
                    branchId: branchId,
                    rangeType: 'current_month',
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
          return BlocBuilder<LaborCostBloc, LaborCostBlocState>(
            builder: (context, state) {
              if (state.status == LaborCostBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == LaborCostBlocStatus.failure) {
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
                        onPressed: () => context.read<LaborCostBloc>().add(
                              LaborCostExpectedRequested(
                                branchId: branchId,
                                rangeType: 'current_month',
                              ),
                            ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              final expected = state.expected;
              if (expected == null) {
                return const Center(child: Text('데이터 없음'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      expected.periodLabel,
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      '현재 총 인건비',
                      '${expected.currentTotalCost.toStringAsFixed(0)}원',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCard(
                      '이전 대비 증감률',
                      '${expected.changeRatePercent.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCard(
                      '현재 인원',
                      '${expected.headcountCurrent}명',
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

  Widget _buildSummaryCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium),
            Text(value, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
