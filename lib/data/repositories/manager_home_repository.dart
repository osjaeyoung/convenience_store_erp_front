import '../models/manager_home/manager_alert.dart';
import '../models/manager_home/manager_branch.dart';
import '../models/manager_home/today_worker.dart';
import '../network/api_client.dart';

/// 점장 홈 API
class ManagerHomeRepository {
  ManagerHomeRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 점장 지점 권한 받기 (공유 ID 인증)
  Future<Map<String, dynamic>> joinBranch({
    required int managerRegistrationId,
    required String managerPhoneNumber,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/manager/home/branches/join',
      data: {
        'manager_registration_id': managerRegistrationId,
        'manager_phone_number': managerPhoneNumber,
      },
    );
    return res.data!;
  }

  /// 이름+전화번호로 사전등록 점포 조회
  Future<List<Map<String, dynamic>>> lookupBranches({
    required String managerName,
    required String managerPhoneNumber,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/manager/home/branches/lookup',
      data: {
        'manager_name': managerName,
        'manager_phone_number': managerPhoneNumber,
      },
    );
    final items = res.data?['items'] as List<dynamic>? ?? const [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// 이름+전화번호 매칭 점포 일괄 연결
  Future<Map<String, dynamic>> joinBranchesBulk({
    required String managerName,
    required String managerPhoneNumber,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/manager/home/branches/join-bulk',
      data: {
        'manager_name': managerName,
        'manager_phone_number': managerPhoneNumber,
      },
    );
    return res.data ?? const {};
  }

  /// 점장 홈 지점 목록
  Future<List<ManagerBranch>> getBranches({String? date}) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/manager/home/branches',
      queryParameters: date != null ? {'date': date} : null,
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ManagerBranch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 점장 홈 지점 상세
  Future<ManagerBranch> getBranchDetail({
    required int branchId,
    String? date,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/manager/home/branches/$branchId',
      queryParameters: date != null ? {'date': date} : null,
    );
    return ManagerBranch.fromJson(res.data!);
  }

  /// 채용 현황 조회
  Future<Map<String, dynamic>> getRecruitmentStatus(int branchId) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/recruitment-status',
    );
    return res.data!;
  }

  /// 알림 목록 조회
  Future<List<ManagerAlert>> getAlerts(int branchId) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/alerts',
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ManagerAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 알림 펼침/닫힘
  Future<Map<String, dynamic>> patchAlert({
    required int branchId,
    required int alertId,
    required bool isOpen,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/alerts/$alertId',
      data: {'is_open': isOpen},
    );
    return res.data!;
  }

  /// 오늘 근무자 현황 조회
  Future<List<TodayWorker>> getTodayWorkers({
    required int branchId,
    String? date,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/today-workers',
      queryParameters: date != null ? {'date': date} : null,
    );
    final rows = res.data!['rows'] as List<dynamic>? ?? [];
    return rows
        .map((e) => TodayWorker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 오늘 근무자 상태/메모 저장
  Future<Map<String, dynamic>> putTodayWorkerStatus({
    required int branchId,
    required String workDate,
    required String timeLabel,
    required String workerName,
    required String status,
    String? memo,
  }) async {
    final res = await _apiClient.dio.put<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/today-workers/status',
      data: {
        'work_date': workDate,
        'time_label': timeLabel,
        'worker_name': workerName,
        'status': status,
        if (memo != null) 'memo': memo,
      },
    );
    return res.data!;
  }

  /// 오늘 근무자 메모 삭제
  Future<Map<String, dynamic>> deleteTodayWorkerMemo({
    required int branchId,
    required int statusId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/manager/home/branches/$branchId/today-workers/$statusId/memo',
    );
    return res.data!;
  }
}
