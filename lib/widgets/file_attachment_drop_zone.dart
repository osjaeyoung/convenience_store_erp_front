import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 파일 첨부 영역 (민트 테두리 + 아이콘 + 안내 문구). 탭 시 [onTap] 호출.
class FileAttachmentDropZone extends StatelessWidget {
  const FileAttachmentDropZone({
    super.key,
    required this.onTap,
    this.fileName,
    this.emptySubtitle = '파일을 첨부해주세요.',
    this.height = 200,
    this.borderRadius = 12,
    this.borderColor = AppColors.primary,
    this.backgroundColor = AppColors.primaryLight,
    this.iconAsset = _defaultIconAsset,
    this.iconSize = 48,
  });

  final VoidCallback onTap;
  final String? fileName;
  final String emptySubtitle;
  final double height;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final String iconAsset;
  final double iconSize;

  static const String _defaultIconAsset =
      'assets/icons/png/common/plus_circle_icon.png';

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.trim().isNotEmpty;
    final label = hasFile ? fileName!.trim() : emptySubtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMediumR.copyWith(
                      color: hasFile
                          ? AppColors.textPrimary
                          : AppColors.primary,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
