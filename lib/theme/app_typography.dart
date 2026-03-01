import 'package:flutter/material.dart';

/// Figma 디자인에서 추출한 타이포그래피 토큰
/// Pretendard 폰트, Heading 1~3, Body Large/Medium/Small/X-Small
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Pretendard';

  static TextTheme get textTheme => TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineLarge: heading2,
        headlineMedium: heading2,
        headlineSmall: heading3,
        titleLarge: bodyLargeB,
        titleMedium: bodyMediumB,
        titleSmall: bodySmallB,
        bodyLarge: bodyLargeR,
        bodyMedium: bodyMediumR,
        bodySmall: bodySmallR,
        labelLarge: bodyMediumM,
        labelMedium: bodySmallM,
        labelSmall: bodyXSmallM,
      );

  // ─── Heading ─────────────────────────────────────────────────────────────
  /// Heading 1 / 24px / Semibold
  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Heading 2 / 20px / Semibold
  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Heading 3 / 18px / Semibold
  static const TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // ─── Body Large (16px) ───────────────────────────────────────────────────
  /// Body Large / Semibold / 16px
  static const TextStyle bodyLargeB = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// Body Large / Medium / 16px
  static const TextStyle bodyLargeM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Body Large / Regular / 16px
  static const TextStyle bodyLargeR = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Body Medium (14px) ───────────────────────────────────────────────────
  /// Body Medium / Semibold / 14px
  static const TextStyle bodyMediumB = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// Body Medium / Medium / 14px
  static const TextStyle bodyMediumM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Body Medium / Regular / 14px
  static const TextStyle bodyMediumR = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // ─── Body Small (12px) ───────────────────────────────────────────────────
  /// Body Small / Semibold / 12px
  static const TextStyle bodySmallB = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Body Small / Medium / 12px
  static const TextStyle bodySmallM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Body Small / Regular / 12px
  static const TextStyle bodySmallR = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ─── Body X-Small (10px) ─────────────────────────────────────────────────
  /// Body X-Small / Medium / 10px
  static const TextStyle bodyXSmallM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // ─── Material TextTheme 호환 (기존 코드 호환용) ───────────────────────────
  static const TextStyle displayLarge = heading1;
  static const TextStyle displayMedium = heading2;
  static const TextStyle displaySmall = heading3;
  static const TextStyle headlineLarge = heading2;
  static const TextStyle headlineMedium = heading2;
  static const TextStyle headlineSmall = heading3;
  static const TextStyle titleLarge = bodyLargeB;
  static const TextStyle titleMedium = bodyMediumB;
  static const TextStyle titleSmall = bodySmallB;
  static const TextStyle bodyLarge = bodyLargeR;
  static const TextStyle bodyMedium = bodyMediumR;
  static const TextStyle bodySmall = bodySmallR;
  static const TextStyle labelLarge = bodyMediumM;
  static const TextStyle labelMedium = bodySmallM;
  static const TextStyle labelSmall = bodyXSmallM;
}
