import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

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

  /// 월 묶음 연/월 수정 (스펙 3-2)
  Future<StoreExpenseMonthSummary> patchMonth({
    required int branchId,
    required int expenseMonthId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/months/$expenseMonthId',
      data: {'year': year, 'month': month},
    );
    return StoreExpenseMonthSummary.fromJson(res.data!);
  }

  /// 항목에 증빙 파일 추가 (스펙 6)
  Future<StoreExpenseItem> appendItemFiles({
    required int branchId,
    required int expenseItemId,
    required List<PlatformFile> files,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry(
        'files',
        await _expenseOcrMultipartFile(file),
      ));
    }
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/items/$expenseItemId/file',
      data: formData,
      options: Options(
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    return StoreExpenseItem.fromJson(res.data!);
  }

  /// 연간 점내 비용 추이 (스펙 11)
  Future<StoreExpenseYearTrend> getTrend({
    required int branchId,
    required int year,
    String rangeType = 'year',
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/trend',
      queryParameters: {
        'range_type': rangeType,
        'year': year,
      },
    );
    return StoreExpenseYearTrend.fromJson(res.data!);
  }

  /// 영수증 OCR (스펙 12)
  Future<StoreExpenseReceiptOcrResult> postReceiptOcr({
    required PlatformFile file,
  }) async {
    final formData = FormData.fromMap({
      'file': await _expenseOcrMultipartFile(file),
    });
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/store-expenses/receipt-ocr',
      data: formData,
      options: Options(
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    return StoreExpenseReceiptOcrResult.fromJson(res.data!);
  }

  static Future<MultipartFile> _expenseOcrMultipartFile(PlatformFile file) async {
    final name = file.name.trim().isEmpty ? 'receipt.jpg' : file.name.trim();
    final contentType = _ocrMediaType(name);
    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: name,
        contentType: contentType,
      );
    }
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return MultipartFile.fromFile(
        path,
        filename: name,
        contentType: contentType,
      );
    }
    throw StateError('영수증 이미지를 읽을 수 없습니다. 다시 선택해 주세요.');
  }

  static DioMediaType? _ocrMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return DioMediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.pdf')) return DioMediaType('application', 'pdf');
    return null;
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

  /// 2-Step 추가 Step1: 연도/월 선택
  Future<StoreExpenseCreateStep1Result> createStep1({
    required int branchId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/create/step1',
      data: {'year': year, 'month': month},
    );
    return StoreExpenseCreateStep1Result.fromJson(res.data!);
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

  /// 2-Step 추가 Step2: 항목 입력 + 파일 첨부
  Future<StoreExpenseItem> createStep2({
    required int branchId,
    required int expenseMonthId,
    required String expenseDate,
    required String categoryCode,
    required int amount,
    String? memo,
    List<StoreExpenseFileDraft> files = const [],
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/store-expenses/branches/$branchId/create/step2',
      data: {
        'expense_month_id': expenseMonthId,
        'expense_date': expenseDate,
        'category_code': categoryCode,
        'amount': amount,
        if (memo != null && memo.isNotEmpty) 'memo': memo,
        'files': files.map((file) => file.toJson()).toList(),
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
