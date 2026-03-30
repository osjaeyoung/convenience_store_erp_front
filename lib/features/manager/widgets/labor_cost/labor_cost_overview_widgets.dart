import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/labor_cost/expected_labor_cost.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

String _monthShort(String yyyyMm) {
  final p = yyyyMm.split('-');
  if (p.length >= 2) {
    final m = int.tryParse(p[1]);
    if (m != null) return '$m월';
  }
  return yyyyMm;
}

/// 서브탭: 예상 인건비 | 월별 인건비 | 인건비 절감 상세 (Figma 2534 하단 탭)
class LaborCostSubTabsBar extends StatelessWidget {
  const LaborCostSubTabsBar({
    super.key,
    required this.controller,
  });

  final TabController controller;

  static const _tabs = ['예상 인건비', '월별 인건비', '인건비 절감 상세'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.grey0,
        border: Border(bottom: BorderSide(color: AppColors.grey25)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.bodyLargeB.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
        ),
        unselectedLabelStyle: AppTypography.bodyLargeB.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
          color: AppColors.textTertiary,
        ),
        indicatorColor: AppColors.textPrimary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [for (final t in _tabs) Tab(text: t)],
      ),
    );
  }
}

/// 이번 달 / 6개월 드롭다운 (Figma bordered 96×42, radius 10)
class LaborCostPeriodDropdown extends StatelessWidget {
  const LaborCostPeriodDropdown({
    super.key,
    required this.rangeType,
    required this.onChanged,
  });

  final String rangeType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = rangeType == 'six_months' ? '6개월' : '이번 달';
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () async {
            final picked = await showModalBottomSheet<String>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('이번 달'),
                      onTap: () => Navigator.pop(ctx, 'this_month'),
                    ),
                    ListTile(
                      title: const Text('6개월'),
                      onTap: () => Navigator.pop(ctx, 'six_months'),
                    ),
                  ],
                ),
              ),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 96,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grey50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMediumR.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LaborCostFigmaSummaryCard extends StatelessWidget {
  const LaborCostFigmaSummaryCard({
    super.key,
    required this.totalWonText,
    required this.ratioPercentText,
    required this.ratioWentUp,
  });

  final String totalWonText;
  final String ratioPercentText;
  final bool ratioWentUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment(-0.35, 0.2),
          end: Alignment(1.0, 1.0),
          colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalWonText,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 32 / 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppTypography.bodyMediumM.copyWith(
                fontSize: 14,
                height: 16 / 14,
                color: const Color(0xFF666874),
              ),
              children: [
                const TextSpan(text: '전월 대비 총 '),
                TextSpan(
                  text: ratioPercentText,
                  style: AppTypography.bodyMediumM.copyWith(
                    fontSize: 14,
                    height: 16 / 14,
                    color: const Color(0xFF666874),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: ratioWentUp ? ' 올랐어요' : ' 내렸어요',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaborCostHeadcountCompareCard extends StatelessWidget {
  const LaborCostHeadcountCompareCard({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftCount,
    required this.rightCount,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftCount;
  final int rightCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  leftLabel,
                  style: AppTypography.bodySmallM.copyWith(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$leftCount',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.grey50,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  rightLabel,
                  style: AppTypography.bodySmallM.copyWith(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$rightCount',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaborCostDualBarChartSection extends StatelessWidget {
  const LaborCostDualBarChartSection({
    super.key,
    required this.rangeType,
    required this.components,
    required this.monthlyTrend,
  });

  final String rangeType;
  final List<ComponentComparison> components;
  final List<MonthlyTrendItem> monthlyTrend;

  @override
  Widget build(BuildContext context) {
    if (rangeType == 'this_month') {
      return _ThisMonthBars(components: components);
    }
    return _SixMonthBars(items: monthlyTrend);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmallM.copyWith(
            fontSize: 12,
            color: const Color(0xFF666874),
          ),
        ),
      ],
    );
  }
}

class _ThisMonthBars extends StatelessWidget {
  const _ThisMonthBars({required this.components});

  final List<ComponentComparison> components;

  int _maxAmount() {
    var m = 1;
    for (final c in components) {
      if (c.previousAmount > m) m = c.previousAmount;
      if (c.currentAmount > m) m = c.currentAmount;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxA = _maxAmount();
    final labels = components.map((e) => e.componentName).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '인건비',
                      style: AppTypography.bodyLargeM.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' (천원)',
                      style: AppTypography.bodySmallR.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const _LegendDot(
                color: AppColors.textPrimary,
                label: '전월',
              ),
              const SizedBox(width: 12),
              const _LegendDot(color: AppColors.primary, label: '금월'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < components.length; i++) ...[
                if (i > 0) const SizedBox(width: 38),
                _BarPair(
                  label: i < labels.length ? labels[i] : '',
                  prevFrac: components[i].previousAmount / maxA,
                  curFrac: components[i].currentAmount / maxA,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BarPair extends StatelessWidget {
  const _BarPair({
    required this.label,
    required this.prevFrac,
    required this.curFrac,
  });

  final String label;
  final double prevFrac;
  final double curFrac;

  @override
  Widget build(BuildContext context) {
    const maxH = 120.0;
    final hPrev = (prevFrac * maxH).clamp(4.0, maxH);
    final hCur = (curFrac * maxH).clamp(4.0, maxH);
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: hPrev,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: hCur,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.bodySmallM.copyWith(
              fontSize: 12,
              color: const Color(0xFF666874),
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SixMonthBars extends StatelessWidget {
  const _SixMonthBars({required this.items});

  final List<MonthlyTrendItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '6개월 추이 데이터가 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }
    final maxSeriesValue = items.fold<int>(
      1,
      (m, e) => math.max(
        m,
        math.max(e.allowancePay, e.basePay),
      ),
    );
    final roundedTop = ((maxSeriesValue + 4999) ~/ 5000) * 5000;
    final topTick = math.max(5000, roundedTop);
    final midTick = (topTick / 2).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '인건비',
                      style: AppTypography.bodyLargeM.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' (천원)',
                      style: AppTypography.bodySmallR.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const _LegendDot(color: AppColors.textPrimary, label: '수당'),
              const SizedBox(width: 12),
              const _LegendDot(color: AppColors.primary, label: '기본급'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _thousandLabel(topTick),
                          style: AppTypography.bodySmallR.copyWith(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _thousandLabel(midTick),
                          style: AppTypography.bodySmallR.copyWith(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _LaborLineChart(
                    items: items,
                    topTick: topTick,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _thousandLabel(int won) => '${(won / 1000).round()}';

class _LaborLineChart extends StatelessWidget {
  const _LaborLineChart({
    required this.items,
    required this.topTick,
  });

  final List<MonthlyTrendItem> items;
  final int topTick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LaborLineChartPainter(
              items: items,
              topTick: topTick,
              allowanceColor: AppColors.textPrimary,
              basePayColor: AppColors.primary,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Text(
                  _monthShort(items[i].month),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmallM.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF666874),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LaborLineChartPainter extends CustomPainter {
  _LaborLineChartPainter({
    required this.items,
    required this.topTick,
    required this.allowanceColor,
    required this.basePayColor,
  });

  final List<MonthlyTrendItem> items;
  final int topTick;
  final Color allowanceColor;
  final Color basePayColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final chartLeft = 0.0;
    final chartRight = size.width;
    final chartTop = 8.0;
    final chartBottom = size.height - 12;
    final chartHeight = chartBottom - chartTop;

    final gridPaint = Paint()
      ..color = const Color(0xFFE6EAF3)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF2A2B34)
      ..strokeWidth = 1.2;

    final yTop = chartTop;
    final yMid = chartTop + chartHeight / 2;
    final yBottom = chartBottom;
    canvas.drawLine(Offset(chartLeft, yTop), Offset(chartRight, yTop), gridPaint);
    canvas.drawLine(Offset(chartLeft, yMid), Offset(chartRight, yMid), gridPaint);
    canvas.drawLine(Offset(chartLeft, yBottom), Offset(chartRight, yBottom), axisPaint);

    final denom = topTick <= 0 ? 1 : topTick;
    final stepX = items.length == 1 ? 0.0 : size.width / (items.length - 1);
    final allowancePath = Path();
    final basePayPath = Path();
    final allowancePoints = <Offset>[];
    final basePayPoints = <Offset>[];

    for (var i = 0; i < items.length; i++) {
      final x = chartLeft + stepX * i;
      final allowanceY =
          yBottom - ((items[i].allowancePay / denom) * chartHeight).clamp(0.0, chartHeight);
      final basePayY =
          yBottom - ((items[i].basePay / denom) * chartHeight).clamp(0.0, chartHeight);
      final a = Offset(x, allowanceY);
      final b = Offset(x, basePayY);
      allowancePoints.add(a);
      basePayPoints.add(b);
      if (i == 0) {
        allowancePath.moveTo(a.dx, a.dy);
        basePayPath.moveTo(b.dx, b.dy);
      } else {
        allowancePath.lineTo(a.dx, a.dy);
        basePayPath.lineTo(b.dx, b.dy);
      }
    }

    final allowanceLinePaint = Paint()
      ..color = allowanceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final basePayLinePaint = Paint()
      ..color = basePayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(allowancePath, allowanceLinePaint);
    canvas.drawPath(basePayPath, basePayLinePaint);

    final allowanceDotPaint = Paint()..color = allowanceColor;
    final basePayDotPaint = Paint()..color = basePayColor;
    for (final p in allowancePoints) {
      canvas.drawCircle(p, 3, allowanceDotPaint);
    }
    for (final p in basePayPoints) {
      canvas.drawCircle(p, 3, basePayDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LaborLineChartPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.topTick != topTick ||
        oldDelegate.allowanceColor != allowanceColor ||
        oldDelegate.basePayColor != basePayColor;
  }
}

/// 절감 Point + 빈 상태 + 검정 CTA (Figma 2534:11552 / 12883 empty)
class LaborCostSavingPointsFigma extends StatelessWidget {
  const LaborCostSavingPointsFigma({
    super.key,
    required this.points,
    required this.onDetailTap,
  });

  final List<SavingPoint> points;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    final empty = points.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/png/common/pin_green_icon.png',
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '인건비 절감 Point',
                style: AppTypography.bodySmallM.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF666874),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (empty)
            Text(
              '이번달 절감 Point가 없습니다',
              style: AppTypography.bodyMediumR.copyWith(
                fontSize: 14,
                height: 19 / 14,
                color: AppColors.textTertiary,
              ),
            )
          else ...[
            for (final p in points) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '→',
                    style: AppTypography.bodyMediumM.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF666874),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: AppTypography.bodyMediumM.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          style: AppTypography.bodyMediumR.copyWith(
                            fontSize: 14,
                            height: 19 / 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton(
                onPressed: onDetailTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.grey0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '절감 포인트 상세보기',
                      style: AppTypography.bodySmallM.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.grey0),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 상단 "이번 달 예상 인건비" + money 아이콘 행
class LaborCostSectionTitleRow extends StatelessWidget {
  const LaborCostSectionTitleRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/png/common/money_icon.png',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '이번 달 예상 인건비',
            style: AppTypography.bodyLargeM.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
            ),
          ),
        ],
      ),
    );
  }
}
