part of 'recruitment_bloc.dart';

enum RecruitmentBlocStatus { initial, loading, success, failure }

class RecruitmentBlocState extends Equatable {
  const RecruitmentBlocState._({
    required this.status,
    this.homeData,
    this.branchId,
    this.errorMessage,
  });

  const RecruitmentBlocState.initial()
      : this._(status: RecruitmentBlocStatus.initial);

  const RecruitmentBlocState.loading({
    RecruitmentHomeResponse? previousData,
    int? branchId,
  }) : this._(
          status: RecruitmentBlocStatus.loading,
          homeData: previousData,
          branchId: branchId,
        );

  const RecruitmentBlocState.success({
    required RecruitmentHomeResponse homeData,
    required int branchId,
  }) : this._(
          status: RecruitmentBlocStatus.success,
          homeData: homeData,
          branchId: branchId,
        );

  const RecruitmentBlocState.failure(
    String message, {
    RecruitmentHomeResponse? previousData,
    int? branchId,
  }) : this._(
          status: RecruitmentBlocStatus.failure,
          homeData: previousData,
          branchId: branchId,
          errorMessage: message,
        );

  final RecruitmentBlocStatus status;
  final RecruitmentHomeResponse? homeData;
  final int? branchId;
  final String? errorMessage;

  bool get hasData => homeData != null;

  @override
  List<Object?> get props => [status, homeData, branchId, errorMessage];
}
