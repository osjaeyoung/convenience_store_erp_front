/// 월별 인건비 직원 상세 조회 응답
class MonthlyLaborDetail {
  const MonthlyLaborDetail({
    required this.branchId,
    required this.year,
    required this.month,
    required this.periodLabel,
    required this.totalEmployeeCount,
    required this.totalWorkMinutes,
    required this.totalCost,
    required this.employees,
  });

  final int branchId;
  final int year;
  final int month;
  final String periodLabel;
  final int totalEmployeeCount;
  final int totalWorkMinutes;
  final int totalCost;
  final List<EmployeeLaborDetail> employees;

  factory MonthlyLaborDetail.fromJson(Map<String, dynamic> json) {
    return MonthlyLaborDetail(
      branchId: json['branch_id'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      periodLabel: json['period_label'] as String,
      totalEmployeeCount: json['total_employee_count'] as int,
      totalWorkMinutes: json['total_work_minutes'] as int,
      totalCost: json['total_cost'] as int,
      employees: (json['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeLaborDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
    required this.basePay,
    required this.weeklyAllowance,
    required this.overtimePay,
    required this.totalCost,
  });

  final int employeeId;
  final String employeeName;
  final String wageType;
  final String wageTypeLabel;
  final int wageAmount;
  final int totalWorkMinutes;
  final double totalWorkHours;
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
      wageAmount: json['wage_amount'] as int,
      totalWorkMinutes: json['total_work_minutes'] as int,
      totalWorkHours: (json['total_work_hours'] as num).toDouble(),
      basePay: json['base_pay'] as int,
      weeklyAllowance: json['weekly_allowance'] as int,
      overtimePay: json['overtime_pay'] as int,
      totalCost: json['total_cost'] as int,
    );
  }
}
