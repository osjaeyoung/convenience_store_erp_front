part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState._({
    required this.status,
    this.ownerBranches = const [],
    this.managerBranches = const [],
    this.selectedBranchDetail,
    this.detailLoading = false,
    this.detailErrorMessage,
    this.errorMessage,
  });

  const HomeState.initial()
      : this._(status: HomeStatus.initial);

  const HomeState.loading()
      : this._(status: HomeStatus.loading);

  HomeState.ownerBranchesLoaded(List<OwnerBranch> branches)
      : this._(
          status: HomeStatus.success,
          ownerBranches: branches,
        );

  HomeState.managerBranchesLoaded(List<ManagerBranch> branches)
      : this._(
          status: HomeStatus.success,
          managerBranches: branches,
        );

  const HomeState.failure(String message)
      : this._(status: HomeStatus.failure, errorMessage: message);

  HomeState copyWith({
    HomeStatus? status,
    List<OwnerBranch>? ownerBranches,
    List<ManagerBranch>? managerBranches,
    HomeBranchDetail? selectedBranchDetail,
    bool? detailLoading,
    String? detailErrorMessage,
    String? errorMessage,
  }) {
    return HomeState._(
      status: status ?? this.status,
      ownerBranches: ownerBranches ?? this.ownerBranches,
      managerBranches: managerBranches ?? this.managerBranches,
      selectedBranchDetail: selectedBranchDetail ?? this.selectedBranchDetail,
      detailLoading: detailLoading ?? this.detailLoading,
      detailErrorMessage: detailErrorMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  final HomeStatus status;
  final List<OwnerBranch> ownerBranches;
  final List<ManagerBranch> managerBranches;
  final HomeBranchDetail? selectedBranchDetail;
  final bool detailLoading;
  final String? detailErrorMessage;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        ownerBranches,
        managerBranches,
        selectedBranchDetail,
        detailLoading,
        detailErrorMessage,
        errorMessage,
      ];
}

class HomeBranchDetail extends Equatable {
  const HomeBranchDetail({
    required this.branchId,
    required this.managerName,
    required this.alertTitle,
    required this.waitingInterview,
    required this.newApplicants,
    required this.newContacts,
    required this.rows,
    required this.workDate,
    required this.dateLabel,
    this.expectedTotalAmountText,
    this.expectedChangeText,
    this.savingPointTexts = const [],
  });

  final int branchId;
  final String managerName;
  final String alertTitle;
  final int waitingInterview;
  final int newApplicants;
  final int newContacts;
  final List<HomeWorkerRow> rows;
  final String workDate;
  final String dateLabel;
  final String? expectedTotalAmountText;
  final String? expectedChangeText;
  final List<String> savingPointTexts;

  @override
  List<Object?> get props => [
        branchId,
        managerName,
        alertTitle,
        waitingInterview,
        newApplicants,
        newContacts,
        rows,
        workDate,
        dateLabel,
        expectedTotalAmountText,
        expectedChangeText,
        savingPointTexts,
      ];
}

class HomeWorkerRow extends Equatable {
  const HomeWorkerRow({
    required this.time,
    required this.workerName,
    required this.status,
    this.memo,
    this.statusId,
  });

  final String time;
  final String workerName;
  final String status;
  final String? memo;
  final int? statusId;

  @override
  List<Object?> get props => [time, workerName, status, memo, statusId];
}
