part of 'staff_management_bloc.dart';

abstract class StaffManagementBlocEvent extends Equatable {
  const StaffManagementBlocEvent();

  @override
  List<Object?> get props => [];
}

class StaffManagementInitialized extends StaffManagementBlocEvent {
  const StaffManagementInitialized({
    this.branchId,
    required this.date,
  });

  final int? branchId;
  final String date;

  @override
  List<Object?> get props => [branchId, date];
}

class StaffManagementDayScheduleRequested extends StaffManagementBlocEvent {
  const StaffManagementDayScheduleRequested({
    this.branchId,
    required this.date,
  });

  final int? branchId;
  final String date;

  @override
  List<Object?> get props => [branchId, date];
}

class StaffManagementWeekScheduleRequested extends StaffManagementBlocEvent {
  const StaffManagementWeekScheduleRequested({
    this.branchId,
    required this.weekStartDate,
  });

  final int? branchId;
  final String weekStartDate;

  @override
  List<Object?> get props => [branchId, weekStartDate];
}

class StaffManagementEmployeesCompareRequested extends StaffManagementBlocEvent {
  const StaffManagementEmployeesCompareRequested({
    this.branchId,
    this.q,
  });

  final int? branchId;
  final String? q;

  @override
  List<Object?> get props => [branchId, q];
}

class StaffManagementEmployeeDetailRequested extends StaffManagementBlocEvent {
  const StaffManagementEmployeeDetailRequested({
    this.branchId,
    required this.employeeId,
  });

  final int? branchId;
  final int employeeId;

  @override
  List<Object?> get props => [branchId, employeeId];
}

class StaffManagementEmploymentContractsRequested
    extends StaffManagementBlocEvent {
  const StaffManagementEmploymentContractsRequested({
    this.branchId,
    required this.employeeId,
    this.status,
    this.templateVersion,
  });

  final int? branchId;
  final int employeeId;
  final String? status;
  final String? templateVersion;

  @override
  List<Object?> get props => [branchId, employeeId, status, templateVersion];
}

class StaffManagementReviewCreated extends StaffManagementBlocEvent {
  const StaffManagementReviewCreated({
    this.branchId,
    required this.employeeId,
    required this.rating,
    required this.comment,
  });

  final int? branchId;
  final int employeeId;
  final int rating;
  final String comment;

  @override
  List<Object?> get props => [branchId, employeeId, rating, comment];
}

class StaffManagementReviewDeleted extends StaffManagementBlocEvent {
  const StaffManagementReviewDeleted({
    this.branchId,
    required this.employeeId,
    required this.reviewId,
  });

  final int? branchId;
  final int employeeId;
  final int reviewId;

  @override
  List<Object?> get props => [branchId, employeeId, reviewId];
}

/// 근무배정 - 일별 일정 저장
class StaffManagementDaySchedulePutRequested extends StaffManagementBlocEvent {
  const StaffManagementDaySchedulePutRequested({
    required this.branchId,
    required this.workDate,
    required this.slots,
  });

  final int branchId;
  final String workDate;
  final List<Map<String, dynamic>> slots;

  @override
  List<Object?> get props => [branchId, workDate, slots];
}

/// 근무배정 - 주별 일정 저장
class StaffManagementWeekSchedulePutRequested extends StaffManagementBlocEvent {
  const StaffManagementWeekSchedulePutRequested({
    required this.branchId,
    required this.weekStartDate,
    required this.days,
  });

  final int branchId;
  final String weekStartDate;
  final List<Map<String, dynamic>> days;

  @override
  List<Object?> get props => [branchId, weekStartDate, days];
}

/// 근무일정 탭 - 특정 슬롯 상태/메모 수정
/// manager/owner home today-workers API (PUT .../today-workers/status) 사용
class StaffManagementWorkerStatusSaveRequested
    extends StaffManagementBlocEvent {
  const StaffManagementWorkerStatusSaveRequested({
    required this.branchId,
    required this.workDate,
    required this.timeLabel,
    required this.workerName,
    required this.status,
    this.memo,
  });

  final int branchId;
  final String workDate;
  final String timeLabel;
  final String workerName;
  final String status;
  final String? memo;

  @override
  List<Object?> get props => [branchId, workDate, timeLabel, workerName, status, memo];
}
