part of 'recruitment_bloc.dart';

abstract class RecruitmentBlocEvent extends Equatable {
  const RecruitmentBlocEvent();

  @override
  List<Object?> get props => [];
}

class RecruitmentHomeRequested extends RecruitmentBlocEvent {
  const RecruitmentHomeRequested({
    required this.branchId,
    this.keyword,
    this.gender,
    this.ageMin,
    this.ageMax,
    this.regions,
    this.minRating,
    this.page = 1,
    this.pageSize = 20,
  });

  final int branchId;
  final String? keyword;
  final String? gender;
  final int? ageMin;
  final int? ageMax;
  final List<String>? regions;
  final double? minRating;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [
        branchId,
        keyword,
        gender,
        ageMin,
        ageMax,
        regions,
        minRating,
        page,
        pageSize,
      ];
}
