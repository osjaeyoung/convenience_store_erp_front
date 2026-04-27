part of 'recruitment_bloc.dart';

enum RecruitmentBlocStatus { initial, loading, success, failure }

class RecruitmentBlocState extends Equatable {
  const RecruitmentBlocState._({
    required this.status,
    this.homeData,
    this.branchId,
    this.errorMessage,
    this.paginationErrorMessage,
    this.isLoadingMore = false,
  });

  const RecruitmentBlocState.initial()
    : this._(status: RecruitmentBlocStatus.initial);

  const RecruitmentBlocState.loading({
    RecruitmentHomeResponse? previousData,
    int? branchId,
    bool isLoadingMore = false,
  }) : this._(
         status: RecruitmentBlocStatus.loading,
         homeData: previousData,
         branchId: branchId,
         isLoadingMore: isLoadingMore,
       );

  const RecruitmentBlocState.success({
    required RecruitmentHomeResponse homeData,
    required int branchId,
    String? paginationErrorMessage,
  }) : this._(
         status: RecruitmentBlocStatus.success,
         homeData: homeData,
         branchId: branchId,
         paginationErrorMessage: paginationErrorMessage,
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
  final String? paginationErrorMessage;
  final bool isLoadingMore;

  bool get hasData => homeData != null;
  bool get hasMoreSearchResults {
    final data = homeData;
    if (data == null) return false;
    return data.searchResults.length < data.totalCount;
  }

  @override
  List<Object?> get props => [
    status,
    homeData,
    branchId,
    errorMessage,
    paginationErrorMessage,
    isLoadingMore,
  ];
}
