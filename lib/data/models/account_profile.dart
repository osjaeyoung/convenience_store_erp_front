/// `GET/PATCH /me/account` 응답 (계정·설정 UI)
class AccountSettingsLinks {
  const AccountSettingsLinks({
    this.supportUrl,
    this.noticesUrl,
    this.policyUrl,
  });

  final String? supportUrl;
  final String? noticesUrl;
  final String? policyUrl;

  factory AccountSettingsLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AccountSettingsLinks();
    String? s(dynamic v) {
      final t = v?.toString().trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return AccountSettingsLinks(
      supportUrl: s(json['support_url']),
      noticesUrl: s(json['notices_url']),
      policyUrl: s(json['policy_url']),
    );
  }
}

class AccountProfile {
  const AccountProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.phoneNumberMasked,
    this.birthDate,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.gender,
    this.address,
    required this.role,
    required this.roleLabelKo,
    required this.usageTypeLabelKo,
    this.approvalStatus,
    this.approvalStatusLabelKo,
    this.signupStep,
    this.signupStep1Passed,
    this.signupStep2Passed,
    this.isActive,
    this.memberSince,
    this.settingsLinks = const AccountSettingsLinks(),
    this.hasPasswordLogin = true,
    this.sessionRefreshRequired = false,
  });

  final int userId;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? phoneNumberMasked;
  final String? birthDate;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? gender;
  final String? address;
  final String role;
  final String roleLabelKo;
  final String usageTypeLabelKo;
  final String? approvalStatus;
  final String? approvalStatusLabelKo;
  final String? signupStep;
  final bool? signupStep1Passed;
  final bool? signupStep2Passed;
  final bool? isActive;
  final String? memberSince;
  final AccountSettingsLinks settingsLinks;
  final bool hasPasswordLogin;
  final bool sessionRefreshRequired;

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      phoneNumberMasked: json['phone_number_masked']?.toString(),
      birthDate: json['birth_date']?.toString(),
      birthYear: (json['birth_year'] as num?)?.toInt(),
      birthMonth: (json['birth_month'] as num?)?.toInt(),
      birthDay: (json['birth_day'] as num?)?.toInt(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString() ?? '',
      roleLabelKo: json['role_label_ko']?.toString() ?? '',
      usageTypeLabelKo: json['usage_type_label_ko']?.toString() ?? '',
      approvalStatus: json['approval_status']?.toString(),
      approvalStatusLabelKo: json['approval_status_label_ko']?.toString(),
      signupStep: json['signup_step']?.toString(),
      signupStep1Passed: json['signup_step1_passed'] as bool?,
      signupStep2Passed: json['signup_step2_passed'] as bool?,
      isActive: json['is_active'] as bool?,
      memberSince: json['member_since']?.toString(),
      settingsLinks: AccountSettingsLinks.fromJson(
        json['settings_links'] as Map<String, dynamic>?,
      ),
      hasPasswordLogin: json['has_password_login'] as bool? ?? true,
      sessionRefreshRequired:
          json['session_refresh_required'] as bool? ?? false,
    );
  }
}
