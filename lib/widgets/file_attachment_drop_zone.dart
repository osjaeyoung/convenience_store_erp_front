import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 파일 첨부 영역 (민트 테두리 + 아이콘 + 안내 문구). 탭 시 [onTap] 호출.
///
/// [fullWidthBarHeight]가 있으면 부모 너비에 맞춘 가로 넓은 직사각형(높이만 고정)에 아이콘·문구를 세로 중앙 정렬합니다.
/// 없으면 [height]만 지정한 가로 전체 카드 레이아웃을 씁니다.
class FileAttachmentDropZone extends StatelessWidget {
  const FileAttachmentDropZone({
    super.key,
    required this.onTap,
    this.fileName,
    this.emptySubtitle = '파일을 첨부해주세요.',
    this.height = 200,
    this.fullWidthBarHeight,
    this.borderRadius = 12,
    this.borderColor = AppColors.primary,
    this.backgroundColor = AppColors.primaryLight,
    this.iconAsset = _defaultIconAsset,
    this.iconSize = 48,
    this.barIconTextGap = 8,
  });

  final VoidCallback onTap;
  final String? fileName;
  final String emptySubtitle;
  final double height;
  /// 가로 최대 너비 바의 높이(논리 픽셀). 지정 시 [height]는 쓰이지 않습니다.
  final double? fullWidthBarHeight;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final String iconAsset;
  final double iconSize;
  /// [fullWidthBarHeight] 모드에서 아이콘과 문구 사이 간격
  final double barIconTextGap;

  static const String _defaultIconAsset =
      'assets/icons/png/common/plus_circle_icon.png';

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.trim().isNotEmpty;
    final label = hasFile ? fileName!.trim() : emptySubtitle;
    final labelStyle = AppTypography.bodyMediumR.copyWith(
      color: hasFile ? AppColors.textPrimary : AppColors.primary,
      fontSize: 14.sp,
      height: 20 / 14,
    );

    final barH = fullWidthBarHeight;
    if (barH != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            height: barH,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      iconAsset,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: barIconTextGap),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
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
