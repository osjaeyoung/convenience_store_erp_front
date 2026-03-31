import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Figma / 기획 기준 **논리 폭 360** 에 맞춘 레이아웃 스케일.
/// `ScreenUtilInit`는 [main.dart]에서 한 번만 호출합니다.
class AppDesign {
  AppDesign._();

  /// 디자인 캔버스 가로 (pt)
  static const double width = 360;

  /// 디자인 캔버스 세로 (pt). 가로 360 기준 모바일 흔한 비율에 맞춘 보조 값입니다.
  static const double height = 800;

  static Size get designSize => Size(width, height);
}

/// `import 'app_design.dart'` 한 곳에서 ScreenUtil 확장을 쓰기 위한 재노출용.
/// 실제 변환은 [num] 의 `.w` `.h` `.sp` `.r` (flutter_screenutil)을 사용합니다.
extension AppDesignNum on num {
  /// 가로 기준 스케일 (디자인 width 360 기준)
  double get dw => w;

  /// 세로 기준 스케일
  double get dh => h;

  /// 반지름 등 양방향 스케일
  double get dr => r;

  /// 텍스트 스케일
  double get dsp => sp;
}
