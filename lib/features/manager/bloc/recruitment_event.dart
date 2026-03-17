part of 'recruitment_bloc.dart';

abstract class RecruitmentBlocEvent extends Equatable {
  const RecruitmentBlocEvent();

  @override
  List<Object?> get props => [];
}

class RecruitmentStatusRequested extends RecruitmentBlocEvent {
  const RecruitmentStatusRequested({this.branchId});

  final int? branchId;

  @override
  List<Object?> get props => [branchId];
}
