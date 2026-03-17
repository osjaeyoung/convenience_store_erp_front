part of 'labor_cost_bloc.dart';

enum LaborCostBlocStatus { initial, loading, success, failure }

class LaborCostBlocState extends Equatable {
  const LaborCostBlocState._({
    required this.status,
    this.expected,
    this.monthlyDetail,
    this.savingDetail,
    this.errorMessage,
  });

  const LaborCostBlocState.initial()
      : this._(status: LaborCostBlocStatus.initial);

  const LaborCostBlocState.loading()
      : this._(status: LaborCostBlocStatus.loading);

  LaborCostBlocState.expectedLoaded(ExpectedLaborCost data)
      : this._(status: LaborCostBlocStatus.success, expected: data);

  LaborCostBlocState.monthlyDetailLoaded(MonthlyLaborDetail data)
      : this._(status: LaborCostBlocStatus.success, monthlyDetail: data);

  LaborCostBlocState.savingDetailLoaded(LaborSavingDetail data)
      : this._(status: LaborCostBlocStatus.success, savingDetail: data);

  const LaborCostBlocState.failure(String message)
      : this._(status: LaborCostBlocStatus.failure, errorMessage: message);

  final LaborCostBlocStatus status;
  final ExpectedLaborCost? expected;
  final MonthlyLaborDetail? monthlyDetail;
  final LaborSavingDetail? savingDetail;
  final String? errorMessage;

  @override
  List<Object?> get props =>
      [status, expected, monthlyDetail, savingDetail, errorMessage];
}
