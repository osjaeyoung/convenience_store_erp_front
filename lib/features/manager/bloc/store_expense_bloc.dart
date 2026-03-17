import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/store_expense/store_expense_dashboard.dart';
import '../../../data/repositories/store_expense_repository.dart';

part 'store_expense_event.dart';
part 'store_expense_state.dart';

class StoreExpenseBloc extends Bloc<StoreExpenseBlocEvent, StoreExpenseBlocState> {
  StoreExpenseBloc(this._repository) : super(const StoreExpenseBlocState.initial()) {
    on<StoreExpenseDashboardRequested>(_onDashboardRequested);
  }

  final StoreExpenseRepository _repository;

  Future<void> _onDashboardRequested(
    StoreExpenseDashboardRequested event,
    Emitter<StoreExpenseBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const StoreExpenseBlocState.loading());
    try {
      final data = await _repository.getDashboard(
        branchId: event.branchId!,
        year: event.year,
        month: event.month,
        baseDay: event.baseDay,
      );
      emit(StoreExpenseBlocState.dashboardLoaded(data));
    } catch (e) {
      emit(StoreExpenseBlocState.failure(e.toString()));
    }
  }
}
