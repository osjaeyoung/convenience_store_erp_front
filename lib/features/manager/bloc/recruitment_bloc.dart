import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/manager_home_repository.dart';

part 'recruitment_event.dart';
part 'recruitment_state.dart';

/// 구인·채용 화면 BLoC
/// 점장: ManagerHomeRepository.getRecruitmentStatus
class RecruitmentBloc extends Bloc<RecruitmentBlocEvent, RecruitmentBlocState> {
  RecruitmentBloc(this._managerHomeRepository)
      : super(const RecruitmentBlocState.initial()) {
    on<RecruitmentStatusRequested>(_onStatusRequested);
  }

  final ManagerHomeRepository _managerHomeRepository;

  Future<void> _onStatusRequested(
    RecruitmentStatusRequested event,
    Emitter<RecruitmentBlocState> emit,
  ) async {
    if (event.branchId == null) return;
    emit(const RecruitmentBlocState.loading());
    try {
      final data = await _managerHomeRepository.getRecruitmentStatus(
        event.branchId!,
      );
      emit(RecruitmentBlocState.statusLoaded(data));
    } catch (e) {
      emit(RecruitmentBlocState.failure(e.toString()));
    }
  }
}
