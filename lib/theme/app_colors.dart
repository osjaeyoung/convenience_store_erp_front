import 'package:flutter/material.dart';

/// Figma 디자인에서 추출한 색상 토큰
/// node-id: 2409-13755, 2409-13865, 2409-15510 기준
class AppColors {
  AppColors._();

  // Primary (민트/청록)
  static const Color primary = Color(0xFF70D2B3);
  static const Color primaryLight = Color(0xFFF6FFFC);
  static const Color primaryDark = Color(0xFF73C4AB);

  // Neutral / Gray scale
  static const Color grey0 = Color(0xFFFFFFFF);
  static const Color grey0Alt = Color(0xFFFBFBFB);
  static const Color grey25 = Color(0xFFF5F5F7);
  static const Color grey50 = Color(0xFFE7E8EF);
  static const Color grey100 = Color(0xFFC7C9D7);
  static const Color grey150 = Color(0xFFA3A4AF);
  static const Color grey200 = Color(0xFF666874);
  static const Color grey250 = Color(0xFF000000);

  static const Color background = grey0Alt;
  static const Color surface = grey0;
  static const Color surfaceVariant = grey25;

  static const Color textPrimary = grey250;
  static const Color textSecondary = grey200;
  static const Color textTertiary = grey150;
  static const Color textDisabled = grey100;

  static const Color border = grey50;
  static const Color borderLight = grey25;
  static const Color divider = grey50;

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = primary;
}
