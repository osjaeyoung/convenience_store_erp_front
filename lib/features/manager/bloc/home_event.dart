part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeBranchesRequested extends HomeEvent {
  const HomeBranchesRequested({this.date});

  final String? date;

  @override
  List<Object?> get props => [date];
}

class HomeBranchDetailRequested extends HomeEvent {
  const HomeBranchDetailRequested({
    required this.branchId,
    this.date,
  });

  final int branchId;
  final String? date;

  @override
  List<Object?> get props => [branchId, date];
}

class HomeWorkerStatusSaveRequested extends HomeEvent {
  const HomeWorkerStatusSaveRequested({
    required this.branchId,
    required this.workDate,
    required this.timeLabel,
    required this.workerName,
    required this.status,
    this.memo,
    this.scheduleId,
  });

  final int branchId;
  final String workDate;
  final String timeLabel;
  final String workerName;
  final String status;
  final String? memo;
  final int? scheduleId;

  @override
  List<Object?> get props => [
        branchId,
        workDate,
        timeLabel,
        workerName,
        status,
        memo,
        scheduleId,
      ];
}

class HomeWorkerMemoDeleteRequested extends HomeEvent {
  const HomeWorkerMemoDeleteRequested({
    required this.branchId,
    required this.workDate,
    required this.timeLabel,
    required this.workerName,
    required this.status,
    this.statusId,
    this.scheduleId,
  });

  final int branchId;
  final String workDate;
  final String timeLabel;
  final String workerName;
  final String status;
  final int? statusId;
  final int? scheduleId;

  @override
  List<Object?> get props => [
        branchId,
        workDate,
        timeLabel,
        workerName,
        status,
        statusId,
        scheduleId,
      ];
}
