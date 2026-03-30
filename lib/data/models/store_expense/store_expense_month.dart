class StoreExpenseMonthSummary {
  const StoreExpenseMonthSummary({
    required this.expenseMonthId,
    required this.year,
    required this.month,
    required this.periodLabel,
    required this.totalAmount,
    required this.itemCount,
    this.createdAt,
    this.updatedAt,
  });

  final int expenseMonthId;
  final int year;
  final int month;
  final String periodLabel;
  final int totalAmount;
  final int itemCount;
  final String? createdAt;
  final String? updatedAt;

  factory StoreExpenseMonthSummary.fromJson(Map<String, dynamic> json) {
    return StoreExpenseMonthSummary(
      expenseMonthId: (json['expense_month_id'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      periodLabel: (json['period_label'] as String?) ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class StoreExpenseCreateStep1Result {
  const StoreExpenseCreateStep1Result({
    required this.expenseMonthId,
    required this.year,
    required this.month,
    required this.periodLabel,
    required this.isNewMonthCreated,
  });

  final int expenseMonthId;
  final int year;
  final int month;
  final String periodLabel;
  final bool isNewMonthCreated;

  factory StoreExpenseCreateStep1Result.fromJson(Map<String, dynamic> json) {
    return StoreExpenseCreateStep1Result(
      expenseMonthId: (json['expense_month_id'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      periodLabel: (json['period_label'] as String?) ?? '',
      isNewMonthCreated: (json['is_new_month_created'] as bool?) ?? false,
    );
  }
}

class StoreExpenseMonthDetail {
  const StoreExpenseMonthDetail({
    required this.expenseMonthId,
    required this.year,
    required this.month,
    required this.periodLabel,
    required this.totalAmount,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int expenseMonthId;
  final int year;
  final int month;
  final String periodLabel;
  final int totalAmount;
  final List<StoreExpenseItem> items;
  final String? createdAt;
  final String? updatedAt;

  factory StoreExpenseMonthDetail.fromJson(Map<String, dynamic> json) {
    return StoreExpenseMonthDetail(
      expenseMonthId: (json['expense_month_id'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      periodLabel: (json['period_label'] as String?) ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => StoreExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class StoreExpenseItem {
  const StoreExpenseItem({
    required this.expenseItemId,
    required this.expenseDate,
    required this.categoryCode,
    required this.categoryLabel,
    required this.amount,
    this.memo,
    this.files = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int expenseItemId;
  final String expenseDate;
  final String categoryCode;
  final String categoryLabel;
  final int amount;
  final String? memo;
  final List<StoreExpenseFile> files;
  final String? createdAt;
  final String? updatedAt;

  factory StoreExpenseItem.fromJson(Map<String, dynamic> json) {
    return StoreExpenseItem(
      expenseItemId: (json['expense_item_id'] as num).toInt(),
      expenseDate: (json['expense_date'] as String?) ?? '',
      categoryCode: (json['category_code'] as String?) ?? '',
      categoryLabel: (json['category_label'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      memo: json['memo'] as String?,
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => StoreExpenseFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class StoreExpenseFile {
  const StoreExpenseFile({
    required this.fileId,
    required this.fileKey,
    required this.fileUrl,
    required this.fileName,
    this.createdAt,
  });

  final int fileId;
  final String fileKey;
  final String fileUrl;
  final String fileName;
  final String? createdAt;

  factory StoreExpenseFile.fromJson(Map<String, dynamic> json) {
    return StoreExpenseFile(
      fileId: (json['file_id'] as num).toInt(),
      fileKey: (json['file_key'] as String?) ?? '',
      fileUrl: (json['file_url'] as String?) ?? '',
      fileName: (json['file_name'] as String?) ?? '',
      createdAt: json['created_at'] as String?,
    );
  }
}

class StoreExpenseFileDraft {
  const StoreExpenseFileDraft({
    required this.fileKey,
    required this.fileUrl,
    required this.fileName,
  });

  final String fileKey;
  final String fileUrl;
  final String fileName;

  Map<String, dynamic> toJson() {
    return {
      'file_key': fileKey,
      'file_url': fileUrl,
      'file_name': fileName,
    };
  }
}

class StoreExpenseCategory {
  const StoreExpenseCategory({
    required this.categoryCode,
    required this.categoryLabel,
    this.colorHex,
    required this.isActive,
  });

  final String categoryCode;
  final String categoryLabel;
  final String? colorHex;
  final bool isActive;

  factory StoreExpenseCategory.fromJson(Map<String, dynamic> json) {
    return StoreExpenseCategory(
      categoryCode: (json['category_code'] as String?) ?? '',
      categoryLabel: (json['category_label'] as String?) ?? '',
      colorHex: json['color_hex'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

