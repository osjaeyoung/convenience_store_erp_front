/// 예상 인건비 조회 응답
class ExpectedLaborCost {
  const ExpectedLaborCost({
    required this.branchId,
    required this.rangeType,
    required this.periodLabel,
    required this.currentTotalCost,
    required this.previousTotalCost,
    required this.changeRatePercent,
    required this.headcountPrevious,
    required this.headcountCurrent,
    this.componentComparisons = const [],
    this.monthlyTrend = const [],
    this.savingPoints = const [],
  });

  final int branchId;
  final String rangeType;
  final String periodLabel;
  final int currentTotalCost;
  final int previousTotalCost;
  final double changeRatePercent;
  final int headcountPrevious;
  final int headcountCurrent;
  final List<ComponentComparison> componentComparisons;
  final List<MonthlyTrendItem> monthlyTrend;
  final List<SavingPoint> savingPoints;

  factory ExpectedLaborCost.fromJson(Map<String, dynamic> json) {
    return ExpectedLaborCost(
      branchId: json['branch_id'] as int,
      rangeType: json['range_type'] as String,
      periodLabel: json['period_label'] as String,
      currentTotalCost: json['current_total_cost'] as int,
      previousTotalCost: json['previous_total_cost'] as int,
      changeRatePercent: (json['change_rate_percent'] as num).toDouble(),
      headcountPrevious: json['headcount_previous'] as int,
      headcountCurrent: json['headcount_current'] as int,
      componentComparisons: (json['component_comparisons'] as List<dynamic>?)
              ?.map((e) => ComponentComparison.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map((e) => MonthlyTrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      savingPoints: (json['saving_points'] as List<dynamic>?)
              ?.map((e) => SavingPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ComponentComparison {
  const ComponentComparison({
    required this.componentName,
    required this.previousAmount,
    required this.currentAmount,
  });

  final String componentName;
  final int previousAmount;
  final int currentAmount;

  factory ComponentComparison.fromJson(Map<String, dynamic> json) {
    return ComponentComparison(
      componentName: json['component_name'] as String,
      previousAmount: json['previous_amount'] as int,
      currentAmount: json['current_amount'] as int,
    );
  }
}

class MonthlyTrendItem {
  const MonthlyTrendItem({
    required this.month,
    required this.basePay,
    required this.allowancePay,
    required this.totalCost,
    required this.headcount,
  });

  final String month;
  final int basePay;
  final int allowancePay;
  final int totalCost;
  final int headcount;

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendItem(
      month: json['month'] as String,
      basePay: json['base_pay'] as int,
      allowancePay: json['allowance_pay'] as int,
      totalCost: json['total_cost'] as int,
      headcount: json['headcount'] as int,
    );
  }
}

class SavingPoint {
  const SavingPoint({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory SavingPoint.fromJson(Map<String, dynamic> json) {
    return SavingPoint(
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}
