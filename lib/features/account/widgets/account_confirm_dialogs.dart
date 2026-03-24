import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import 'account_figma_styles.dart';

Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  final ok = await _showAccountActionConfirmDialog(
    context,
    iconSvgAsset: 'assets/icons/svg/icon/question_mint_60.svg',
    message: '로그아웃 하시겠습니까?',
    confirmLabel: '로그아웃',
  );
  return ok == true;
}

Future<bool> showWithdrawConfirmDialog(BuildContext context) async {
  final ok = await _showAccountActionConfirmDialog(
    context,
    message: '탈퇴하시겠습니까?',
    confirmLabel: '탈퇴',
  );
  return ok == true;
}

Future<bool?> _showAccountActionConfirmDialog(
  BuildContext context, {
  String? iconSvgAsset,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _AccountActionConfirmDialog(
      iconSvgAsset: iconSvgAsset,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
}

class _AccountActionConfirmDialog extends StatelessWidget {
  const _AccountActionConfirmDialog({
    required this.message,
    required this.confirmLabel,
    this.iconSvgAsset,
  });

  final String? iconSvgAsset;
  final String message;
  final String confirmLabel;

  static const TextStyle _messageStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AccountFigmaStyles.titleColor,
  );

  static const TextStyle _buttonLabel = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: EdgeInsets.fromLTRB(
          24,
          iconSvgAsset != null ? 28 : 32,
          24,
          24,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconSvgAsset != null) ...[
              SvgPicture.asset(
                iconSvgAsset!,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: _messageStyle,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.grey25,
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: _buttonLabel.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmLabel,
                        style: _buttonLabel.copyWith(color: AppColors.grey0),
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
