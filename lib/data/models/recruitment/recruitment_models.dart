import 'package:equatable/equatable.dart';

class RecruitmentHomeResponse extends Equatable {
  const RecruitmentHomeResponse({
    this.recentViewedJobSeekers = const [],
    this.searchResults = const [],
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<RecentViewedJobSeeker> recentViewedJobSeekers;
  final List<JobSeekerSummary> searchResults;
  final int totalCount;
  final int page;
  final int pageSize;

  factory RecruitmentHomeResponse.fromJson(Map<String, dynamic> json) {
    return RecruitmentHomeResponse(
      recentViewedJobSeekers:
          (json['recent_viewed_job_seekers'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RecentViewedJobSeeker.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      searchResults:
          (json['search_results'] as List<dynamic>?)
              ?.map((e) => JobSeekerSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  List<Object?> get props => [
    recentViewedJobSeekers,
    searchResults,
    totalCount,
    page,
    pageSize,
  ];
}

class RecentViewedJobSeeker extends Equatable {
  const RecentViewedJobSeeker({
    required this.employeeId,
    required this.employeeName,
    required this.age,
    this.viewedAt,
  });

  final int employeeId;
  final String employeeName;
  final int age;
  final String? viewedAt;

  factory RecentViewedJobSeeker.fromJson(Map<String, dynamic> json) {
    return RecentViewedJobSeeker(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      viewedAt: json['viewed_at'] as String?,
    );
  }

  String get nameWithAge => '$employeeName($age세)';

  @override
  List<Object?> get props => [employeeId, employeeName, age, viewedAt];
}

class JobSeekerSummary extends Equatable {
  const JobSeekerSummary({
    required this.employeeId,
    required this.employeeName,
    required this.age,
    this.gender,
    this.desiredLocation,
    required this.averageRating,
    required this.reviewCount,
  });

  final int employeeId;
  final String employeeName;
  final int age;
  final String? gender;
  final String? desiredLocation;
  final double averageRating;
  final int reviewCount;

  factory JobSeekerSummary.fromJson(Map<String, dynamic> json) {
    return JobSeekerSummary(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String?,
      desiredLocation: json['desired_location'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    employeeName,
    age,
    gender,
    desiredLocation,
    averageRating,
    reviewCount,
  ];
}

class JobSeekerProfile extends Equatable {
  const JobSeekerProfile({
    this.employeeId,
    this.applicantUserId,
    this.sourceType,
    required this.employeeName,
    required this.age,
    this.gender,
    this.contactPhone,
    this.profileImageUrl,
    this.careerLabel,
    this.desiredLocations = const [],
    required this.averageRating,
    required this.reviewCount,
    this.workHistories = const [],
    this.contactActionLabel,
    this.resumeTitle,
  });

  final int? employeeId;
  final int? applicantUserId;
  final String? sourceType;
  final String employeeName;
  final int age;
  final String? gender;
  final String? contactPhone;
  final String? profileImageUrl;
  final String? careerLabel;
  final List<String> desiredLocations;
  final double averageRating;
  final int reviewCount;
  final List<JobSeekerWorkHistory> workHistories;
  final String? contactActionLabel;
  final String? resumeTitle;

  factory JobSeekerProfile.fromJson(Map<String, dynamic> json) {
    return JobSeekerProfile(
      employeeId: (json['employee_id'] as num?)?.toInt(),
      applicantUserId: (json['applicant_user_id'] as num?)?.toInt(),
      sourceType: json['source_type'] as String?,
      employeeName: json['employee_name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String?,
      contactPhone:
          json['contact_phone'] as String? ?? json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      careerLabel: json['career_label'] as String?,
      desiredLocations:
          (json['desired_locations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      workHistories:
          (json['work_histories'] as List<dynamic>?)
              ?.map(
                (e) => JobSeekerWorkHistory.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      contactActionLabel: json['contact_action_label'] as String?,
      resumeTitle: json['resume_title'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    applicantUserId,
    sourceType,
    employeeName,
    age,
    gender,
    contactPhone,
    profileImageUrl,
    careerLabel,
    desiredLocations,
    averageRating,
    reviewCount,
    workHistories,
    contactActionLabel,
    resumeTitle,
  ];
}

class JobSeekerWorkHistory extends Equatable {
  const JobSeekerWorkHistory({
    this.periodLabel,
    this.companyName,
    this.roleLabel,
  });

  final String? periodLabel;
  final String? companyName;
  final String? roleLabel;

  factory JobSeekerWorkHistory.fromJson(Map<String, dynamic> json) {
    return JobSeekerWorkHistory(
      periodLabel: json['period_label'] as String?,
      companyName: json['company_name'] as String?,
      roleLabel: json['role_label'] as String?,
    );
  }

  @override
  List<Object?> get props => [periodLabel, companyName, roleLabel];
}

class JobSeekerReviewPage extends Equatable {
  const JobSeekerReviewPage({
    required this.employeeId,
    required this.employeeName,
    this.desiredLocation,
    required this.averageRating,
    required this.reviewCount,
    this.items = const [],
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final int employeeId;
  final String employeeName;
  final String? desiredLocation;
  final double averageRating;
  final int reviewCount;
  final List<JobSeekerReview> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory JobSeekerReviewPage.fromJson(Map<String, dynamic> json) {
    return JobSeekerReviewPage(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      desiredLocation: json['desired_location'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => JobSeekerReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    employeeName,
    desiredLocation,
    averageRating,
    reviewCount,
    items,
    totalCount,
    page,
    pageSize,
  ];
}

class JobSeekerReview extends Equatable {
  const JobSeekerReview({
    required this.reviewId,
    required this.branchId,
    this.branchName,
    this.managerName,
    this.createdAt,
    required this.rating,
    required this.maxRating,
    this.comment,
  });

  final int reviewId;
  final int branchId;
  final String? branchName;
  final String? managerName;
  final String? createdAt;
  final int rating;
  final int maxRating;
  final String? comment;

  factory JobSeekerReview.fromJson(Map<String, dynamic> json) {
    return JobSeekerReview(
      reviewId: (json['review_id'] as num?)?.toInt() ?? 0,
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name'] as String?,
      managerName: json['manager_name'] as String?,
      createdAt: json['created_at'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      maxRating: (json['max_rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    reviewId,
    branchId,
    branchName,
    managerName,
    createdAt,
    rating,
    maxRating,
    comment,
  ];
}

class RecruitmentUploadResult extends Equatable {
  const RecruitmentUploadResult({
    required this.fileId,
    required this.fileUrl,
    this.contentType,
    this.size = 0,
  });

  final String fileId;
  final String fileUrl;
  final String? contentType;
  final int size;

  factory RecruitmentUploadResult.fromJson(Map<String, dynamic> json) {
    return RecruitmentUploadResult(
      fileId: json['file_id'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      contentType: json['content_type'] as String?,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [fileId, fileUrl, contentType, size];
}

class RecruitmentPostingPage extends Equatable {
  const RecruitmentPostingPage({
    this.items = const [],
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<RecruitmentPostingSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory RecruitmentPostingPage.fromJson(Map<String, dynamic> json) {
    return RecruitmentPostingPage(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => RecruitmentPostingSummary.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];
}

class RecruitmentPostingSummary extends Equatable {
  const RecruitmentPostingSummary({
    required this.postingId,
    this.badgeLabel,
    this.companyName,
    this.title,
    this.regionSummary,
    this.payType,
    this.payAmount = 0,
    this.applicantCount = 0,
    this.applicantsButtonLabel,
    this.status,
    this.createdAt,
  });

  final int postingId;
  final String? badgeLabel;
  final String? companyName;
  final String? title;
  final String? regionSummary;
  final String? payType;
  final int payAmount;
  final int applicantCount;
  final String? applicantsButtonLabel;
  final String? status;
  final String? createdAt;

  factory RecruitmentPostingSummary.fromJson(Map<String, dynamic> json) {
    return RecruitmentPostingSummary(
      postingId: (json['posting_id'] as num?)?.toInt() ?? 0,
      badgeLabel: json['badge_label'] as String?,
      companyName: json['company_name'] as String?,
      title: json['title'] as String?,
      regionSummary: json['region_summary'] as String?,
      payType: json['pay_type'] as String?,
      payAmount: (json['pay_amount'] as num?)?.toInt() ?? 0,
      applicantCount: (json['applicant_count'] as num?)?.toInt() ?? 0,
      applicantsButtonLabel: json['applicants_button_label'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isDraft => status == 'draft';

  @override
  List<Object?> get props => [
    postingId,
    badgeLabel,
    companyName,
    title,
    regionSummary,
    payType,
    payAmount,
    applicantCount,
    applicantsButtonLabel,
    status,
    createdAt,
  ];
}

class RecruitmentPostingDetail extends Equatable {
  const RecruitmentPostingDetail({
    required this.postingId,
    this.profileImageUrl,
    this.badgeLabel,
    this.companyName,
    this.title,
    this.regionSummary,
    this.regionPath,
    this.address,
    this.payType,
    this.payAmount = 0,
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
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int postingId;
  final String? profileImageUrl;
  final String? badgeLabel;
  final String? companyName;
  final String? title;
  final String? regionSummary;
  final String? regionPath;
  final String? address;
  final String? payType;
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
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  factory RecruitmentPostingDetail.fromJson(Map<String, dynamic> json) {
    return RecruitmentPostingDetail(
      postingId: (json['posting_id'] as num?)?.toInt() ?? 0,
      profileImageUrl: json['profile_image_url'] as String?,
      badgeLabel: json['badge_label'] as String?,
      companyName: json['company_name'] as String?,
      title: json['title'] as String?,
      regionSummary: json['region_summary'] as String?,
      regionPath: json['region_path'] as String?,
      address: json['address'] as String?,
      payType: json['pay_type'] as String?,
      payAmount: (json['pay_amount'] as num?)?.toInt() ?? 0,
      workPeriod: json['work_period'] as String?,
      workDays: json['work_days'] as String?,
      workDaysDetail: json['work_days_detail'] as String?,
      workTime: json['work_time'] as String?,
      workTimeDetail: json['work_time_detail'] as String?,
      jobCategory: json['job_category'] as String?,
      employmentType: json['employment_type'] as String?,
      recruitmentDeadline: json['recruitment_deadline'] as String?,
      recruitmentHeadcount: json['recruitment_headcount'] as String?,
      recruitmentHeadcountDetail:
          json['recruitment_headcount_detail'] as String?,
      education: json['education'] as String?,
      educationDetail: json['education_detail'] as String?,
      managerName: json['manager_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      legalWarningMessage: json['legal_warning_message'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  bool get isDraft => status == 'draft';

  @override
  List<Object?> get props => [
    postingId,
    profileImageUrl,
    badgeLabel,
    companyName,
    title,
    regionSummary,
    regionPath,
    address,
    payType,
    payAmount,
    workPeriod,
    workDays,
    workDaysDetail,
    workTime,
    workTimeDetail,
    jobCategory,
    employmentType,
    recruitmentDeadline,
    recruitmentHeadcount,
    recruitmentHeadcountDetail,
    education,
    educationDetail,
    managerName,
    contactPhone,
    legalWarningMessage,
    status,
    createdAt,
    updatedAt,
  ];
}

class RecruitmentPostingSaveResult extends Equatable {
  const RecruitmentPostingSaveResult({
    required this.postingId,
    this.status,
    this.createdAt,
    this.publishedAt,
  });

  final int postingId;
  final String? status;
  final String? createdAt;
  final String? publishedAt;

  factory RecruitmentPostingSaveResult.fromJson(Map<String, dynamic> json) {
    return RecruitmentPostingSaveResult(
      postingId: (json['posting_id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [postingId, status, createdAt, publishedAt];
}

class RecruitmentPostingRequest extends Equatable {
  const RecruitmentPostingRequest({
    this.profileImageUrl,
    required this.companyName,
    required this.title,
    required this.regionSummary,
    this.regionPath,
    required this.address,
    required this.payType,
    required this.payAmount,
    required this.workPeriod,
    required this.workDays,
    this.workDaysDetail,
    required this.workTime,
    this.workTimeDetail,
    required this.jobCategory,
    required this.employmentType,
    required this.recruitmentDeadline,
    required this.isAlwaysHiring,
    required this.recruitmentHeadcount,
    this.recruitmentHeadcountDetail,
    required this.education,
    this.educationDetail,
    required this.managerName,
    required this.contactPhone,
  });

  final String? profileImageUrl;
  final String companyName;
  final String title;
  final String regionSummary;
  final String? regionPath;
  final String address;
  final String payType;
  final int payAmount;
  final String workPeriod;
  final String workDays;
  final String? workDaysDetail;
  final String workTime;
  final String? workTimeDetail;
  final String jobCategory;
  final String employmentType;
  final String recruitmentDeadline;
  final bool isAlwaysHiring;
  final String recruitmentHeadcount;
  final String? recruitmentHeadcountDetail;
  final String education;
  final String? educationDetail;
  final String managerName;
  final String contactPhone;

  Map<String, dynamic> toJson() {
    return {
      'profile_image_url': profileImageUrl,
      'company_name': companyName,
      'title': title,
      'region_summary': regionSummary,
      'region_path': _nullableValue(regionPath),
      'address': address,
      'pay_type': payType,
      'pay_amount': payAmount,
      'work_period': workPeriod,
      'work_days': workDays,
      'work_days_detail': _nullableValue(workDaysDetail),
      'work_time': workTime,
      'work_time_detail': _nullableValue(workTimeDetail),
      'job_category': jobCategory,
      'employment_type': employmentType,
      'recruitment_deadline': recruitmentDeadline,
      'is_always_hiring': isAlwaysHiring,
      'recruitment_headcount': recruitmentHeadcount,
      'recruitment_headcount_detail': _nullableValue(
        recruitmentHeadcountDetail,
      ),
      'education': education,
      'education_detail': _nullableValue(educationDetail),
      'manager_name': managerName,
      'contact_phone': contactPhone,
    };
  }

  RecruitmentPostingRequest copyWith({
    String? profileImageUrl,
    String? companyName,
    String? title,
    String? regionSummary,
    String? regionPath,
    String? address,
    String? payType,
    int? payAmount,
    String? workPeriod,
    String? workDays,
    String? workDaysDetail,
    String? workTime,
    String? workTimeDetail,
    String? jobCategory,
    String? employmentType,
    String? recruitmentDeadline,
    bool? isAlwaysHiring,
    String? recruitmentHeadcount,
    String? recruitmentHeadcountDetail,
    String? education,
    String? educationDetail,
    String? managerName,
    String? contactPhone,
  }) {
    return RecruitmentPostingRequest(
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      regionSummary: regionSummary ?? this.regionSummary,
      regionPath: regionPath ?? this.regionPath,
      address: address ?? this.address,
      payType: payType ?? this.payType,
      payAmount: payAmount ?? this.payAmount,
      workPeriod: workPeriod ?? this.workPeriod,
      workDays: workDays ?? this.workDays,
      workDaysDetail: workDaysDetail ?? this.workDaysDetail,
      workTime: workTime ?? this.workTime,
      workTimeDetail: workTimeDetail ?? this.workTimeDetail,
      jobCategory: jobCategory ?? this.jobCategory,
      employmentType: employmentType ?? this.employmentType,
      recruitmentDeadline: recruitmentDeadline ?? this.recruitmentDeadline,
      isAlwaysHiring: isAlwaysHiring ?? this.isAlwaysHiring,
      recruitmentHeadcount: recruitmentHeadcount ?? this.recruitmentHeadcount,
      recruitmentHeadcountDetail:
          recruitmentHeadcountDetail ?? this.recruitmentHeadcountDetail,
      education: education ?? this.education,
      educationDetail: educationDetail ?? this.educationDetail,
      managerName: managerName ?? this.managerName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  @override
  List<Object?> get props => [
    profileImageUrl,
    companyName,
    title,
    regionSummary,
    regionPath,
    address,
    payType,
    payAmount,
    workPeriod,
    workDays,
    workDaysDetail,
    workTime,
    workTimeDetail,
    jobCategory,
    employmentType,
    recruitmentDeadline,
    isAlwaysHiring,
    recruitmentHeadcount,
    recruitmentHeadcountDetail,
    education,
    educationDetail,
    managerName,
    contactPhone,
  ];
}

String? _nullableValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class RecruitmentApplicationPage extends Equatable {
  const RecruitmentApplicationPage({
    required this.postingId,
    this.badgeLabel,
    this.companyName,
    this.title,
    this.items = const [],
    required this.totalCount,
  });

  final int postingId;
  final String? badgeLabel;
  final String? companyName;
  final String? title;
  final List<RecruitmentApplicationSummary> items;
  final int totalCount;

  factory RecruitmentApplicationPage.fromJson(Map<String, dynamic> json) {
    return RecruitmentApplicationPage(
      postingId: (json['posting_id'] as num?)?.toInt() ?? 0,
      badgeLabel: json['badge_label'] as String?,
      companyName: json['company_name'] as String?,
      title: json['title'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => RecruitmentApplicationSummary.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    postingId,
    badgeLabel,
    companyName,
    title,
    items,
    totalCount,
  ];
}

class RecruitmentApplicationSummary extends Equatable {
  const RecruitmentApplicationSummary({
    required this.applicationId,
    this.appliedDateLabel,
    this.employeeId,
    this.applicantUserId,
    this.applicationSource,
    required this.employeeName,
    this.desiredLocation,
    required this.averageRating,
    required this.reviewCount,
    this.resumeTitle,
  });

  final int applicationId;
  final String? appliedDateLabel;
  final int? employeeId;
  final int? applicantUserId;
  final String? applicationSource;
  final String employeeName;
  final String? desiredLocation;
  final double averageRating;
  final int reviewCount;
  final String? resumeTitle;

  factory RecruitmentApplicationSummary.fromJson(Map<String, dynamic> json) {
    return RecruitmentApplicationSummary(
      applicationId: (json['application_id'] as num?)?.toInt() ?? 0,
      appliedDateLabel: json['applied_date_label'] as String?,
      employeeId: (json['employee_id'] as num?)?.toInt(),
      applicantUserId: (json['applicant_user_id'] as num?)?.toInt(),
      applicationSource: json['application_source'] as String?,
      employeeName: json['employee_name'] as String? ?? '',
      desiredLocation: json['desired_location'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      resumeTitle: json['resume_title'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    applicationId,
    appliedDateLabel,
    employeeId,
    applicantUserId,
    applicationSource,
    employeeName,
    desiredLocation,
    averageRating,
    reviewCount,
    resumeTitle,
  ];
}

/// `POST .../job-seekers/{id}/contact` 응답
class RecruitmentContactResult extends Equatable {
  const RecruitmentContactResult({
    required this.requested,
    this.inquiryId,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    this.message,
  });

  final bool requested;
  final int? inquiryId;
  final int branchId;
  final int employeeId;
  final String employeeName;
  final String? message;

  factory RecruitmentContactResult.fromJson(Map<String, dynamic> json) {
    return RecruitmentContactResult(
      requested: json['requested'] == true,
      inquiryId: (json['inquiry_id'] as num?)?.toInt(),
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    requested,
    inquiryId,
    branchId,
    employeeId,
    employeeName,
    message,
  ];
}

class RecruitmentChatPage extends Equatable {
  const RecruitmentChatPage({this.items = const [], required this.totalCount});

  final List<RecruitmentChatSummary> items;
  final int totalCount;

  factory RecruitmentChatPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return RecruitmentChatPage(
      items: items
          .whereType<Map>()
          .map(
            (item) => RecruitmentChatSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  List<Object?> get props => [items, totalCount];
}

class RecruitmentChatSummary extends Equatable {
  const RecruitmentChatSummary({
    required this.chatId,
    required this.branchId,
    required this.employeeId,
    this.branchName,
    required this.counterpartyName,
    this.counterpartyRole,
    this.counterpartyProfileImageUrl,
    this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.createdAt,
  });

  final int chatId;
  final int branchId;
  final int employeeId;
  final String? branchName;
  final String counterpartyName;
  final String? counterpartyRole;
  final String? counterpartyProfileImageUrl;
  final String? status;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final String? createdAt;

  factory RecruitmentChatSummary.fromJson(Map<String, dynamic> json) {
    return RecruitmentChatSummary(
      chatId: (json['chat_id'] as num?)?.toInt() ?? 0,
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name'] as String?,
      counterpartyName:
          json['counterparty_name'] as String? ??
          json['employee_name'] as String? ??
          '',
      counterpartyRole: json['counterparty_role'] as String?,
      counterpartyProfileImageUrl:
          json['counterparty_profile_image_url'] as String?,
      status: json['status'] as String?,
      lastMessage:
          json['last_message'] as String? ??
          json['last_message_preview'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  RecruitmentChatSummary copyWith({
    int? chatId,
    int? branchId,
    int? employeeId,
    String? branchName,
    String? counterpartyName,
    String? counterpartyRole,
    String? counterpartyProfileImageUrl,
    String? status,
    String? lastMessage,
    String? lastMessageAt,
    int? unreadCount,
    String? createdAt,
  }) {
    return RecruitmentChatSummary(
      chatId: chatId ?? this.chatId,
      branchId: branchId ?? this.branchId,
      employeeId: employeeId ?? this.employeeId,
      branchName: branchName ?? this.branchName,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      counterpartyRole: counterpartyRole ?? this.counterpartyRole,
      counterpartyProfileImageUrl:
          counterpartyProfileImageUrl ?? this.counterpartyProfileImageUrl,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    chatId,
    branchId,
    employeeId,
    branchName,
    counterpartyName,
    counterpartyRole,
    counterpartyProfileImageUrl,
    status,
    lastMessage,
    lastMessageAt,
    unreadCount,
    createdAt,
  ];
}

class RecruitmentChatMessagePage extends Equatable {
  const RecruitmentChatMessagePage({
    required this.chat,
    required this.currentUserRole,
    this.messages = const [],
  });

  final RecruitmentChatSummary chat;
  final String currentUserRole;
  final List<RecruitmentChatMessage> messages;

  factory RecruitmentChatMessagePage.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return RecruitmentChatMessagePage(
      chat: RecruitmentChatSummary.fromJson(
        Map<String, dynamic>.from(json['chat'] as Map? ?? const {}),
      ),
      currentUserRole: json['current_user_role'] as String? ?? 'business',
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) => RecruitmentChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [chat, currentUserRole, messages];
}

class RecruitmentChatMessage extends Equatable {
  const RecruitmentChatMessage({
    required this.messageId,
    this.senderRole,
    this.senderName,
    this.senderProfileImageUrl,
    required this.messageType,
    required this.text,
    this.createdAt,
    this.contractId,
    this.documentStatus,
    this.canOpenDocument = false,
    this.openDocumentPath,
  });

  final String messageId;
  final String? senderRole;
  final String? senderName;
  final String? senderProfileImageUrl;
  final String messageType;
  final String text;
  final String? createdAt;
  final int? contractId;
  final String? documentStatus;
  final bool canOpenDocument;
  final String? openDocumentPath;

  factory RecruitmentChatMessage.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map?)?.cast<String, dynamic>();
    final document = (json['document'] as Map?)?.cast<String, dynamic>();
    final source = <String, dynamic>{...?metadata, ...?document, ...json};
    final type =
        source['message_type']?.toString() ??
        source['type']?.toString() ??
        'text';
    return RecruitmentChatMessage(
      messageId: source['message_id']?.toString() ?? '',
      senderRole: source['sender_role'] as String?,
      senderName: source['sender_name'] as String?,
      senderProfileImageUrl: source['sender_profile_image_url'] as String?,
      messageType: type,
      text: source['text'] as String? ?? '',
      createdAt: source['created_at'] as String?,
      contractId: _intValue(
        source['contract_id'] ??
            source['employment_contract_id'] ??
            source['document_id'],
      ),
      documentStatus: source['document_status'] as String?,
      canOpenDocument:
          source['can_open_document'] == true ||
          source['open_document_path'] != null ||
          source['contract_id'] != null ||
          source['employment_contract_id'] != null,
      openDocumentPath:
          source['open_document_path'] as String? ??
          source['document_path'] as String?,
    );
  }

  bool get isDocument {
    final normalized = messageType.toLowerCase();
    return normalized == 'document' ||
        normalized == 'contract' ||
        normalized == 'contract_document';
  }

  @override
  List<Object?> get props => [
    messageId,
    senderRole,
    senderName,
    senderProfileImageUrl,
    messageType,
    text,
    createdAt,
    contractId,
    documentStatus,
    canOpenDocument,
    openDocumentPath,
  ];
}
