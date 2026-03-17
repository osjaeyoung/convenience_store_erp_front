import '../network/api_client.dart';

/// 직원관리 API (근무일정 중심)
class StaffManagementRepository {
  StaffManagementRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 날짜별 근무일정 조회
  Future<Map<String, dynamic>> getDaySchedule({
    required int branchId,
    required String date,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/day',
      queryParameters: {'date': date},
    );
    return res.data!;
  }

  /// 주별 근무일정 조회
  Future<Map<String, dynamic>> getWeekSchedule({
    required int branchId,
    required String weekStartDate,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/week',
      queryParameters: {'week_start_date': weekStartDate},
    );
    return res.data!;
  }

  /// 날짜별 근무일정 저장/수정
  Future<Map<String, dynamic>> putDaySchedule({
    required int branchId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _apiClient.dio.put<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/day',
      data: data,
    );
    return res.data!;
  }

  /// 주별 근무일정 저장/수정
  Future<Map<String, dynamic>> putWeekSchedule({
    required int branchId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _apiClient.dio.put<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/week',
      data: data,
    );
    return res.data!;
  }

  /// 특정 슬롯 상태/메모 수정
  Future<Map<String, dynamic>> patchSchedule({
    required int branchId,
    required int scheduleId,
    String? status,
    String? memo,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/$scheduleId',
      data: {
        if (status != null) 'status': status,
        if (memo != null) 'memo': memo,
      },
    );
    return res.data!;
  }

  /// 특정 슬롯 삭제
  Future<Map<String, dynamic>> deleteSchedule({
    required int branchId,
    required int scheduleId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/schedules/$scheduleId',
    );
    return res.data!;
  }

  /// 현근무자/퇴사자 비교 조회
  Future<Map<String, dynamic>> getEmployeesCompare({
    required int branchId,
    String? q,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/compare',
      queryParameters: q != null ? {'q': q} : null,
    );
    return res.data!;
  }

  /// 근무자 상세 조회
  Future<Map<String, dynamic>> getEmployeeDetail({
    required int branchId,
    required int employeeId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId',
    );
    return res.data!;
  }

  /// 근무자 인적사항 수정
  Future<Map<String, dynamic>> patchEmployee({
    required int branchId,
    required int employeeId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId',
      data: data,
    );
    return res.data!;
  }

  /// 자기 자신 근무자로 등록
  Future<Map<String, dynamic>> registerSelf({
    required int branchId,
    String? name,
    String? phoneNumber,
    String? hireDate,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/register-self',
      data: {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (hireDate != null) 'hire_date': hireDate,
      },
    );
    return res.data!;
  }

  /// 근로계약서 목록 조회 (임시저장 포함)
  Future<Map<String, dynamic>> getEmploymentContracts({
    required int branchId,
    required int employeeId,
    String? status,
    String? templateVersion,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (templateVersion != null && templateVersion.isNotEmpty)
          'template_version': templateVersion,
      },
    );
    return res.data!;
  }

  /// 리뷰 등록
  Future<Map<String, dynamic>> createReview({
    required int branchId,
    required int employeeId,
    required int rating,
    required String comment,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/reviews',
      data: {
        'rating': rating,
        'comment': comment,
      },
    );
    return res.data!;
  }

  /// 리뷰 삭제
  Future<Map<String, dynamic>> deleteReview({
    required int branchId,
    required int employeeId,
    required int reviewId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/reviews/$reviewId',
    );
    return res.data!;
  }
}
