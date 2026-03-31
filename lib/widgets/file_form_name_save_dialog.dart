import 'package:flutter/material.dart';

import '../features/auth/widgets/auth_input_field.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Figma 저장 형태 모달 — 제목 / 양식명 입력 / 닫기·저장
Future<String?> showFileFormNameSaveDialog(
  BuildContext context, {
  String? initialFormName,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _FileFormNameSaveDialog(
      initialFormName: initialFormName,
    ),
  );
}

class _FileFormNameSaveDialog extends StatefulWidget {
  const _FileFormNameSaveDialog({this.initialFormName});

  final String? initialFormName;

  @override
  State<_FileFormNameSaveDialog> createState() =>
      _FileFormNameSaveDialogState();
}

class _FileFormNameSaveDialogState extends State<_FileFormNameSaveDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialFormName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.grey0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '제목',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 18.sp,
                height: 24 / 18,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '양식명',
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 14.sp,
                height: 16 / 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            AuthInputField(
              controller: _ctrl,
              hintText: '입력해주세요.',
              minLines: 3,
              maxLines: 5,
              fillColor: AppColors.grey0Alt,
              hintStyle: AppTypography.bodyMediumR.copyWith(
                fontSize: 14.sp,
                height: 19 / 14,
                color: AppColors.grey100,
              ),
              focusedBorderColor: AppColors.primaryDark,
              contentPadding: EdgeInsets.all(16.r),
            ),
            SizedBox(height: 36.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey25,
                        foregroundColor: AppColors.textTertiary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '닫기',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 16.sp,
                          height: 24 / 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        final t = _ctrl.text.trim();
                        if (t.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('양식명을 입력해 주세요.'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, t);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.grey0,
                          fontSize: 16.sp,
                          height: 24 / 16,
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
  }
}
