import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../theme/app_colors.dart';

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  static const Color _mintGlow = Color(0x40A0D9D4);
  static const Color _yellowGlowStrong = Color(0x42F8F292);
  static const Color _yellowGlowSoft = Color(0x26F8F292);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.grey0,
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -170.w,
              top: -150.h,
              child: const _BlurredGlow(
                width: 520,
                height: 380,
                color: _yellowGlowSoft,
                blurSigma: 92,
              ),
            ),
            Positioned(
              left: -90.w,
              bottom: -170.h,
              child: const _BlurredGlow(
                width: 300,
                height: 300,
                color: _yellowGlowStrong,
                blurSigma: 84,
              ),
            ),
            Positioned(
              right: -255.w,
              bottom: -205.h,
              child: const _BlurredGlow(
                width: 760,
                height: 760,
                color: _mintGlow,
                blurSigma: 112,
              ),
            ),
            Positioned(
              right: -40.w,
              bottom: 90.h,
              child: const _BlurredGlow(
                width: 220,
                height: 220,
                color: Color(0x1FA0D9D4),
                blurSigma: 78,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.12),
                child: Image.asset(
                  AppAssets.logoMain,
                  width: 155.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredGlow extends StatelessWidget {
  const _BlurredGlow({
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
  });

  final double width;
  final double height;
  final Color color;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          width: width.w,
          height: height.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width.w),
            gradient: RadialGradient(
              radius: 0.76,
              colors: [
                color,
                color.withValues(alpha: color.a * 0.42),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
        ),
      ),
    );
  }
}
