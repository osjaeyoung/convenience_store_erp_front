import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';

part 'recruitment_event.dart';
part 'recruitment_state.dart';

/// 구인·채용 화면 BLoC
/// 점장: Recruitment home API
class RecruitmentBloc extends Bloc<RecruitmentBlocEvent, RecruitmentBlocState> {
  RecruitmentBloc(this._managerHomeRepository)
    : super(const RecruitmentBlocState.initial()) {
    on<RecruitmentHomeRequested>(_onHomeRequested);
  }

  final ManagerHomeRepository _managerHomeRepository;

  Future<void> _onHomeRequested(
    RecruitmentHomeRequested event,
    Emitter<RecruitmentBlocState> emit,
  ) async {
    final previousData = state.homeData;
    final shouldAppend = event.append && previousData != null;
    emit(
      RecruitmentBlocState.loading(
        previousData: previousData,
        branchId: event.branchId,
        isLoadingMore: shouldAppend,
      ),
    );
    try {
      final data = await _managerHomeRepository.getRecruitmentHome(
        branchId: event.branchId,
        keyword: event.keyword,
        gender: event.gender,
        ageMin: event.ageMin,
        ageMax: event.ageMax,
        regions: event.regions,
        minRating: event.minRating,
        searchAllWorkers: event.searchAllWorkers,
        page: event.page,
        pageSize: event.pageSize,
      );
      final homeData = shouldAppend
          ? _appendHomeData(previousData, data)
          : data;
      emit(
        RecruitmentBlocState.success(
          homeData: homeData,
          branchId: event.branchId,
        ),
      );
    } catch (e) {
      if (shouldAppend) {
        emit(
          RecruitmentBlocState.success(
            homeData: previousData,
            branchId: event.branchId,
            paginationErrorMessage: e.toString(),
          ),
        );
        return;
      }
      emit(
        RecruitmentBlocState.failure(
          e.toString(),
          previousData: previousData,
          branchId: event.branchId,
        ),
      );
    }
  }

  RecruitmentHomeResponse _appendHomeData(
    RecruitmentHomeResponse previous,
    RecruitmentHomeResponse next,
  ) {
    final seenEmployeeIds = previous.searchResults
        .map(_jobSeekerIdentityKey)
        .toSet();
    final appendedSearchResults = [
      ...previous.searchResults,
      for (final item in next.searchResults)
        if (seenEmployeeIds.add(_jobSeekerIdentityKey(item))) item,
    ];

    return RecruitmentHomeResponse(
      recentViewedJobSeekers: next.recentViewedJobSeekers.isNotEmpty
          ? next.recentViewedJobSeekers
          : previous.recentViewedJobSeekers,
      searchResults: appendedSearchResults,
      totalCount: next.totalCount,
      page: next.page,
      pageSize: next.pageSize,
    );
  }

  String _jobSeekerIdentityKey(JobSeekerSummary item) {
    final workerUserId = item.workerUserId;
    if (workerUserId != null && workerUserId > 0) return 'user:$workerUserId';
    return 'employee:${item.employeeId}';
  }
}
