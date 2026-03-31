import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 근무 상태 배지 공통 위젯
/// - 완료: 진회색 배경 + 흰색 텍스트
/// - 예정: 민트 라인 + 연민트 배경
/// - 결근: 빨간 배경 + 흰색 텍스트
/// - 미정: 연회색 라인 + 배경
class WorkStatusBadge extends StatelessWidget {
  const WorkStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  static String normalize(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'done':
      case '완료':
      case '근무완료':
        return '근무완료';
      case 'scheduled':
      case '예정':
      case '근무예정':
        return '근무예정';
      case 'absent':
      case '결근':
        return '결근';
      case 'unset':
      case '미정':
        return '미정';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalize(status);
    final style = _styleFor(normalized);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: style.backgroundColor,
        border: style.borderColor == null
            ? null
            : Border.all(color: style.borderColor!),
      ),
      child: Text(
        normalized,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmallB.copyWith(
          color: style.textColor,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w600,
          height: 16 / (compact ? 12 : 13),
        ),
      ),
    );
  }

  _BadgeStyle _styleFor(String normalized) {
    switch (normalized) {
      case '근무완료':
        return const _BadgeStyle(
          backgroundColor: Color(0xFF666874),
          textColor: AppColors.grey0,
        );
      case '결근':
        return const _BadgeStyle(
          backgroundColor: Color(0xFFFF453A),
          textColor: AppColors.grey0,
        );
      case '근무예정':
        return const _BadgeStyle(
          backgroundColor: Color(0xFFE2F6F0),
          borderColor: AppColors.primary,
          textColor: AppColors.primary,
        );
      case '미정':
        return const _BadgeStyle(
          backgroundColor: AppColors.grey25,
          borderColor: AppColors.grey50,
          textColor: AppColors.grey150,
        );
      default:
        return const _BadgeStyle(
          backgroundColor: AppColors.grey25,
          borderColor: AppColors.grey50,
          textColor: AppColors.textSecondary,
        );
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.backgroundColor,
    this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
}
