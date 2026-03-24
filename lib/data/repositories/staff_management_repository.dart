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

  /// 근무자 삭제
  Future<Map<String, dynamic>> deleteEmployee({
    required int branchId,
    required int employeeId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
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

  /// 앱 가입 사용자 연락처 검색 (근무자 등록용)
  Future<Map<String, dynamic>> searchUsersByPhone({
    required int branchId,
    required String phone,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/search-users',
      queryParameters: {'phone': phone},
    );
    return res.data!;
  }

  /// 앱 사용자를 근무자로 등록 (from-user 엔드포인트)
  Future<Map<String, dynamic>> registerEmployee({
    required int branchId,
    required int userId,
    String? hireDate,
  }) async {
    final now = DateTime.now();
    final hireDateStr = hireDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/from-user',
      data: {
        'user_id': userId,
        'hire_date': hireDateStr,
      },
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

  /// 기타자료 목록 — 스펙 ##21
  Future<Map<String, dynamic>> getEmployeeRecordsEtc({
    required int branchId,
    required int employeeId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/records/etc',
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

  /// 근로계약서 단건 조회 — 스펙 ##26
  Future<Map<String, dynamic>> getEmploymentContractDetail({
    required int branchId,
    required int employeeId,
    required int contractId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts/$contractId',
    );
    return res.data!;
  }

  /// 근로계약서 생성 — 스펙 ##23
  Future<Map<String, dynamic>> createEmploymentContract({
    required int branchId,
    required int employeeId,
    required Map<String, dynamic> body,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts',
      data: body,
    );
    return res.data!;
  }

  /// 근로계약서 파일 전용 등록 — 스펙 ##23-1
  Future<Map<String, dynamic>> createEmploymentContractFileOnly({
    required int branchId,
    required int employeeId,
    required String templateVersion,
    String? title,
    required List<Map<String, dynamic>> files,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts/file-only',
      data: {
        'template_version': templateVersion,
        if (title != null && title.isNotEmpty) 'title': title,
        'files': files,
      },
    );
    return res.data!;
  }

  /// 근로계약서 수정 — 스펙 ##24
  Future<Map<String, dynamic>> patchEmploymentContract({
    required int branchId,
    required int employeeId,
    required int contractId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts/$contractId',
      data: data,
    );
    return res.data!;
  }

  /// 근로계약서 파일 추가 — 스펙 ##25
  Future<Map<String, dynamic>> patchEmploymentContractFiles({
    required int branchId,
    required int employeeId,
    required int contractId,
    required List<Map<String, dynamic>> files,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts/$contractId/file',
      data: {'files': files},
    );
    return res.data!;
  }

  /// 근로계약서 삭제 — 스펙 ##27
  Future<Map<String, dynamic>> deleteEmploymentContract({
    required int branchId,
    required int employeeId,
    required int contractId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/employment-contracts/$contractId',
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

  /// 급여명세 작성 화면 자동 채우기 — GET .../payroll-auto-fill?year=&month=
  Future<Map<String, dynamic>> getPayrollStatementAutoFill({
    required int branchId,
    required int employeeId,
    required int year,
    required int month,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-auto-fill',
      queryParameters: {
        'year': year,
        'month': month,
      },
    );
    return res.data!;
  }

  /// 급여명세 미리계산 (저장 안 함)
  Future<Map<String, dynamic>> calculatePayrollStatement({
    required int branchId,
    required int employeeId,
    required Map<String, dynamic> body,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements/calculate',
      data: body,
    );
    return res.data!;
  }

  /// 급여명세 저장 (글 데이터, 선택적으로 `files` 배열 포함 — 스펙 ##16)
  Future<Map<String, dynamic>> createPayrollStatement({
    required int branchId,
    required int employeeId,
    required Map<String, dynamic> body,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements',
      data: body,
    );
    return res.data!;
  }

  /// 급여명세 파일 전용 등록 (연/월 + `files` 필수) — 스펙 ##16-1
  Future<Map<String, dynamic>> createPayrollStatementFileOnly({
    required int branchId,
    required int employeeId,
    required int year,
    required int month,
    required List<Map<String, dynamic>> files,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements/file-only',
      data: {
        'year': year,
        'month': month,
        'files': files,
      },
    );
    return res.data!;
  }

  /// 급여명세 목록
  Future<Map<String, dynamic>> getPayrollStatements({
    required int branchId,
    required int employeeId,
    int? year,
    int? month,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements',
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    return res.data!;
  }

  /// 급여명세 상세
  Future<Map<String, dynamic>> getPayrollStatementDetail({
    required int branchId,
    required int employeeId,
    required int payrollId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements/$payrollId',
    );
    return res.data!;
  }

  /// 급여명세 삭제
  Future<Map<String, dynamic>> deletePayrollStatement({
    required int branchId,
    required int employeeId,
    required int payrollId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements/$payrollId',
    );
    return res.data!;
  }

  /// 급여명세 파일만 추가
  Future<Map<String, dynamic>> patchPayrollStatementFiles({
    required int branchId,
    required int employeeId,
    required int payrollId,
    required List<Map<String, dynamic>> files,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/staff-management/branches/$branchId/employees/$employeeId/payroll-statements/$payrollId/file',
      data: {'files': files},
    );
    return res.data!;
  }
}
