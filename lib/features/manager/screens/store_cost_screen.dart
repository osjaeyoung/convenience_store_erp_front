import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_routes.dart';
import '../bloc/selected_branch_cubit.dart';
import '../bloc/store_expense_bloc.dart';

/// 매장·비용 화면
class StoreCostScreen extends StatelessWidget {
  const StoreCostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매장·비용'),
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
            final now = DateTime.now();
            context.read<StoreExpenseBloc>().add(
                  StoreExpenseDashboardRequested(
                    branchId: branchId,
                    year: now.year,
                    month: now.month,
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
          return BlocBuilder<StoreExpenseBloc, StoreExpenseBlocState>(
            builder: (context, state) {
              if (state.status == StoreExpenseBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == StoreExpenseBlocStatus.failure) {
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
                          context.read<StoreExpenseBloc>().add(
                                StoreExpenseDashboardRequested(
                                  branchId: branchId,
                                  year: now.year,
                                  month: now.month,
                                ),
                              );
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              final dashboard = state.dashboard;
              if (dashboard == null) {
                return const Center(child: Text('데이터 없음'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${dashboard.year}년 ${dashboard.month}월',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      '당월 누적',
                      '${dashboard.currentMonthToDateTotal.toStringAsFixed(0)}원',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCard(
                      '전월 대비 증감률',
                      '${dashboard.changeRatePercent.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCard(
                      '월 총 비용',
                      '${dashboard.monthlyTotalCost.toStringAsFixed(0)}원',
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

  static Widget _buildSummaryCard(String label, String value) {
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
