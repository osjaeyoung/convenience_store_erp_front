import 'package:flutter/material.dart';

import '../features/auth/widgets/auth_input_field.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '제목',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 18,
                height: 24 / 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '양식명',
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 14,
                height: 16 / 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            AuthInputField(
              controller: _ctrl,
              hintText: '입력해주세요.',
              minLines: 3,
              maxLines: 5,
              fillColor: AppColors.grey0Alt,
              hintStyle: AppTypography.bodyMediumR.copyWith(
                fontSize: 14,
                height: 19 / 14,
                color: AppColors.grey100,
              ),
              focusedBorderColor: AppColors.primaryDark,
              contentPadding: const EdgeInsets.all(16),
            ),
            const SizedBox(height: 36),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '닫기',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.grey0,
                          fontSize: 16,
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
