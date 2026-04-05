class PhoneNumberExistsResult {
  const PhoneNumberExistsResult({
    required this.phoneNumber,
    required this.exists,
    required this.hasPasswordLogin,
  });

  final String phoneNumber;
  final bool exists;
  final bool hasPasswordLogin;

  factory PhoneNumberExistsResult.fromJson(Map<String, dynamic> json) {
    return PhoneNumberExistsResult(
      phoneNumber: json['phone_number']?.toString() ?? '',
      exists: json['exists'] == true,
      hasPasswordLogin: json['has_password_login'] == true,
    );
  }
}

class AccountNotice {
  const AccountNotice({
    required this.noticeId,
    required this.title,
    required this.content,
    this.publishedAt,
  });

  final int noticeId;
  final String title;
  final String content;
  final String? publishedAt;

  factory AccountNotice.fromJson(Map<String, dynamic> json) {
    return AccountNotice(
      noticeId: (json['notice_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      publishedAt: json['published_at']?.toString(),
    );
  }
}

class AccountNoticePage {
  const AccountNoticePage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<AccountNotice> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory AccountNoticePage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return AccountNoticePage(
      items: rawItems
          .map((item) => AccountNotice.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? rawItems.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }
}

class AccountInquiry {
  const AccountInquiry({
    required this.inquiryId,
    required this.inquiryType,
    required this.title,
    required this.content,
    this.createdAt,
    required this.isAnswered,
    required this.isAnswerChecked,
    this.answer,
    this.answeredAt,
  });

  final int inquiryId;
  final String inquiryType;
  final String title;
  final String content;
  final String? createdAt;
  final bool isAnswered;
  final bool isAnswerChecked;
  final String? answer;
  final String? answeredAt;

  factory AccountInquiry.fromJson(Map<String, dynamic> json) {
    return AccountInquiry(
      inquiryId: (json['inquiry_id'] as num?)?.toInt() ?? 0,
      inquiryType: json['inquiry_type']?.toString() ?? 'etc',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      isAnswered: json['is_answered'] == true,
      isAnswerChecked: json['is_answer_checked'] == true,
      answer: json['answer']?.toString(),
      answeredAt: json['answered_at']?.toString(),
    );
  }
}

class AccountInquiryPage {
  const AccountInquiryPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<AccountInquiry> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory AccountInquiryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return AccountInquiryPage(
      items: rawItems
          .map((item) => AccountInquiry.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? rawItems.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }
}

class PasswordResetByPhoneResult {
  const PasswordResetByPhoneResult({
    required this.reset,
    required this.message,
    required this.hasPasswordLogin,
  });

  final bool reset;
  final String message;
  final bool hasPasswordLogin;

  factory PasswordResetByPhoneResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetByPhoneResult(
      reset: json['reset'] == true,
      message: json['message']?.toString() ?? '',
      hasPasswordLogin: json['has_password_login'] == true,
    );
  }
}
