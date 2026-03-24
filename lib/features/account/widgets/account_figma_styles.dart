import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AccountFigmaStyles {
  AccountFigmaStyles._();

  static const Color titleColor = Color(0xFF1D1D1F);
  static const Color rowLabelColor = Color(0xFF1D1D1F);
  static const Color fieldLabelColor = Color(0xFF666874);
  static const Color mutedValueColor = Color(0xFFC7C9D7);
  static const Color footerMutedColor = Color(0xFFA3A4AF);

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    letterSpacing: -0.3,
    color: titleColor,
  );

  static const TextStyle rowTitle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: rowLabelColor,
  );

  static const TextStyle footerAction = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 16 / 14,
    color: footerMutedColor,
  );

  static const TextStyle fieldCaption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: fieldLabelColor,
  );

  static const TextStyle fieldValue = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: titleColor,
  );

  static const TextStyle fieldValueMuted = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: mutedValueColor,
  );

  static const TextStyle verifyHeadline = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 32 / 24,
    color: titleColor,
  );

  static Widget chevronNext16() {
    return Icon(
      Icons.chevron_right_rounded,
      size: 16,
      color: AppColors.grey100,
    );
  }

  /// Figma: 민트 작은 액션 (변경 / 전송 등), 높이 24, radius 4, 12 Semibold (최소 가로 43)
  static ButtonStyle mintSmallActionStyle = TextButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.grey0,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    minimumSize: const Size(43, 24),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  static const TextStyle mintSmallActionLabel = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1,
    color: AppColors.grey0,
  );
}

PreferredSizeWidget accountFigmaAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    toolbarHeight: 60,
    leadingWidth: 48,
    leading: IconButton(
      padding: const EdgeInsets.only(left: 20),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      color: AccountFigmaStyles.titleColor,
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(title, style: AccountFigmaStyles.appBarTitle),
    centerTitle: false,
    titleSpacing: 10,
    backgroundColor: AppColors.grey0,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: actions,
  );
}
