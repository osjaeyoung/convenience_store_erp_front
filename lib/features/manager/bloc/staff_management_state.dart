part of 'staff_management_bloc.dart';

enum StaffManagementBlocStatus { initial, loading, success, failure }

class StaffManagementBlocState extends Equatable {
  const StaffManagementBlocState._({
    required this.status,
    this.daySchedule,
    this.weekSchedule,
    this.employeesCompare,
    this.errorMessage,
  });

  const StaffManagementBlocState.initial()
      : this._(status: StaffManagementBlocStatus.initial);

  const StaffManagementBlocState.loading()
      : this._(status: StaffManagementBlocStatus.loading);

  StaffManagementBlocState.dayScheduleLoaded(Map<String, dynamic> data)
      : this._(status: StaffManagementBlocStatus.success, daySchedule: data);

  StaffManagementBlocState.weekScheduleLoaded(Map<String, dynamic> data)
      : this._(status: StaffManagementBlocStatus.success, weekSchedule: data);

  StaffManagementBlocState.employeesCompareLoaded(Map<String, dynamic> data)
      : this._(status: StaffManagementBlocStatus.success, employeesCompare: data);

  const StaffManagementBlocState.failure(String message)
      : this._(status: StaffManagementBlocStatus.failure, errorMessage: message);

  final StaffManagementBlocStatus status;
  final Map<String, dynamic>? daySchedule;
  final Map<String, dynamic>? weekSchedule;
  final Map<String, dynamic>? employeesCompare;
  final String? errorMessage;

  @override
  List<Object?> get props =>
      [status, daySchedule, weekSchedule, employeesCompare, errorMessage];
}
