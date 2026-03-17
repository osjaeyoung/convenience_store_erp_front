/// 점장 홈 지점
class ManagerBranch {
  const ManagerBranch({
    required this.id,
    required this.name,
    this.code,
    this.reviewStatus,
    this.recruitment,
    this.openAlertCount = 0,
    this.todayWorkerCount = 0,
  });

  final int id;
  final String name;
  final String? code;
  final String? reviewStatus;
  final RecruitmentSummary? recruitment;
  final int openAlertCount;
  final int todayWorkerCount;

  factory ManagerBranch.fromJson(Map<String, dynamic> json) {
    return ManagerBranch(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      reviewStatus: json['review_status'] as String?,
      recruitment: json['recruitment'] != null
          ? RecruitmentSummary.fromJson(
              json['recruitment'] as Map<String, dynamic>)
          : null,
      openAlertCount: json['open_alert_count'] as int? ?? 0,
      todayWorkerCount: json['today_worker_count'] as int? ?? 0,
    );
  }
}

class RecruitmentSummary {
  const RecruitmentSummary({
    this.waitingInterviews = 0,
    this.newApplicants = 0,
    this.newContacts = 0,
    this.updatedAt,
  });

  final int waitingInterviews;
  final int newApplicants;
  final int newContacts;
  final String? updatedAt;

  factory RecruitmentSummary.fromJson(Map<String, dynamic> json) {
    return RecruitmentSummary(
      waitingInterviews: json['waiting_interviews'] as int? ?? 0,
      newApplicants: json['new_applicants'] as int? ?? 0,
      newContacts: json['new_contacts'] as int? ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
