/// 인건비 절감 상세 조회 응답
class LaborSavingDetail {
  const LaborSavingDetail({
    required this.branchId,
    required this.year,
    required this.month,
    this.retirementExpectedWorkers = const [],
    this.weeklyAllowanceImprovementPoints = const [],
    this.overlappingWorkIssues = const [],
  });

  final int branchId;
  final int year;
  final int month;
  final List<RetirementExpectedWorker> retirementExpectedWorkers;
  final List<WeeklyAllowanceImprovementPoint> weeklyAllowanceImprovementPoints;
  final List<OverlappingWorkIssue> overlappingWorkIssues;

  factory LaborSavingDetail.fromJson(Map<String, dynamic> json) {
    return LaborSavingDetail(
      branchId: json['branch_id'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      retirementExpectedWorkers:
          (json['retirement_expected_workers'] as List<dynamic>?)
                  ?.map((e) =>
                      RetirementExpectedWorker.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      weeklyAllowanceImprovementPoints:
          (json['weekly_allowance_improvement_points'] as List<dynamic>?)
                  ?.map((e) => WeeklyAllowanceImprovementPoint.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      overlappingWorkIssues:
          (json['overlapping_work_issues'] as List<dynamic>?)
                  ?.map((e) =>
                      OverlappingWorkIssue.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
    );
  }
}

class RetirementExpectedWorker {
  const RetirementExpectedWorker({
    required this.employeeId,
    required this.employeeName,
    required this.hireDate,
    required this.severanceEligibleDate,
    required this.averageWeeklyMinutesRecent4weeks,
    required this.legalWeeklyHoursConditionMet,
  });

  final int employeeId;
  final String employeeName;
  final String hireDate;
  final String severanceEligibleDate;
  final int averageWeeklyMinutesRecent4weeks;
  final bool legalWeeklyHoursConditionMet;

  factory RetirementExpectedWorker.fromJson(Map<String, dynamic> json) {
    return RetirementExpectedWorker(
      employeeId: json['employee_id'] as int,
      employeeName: json['employee_name'] as String,
      hireDate: json['hire_date'] as String,
      severanceEligibleDate: json['severance_eligible_date'] as String,
      averageWeeklyMinutesRecent4weeks:
          json['average_weekly_minutes_recent_4weeks'] as int,
      legalWeeklyHoursConditionMet:
          json['legal_weekly_hours_condition_met'] as bool,
    );
  }
}

class WeeklyAllowanceImprovementPoint {
  const WeeklyAllowanceImprovementPoint({
    required this.pointTitle,
    this.legalBasis,
    this.recommendsNewHire = false,
    this.newHireWeeklyMinutes,
    this.recommendationNote,
    this.beforeWorkers = const [],
    this.afterWorkers = const [],
  });

  final String pointTitle;
  final String? legalBasis;
  final bool recommendsNewHire;
  final int? newHireWeeklyMinutes;
  final String? recommendationNote;
  final List<WorkerInfo> beforeWorkers;
  final List<WorkerInfo> afterWorkers;

  List<WorkerInfo> get resolvedAfterWorkers {
    final hasNewHire = afterWorkers.any((worker) => worker.isNewHire);
    if (!recommendsNewHire || hasNewHire || newHireWeeklyMinutes == null) {
      return afterWorkers;
    }

    return <WorkerInfo>[
      ...afterWorkers,
      WorkerInfo(
        employeeName: '신규채용',
        category: '개선안',
        weeklyWorkMinutes: newHireWeeklyMinutes!,
      ),
    ];
  }

  factory WeeklyAllowanceImprovementPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyAllowanceImprovementPoint(
      pointTitle: json['point_title'] as String,
      legalBasis: json['legal_basis'] as String?,
      recommendsNewHire: json['recommends_new_hire'] as bool? ?? false,
      newHireWeeklyMinutes: json['new_hire_weekly_minutes'] as int?,
      recommendationNote: json['recommendation_note'] as String?,
      beforeWorkers: (json['before_workers'] as List<dynamic>?)
              ?.map((e) => WorkerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      afterWorkers: (json['after_workers'] as List<dynamic>?)
              ?.map((e) => WorkerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkerInfo {
  const WorkerInfo({
    required this.employeeName,
    required this.category,
    required this.weeklyWorkMinutes,
  });

  final String employeeName;
  final String category;
  final int weeklyWorkMinutes;

  bool get isNewHire => employeeName.trim() == '신규채용';

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      employeeName: json['employee_name'] as String,
      category: json['category'] as String,
      weeklyWorkMinutes: json['weekly_work_minutes'] as int,
    );
  }
}

class OverlappingWorkIssue {
  const OverlappingWorkIssue({
    required this.workDate,
    this.employeeNames = const [],
    required this.overlapTimeRange,
    required this.scheduleIdPair,
  });

  final String workDate;
  final List<String> employeeNames;
  final String overlapTimeRange;
  final List<int> scheduleIdPair;

  String get employeeName => employeeNames.join(', ');

  factory OverlappingWorkIssue.fromJson(Map<String, dynamic> json) {
    final namesRaw = json['employee_names'];
    final names = namesRaw is List
        ? namesRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final fallback = json['employee_name']?.toString();
    return OverlappingWorkIssue(
      workDate: json['work_date'] as String,
      employeeNames: names.isNotEmpty
          ? names
          : <String>[
              if (fallback != null && fallback.isNotEmpty) fallback,
            ],
      overlapTimeRange: json['overlap_time_range'] as String,
      scheduleIdPair:
          (json['schedule_id_pair'] as List<dynamic>).cast<int>(),
    );
  }
}
