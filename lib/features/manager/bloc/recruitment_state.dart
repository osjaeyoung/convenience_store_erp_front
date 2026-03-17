part of 'recruitment_bloc.dart';

enum RecruitmentBlocStatus { initial, loading, success, failure }

class RecruitmentBlocState extends Equatable {
  const RecruitmentBlocState._({
    required this.status,
    this.recruitmentStatus,
    this.errorMessage,
  });

  const RecruitmentBlocState.initial()
      : this._(status: RecruitmentBlocStatus.initial);

  const RecruitmentBlocState.loading()
      : this._(status: RecruitmentBlocStatus.loading);

  RecruitmentBlocState.statusLoaded(Map<String, dynamic> data)
      : this._(status: RecruitmentBlocStatus.success, recruitmentStatus: data);

  const RecruitmentBlocState.failure(String message)
      : this._(status: RecruitmentBlocStatus.failure, errorMessage: message);

  final RecruitmentBlocStatus status;
  final Map<String, dynamic>? recruitmentStatus;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, recruitmentStatus, errorMessage];
}
