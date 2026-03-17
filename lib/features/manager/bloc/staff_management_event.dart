part of 'staff_management_bloc.dart';

abstract class StaffManagementBlocEvent extends Equatable {
  const StaffManagementBlocEvent();

  @override
  List<Object?> get props => [];
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
