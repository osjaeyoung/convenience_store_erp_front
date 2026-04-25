/// 월별 인건비 직원 상세 조회 응답
class MonthlyLaborDetail {
  const MonthlyLaborDetail({
    required this.branchId,
    required this.year,
    required this.month,
    required this.periodLabel,
    this.businessDays = 0,
    required this.totalEmployeeCount,
    required this.totalWorkMinutes,
    required this.totalCost,
    this.previousTotalCost = 0,
    this.changeRatePercent = 0,
    this.componentSummaries = const [],
    required this.employees,
  });

  final int branchId;
  final int year;
  final int month;
  final String periodLabel;
  final int businessDays;
  final int totalEmployeeCount;
  final int totalWorkMinutes;
  final int totalCost;
  final int previousTotalCost;
  final double changeRatePercent;
  final List<ComponentSummary> componentSummaries;
  final List<EmployeeLaborDetail> employees;

  factory MonthlyLaborDetail.fromJson(Map<String, dynamic> json) {
    return MonthlyLaborDetail(
      branchId: json['branch_id'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      periodLabel: json['period_label'] as String,
      businessDays: (json['business_days'] as num?)?.toInt() ?? 0,
      totalEmployeeCount: json['total_employee_count'] as int,
      totalWorkMinutes: json['total_work_minutes'] as int,
      totalCost: json['total_cost'] as int,
      previousTotalCost: (json['previous_total_cost'] as num?)?.toInt() ?? 0,
      changeRatePercent: (json['change_rate_percent'] as num?)?.toDouble() ?? 0,
      componentSummaries: (json['component_summaries'] as List<dynamic>?)
              ?.map((e) => ComponentSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: (json['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeLaborDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ComponentSummary {
  const ComponentSummary({
    required this.componentName,
    required this.amount,
  });

  final String componentName;
  final int amount;

  factory ComponentSummary.fromJson(Map<String, dynamic> json) {
    return ComponentSummary(
      componentName: json['component_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class EmployeeLaborDetail {
  const EmployeeLaborDetail({
    required this.employeeId,
    required this.employeeName,
    required this.wageType,
    required this.wageTypeLabel,
    required this.wageAmount,
    required this.totalWorkMinutes,
    required this.totalWorkHours,
    this.contractWeeklyWorkMinutes,
    required this.basePay,
    required this.weeklyAllowance,
    required this.overtimePay,
    required this.totalCost,
  });

  final int employeeId;
  final String employeeName;
  final String wageType;
  final String wageTypeLabel;
  final int? wageAmount;
  final int totalWorkMinutes;
  final double totalWorkHours;
  final int? contractWeeklyWorkMinutes;
  final int basePay;
  final int weeklyAllowance;
  final int overtimePay;
  final int totalCost;

  factory EmployeeLaborDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeLaborDetail(
      employeeId: json['employee_id'] as int,
      employeeName: json['employee_name'] as String,
      wageType: json['wage_type'] as String,
      wageTypeLabel: json['wage_type_label'] as String,
      wageAmount: (json['wage_amount'] as num?)?.toInt(),
      totalWorkMinutes: json['total_work_minutes'] as int,
      totalWorkHours: (json['total_work_hours'] as num).toDouble(),
      contractWeeklyWorkMinutes:
          (json['contract_weekly_work_minutes'] as num?)?.toInt(),
      basePay: json['base_pay'] as int,
      weeklyAllowance: json['weekly_allowance'] as int,
      overtimePay: json['overtime_pay'] as int,
      totalCost: json['total_cost'] as int,
    );
  }
}
