import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Figma `개인 공간` 지역 필터(노드 2534:16791 등)와 동일한 시·도 목록·순서.
const List<String> kRecruitmentRegionCatalog = <String>[
  '서울',
  '인천',
  '경기',
  '충남',
  '충북',
  '세종',
  '대전',
  '강원',
  '경북',
  '대구',
  '경남',
  '부산',
  '전북',
  '전남',
  '광주',
  '제주',
];

/// 상위 지역 선택 바텀시트.
/// - 바깥에서 `null`이면 시트를 닫기만 한 경우(변경 없음).
/// - `''`이면 전체(필터 해제).
Future<String?> showRecruitmentRegionPickerSheet(
  BuildContext context, {
  String? selectedRegion,
}) {
  final normalized = selectedRegion?.trim();
  String? draft = normalized == null || normalized.isEmpty
      ? null
      : (kRecruitmentRegionCatalog.contains(normalized) ? normalized : null);

  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: AppColors.grey0,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.72;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8.h),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
                  child: Row(
                    children: [
                      Text(
                        '지역',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setModalState(() => draft = null),
                        child: Text(
                          '전체',
                          style: AppTypography.bodyMediumM.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      mainAxisExtent: 56.h,
                    ),
                    itemCount: kRecruitmentRegionCatalog.length,
                    itemBuilder: (context, index) {
                      final region = kRecruitmentRegionCatalog[index];
                      final selected = draft == region;
                      return _RegionCheckboxTile(
                        label: region,
                        selected: selected,
                        onTap: () {
                          setModalState(() {
                            draft = selected ? null : region;
                          });
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop<String?>(
                        draft ?? '',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('적용'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _RegionCheckboxTile extends StatelessWidget {
  const _RegionCheckboxTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.grey0,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14.r,
                        color: AppColors.grey0,
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMediumM.copyWith(
                    fontSize: 14.sp,
                    height: 16 / 14,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma 필터 칩: 흰 배경, 회색 테두리, 좌측 라벨 · 우측 12px 드롭다운 화살표.
class RecruitmentFilterPill extends StatelessWidget {
  const RecruitmentFilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100.r),
      child: Container(
        constraints: BoxConstraints(minWidth: 72.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmallR.copyWith(
                  fontSize: 12.sp,
                  height: 18 / 12,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 12,
              color: active ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
