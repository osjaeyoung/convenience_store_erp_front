import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MintAddButton extends StatelessWidget {
  const MintAddButton({
    super.key,
    this.label = '추가하기',
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  static const Color _backgroundColor = Color(0xFFE2F6F0);
  static const String _iconPath = 'assets/icons/svg/icon/plus_mint_20.svg';

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(52.h),
        side: const BorderSide(color: AppColors.primary),
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySmallM.copyWith(
              color: AppColors.primary,
              height: 16 / 12,
            ),
          ),
          SizedBox(width: 8.w),
          SvgPicture.asset(
            _iconPath,
            width: 20,
            height: 20,
          ),
        ],
      ),
    );
  }
}
