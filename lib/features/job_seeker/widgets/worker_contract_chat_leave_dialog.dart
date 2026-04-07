import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Figma 2534:10715 — 채팅방 나가기 확인 (근로자 계약채팅)
const String kWorkerContractChatLeaveQuestionIconAsset =
    'assets/icons/svg/icon/question_mint_60.svg';

/// `true` if the user tapped **확인**, otherwise `false`.
Future<bool> showWorkerContractChatLeaveDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grey0,
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 30.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    kWorkerContractChatLeaveQuestionIconAsset,
                    width: 60.r,
                    height: 60.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '해당 채팅방을 나가시겠습니까?',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '확인',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.3,
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F7),
                          foregroundColor: const Color(0xFFA3A4AF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: const Color(0xFFA3A4AF),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.3,
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
