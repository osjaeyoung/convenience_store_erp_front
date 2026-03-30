import '../models/store_expense/store_expense_dashboard.dart';
import '../models/store_expense/store_expense_month.dart';
import '../network/api_client.dart';

/// 매장 비용 API
class StoreExpenseRepository {
  StoreExpenseRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 월간 표시 대시보드 조회
  Future<StoreExpenseDashboard> getDashboard({
    required int branchId,
    required int year,
    required int month,
    int? baseDay,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/dashboard',
      queryParameters: {
        'year': year,
        'month': month,
        if (baseDay != null) 'base_day': baseDay,
      },
    );
    return StoreExpenseDashboard.fromJson(res.data!);
  }

  /// 월별 점내 비용 묶음 목록 조회
  Future<List<StoreExpenseMonthSummary>> getMonths({
    required int branchId,
    required int year,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months',
      queryParameters: {'year': year},
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => StoreExpenseMonthSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 월별 점내 비용 추가
  Future<StoreExpenseMonthSummary> postMonth({
    required int branchId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months',
      data: {'year': year, 'month': month},
    );
    return StoreExpenseMonthSummary.fromJson(res.data!);
  }

  /// 카테고리 목록 조회
  Future<List<StoreExpenseCategory>> getCategories() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/store-expenses/categories',
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => StoreExpenseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 항목 추가
  Future<StoreExpenseItem> postItem({
    required int branchId,
    required int expenseMonthId,
    required String expenseDate,
    required String categoryCode,
    required int amount,
    String? memo,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months/$expenseMonthId/items',
      data: {
        'expense_date': expenseDate,
        'category_code': categoryCode,
        'amount': amount,
        if (memo != null) 'memo': memo,
      },
    );
    return StoreExpenseItem.fromJson(res.data!);
  }

  /// 월 상세 조회
  Future<StoreExpenseMonthDetail> getMonthDetail({
    required int branchId,
    required int expenseMonthId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months/$expenseMonthId',
    );
    return StoreExpenseMonthDetail.fromJson(res.data!);
  }

  /// 항목 수정
  Future<Map<String, dynamic>> patchItem({
    required int branchId,
    required int expenseItemId,
    String? expenseDate,
    String? categoryCode,
    int? amount,
    String? memo,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/items/$expenseItemId',
      data: {
        if (expenseDate != null) 'expense_date': expenseDate,
        if (categoryCode != null) 'category_code': categoryCode,
        if (amount != null) 'amount': amount,
        if (memo != null) 'memo': memo,
      },
    );
    return res.data!;
  }

  /// 항목 삭제
  Future<Map<String, dynamic>> deleteItem({
    required int branchId,
    required int expenseItemId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/items/$expenseItemId',
    );
    return res.data!;
  }

  /// 월 묶음 삭제
  Future<Map<String, dynamic>> deleteMonth({
    required int branchId,
    required int expenseMonthId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months/$expenseMonthId',
    );
    return res.data!;
  }
}
