import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

final NumberFormat _workerNumberFormat = NumberFormat('#,###', 'ko_KR');

String formatWorkerAmount(int amount) => _workerNumberFormat.format(amount);

String workerDisplayValue(String? value, {String fallback = '-'}) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return fallback;
  return trimmed;
}

PreferredSizeWidget workerSubPageAppBar(
  BuildContext context, {
  required String title,
}) {
  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppColors.grey0,
    surfaceTintColor: AppColors.grey0,
    leading: IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.textPrimary,
        size: 20,
      ),
    ),
    titleSpacing: 0,
    title: Text(
      title,
      style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary),
    ),
  );
}

Widget workerSectionTitle(String title) {
  return Text(
    title,
    style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
  );
}

Widget workerErrorView({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.grey0,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );
}

Widget workerEmptyView({required String message, String? description}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 36.r, color: AppColors.textTertiary),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLargeB.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (description != null && description.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<bool> showWorkerConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = '취소',
  String confirmLabel = '확인',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.grey0,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 44.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmLabel,
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}
