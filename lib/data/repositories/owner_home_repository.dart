import '../models/owner_home/owner_branch.dart';
import '../models/owner_home/owner_me.dart';
import '../network/api_client.dart';

/// 경영주 홈 API
class OwnerHomeRepository {
  OwnerHomeRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 내 정보 조회 (역할별 응답) - GET /me
  Future<OwnerMe> getMe() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/me');
    return OwnerMe.fromJson(res.data!);
  }

  /// 경영주 점포 목록
  Future<List<OwnerBranch>> getBranches() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches',
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => OwnerBranch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 경영주 점포 추가
  Future<OwnerBranch> addBranch({
    required String branchName,
    String? branchCode,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/owner/home/branches',
      data: {
        'branch_name': branchName,
        if (branchCode != null && branchCode.isNotEmpty) 'branch_code': branchCode,
      },
    );
    return OwnerBranch.fromJson(res.data!);
  }

  /// 점포 상세
  Future<OwnerBranch> getBranchDetail(int branchId) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches/$branchId',
    );
    return OwnerBranch.fromJson(res.data!);
  }

  /// 등록된 점장 리스트
  Future<List<Map<String, dynamic>>> getManagerRegistrations(
    int branchId,
  ) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/manager-registrations',
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// 점장 등록
  Future<Map<String, dynamic>> postManager({
    required int branchId,
    int? managerUserId,
    String? managerName,
    String? managerPhoneNumber,
  }) async {
    final data = <String, dynamic>{};
    if (managerUserId != null) data['manager_user_id'] = managerUserId;
    if (managerName != null) data['manager_name'] = managerName;
    if (managerPhoneNumber != null) {
      data['manager_phone_number'] = managerPhoneNumber;
    }
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/manager',
      data: data,
    );
    return res.data!;
  }

  /// 점장 삭제
  Future<Map<String, dynamic>> deleteManager(int branchId) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/manager',
    );
    return res.data!;
  }

  /// 점장 사전등록 ID 삭제
  Future<Map<String, dynamic>> deleteManagerRegistration({
    required int branchId,
    required int registrationId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/manager-registrations/$registrationId',
    );
    return res.data!;
  }

  /// 알림 목록 (경영주)
  Future<List<Map<String, dynamic>>> getAlerts(int branchId) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/alerts',
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// 채용 현황 조회 (경영주)
  Future<Map<String, dynamic>> getRecruitmentStatus(int branchId) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/recruitment-status',
    );
    return res.data!;
  }

  /// 알림 펼침/닫힘
  Future<Map<String, dynamic>> patchAlert({
    required int branchId,
    required int alertId,
    required bool isOpen,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/alerts/$alertId',
      data: {'is_open': isOpen},
    );
    return res.data!;
  }

  /// 오늘 근무자 현황
  Future<Map<String, dynamic>> getTodayWorkers({
    required int branchId,
    required String date,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/today-workers',
      queryParameters: {'date': date},
    );
    return res.data!;
  }

  /// 오늘 근무 상태 변경
  Future<Map<String, dynamic>> putTodayWorkerStatus({
    required int branchId,
    required String workDate,
    required String timeLabel,
    required String workerName,
    required String status,
    String? memo,
  }) async {
    final res = await _apiClient.dio.put<Map<String, dynamic>>(
      '/owner/home/branches/$branchId/today-workers/status',
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
      '/owner/home/branches/$branchId/today-workers/$statusId/memo',
    );
    return res.data!;
  }
}
