import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'worker_common.dart';

class WorkerRecruitmentCard extends StatelessWidget {
  const WorkerRecruitmentCard({
    super.key,
    this.badgeLabel,
    required this.companyName,
    required this.title,
    this.regionSummary,
    required this.payType,
    required this.payAmount,
    this.footerLabel,
    this.onTap,
    this.topSpacing = 0,
  });

  final String? badgeLabel;
  final String companyName;
  final String title;
  final String? regionSummary;
  final String payType;
  final int payAmount;
  final String? footerLabel;
  final VoidCallback? onTap;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topSpacing > 0) SizedBox(height: topSpacing),
              if ((badgeLabel ?? '').isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                companyName,
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: AppTypography.bodyLargeB.copyWith(
                  color: const Color(0xFF404040),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 24 / 16,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.grey0Alt,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      child: Text(
                        workerDisplayValue(regionSummary),
                        style: AppTypography.bodyMediumR.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _InfoRow(
                      icon: Icons.monetization_on_outlined,
                      child: Row(
                        children: [
                          Text(
                            payType,
                            style: AppTypography.bodyMediumM.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            formatWorkerAmount(payAmount),
                            style: AppTypography.bodyMediumR.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if ((footerLabel ?? '').isNotEmpty) ...[
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    footerLabel!,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: AppColors.textTertiary),
        SizedBox(width: 6.w),
        Expanded(child: child),
      ],
    );
  }
}
