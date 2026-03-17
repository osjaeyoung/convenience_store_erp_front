import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/manager_home_repository.dart';
import '../../../data/repositories/owner_home_repository.dart';
import '../../../data/repositories/staff_management_repository.dart';

part 'staff_management_event.dart';
part 'staff_management_state.dart';

class StaffManagementBloc
    extends Bloc<StaffManagementBlocEvent, StaffManagementBlocState> {
  StaffManagementBloc(
    this._repository,
    this._managerHomeRepository,
    this._ownerHomeRepository, {
    required this.isOwner,
  }) : super(const StaffManagementBlocState.initial()) {
    on<StaffManagementInitialized>(_onInitialized);
    on<StaffManagementDayScheduleRequested>(_onDayScheduleRequested);
    on<StaffManagementWeekScheduleRequested>(_onWeekScheduleRequested);
    on<StaffManagementEmployeesCompareRequested>(_onEmployeesCompareRequested);
    on<StaffManagementEmployeeDetailRequested>(_onEmployeeDetailRequested);
    on<StaffManagementEmploymentContractsRequested>(
      _onEmploymentContractsRequested,
    );
    on<StaffManagementReviewCreated>(_onReviewCreated);
    on<StaffManagementReviewDeleted>(_onReviewDeleted);
    on<StaffManagementWorkerStatusSaveRequested>(
      _onWorkerStatusSaveRequested,
    );
    on<StaffManagementDaySchedulePutRequested>(_onDaySchedulePutRequested);
    on<StaffManagementWeekSchedulePutRequested>(_onWeekSchedulePutRequested);
  }

  final StaffManagementRepository _repository;
  final ManagerHomeRepository _managerHomeRepository;
  final OwnerHomeRepository _ownerHomeRepository;
  final bool isOwner;

  Future<void> _onInitialized(
    StaffManagementInitialized event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        clearError: true,
      ),
    );
    await Future.wait([
      _loadDaySchedule(
        emit,
        branchId: event.branchId,
        date: event.date,
        showLoading: false,
      ),
      _loadEmployeesCompare(
        emit,
        branchId: event.branchId,
        q: null,
        showLoading: false,
      ),
    ]);
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.success,
        isLoading: false,
      ),
    );
  }

  Future<void> _onDayScheduleRequested(
    StaffManagementDayScheduleRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    await _loadDaySchedule(
      emit,
      branchId: event.branchId,
      date: event.date,
      showLoading: true,
    );
  }

  Future<void> _onWeekScheduleRequested(
    StaffManagementWeekScheduleRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        clearError: true,
      ),
    );
    try {
      final data = await _repository.getWeekSchedule(
        branchId: event.branchId!,
        weekStartDate: event.weekStartDate,
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          weekSchedule: data,
          weekStartDate: event.weekStartDate,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onEmployeesCompareRequested(
    StaffManagementEmployeesCompareRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    await _loadEmployeesCompare(
      emit,
      branchId: event.branchId,
      q: event.q,
      showLoading: true,
    );
  }

  Future<void> _onEmployeeDetailRequested(
    StaffManagementEmployeeDetailRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        selectedEmployeeId: event.employeeId,
        clearError: true,
      ),
    );
    try {
      final data = await _repository.getEmployeeDetail(
        branchId: event.branchId!,
        employeeId: event.employeeId,
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          employeeDetail: data,
          selectedEmployeeId: event.employeeId,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onEmploymentContractsRequested(
    StaffManagementEmploymentContractsRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        selectedEmployeeId: event.employeeId,
        clearError: true,
      ),
    );
    try {
      final data = await _repository.getEmploymentContracts(
        branchId: event.branchId!,
        employeeId: event.employeeId,
        status: event.status,
        templateVersion: event.templateVersion,
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          employmentContracts: data,
          selectedEmployeeId: event.employeeId,
          contractStatusFilter: event.status,
          contractTemplateFilter: event.templateVersion,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onReviewCreated(
    StaffManagementReviewCreated event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    try {
      await _repository.createReview(
        branchId: event.branchId!,
        employeeId: event.employeeId,
        rating: event.rating,
        comment: event.comment,
      );
      add(
        StaffManagementEmployeeDetailRequested(
          branchId: event.branchId,
          employeeId: event.employeeId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onReviewDeleted(
    StaffManagementReviewDeleted event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    try {
      await _repository.deleteReview(
        branchId: event.branchId!,
        employeeId: event.employeeId,
        reviewId: event.reviewId,
      );
      add(
        StaffManagementEmployeeDetailRequested(
          branchId: event.branchId,
          employeeId: event.employeeId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onDaySchedulePutRequested(
    StaffManagementDaySchedulePutRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        clearError: true,
      ),
    );
    try {
      await _repository.putDaySchedule(
        branchId: event.branchId,
        data: {
          'work_date': event.workDate,
          'slots': event.slots,
        },
      );
      add(
        StaffManagementDayScheduleRequested(
          branchId: event.branchId,
          date: event.workDate,
        ),
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onWeekSchedulePutRequested(
    StaffManagementWeekSchedulePutRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StaffManagementBlocStatus.loading,
        isLoading: true,
        clearError: true,
      ),
    );
    try {
      await _repository.putWeekSchedule(
        branchId: event.branchId,
        data: {
          'week_start_date': event.weekStartDate,
          'days': event.days,
        },
      );
      add(
        StaffManagementWeekScheduleRequested(
          branchId: event.branchId,
          weekStartDate: event.weekStartDate,
        ),
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onWorkerStatusSaveRequested(
    StaffManagementWorkerStatusSaveRequested event,
    Emitter<StaffManagementBlocState> emit,
  ) async {
    try {
      final apiStatus = _toTodayWorkersApiStatus(event.status);
      if (isOwner) {
        await _ownerHomeRepository.putTodayWorkerStatus(
          branchId: event.branchId,
          workDate: event.workDate,
          timeLabel: event.timeLabel,
          workerName: event.workerName,
          status: apiStatus,
          memo: event.memo,
        );
      } else {
        await _managerHomeRepository.putTodayWorkerStatus(
          branchId: event.branchId,
          workDate: event.workDate,
          timeLabel: event.timeLabel,
          workerName: event.workerName,
          status: apiStatus,
          memo: event.memo,
        );
      }
      add(
        StaffManagementDayScheduleRequested(
          branchId: event.branchId,
          date: event.workDate,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  /// manager/owner home today-workers API용 (scheduled|done|absent|unset|planned|pending)
  String _toTodayWorkersApiStatus(String status) {
    switch (status) {
      case '완료':
      case '근무완료':
        return 'done';
      case '예정':
      case '근무예정':
        return 'scheduled';
      case '결근':
        return 'absent';
      case '미정':
        return 'unset';
      default:
        return status.toLowerCase();
    }
  }

  Future<void> _loadDaySchedule(
    Emitter<StaffManagementBlocState> emit, {
    required int? branchId,
    required String date,
    required bool showLoading,
  }) async {
    if (branchId == null) return;
    if (showLoading) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.loading,
          isLoading: true,
          clearError: true,
        ),
      );
    }
    try {
      final data = await _repository.getDaySchedule(
        branchId: branchId,
        date: date,
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          daySchedule: data,
          dayDate: date,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _loadEmployeesCompare(
    Emitter<StaffManagementBlocState> emit, {
    required int? branchId,
    required String? q,
    required bool showLoading,
  }) async {
    if (branchId == null) return;
    if (showLoading) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.loading,
          isLoading: true,
          clearError: true,
        ),
      );
    }
    try {
      final data = await _repository.getEmployeesCompare(
        branchId: branchId,
        q: q,
      );
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.success,
          employeesCompare: data,
          employeesQuery: q,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StaffManagementBlocStatus.failure,
          errorMessage: e.toString(),
          isLoading: false,
        ),
      );
    }
  }
}
