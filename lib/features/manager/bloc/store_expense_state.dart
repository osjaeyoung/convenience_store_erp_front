part of 'store_expense_bloc.dart';

enum StoreExpenseBlocStatus { initial, loading, success, failure }

class StoreExpenseBlocState extends Equatable {
  const StoreExpenseBlocState._({
    required this.status,
    this.dashboard,
    this.errorMessage,
  });

  const StoreExpenseBlocState.initial()
      : this._(status: StoreExpenseBlocStatus.initial);

  const StoreExpenseBlocState.loading()
      : this._(status: StoreExpenseBlocStatus.loading);

  StoreExpenseBlocState.dashboardLoaded(StoreExpenseDashboard data)
      : this._(status: StoreExpenseBlocStatus.success, dashboard: data);

  const StoreExpenseBlocState.failure(String message)
      : this._(status: StoreExpenseBlocStatus.failure, errorMessage: message);

  final StoreExpenseBlocStatus status;
  final StoreExpenseDashboard? dashboard;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, dashboard, errorMessage];
}
