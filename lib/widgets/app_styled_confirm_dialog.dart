import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 어두운 블러 딤 + 둥근 화이트 카드 + 하단 2버튼(취소 / 확인) 확인창
Future<bool?> showAppStyledConfirmDialog(
  BuildContext context, {
  required String message,
  String cancelLabel = '취소',
  String confirmLabel = '확인',
  Color confirmBackgroundColor = AppColors.primary,
  Color confirmForegroundColor = AppColors.grey0,
}) {
  final barrierLabel =
      MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(dialogContext, false),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.48),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Material(
                color: AppColors.grey0,
                borderRadius: BorderRadius.circular(22.r),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 30.h, 22.w, 20.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLargeB.copyWith(
                            fontSize: 17.sp,
                            height: 1.45,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 26.h),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.grey25,
                                    foregroundColor: AppColors.grey200,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    cancelLabel,
                                    style: AppTypography.bodyMediumB.copyWith(
                                      color: AppColors.grey200,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 11.w),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: confirmBackgroundColor,
                                    foregroundColor: confirmForegroundColor,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    confirmLabel,
                                    style: AppTypography.bodyMediumB.copyWith(
                                      color: confirmForegroundColor,
                                      fontSize: 15.sp,
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
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    },
  );
}

/// 삭제 확인 — 민트 확인 버튼
Future<bool?> showAppStyledDeleteDialog(
  BuildContext context, {
  required String message,
}) {
  return showAppStyledConfirmDialog(
    context,
    message: message,
    cancelLabel: '취소',
    confirmLabel: '삭제',
    confirmBackgroundColor: AppColors.primary,
    confirmForegroundColor: AppColors.grey0,
  );
}
