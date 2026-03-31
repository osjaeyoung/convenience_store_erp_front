import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/manager_home/manager_alert.dart';
import '../models/manager_home/manager_branch.dart';
import '../models/manager_home/today_worker.dart';
import '../models/recruitment/recruitment_models.dart';
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

  /// 채용 공고 이미지 업로드
  Future<RecruitmentUploadResult> uploadRecruitmentFile({
    required PlatformFile file,
    String type = 'posting_profile_image',
  }) async {
    final formData = FormData.fromMap({
      'file': await _recruitmentMultipartFile(file),
      'type': type,
    });
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/recruitment/files',
      data: formData,
      options: Options(
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return RecruitmentUploadResult.fromJson(res.data!);
  }

  /// 구인구직 홈 조회
  Future<RecruitmentHomeResponse> getRecruitmentHome({
    required int branchId,
    String? keyword,
    String? gender,
    int? ageMin,
    int? ageMax,
    String? region,
    double? minRating,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/home',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender,
        if (ageMin != null) 'age_min': ageMin,
        if (ageMax != null) 'age_max': ageMax,
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
        if (minRating != null) 'min_rating': minRating,
        'page': page,
        'page_size': pageSize,
      },
    );
    return RecruitmentHomeResponse.fromJson(res.data!);
  }

  /// 구직자 프로필 열람 기록 저장
  Future<void> openJobSeekerProfile({
    required int branchId,
    required int employeeId,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/job-seekers/$employeeId/open',
    );
  }

  /// 구직자 프로필 조회
  Future<JobSeekerProfile> getJobSeekerProfile({
    required int branchId,
    required int employeeId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/job-seekers/$employeeId',
    );
    return JobSeekerProfile.fromJson(res.data!);
  }

  /// 구직자 리뷰 상세 조회
  Future<JobSeekerReviewPage> getJobSeekerReviews({
    required int branchId,
    required int employeeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/job-seekers/$employeeId/reviews',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return JobSeekerReviewPage.fromJson(res.data!);
  }

  /// 채용 게시판 목록 조회
  Future<RecruitmentPostingPage> getRecruitmentPostings({
    required int branchId,
    String? keyword,
    String? region,
    bool includeDraft = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
        if (includeDraft) 'include_draft': true,
        'page': page,
        'page_size': pageSize,
      },
    );
    return RecruitmentPostingPage.fromJson(res.data!);
  }

  /// 내 채용 게시글 목록 조회
  Future<RecruitmentPostingPage> getMyRecruitmentPostings({
    required int branchId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/my-postings',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return RecruitmentPostingPage.fromJson(res.data!);
  }

  /// 채용 공고 상세 조회
  Future<RecruitmentPostingDetail> getRecruitmentPostingDetail({
    required int branchId,
    required int postingId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/$postingId',
    );
    return RecruitmentPostingDetail.fromJson(res.data!);
  }

  /// 채용 공고 미리보기
  Future<RecruitmentPostingDetail> previewRecruitmentPosting({
    required int branchId,
    required RecruitmentPostingRequest request,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/preview',
      data: request.toJson(),
    );
    return RecruitmentPostingDetail.fromJson(res.data!);
  }

  /// 채용 공고 등록 (임시저장)
  Future<RecruitmentPostingSaveResult> createRecruitmentPosting({
    required int branchId,
    required RecruitmentPostingRequest request,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings',
      data: request.toJson(),
    );
    return RecruitmentPostingSaveResult.fromJson(res.data!);
  }

  /// 채용 공고 게시
  Future<RecruitmentPostingSaveResult> publishRecruitmentPosting({
    required int branchId,
    required int postingId,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/$postingId/publish',
    );
    return RecruitmentPostingSaveResult.fromJson(res.data!);
  }

  /// 채용 공고 수정
  Future<RecruitmentPostingDetail> patchRecruitmentPosting({
    required int branchId,
    required int postingId,
    required RecruitmentPostingRequest request,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/$postingId',
      data: request.toJson(),
    );
    return RecruitmentPostingDetail.fromJson(res.data!);
  }

  /// 채용 공고 삭제
  Future<Map<String, dynamic>> deleteRecruitmentPosting({
    required int branchId,
    required int postingId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/$postingId',
    );
    return res.data ?? const {};
  }

  /// 지원현황 조회 (공고별)
  Future<RecruitmentApplicationPage> getRecruitmentApplications({
    required int branchId,
    required int postingId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/postings/$postingId/applications',
    );
    return RecruitmentApplicationPage.fromJson(res.data!);
  }

  /// 지원자 상세 조회
  Future<JobSeekerProfile> getRecruitmentApplicationDetail({
    required int branchId,
    required int applicationId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/applications/$applicationId',
    );
    return JobSeekerProfile.fromJson(res.data!);
  }

  /// 지원자 삭제
  Future<Map<String, dynamic>> deleteRecruitmentApplication({
    required int branchId,
    required int applicationId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/recruitment/branches/$branchId/applications/$applicationId',
    );
    return res.data ?? const {};
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

  static Future<MultipartFile> _recruitmentMultipartFile(PlatformFile file) async {
    final name = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final contentType = _recruitmentMultipartMediaType(name);
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
    throw StateError('첨부 이미지를 읽을 수 없습니다. 다시 선택해 주세요.');
  }

  static DioMediaType? _recruitmentMultipartMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return DioMediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    return null;
  }
}
