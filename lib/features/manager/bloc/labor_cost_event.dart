part of 'labor_cost_bloc.dart';

abstract class LaborCostBlocEvent extends Equatable {
  const LaborCostBlocEvent();

  @override
  List<Object?> get props => [];
}

class LaborCostExpectedRequested extends LaborCostBlocEvent {
  const LaborCostExpectedRequested({
    this.branchId,
    this.rangeType = 'this_month',
  });

  final int? branchId;
  final String rangeType;

  @override
  List<Object?> get props => [branchId, rangeType];
}

class LaborCostMonthlyDetailRequested extends LaborCostBlocEvent {
  const LaborCostMonthlyDetailRequested({
    this.branchId,
    required this.year,
    required this.month,
  });

  final int? branchId;
  final int year;
  final int month;

  @override
  List<Object?> get props => [branchId, year, month];
}

class LaborCostSavingDetailRequested extends LaborCostBlocEvent {
  const LaborCostSavingDetailRequested({
    this.branchId,
    required this.year,
    required this.month,
  });

  final int? branchId;
  final int year;
  final int month;

  @override
  List<Object?> get props => [branchId, year, month];
}
