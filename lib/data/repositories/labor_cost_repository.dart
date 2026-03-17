import '../models/labor_cost/expected_labor_cost.dart';
import '../models/labor_cost/monthly_detail.dart';
import '../models/labor_cost/saving_detail.dart';
import '../network/api_client.dart';

/// 인건비 API
class LaborCostRepository {
  LaborCostRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 예상 인건비 조회 (이번달 / 6개월)
  Future<ExpectedLaborCost> getExpected({
    required int branchId,
    required String rangeType,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/labor-cost/branches/$branchId/expected',
      queryParameters: {'range_type': rangeType},
    );
    return ExpectedLaborCost.fromJson(res.data!);
  }

  /// 월별 인건비 직원 상세 조회
  Future<MonthlyLaborDetail> getMonthlyDetail({
    required int branchId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/labor-cost/branches/$branchId/monthly-detail',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthlyLaborDetail.fromJson(res.data!);
  }

  /// 인건비 절감 상세 조회
  Future<LaborSavingDetail> getSavingDetail({
    required int branchId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/labor-cost/branches/$branchId/saving-detail',
      queryParameters: {'year': year, 'month': month},
    );
    return LaborSavingDetail.fromJson(res.data!);
  }
}
