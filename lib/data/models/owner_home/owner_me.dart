/// 내 정보 조회 (역할별 응답) - GET /me
class OwnerMe {
  const OwnerMe({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.role,
    this.approvalStatus,
    this.signupStep,
    this.owner,
    this.manager,
    this.worker,
  });

  final int id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? role;
  final String? approvalStatus;
  final String? signupStep;
  final OwnerProfile? owner;
  final ManagerProfile? manager;
  final WorkerProfile? worker;

  factory OwnerMe.fromJson(Map<String, dynamic> json) {
    return OwnerMe(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String?,
      approvalStatus: json['approval_status'] as String?,
      signupStep: json['signup_step'] as String?,
      owner: json['owner'] != null
          ? OwnerProfile.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      manager: json['manager'] != null
          ? ManagerProfile.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      worker: json['worker'] != null
          ? WorkerProfile.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OwnerProfile {
  const OwnerProfile({
    this.totalBranches = 0,
    this.pendingBranches = 0,
    this.approvedBranches = 0,
    this.rejectedBranches = 0,
    this.branches = const [],
  });

  final int totalBranches;
  final int pendingBranches;
  final int approvedBranches;
  final int rejectedBranches;
  final List<OwnerBranchSummary> branches;

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      totalBranches: json['total_branches'] as int? ?? 0,
      pendingBranches: json['pending_branches'] as int? ?? 0,
      approvedBranches: json['approved_branches'] as int? ?? 0,
      rejectedBranches: json['rejected_branches'] as int? ?? 0,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) =>
                  OwnerBranchSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OwnerBranchSummary {
  const OwnerBranchSummary({
    required this.id,
    required this.name,
    this.code,
    this.reviewStatus,
    this.isOpenForManager = true,
  });

  final int id;
  final String name;
  final String? code;
  final String? reviewStatus;
  final bool isOpenForManager;

  factory OwnerBranchSummary.fromJson(Map<String, dynamic> json) {
    return OwnerBranchSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      reviewStatus: json['review_status'] as String?,
      isOpenForManager: json['is_open_for_manager'] as bool? ?? true,
    );
  }
}

class ManagerProfile {
  const ManagerProfile({this.branches = const []});
  final List<dynamic> branches;
  factory ManagerProfile.fromJson(Map<String, dynamic> json) {
    return ManagerProfile(
      branches: json['branches'] as List<dynamic>? ?? [],
    );
  }
}

class WorkerProfile {
  const WorkerProfile();
  factory WorkerProfile.fromJson(Map<String, dynamic> json) =>
      const WorkerProfile();
}
