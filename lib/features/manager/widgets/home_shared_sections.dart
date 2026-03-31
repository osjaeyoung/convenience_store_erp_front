import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'work_status_badge.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeTodayWorkersSection extends StatelessWidget {
  const HomeTodayWorkersSection({
    super.key,
    required this.dateLabel,
    required this.rows,
    this.onTapHeader,
    this.onTapStatus,
    this.onTapMemo,
    this.showHeader = true,
    this.tableHorizontalPadding = 8,
  });

  final String dateLabel;
  final bool showHeader;
  final double tableHorizontalPadding;
  final List<
      ({
        String time,
        String workerName,
        String status,
        bool hasMemo,
      })> rows;
  final VoidCallback? onTapHeader;
  final void Function(
    int index,
    ({
      String time,
      String workerName,
      String status,
      bool hasMemo,
    }) row,
  )?
      onTapStatus;
  final void Function(
    int index,
    ({
      String time,
      String workerName,
      String status,
      bool hasMemo,
    }) row,
  )?
      onTapMemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Image.asset(
                'assets/icons/png/common/person_book_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 6.w),
              Text(
                '오늘의 근무자 현황',
                style: AppTypography.bodyLargeM.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onTapHeader,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
        ],
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(color: AppColors.grey25),
              color: AppColors.grey0Alt,
            ),
            child: Text(
              dateLabel,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey25,
            border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
          ),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: tableHorizontalPadding,
          ),
          child: Row(
            children: const [
              _HeaderCell('시간'),
              _HeaderCell('근무자', textAlign: TextAlign.start),
              _HeaderCell('메모'),
              _HeaderCell('상태'),
            ],
          ),
        ),
        ...rows.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final row = entry.value;
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: tableHorizontalPadding,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey25)),
              ),
              child: Row(
                children: [
                  _BodyCell(row.time),
                  _WorkerNameCell(row.workerName),
                  _MemoIconCell(
                    hasMemo: row.hasMemo,
                    onTap: row.hasMemo && onTapMemo != null
                        ? () => onTapMemo!(index, row)
                        : null,
                  ),
                  _StatusCell(
                    row.status,
                    onTap: onTapStatus == null
                        ? null
                        : () => onTapStatus!(index, row),
                  ),
                ],
              ),
            );
          },
        ),
        if (rows.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 18,
              horizontal: tableHorizontalPadding,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey25)),
            ),
            child: Text(
              '해당 날짜의 근무자 정보가 없습니다.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textTertiary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class HomeMonthlyLaborCostCard extends StatelessWidget {
  const HomeMonthlyLaborCostCard({
    super.key,
    required this.totalAmountText,
    required this.changeText,
    required this.onDetailTap,
  });

  final String totalAmountText;
  final String changeText;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/png/common/money_icon.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 6.w),
            Text(
              '이번 달 예상 인건비',
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                height: 20 / 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              begin: Alignment(-0.2, 0.2),
              end: Alignment(1.0, 1.0),
              colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F1D1D1F),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                totalAmountText,
                textAlign: TextAlign.center,
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 26 / 20,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                changeText,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 16 / 14,
                ),
              ),
              SizedBox(height: 12.h),
              _LearnMoreButton(onTap: onDetailTap),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeLaborSavingPointCard extends StatelessWidget {
  const HomeLaborSavingPointCard({
    super.key,
    required this.points,
    required this.onDetailTap,
  });

  final List<TextSpan> points;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: AppColors.primaryLight,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/png/common/pin_green_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 4.w),
              Text(
                '인건비 절감 Point',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...points.map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                  ),
                  children: [const TextSpan(text: '→ '), point],
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          _LearnMoreButton(onTap: onDetailTap),
        ],
      ),
    );
  }
}

class _LearnMoreButton extends StatelessWidget {
  const _LearnMoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(36.h),
          padding: EdgeInsets.symmetric(vertical: 6.h),
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '자세히 알아보기',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallM.copyWith(
                color: AppColors.grey0,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
              ),
            ),
            SizedBox(width: 8.w),
            SvgPicture.asset(
              'assets/icons/svg/icon/chevron_right_white_5x9.svg',
              width: 5,
              height: 9,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.textAlign = TextAlign.center});

  final String text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: textAlign,
        style: AppTypography.bodySmallB.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          height: 19 / 14,
        ),
      ),
    );
  }
}

class _MemoIconCell extends StatelessWidget {
  const _MemoIconCell({
    required this.hasMemo,
    this.onTap,
  });

  final bool hasMemo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Opacity(
            opacity: hasMemo ? 1 : 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.grey50),
                backgroundBlendMode: BlendMode.srcOver,
                color: AppColors.grey25,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/svg/icon/pencil_grey_12.svg',
                width: 12,
                height: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell(this.status, {this.onTap});

  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: WorkStatusBadge(status: status, compact: true),
        ),
      ),
    );
  }
}

class _WorkerNameCell extends StatelessWidget {
  const _WorkerNameCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/svg/icon/star_mint_16.svg',
            width: 16,
            height: 16,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 19 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
