String _stringOf(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _intOf(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _boolOf(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

class WorkerRecruitmentPostingSummary {
  const WorkerRecruitmentPostingSummary({
    required this.postingId,
    required this.branchId,
    this.badgeLabel,
    required this.companyName,
    required this.title,
    this.regionSummary,
    required this.payType,
    required this.payAmount,
    this.isApplied = false,
    this.appliedAt,
    this.createdAt,
  });

  final int postingId;
  final int branchId;
  final String? badgeLabel;
  final String companyName;
  final String title;
  final String? regionSummary;
  final String payType;
  final int payAmount;
  final bool isApplied;
  final String? appliedAt;
  final String? createdAt;

  factory WorkerRecruitmentPostingSummary.fromJson(Map<String, dynamic> json) {
    return WorkerRecruitmentPostingSummary(
      postingId: _intOf(json['posting_id']),
      branchId: _intOf(json['branch_id']),
      badgeLabel: _nullableString(json['badge_label']),
      companyName: _stringOf(json['company_name']),
      title: _stringOf(json['title']),
      regionSummary: _nullableString(json['region_summary']),
      payType: _stringOf(json['pay_type']),
      payAmount: _intOf(json['pay_amount']),
      isApplied: _boolOf(json['is_applied']),
      appliedAt: _nullableString(json['applied_at']),
      createdAt: _nullableString(json['created_at']),
    );
  }
}

class WorkerRecruitmentPostingPage {
  const WorkerRecruitmentPostingPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.regionOptions = const [],
  });

  final List<WorkerRecruitmentPostingSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final List<String> regionOptions;

  factory WorkerRecruitmentPostingPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final regionOptions = json['region_options'] as List<dynamic>? ?? const [];
    return WorkerRecruitmentPostingPage(
      items: items
          .whereType<Map>()
          .map(
            (item) => WorkerRecruitmentPostingSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalCount: _intOf(json['total_count']),
      page: _intOf(json['page']),
      pageSize: _intOf(json['page_size']),
      regionOptions: regionOptions
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class WorkerRecruitmentPostingDetail {
  const WorkerRecruitmentPostingDetail({
    required this.postingId,
    required this.branchId,
    this.profileImageUrl,
    this.badgeLabel,
    required this.companyName,
    required this.title,
    this.regionSummary,
    this.address,
    required this.payType,
    required this.payAmount,
    this.workPeriod,
    this.workDays,
    this.workDaysDetail,
    this.workTime,
    this.workTimeDetail,
    this.jobCategory,
    this.employmentType,
    this.recruitmentDeadline,
    this.recruitmentHeadcount,
    this.recruitmentHeadcountDetail,
    this.education,
    this.educationDetail,
    this.managerName,
    this.contactPhone,
    this.legalWarningMessage,
    this.isApplied = false,
    this.applicationId,
    this.applicationActionLabel,
    this.createdAt,
    this.updatedAt,
  });

  final int postingId;
  final int branchId;
  final String? profileImageUrl;
  final String? badgeLabel;
  final String companyName;
  final String title;
  final String? regionSummary;
  final String? address;
  final String payType;
  final int payAmount;
  final String? workPeriod;
  final String? workDays;
  final String? workDaysDetail;
  final String? workTime;
  final String? workTimeDetail;
  final String? jobCategory;
  final String? employmentType;
  final String? recruitmentDeadline;
  final String? recruitmentHeadcount;
  final String? recruitmentHeadcountDetail;
  final String? education;
  final String? educationDetail;
  final String? managerName;
  final String? contactPhone;
  final String? legalWarningMessage;
  final bool isApplied;
  final int? applicationId;
  final String? applicationActionLabel;
  final String? createdAt;
  final String? updatedAt;

  factory WorkerRecruitmentPostingDetail.fromJson(Map<String, dynamic> json) {
    return WorkerRecruitmentPostingDetail(
      postingId: _intOf(json['posting_id']),
      branchId: _intOf(json['branch_id']),
      profileImageUrl: _nullableString(json['profile_image_url']),
      badgeLabel: _nullableString(json['badge_label']),
      companyName: _stringOf(json['company_name']),
      title: _stringOf(json['title']),
      regionSummary: _nullableString(json['region_summary']),
      address: _nullableString(json['address']),
      payType: _stringOf(json['pay_type']),
      payAmount: _intOf(json['pay_amount']),
      workPeriod: _nullableString(json['work_period']),
      workDays: _nullableString(json['work_days']),
      workDaysDetail: _nullableString(json['work_days_detail']),
      workTime: _nullableString(json['work_time']),
      workTimeDetail: _nullableString(json['work_time_detail']),
      jobCategory: _nullableString(json['job_category']),
      employmentType: _nullableString(json['employment_type']),
      recruitmentDeadline: _nullableString(json['recruitment_deadline']),
      recruitmentHeadcount: _nullableString(json['recruitment_headcount']),
      recruitmentHeadcountDetail: _nullableString(
        json['recruitment_headcount_detail'],
      ),
      education: _nullableString(json['education']),
      educationDetail: _nullableString(json['education_detail']),
      managerName: _nullableString(json['manager_name']),
      contactPhone: _nullableString(json['contact_phone']),
      legalWarningMessage: _nullableString(json['legal_warning_message']),
      isApplied: _boolOf(json['is_applied']),
      applicationId: _nullableInt(json['application_id']),
      applicationActionLabel: _nullableString(json['application_action_label']),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }
}

class WorkerResumeSummary {
  const WorkerResumeSummary({
    required this.resumeId,
    required this.title,
    this.resumeTypeLabel,
    this.isDefault = false,
    this.status,
  });

  final int resumeId;
  final String title;
  final String? resumeTypeLabel;
  final bool isDefault;
  final String? status;

  factory WorkerResumeSummary.fromJson(Map<String, dynamic> json) {
    return WorkerResumeSummary(
      resumeId: _intOf(json['resume_id']),
      title: _stringOf(json['title']),
      resumeTypeLabel: _nullableString(json['resume_type_label']),
      isDefault: _boolOf(json['is_default']),
      status: _nullableString(json['status']),
    );
  }
}

class WorkerResumePage {
  const WorkerResumePage({required this.items, required this.totalCount});

  final List<WorkerResumeSummary> items;
  final int totalCount;

  factory WorkerResumePage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return WorkerResumePage(
      items: items
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      totalCount: _intOf(json['total_count']),
    );
  }
}

class WorkerRecruitmentApplyOptions {
  const WorkerRecruitmentApplyOptions({
    required this.postingId,
    required this.companyName,
    required this.title,
    this.alreadyApplied = false,
    this.existingApplicationId,
    this.canApply = false,
    this.blockedReason,
    this.resumes = const [],
    this.selectedResumeId,
    this.confirmTitle,
    this.confirmMessage,
  });

  final int postingId;
  final String companyName;
  final String title;
  final bool alreadyApplied;
  final int? existingApplicationId;
  final bool canApply;
  final String? blockedReason;
  final List<WorkerResumeSummary> resumes;
  final int? selectedResumeId;
  final String? confirmTitle;
  final String? confirmMessage;

  factory WorkerRecruitmentApplyOptions.fromJson(Map<String, dynamic> json) {
    final resumes = json['resumes'] as List<dynamic>? ?? const [];
    return WorkerRecruitmentApplyOptions(
      postingId: _intOf(json['posting_id']),
      companyName: _stringOf(json['company_name']),
      title: _stringOf(json['title']),
      alreadyApplied: _boolOf(json['already_applied']),
      existingApplicationId: _nullableInt(json['existing_application_id']),
      canApply: _boolOf(json['can_apply']),
      blockedReason: _nullableString(json['blocked_reason']),
      resumes: resumes
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      selectedResumeId: _nullableInt(json['selected_resume_id']),
      confirmTitle: _nullableString(json['confirm_title']),
      confirmMessage: _nullableString(json['confirm_message']),
    );
  }
}

class WorkerRecruitmentApplicationCreateResult {
  const WorkerRecruitmentApplicationCreateResult({
    required this.applicationId,
    required this.postingId,
    required this.resumeId,
    this.status,
    this.appliedAt,
  });

  final int applicationId;
  final int postingId;
  final int resumeId;
  final String? status;
  final String? appliedAt;

  factory WorkerRecruitmentApplicationCreateResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return WorkerRecruitmentApplicationCreateResult(
      applicationId: _intOf(json['application_id']),
      postingId: _intOf(json['posting_id']),
      resumeId: _intOf(json['resume_id']),
      status: _nullableString(json['status']),
      appliedAt: _nullableString(json['applied_at']),
    );
  }
}

class WorkerRecruitmentApplicationSummary {
  const WorkerRecruitmentApplicationSummary({
    required this.applicationId,
    required this.postingId,
    required this.branchId,
    this.badgeLabel,
    required this.companyName,
    required this.title,
    this.regionSummary,
    required this.payType,
    required this.payAmount,
    this.appliedAt,
    this.appliedDateLabel,
  });

  final int applicationId;
  final int postingId;
  final int branchId;
  final String? badgeLabel;
  final String companyName;
  final String title;
  final String? regionSummary;
  final String payType;
  final int payAmount;
  final String? appliedAt;
  final String? appliedDateLabel;

  factory WorkerRecruitmentApplicationSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return WorkerRecruitmentApplicationSummary(
      applicationId: _intOf(json['application_id']),
      postingId: _intOf(json['posting_id']),
      branchId: _intOf(json['branch_id']),
      badgeLabel: _nullableString(json['badge_label']),
      companyName: _stringOf(json['company_name']),
      title: _stringOf(json['title']),
      regionSummary: _nullableString(json['region_summary']),
      payType: _stringOf(json['pay_type']),
      payAmount: _intOf(json['pay_amount']),
      appliedAt: _nullableString(json['applied_at']),
      appliedDateLabel: _nullableString(json['applied_date_label']),
    );
  }
}

class WorkerRecruitmentApplicationPage {
  const WorkerRecruitmentApplicationPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<WorkerRecruitmentApplicationSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory WorkerRecruitmentApplicationPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return WorkerRecruitmentApplicationPage(
      items: items
          .whereType<Map>()
          .map(
            (item) => WorkerRecruitmentApplicationSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalCount: _intOf(json['total_count']),
      page: _intOf(json['page']),
      pageSize: _intOf(json['page_size']),
    );
  }
}
