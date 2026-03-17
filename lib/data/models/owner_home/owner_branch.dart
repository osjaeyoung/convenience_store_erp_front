/// 경영주 점포
class OwnerBranch {
  const OwnerBranch({
    required this.id,
    required this.name,
    this.code,
    this.reviewStatus,
    this.reviewNote,
    this.managerUserId,
    this.isOpenForManager = true,
    this.createdAt,
    this.manager,
    this.managerCandidates = const [],
    this.workers = const [],
    this.todayShiftDate,
    this.todayShiftRows = const [],
    this.monthlyLaborCost,
  });

  final int id;
  final String name;
  final String? code;
  final String? reviewStatus;
  final String? reviewNote;
  final int? managerUserId;
  final bool isOpenForManager;
  final String? createdAt;
  final BranchManager? manager;
  final List<dynamic> managerCandidates;
  final List<dynamic> workers;
  final String? todayShiftDate;
  final List<dynamic> todayShiftRows;
  final MonthlyLaborCostSummary? monthlyLaborCost;

  factory OwnerBranch.fromJson(Map<String, dynamic> json) {
    return OwnerBranch(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      reviewStatus: json['review_status'] as String?,
      reviewNote: json['review_note'] as String?,
      managerUserId: json['manager_user_id'] as int?,
      isOpenForManager: json['is_open_for_manager'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      manager: json['manager'] != null
          ? BranchManager.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      managerCandidates:
          json['manager_candidates'] as List<dynamic>? ?? [],
      workers: json['workers'] as List<dynamic>? ?? [],
      todayShiftDate: json['today_shift_date'] as String?,
      todayShiftRows: json['today_shift_rows'] as List<dynamic>? ?? [],
      monthlyLaborCost: json['monthly_labor_cost'] != null
          ? MonthlyLaborCostSummary.fromJson(
              json['monthly_labor_cost'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BranchManager {
  const BranchManager({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.approvalStatus,
  });

  final int userId;
  final String fullName;
  final String phoneNumber;
  final String? approvalStatus;

  factory BranchManager.fromJson(Map<String, dynamic> json) {
    return BranchManager(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      approvalStatus: json['approval_status'] as String?,
    );
  }
}

class MonthlyLaborCostSummary {
  const MonthlyLaborCostSummary({
    this.monthlyTotal = 0,
    this.message,
  });

  final int monthlyTotal;
  final String? message;

  factory MonthlyLaborCostSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyLaborCostSummary(
      monthlyTotal: json['monthly_total'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}
