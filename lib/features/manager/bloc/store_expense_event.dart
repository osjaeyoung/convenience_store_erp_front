part of 'store_expense_bloc.dart';

abstract class StoreExpenseBlocEvent extends Equatable {
  const StoreExpenseBlocEvent();

  @override
  List<Object?> get props => [];
}

class StoreExpenseDashboardRequested extends StoreExpenseBlocEvent {
  const StoreExpenseDashboardRequested({
    this.branchId,
    required this.year,
    required this.month,
    this.baseDay,
  });

  final int? branchId;
  final int year;
  final int month;
  final int? baseDay;

  @override
  List<Object?> get props => [branchId, year, month, baseDay];
}
