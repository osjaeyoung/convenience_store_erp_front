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

String _normalizeContractChatStatusLabel(String status, String label) {
  switch (status) {
    case 'business_draft':
    case 'waiting_worker':
      return '미완료';
    case 'completed':
      return '작성 완료';
    default:
      return label;
  }
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
    this.editButtonLabel,
    this.deleteButtonLabel,
    this.canDelete = true,
    this.createdAt,
    this.updatedAt,
  });

  final int resumeId;
  final String title;
  final String? resumeTypeLabel;
  final bool isDefault;
  final String? status;
  final String? editButtonLabel;
  final String? deleteButtonLabel;
  final bool canDelete;
  final String? createdAt;
  final String? updatedAt;

  factory WorkerResumeSummary.fromJson(Map<String, dynamic> json) {
    return WorkerResumeSummary(
      resumeId: _intOf(json['resume_id']),
      title: _stringOf(json['title']),
      resumeTypeLabel: _nullableString(json['resume_type_label']),
      isDefault: _boolOf(json['is_default']),
      status: _nullableString(json['status']),
      editButtonLabel: _nullableString(json['edit_button_label']),
      deleteButtonLabel: _nullableString(json['delete_button_label']),
      canDelete: json.containsKey('can_delete')
          ? _boolOf(json['can_delete'])
          : true,
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }
}

class WorkerResumePage {
  const WorkerResumePage({
    required this.items,
    required this.totalCount,
    this.isEmpty = false,
    this.emptyMessage,
    this.createButtonLabel,
  });

  final List<WorkerResumeSummary> items;
  final int totalCount;
  final bool isEmpty;
  final String? emptyMessage;
  final String? createButtonLabel;

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
      isEmpty: _boolOf(json['is_empty']),
      emptyMessage: _nullableString(json['empty_message']),
      createButtonLabel: _nullableString(json['create_button_label']),
    );
  }
}

class WorkerResumeOption {
  const WorkerResumeOption({required this.value, required this.label});

  final String value;
  final String label;

  factory WorkerResumeOption.fromJson(Map<String, dynamic> json) {
    return WorkerResumeOption(
      value: _stringOf(json['value']),
      label: _stringOf(json['label']),
    );
  }
}

class WorkerResumeProfileSummary {
  const WorkerResumeProfileSummary({
    required this.fullName,
    this.gender,
    this.genderLabel,
    this.age,
    this.ageLabel,
    this.address,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
  });

  final String fullName;
  final String? gender;
  final String? genderLabel;
  final int? age;
  final String? ageLabel;
  final String? address;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;

  factory WorkerResumeProfileSummary.fromJson(Map<String, dynamic> json) {
    return WorkerResumeProfileSummary(
      fullName: _stringOf(json['full_name']),
      gender: _nullableString(json['gender']),
      genderLabel: _nullableString(json['gender_label']),
      age: _nullableInt(json['age']),
      ageLabel: _nullableString(json['age_label']),
      address: _nullableString(json['address']),
      email: _nullableString(json['email']),
      phoneNumber: _nullableString(json['phone_number']),
      profileImageUrl: _nullableString(json['profile_image_url']),
    );
  }
}

class WorkerResumeCareerEntry {
  const WorkerResumeCareerEntry({
    this.careerId,
    required this.companyName,
    this.durationType,
    this.durationTypeLabel,
    this.startedYearMonth,
    this.endedYearMonth,
    this.duty,
    this.periodLabel,
  });

  final int? careerId;
  final String companyName;
  final String? durationType;
  final String? durationTypeLabel;
  final String? startedYearMonth;
  final String? endedYearMonth;
  final String? duty;
  final String? periodLabel;

  factory WorkerResumeCareerEntry.fromJson(Map<String, dynamic> json) {
    return WorkerResumeCareerEntry(
      careerId: _nullableInt(json['career_id']),
      companyName: _stringOf(json['company_name']),
      durationType: _nullableString(json['duration_type']),
      durationTypeLabel: _nullableString(json['duration_type_label']),
      startedYearMonth: _nullableString(json['started_year_month']),
      endedYearMonth: _nullableString(json['ended_year_month']),
      duty: _nullableString(json['duty']),
      periodLabel: _nullableString(json['period_label']),
    );
  }
}

class WorkerResumeWorkHistoryItem {
  const WorkerResumeWorkHistoryItem({
    this.periodLabel,
    required this.companyName,
    this.duty,
  });

  final String? periodLabel;
  final String companyName;
  final String? duty;

  factory WorkerResumeWorkHistoryItem.fromJson(Map<String, dynamic> json) {
    return WorkerResumeWorkHistoryItem(
      periodLabel: _nullableString(json['period_label']),
      companyName: _stringOf(json['company_name']),
      duty: _nullableString(json['duty']),
    );
  }
}

class WorkerResumeFormData {
  const WorkerResumeFormData({
    this.resumeId,
    this.resumeTitle,
    required this.mode,
    this.headerTitle,
    this.submitButtonLabel,
    this.editButtonLabel,
    this.deleteButtonLabel,
    this.canDelete = false,
    this.profileSummary,
    this.educationLevel,
    this.educationStatus,
    this.careerType,
    this.selfIntroduction,
    this.educationLevelOptions = const [],
    this.educationStatusOptions = const [],
    this.careerTypeOptions = const [],
    this.durationTypeOptions = const [],
    this.careerEntries = const [],
    this.workHistoryItems = const [],
    this.addCareerButtonLabel,
    this.resumeRegionPath,
    this.resumeAddressDetail,
  });

  final int? resumeId;
  final String? resumeTitle;
  final String mode;
  final String? headerTitle;
  final String? submitButtonLabel;
  final String? editButtonLabel;
  final String? deleteButtonLabel;
  final bool canDelete;
  final WorkerResumeProfileSummary? profileSummary;
  final String? educationLevel;
  final String? educationStatus;
  final String? careerType;
  final String? selfIntroduction;
  final List<WorkerResumeOption> educationLevelOptions;
  final List<WorkerResumeOption> educationStatusOptions;
  final List<WorkerResumeOption> careerTypeOptions;
  final List<WorkerResumeOption> durationTypeOptions;
  final List<WorkerResumeCareerEntry> careerEntries;
  final List<WorkerResumeWorkHistoryItem> workHistoryItems;
  final String? addCareerButtonLabel;
  /// 저장용: 공백 구분 경로 (`서울 강남구 개포2동`). 화면 표시는 ` > ` 로 변환.
  final String? resumeRegionPath;
  final String? resumeAddressDetail;

  bool get isEditMode => mode == 'edit';

  factory WorkerResumeFormData.fromJson(Map<String, dynamic> json) {
    final educationLevelOptions =
        json['education_level_options'] as List<dynamic>? ?? const [];
    final educationStatusOptions =
        json['education_status_options'] as List<dynamic>? ?? const [];
    final careerTypeOptions =
        json['career_type_options'] as List<dynamic>? ?? const [];
    final durationTypeOptions =
        json['duration_type_options'] as List<dynamic>? ?? const [];
    final careerEntries = json['career_entries'] as List<dynamic>? ?? const [];
    final workHistoryItems =
        json['work_history_items'] as List<dynamic>? ?? const [];

    return WorkerResumeFormData(
      resumeId: _nullableInt(json['resume_id']),
      resumeTitle: _nullableString(json['resume_title']),
      mode: _stringOf(json['mode']),
      headerTitle: _nullableString(json['header_title']),
      submitButtonLabel: _nullableString(json['submit_button_label']),
      editButtonLabel: _nullableString(json['edit_button_label']),
      deleteButtonLabel: _nullableString(json['delete_button_label']),
      canDelete: _boolOf(json['can_delete']),
      profileSummary: json['profile_summary'] is Map
          ? WorkerResumeProfileSummary.fromJson(
              Map<String, dynamic>.from(json['profile_summary'] as Map),
            )
          : null,
      educationLevel: _nullableString(json['education_level']),
      educationStatus: _nullableString(json['education_status']),
      careerType: _nullableString(json['career_type']),
      selfIntroduction: _nullableString(json['self_introduction']),
      educationLevelOptions: educationLevelOptions
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      educationStatusOptions: educationStatusOptions
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      careerTypeOptions: careerTypeOptions
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      durationTypeOptions: durationTypeOptions
          .whereType<Map>()
          .map(
            (item) =>
                WorkerResumeOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      careerEntries: careerEntries
          .whereType<Map>()
          .map(
            (item) => WorkerResumeCareerEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      workHistoryItems: workHistoryItems
          .whereType<Map>()
          .map(
            (item) => WorkerResumeWorkHistoryItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      addCareerButtonLabel: _nullableString(json['add_career_button_label']),
      resumeRegionPath: _nullableString(json['resume_region_path']),
      resumeAddressDetail: _nullableString(json['resume_address_detail']),
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

class WorkerContractChatSummary {
  const WorkerContractChatSummary({
    required this.contractId,
    required this.branchId,
    required this.employeeId,
    required this.branchName,
    required this.title,
    this.counterpartyName,
    this.counterpartyRole,
    required this.chatStatus,
    required this.chatStatusLabel,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final int contractId;
  final int branchId;
  final int employeeId;
  final String branchName;
  final String title;
  final String? counterpartyName;
  final String? counterpartyRole;
  final String chatStatus;
  final String chatStatusLabel;
  final String? lastMessagePreview;
  final String? lastMessageAt;
  final int unreadCount;

  bool get isCompleted => chatStatus == 'completed';

  factory WorkerContractChatSummary.fromJson(Map<String, dynamic> json) {
    return WorkerContractChatSummary(
      contractId: _intOf(json['contract_id']),
      branchId: _intOf(json['branch_id']),
      employeeId: _intOf(json['employee_id']),
      branchName: _stringOf(json['branch_name']),
      title: _stringOf(json['title']),
      counterpartyName: _nullableString(json['counterparty_name']),
      counterpartyRole: _nullableString(json['counterparty_role']),
      chatStatus: _stringOf(json['chat_status']),
      chatStatusLabel: _normalizeContractChatStatusLabel(
        _stringOf(json['chat_status']),
        _stringOf(json['chat_status_label']),
      ),
      lastMessagePreview: _nullableString(json['last_message_preview']),
      lastMessageAt: _nullableString(json['last_message_at']),
      unreadCount: _intOf(json['unread_count']),
    );
  }
}

class WorkerContractChatPage {
  const WorkerContractChatPage({
    required this.items,
    this.emptyTitle,
    this.emptyDescription,
  });

  final List<WorkerContractChatSummary> items;
  final String? emptyTitle;
  final String? emptyDescription;

  factory WorkerContractChatPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return WorkerContractChatPage(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => WorkerContractChatSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      emptyTitle: _nullableString(json['empty_title']),
      emptyDescription: _nullableString(json['empty_description']),
    );
  }
}

class WorkerContractChatThread {
  const WorkerContractChatThread({
    required this.contractId,
    required this.branchId,
    required this.employeeId,
    required this.branchName,
    required this.title,
    this.counterpartyName,
    this.counterpartyRole,
    required this.chatStatus,
    required this.chatStatusLabel,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final int contractId;
  final int branchId;
  final int employeeId;
  final String branchName;
  final String title;
  final String? counterpartyName;
  final String? counterpartyRole;
  final String chatStatus;
  final String chatStatusLabel;
  final String? lastMessagePreview;
  final String? lastMessageAt;
  final int unreadCount;

  bool get isCompleted => chatStatus == 'completed';

  factory WorkerContractChatThread.fromJson(Map<String, dynamic> json) {
    return WorkerContractChatThread(
      contractId: _intOf(json['contract_id']),
      branchId: _intOf(json['branch_id']),
      employeeId: _intOf(json['employee_id']),
      branchName: _stringOf(json['branch_name']),
      title: _stringOf(json['title']),
      counterpartyName: _nullableString(json['counterparty_name']),
      counterpartyRole: _nullableString(json['counterparty_role']),
      chatStatus: _stringOf(json['chat_status']),
      chatStatusLabel: _normalizeContractChatStatusLabel(
        _stringOf(json['chat_status']),
        _stringOf(json['chat_status_label']),
      ),
      lastMessagePreview: _nullableString(json['last_message_preview']),
      lastMessageAt: _nullableString(json['last_message_at']),
      unreadCount: _intOf(json['unread_count']),
    );
  }
}

class WorkerContractChatMessage {
  const WorkerContractChatMessage({
    required this.messageId,
    required this.senderRole,
    this.senderName,
    required this.messageType,
    required this.text,
    this.createdAt,
    this.documentStatus,
    this.canOpenDocument = false,
    this.openDocumentPath,
  });

  final String messageId;
  final String senderRole;
  final String? senderName;
  final String messageType;
  final String text;
  final String? createdAt;
  final String? documentStatus;
  final bool canOpenDocument;
  final String? openDocumentPath;

  bool get fromWorker => senderRole == 'worker';

  factory WorkerContractChatMessage.fromJson(Map<String, dynamic> json) {
    return WorkerContractChatMessage(
      messageId: _stringOf(json['message_id']),
      senderRole: _stringOf(json['sender_role']),
      senderName: _nullableString(json['sender_name']),
      messageType: _stringOf(json['message_type']),
      text: _stringOf(json['text']),
      createdAt: _nullableString(json['created_at']),
      documentStatus: _nullableString(json['document_status']),
      canOpenDocument: _boolOf(json['can_open_document']),
      openDocumentPath: _nullableString(json['open_document_path']),
    );
  }
}

class WorkerContractChatDetail {
  const WorkerContractChatDetail({
    required this.thread,
    required this.currentUserRole,
    required this.messages,
    this.canOpenDocument = false,
    this.canDownloadDocument = false,
  });

  final WorkerContractChatThread thread;
  final String currentUserRole;
  final List<WorkerContractChatMessage> messages;
  final bool canOpenDocument;
  final bool canDownloadDocument;

  factory WorkerContractChatDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    final threadJson = json['thread'];
    return WorkerContractChatDetail(
      thread: WorkerContractChatThread.fromJson(
        threadJson is Map ? Map<String, dynamic>.from(threadJson) : const {},
      ),
      currentUserRole: _stringOf(json['current_user_role']),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) => WorkerContractChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      canOpenDocument: _boolOf(json['can_open_document']),
      canDownloadDocument: _boolOf(json['can_download_document']),
    );
  }
}

/// `DELETE /contract-chats/{contract_id}` 응답 — `docs/api_spec_contract_chat.md` §3-1
class WorkerContractChatDeleteResult {
  const WorkerContractChatDeleteResult({required this.deleted});

  final bool deleted;

  factory WorkerContractChatDeleteResult.fromJson(Map<String, dynamic> json) {
    return WorkerContractChatDeleteResult(
      deleted: _boolOf(json['deleted']),
    );
  }
}

class WorkerContractChatDocument {
  const WorkerContractChatDocument({
    required this.contractId,
    required this.title,
    required this.templateVersion,
    required this.chatStatus,
    required this.chatStatusLabel,
    required this.currentUserRole,
    required this.formValues,
    this.documentPreviewText,
    required this.businessFieldKeys,
    required this.workerFieldKeys,
    required this.editableFieldKeys,
    required this.requiredFieldKeys,
    required this.requiredFieldLabels,
    this.primaryAction,
    this.primaryActionLabel,
    this.downloadAvailable = false,
  });

  final int contractId;
  final String title;
  final String templateVersion;
  final String chatStatus;
  final String chatStatusLabel;
  final String currentUserRole;
  final Map<String, dynamic> formValues;
  final String? documentPreviewText;
  final List<String> businessFieldKeys;
  final List<String> workerFieldKeys;
  final List<String> editableFieldKeys;
  final List<String> requiredFieldKeys;
  final Map<String, String> requiredFieldLabels;
  final String? primaryAction;
  final String? primaryActionLabel;
  final bool downloadAvailable;

  bool canEditField(String key) => editableFieldKeys.contains(key);

  factory WorkerContractChatDocument.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      final list = raw as List<dynamic>? ?? const [];
      return list
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final labelsRaw = json['required_field_labels'];
    final labels = <String, String>{};
    if (labelsRaw is Map) {
      for (final entry in labelsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value?.toString() ?? '';
        if (key.isNotEmpty) {
          labels[key] = value;
        }
      }
    }

    return WorkerContractChatDocument(
      contractId: _intOf(json['contract_id']),
      title: _stringOf(json['title']),
      templateVersion: _stringOf(json['template_version']),
      chatStatus: _stringOf(json['chat_status']),
      chatStatusLabel: _normalizeContractChatStatusLabel(
        _stringOf(json['chat_status']),
        _stringOf(json['chat_status_label']),
      ),
      currentUserRole: _stringOf(json['current_user_role']),
      formValues: json['form_values'] is Map
          ? Map<String, dynamic>.from(json['form_values'] as Map)
          : <String, dynamic>{},
      documentPreviewText: _nullableString(json['document_preview_text']),
      businessFieldKeys: parseStringList(json['business_field_keys']),
      workerFieldKeys: parseStringList(json['worker_field_keys']),
      editableFieldKeys: parseStringList(json['editable_field_keys']),
      requiredFieldKeys: parseStringList(json['required_field_keys']),
      requiredFieldLabels: labels,
      primaryAction: _nullableString(json['primary_action']),
      primaryActionLabel: _nullableString(json['primary_action_label']),
      downloadAvailable: _boolOf(json['download_available']),
    );
  }
}
