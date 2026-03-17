import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class HomeTodayWorkersSection extends StatelessWidget {
  const HomeTodayWorkersSection({
    super.key,
    required this.dateLabel,
    required this.rows,
    this.onTapHeader,
    this.onTapStatus,
    this.onTapMemo,
  });

  final String dateLabel;
  final List<
      ({
        String time,
        String workerName,
        String status,
        bool hasMemo,
      })> rows;
  final VoidCallback? onTapHeader;
  final void Function(
    ({
      String time,
      String workerName,
      String status,
      bool hasMemo,
    }) row,
  )?
      onTapStatus;
  final void Function(
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
        Row(
          children: [
            Image.asset(
              'assets/icons/png/common/person_book_icon.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              '오늘의 근무자 현황',
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 20 / 16,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onTapHeader,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.grey25),
              color: AppColors.grey0Alt,
            ),
            child: Text(
              dateLabel,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.grey25,
            border: Border(top: BorderSide(color: Color(0xFF666874), width: 1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: const [
              _HeaderCell('시간'),
              _HeaderCell('근무자'),
              _HeaderCell('메모'),
              _HeaderCell('상태'),
            ],
          ),
        ),
        ...rows.map(
          (row) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey25)),
            ),
            child: Row(
              children: [
                _BodyCell(row.time),
                _WorkerNameCell(row.workerName),
                _MemoIconCell(
                  hasMemo: row.hasMemo,
                  onTap: row.hasMemo && onTapMemo != null ? () => onTapMemo!(row) : null,
                ),
                _StatusCell(
                  row.status,
                  onTap: onTapStatus == null ? null : () => onTapStatus!(row),
                ),
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey25)),
            ),
            child: Text(
              '해당 날짜의 근무자 정보가 없습니다.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textTertiary,
                fontSize: 14,
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
  });

  final String totalAmountText;
  final String changeText;

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
            const SizedBox(width: 6),
            Text(
              '이번 달 예상 인건비',
              style: AppTypography.bodyLargeM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 20 / 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 26 / 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                changeText,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 16 / 14,
                ),
              ),
              const SizedBox(height: 12),
              const _LearnMoreButton(),
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
  });

  final List<TextSpan> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 4),
              Text(
                '인건비 절감 Point',
                style: AppTypography.bodySmallM.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                  ),
                  children: [const TextSpan(text: '→ '), point],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _LearnMoreButton(),
        ],
      ),
    );
  }
}

class _LearnMoreButton extends StatelessWidget {
  const _LearnMoreButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(36),
          padding: const EdgeInsets.symmetric(vertical: 6),
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
              ),
            ),
            const SizedBox(width: 8),
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
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmallB.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
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
          fontSize: 14,
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
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: hasMemo ? 1 : 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
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
    final isDone = status == '완료';
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: isDone ? null : Border.all(color: AppColors.primary),
              color: isDone ? const Color(0xFF666874) : AppColors.primaryLight,
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallB.copyWith(
                color: isDone ? AppColors.grey0 : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
              ),
            ),
          ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/svg/icon/star_mint_16.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 19 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
