import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Figma 디자인에서 추출한 타이포그래피 토큰 (기준 폭 360pt → `.sp` 스케일)
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
  static TextStyle get heading1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  /// Heading 2 / 20px / Semibold
  static TextStyle get heading2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Heading 3 / 18px / Semibold
  static TextStyle get heading3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  // ─── Body Large (16px) ───────────────────────────────────────────────────
  /// Body Large / Semibold / 16px
  static TextStyle get bodyLargeB => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  /// AppBar 제목 전역 — 뒤로가기(<) 있는 서브페이지와 동일 (16/600, 좌측 타이틀)
  static TextStyle get appBarTitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: const Color(0xFF1D1D1F),
      );

  /// Body Large / Medium / 16px
  static TextStyle get bodyLargeM => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  /// Body Large / Regular / 16px
  static TextStyle get bodyLargeR => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ─── Body Medium (14px) ───────────────────────────────────────────────────
  /// Body Medium / Semibold / 14px
  static TextStyle get bodyMediumB => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  /// Body Medium / Medium / 14px
  static TextStyle get bodyMediumM => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  /// Body Medium / Regular / 14px
  static TextStyle get bodyMediumR => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  // ─── Body Small (12px) ───────────────────────────────────────────────────
  /// Body Small / Semibold / 12px
  static TextStyle get bodySmallB => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Body Small / Medium / 12px
  static TextStyle get bodySmallM => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Body Small / Regular / 12px
  static TextStyle get bodySmallR => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ─── Body X-Small (10px) ─────────────────────────────────────────────────
  /// Body X-Small / Medium / 10px
  static TextStyle get bodyXSmallM => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  // ─── Material TextTheme 호환 (기존 코드 호환용) ───────────────────────────
  static TextStyle get displayLarge => heading1;
  static TextStyle get displayMedium => heading2;
  static TextStyle get displaySmall => heading3;
  static TextStyle get headlineLarge => heading2;
  static TextStyle get headlineMedium => heading2;
  static TextStyle get headlineSmall => heading3;
  static TextStyle get titleLarge => bodyLargeB;
  static TextStyle get titleMedium => bodyMediumB;
  static TextStyle get titleSmall => bodySmallB;
  static TextStyle get bodyLarge => bodyLargeR;
  static TextStyle get bodyMedium => bodyMediumR;
  static TextStyle get bodySmall => bodySmallR;
  static TextStyle get labelLarge => bodyMediumM;
  static TextStyle get labelMedium => bodySmallM;
  static TextStyle get labelSmall => bodyXSmallM;
}
