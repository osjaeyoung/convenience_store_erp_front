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
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '제목',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumB.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '양식명',
              style: AppTypography.bodySmallB.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            AuthInputField(
              controller: _ctrl,
              hintText: '입력해주세요.',
              minLines: 3,
              maxLines: 5,
              fillColor: AppColors.grey25,
              focusedBorderColor: AppColors.primaryDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey25,
                        foregroundColor: AppColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '닫기',
                        style: AppTypography.bodyMediumM.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTypography.bodyMediumB.copyWith(
                          color: AppColors.grey0,
                          fontSize: 15,
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
