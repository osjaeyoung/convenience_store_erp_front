import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import '../../../data/models/labor_cost/expected_labor_cost.dart';
import '../../../data/models/labor_cost/monthly_detail.dart';
import '../../../data/models/labor_cost/saving_detail.dart';
import '../../../data/repositories/labor_cost_repository.dart';

part 'labor_cost_event.dart';
part 'labor_cost_state.dart';

class LaborCostBloc extends Bloc<LaborCostBlocEvent, LaborCostBlocState> {
  LaborCostBloc(this._repository) : super(const LaborCostBlocState.initial()) {
    on<LaborCostExpectedRequested>(_onExpectedRequested);
    on<LaborCostMonthlyDetailRequested>(_onMonthlyDetailRequested);
    on<LaborCostSavingDetailRequested>(_onSavingDetailRequested);
  }

  final LaborCostRepository _repository;

  Future<void> _onExpectedRequested(
    LaborCostExpectedRequested event,
    Emitter<LaborCostBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const LaborCostBlocState.loading());
    try {
      final data = await _repository.getExpected(
        branchId: event.branchId!,
        rangeType: event.rangeType,
      );
      emit(LaborCostBlocState.expectedLoaded(data));
    } catch (e) {
      emit(LaborCostBlocState.failure(userFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onMonthlyDetailRequested(
    LaborCostMonthlyDetailRequested event,
    Emitter<LaborCostBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const LaborCostBlocState.loading());
    try {
      final data = await _repository.getMonthlyDetail(
        branchId: event.branchId!,
        year: event.year,
        month: event.month,
      );
      emit(LaborCostBlocState.monthlyDetailLoaded(data));
    } catch (e) {
      emit(LaborCostBlocState.failure(userFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onSavingDetailRequested(
    LaborCostSavingDetailRequested event,
    Emitter<LaborCostBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const LaborCostBlocState.loading());
    try {
      final data = await _repository.getSavingDetail(
        branchId: event.branchId!,
        year: event.year,
        month: event.month,
      );
      emit(LaborCostBlocState.savingDetailLoaded(data));
    } catch (e) {
      emit(LaborCostBlocState.failure(userFriendlyErrorMessage(e)));
    }
  }
}
