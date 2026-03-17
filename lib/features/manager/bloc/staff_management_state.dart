part of 'staff_management_bloc.dart';

enum StaffManagementBlocStatus { initial, loading, success, failure }

class StaffManagementBlocState extends Equatable {
  const StaffManagementBlocState({
    required this.status,
    required this.isLoading,
    this.daySchedule,
    this.weekSchedule,
    this.employeesCompare,
    this.employeeDetail,
    this.employmentContracts,
    this.selectedEmployeeId,
    this.dayDate,
    this.weekStartDate,
    this.employeesQuery,
    this.contractStatusFilter,
    this.contractTemplateFilter,
    this.errorMessage,
  });

  const StaffManagementBlocState.initial()
      : this(
          status: StaffManagementBlocStatus.initial,
          isLoading: false,
        );

  final StaffManagementBlocStatus status;
  final bool isLoading;
  final Map<String, dynamic>? daySchedule;
  final Map<String, dynamic>? weekSchedule;
  final Map<String, dynamic>? employeesCompare;
  final Map<String, dynamic>? employeeDetail;
  final Map<String, dynamic>? employmentContracts;
  final int? selectedEmployeeId;
  final String? dayDate;
  final String? weekStartDate;
  final String? employeesQuery;
  final String? contractStatusFilter;
  final String? contractTemplateFilter;
  final String? errorMessage;

  StaffManagementBlocState copyWith({
    StaffManagementBlocStatus? status,
    bool? isLoading,
    Map<String, dynamic>? daySchedule,
    Map<String, dynamic>? weekSchedule,
    Map<String, dynamic>? employeesCompare,
    Map<String, dynamic>? employeeDetail,
    Map<String, dynamic>? employmentContracts,
    int? selectedEmployeeId,
    String? dayDate,
    String? weekStartDate,
    String? employeesQuery,
    String? contractStatusFilter,
    String? contractTemplateFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffManagementBlocState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      daySchedule: daySchedule ?? this.daySchedule,
      weekSchedule: weekSchedule ?? this.weekSchedule,
      employeesCompare: employeesCompare ?? this.employeesCompare,
      employeeDetail: employeeDetail ?? this.employeeDetail,
      employmentContracts: employmentContracts ?? this.employmentContracts,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      dayDate: dayDate ?? this.dayDate,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      employeesQuery: employeesQuery ?? this.employeesQuery,
      contractStatusFilter: contractStatusFilter ?? this.contractStatusFilter,
      contractTemplateFilter:
          contractTemplateFilter ?? this.contractTemplateFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isLoading,
        daySchedule,
        weekSchedule,
        employeesCompare,
        employeeDetail,
        employmentContracts,
        selectedEmployeeId,
        dayDate,
        weekStartDate,
        employeesQuery,
        contractStatusFilter,
        contractTemplateFilter,
        errorMessage,
      ];
}
