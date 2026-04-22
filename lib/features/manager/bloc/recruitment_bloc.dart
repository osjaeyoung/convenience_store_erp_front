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
    emit(
      RecruitmentBlocState.loading(
        previousData: state.homeData,
        branchId: event.branchId,
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
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(
        RecruitmentBlocState.success(
          homeData: data,
          branchId: event.branchId,
        ),
      );
    } catch (e) {
      emit(
        RecruitmentBlocState.failure(
          e.toString(),
          previousData: state.homeData,
          branchId: event.branchId,
        ),
      );
    }
  }
}
