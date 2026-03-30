/// 월간 표시 대시보드 조회 응답
class StoreExpenseDashboard {
  const StoreExpenseDashboard({
    required this.branchId,
    required this.year,
    required this.month,
    required this.baseDay,
    required this.asOfDate,
    required this.currentMonthToDateTotal,
    required this.previousMonthToDateTotal,
    required this.changeRatePercent,
    required this.monthlyTotalCost,
    this.categoryCards = const [],
    this.calendarExpenses = const [],
  });

  final int branchId;
  final int year;
  final int month;
  final int baseDay;
  final String asOfDate;
  final int currentMonthToDateTotal;
  final int previousMonthToDateTotal;
  final double changeRatePercent;
  final int monthlyTotalCost;
  final List<CategoryCard> categoryCards;
  final List<CalendarExpense> calendarExpenses;

  factory StoreExpenseDashboard.fromJson(Map<String, dynamic> json) {
    return StoreExpenseDashboard(
      branchId: json['branch_id'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      baseDay: json['base_day'] as int,
      asOfDate: json['as_of_date'] as String,
      currentMonthToDateTotal: json['current_month_to_date_total'] as int,
      previousMonthToDateTotal: json['previous_month_to_date_total'] as int,
      changeRatePercent:
          (json['change_rate_percent'] as num).toDouble(),
      monthlyTotalCost: json['monthly_total_cost'] as int,
      categoryCards: (json['category_cards'] as List<dynamic>?)
              ?.map((e) => CategoryCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calendarExpenses: (json['calendar_expenses'] as List<dynamic>?)
              ?.map((e) =>
                  CalendarExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CategoryCard {
  const CategoryCard({
    required this.categoryCode,
    required this.categoryLabel,
    required this.monthAmount,
    required this.transactionCount,
    this.summaryLabel,
  });

  final String categoryCode;
  final String categoryLabel;
  final int monthAmount;
  final int transactionCount;
  final String? summaryLabel;

  factory CategoryCard.fromJson(Map<String, dynamic> json) {
    return CategoryCard(
      categoryCode: json['category_code'] as String,
      categoryLabel: json['category_label'] as String,
      monthAmount: json['month_amount'] as int,
      transactionCount: json['transaction_count'] as int,
      summaryLabel: json['summary_label'] as String?,
    );
  }
}

class CalendarExpense {
  const CalendarExpense({
    required this.date,
    required this.items,
    required this.dayTotalAmount,
  });

  final String date;
  final List<ExpenseItem> items;
  final int dayTotalAmount;

  factory CalendarExpense.fromJson(Map<String, dynamic> json) {
    return CalendarExpense(
      date: json['date'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dayTotalAmount: json['day_total_amount'] as int,
    );
  }
}

class ExpenseItem {
  const ExpenseItem({
    required this.expenseItemId,
    required this.categoryCode,
    required this.categoryLabel,
    required this.amount,
  });

  final int expenseItemId;
  final String categoryCode;
  final String categoryLabel;
  final int amount;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      expenseItemId: json['expense_item_id'] as int,
      categoryCode: json['category_code'] as String,
      categoryLabel: json['category_label'] as String,
      amount: json['amount'] as int,
    );
  }
}
