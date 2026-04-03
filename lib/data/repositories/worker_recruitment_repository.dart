import '../models/worker/worker_recruitment_models.dart';
import '../network/api_client.dart';

/// 근로자 개인 공간의 채용 관련 API
class WorkerRecruitmentRepository {
  WorkerRecruitmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WorkerRecruitmentPostingPage> getPostings({
    String? keyword,
    String? region,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/recruitment/postings',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
        'page': page,
        'page_size': pageSize,
      },
    );
    return WorkerRecruitmentPostingPage.fromJson(res.data ?? const {});
  }

  Future<WorkerRecruitmentPostingDetail> getPostingDetail({
    required int postingId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/recruitment/postings/$postingId',
    );
    return WorkerRecruitmentPostingDetail.fromJson(res.data ?? const {});
  }

  Future<WorkerRecruitmentApplyOptions> getApplyOptions({
    required int postingId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/recruitment/postings/$postingId/apply-options',
    );
    return WorkerRecruitmentApplyOptions.fromJson(res.data ?? const {});
  }

  Future<WorkerRecruitmentApplicationCreateResult> createApplication({
    required int postingId,
    required int resumeId,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/worker/recruitment/postings/$postingId/applications',
      data: {'resume_id': resumeId},
    );
    return WorkerRecruitmentApplicationCreateResult.fromJson(
      res.data ?? const {},
    );
  }

  Future<WorkerRecruitmentApplicationPage> getApplications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/recruitment/applications',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return WorkerRecruitmentApplicationPage.fromJson(res.data ?? const {});
  }

  Future<WorkerResumePage> getResumes() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/resumes',
    );
    return WorkerResumePage.fromJson(res.data ?? const {});
  }
}
