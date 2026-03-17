import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/staff_management_repository.dart';

part 'staff_management_event.dart';
part 'staff_management_state.dart';

class StaffManagementBloc
    extends Bloc<StaffManagementBlocEvent, StaffManagementBlocState> {
  StaffManagementBloc(this._repository)
      : super(const StaffManagementBlocState.initial()) {
    on<StaffManagementDayScheduleRequested>(_onDayScheduleRequested);
    on<StaffManagementWeekScheduleRequested>(_onWeekScheduleRequested);
    on<StaffManagementEmployeesCompareRequested>(_onEmployeesCompareRequested);
  }

  final StaffManagementRepository _repository;

  Future<void> _onDayScheduleRequested(
    StaffManagementDayScheduleRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const StaffManagementBlocState.loading());
    try {
      final data = await _repository.getDaySchedule(
        branchId: event.branchId!,
        date: event.date,
      );
      emit(StaffManagementBlocState.dayScheduleLoaded(data));
    } catch (e) {
      emit(StaffManagementBlocState.failure(e.toString()));
    }
  }

  Future<void> _onWeekScheduleRequested(
    StaffManagementWeekScheduleRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const StaffManagementBlocState.loading());
    try {
      final data = await _repository.getWeekSchedule(
        branchId: event.branchId!,
        weekStartDate: event.weekStartDate,
      );
      emit(StaffManagementBlocState.weekScheduleLoaded(data));
    } catch (e) {
      emit(StaffManagementBlocState.failure(e.toString()));
    }
  }

  Future<void> _onEmployeesCompareRequested(
    StaffManagementEmployeesCompareRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const StaffManagementBlocState.loading());
    try {
      final data = await _repository.getEmployeesCompare(
        branchId: event.branchId!,
        q: event.q,
      );
      emit(StaffManagementBlocState.employeesCompareLoaded(data));
    } catch (e) {
      emit(StaffManagementBlocState.failure(e.toString()));
    }
  }
}
