import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/region/region_api_query.dart';
import '../models/recruitment/recruitment_models.dart';
import '../models/worker/worker_recruitment_models.dart';
import '../network/api_client.dart';

/// 근로자 개인 공간의 채용 관련 API
class WorkerRecruitmentRepository {
  WorkerRecruitmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WorkerRecruitmentPostingPage> getPostings({
    String? keyword,
    List<String>? regions,
    int page = 1,
    int pageSize = 20,
  }) async {
    final regionParam = regionQueryParamCommaJoined(regions);
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/recruitment/postings',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (regionParam != null) 'region': regionParam,
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

  Future<WorkerResumeFormData> getResumeTemplate() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/resumes/template',
    );
    return WorkerResumeFormData.fromJson(res.data ?? const {});
  }

  Future<WorkerResumeFormData> getResumeDetail({required int resumeId}) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/worker/resumes/$resumeId',
    );
    return WorkerResumeFormData.fromJson(res.data ?? const {});
  }

  Future<String> uploadWorkerProfileImage({required PlatformFile file}) async {
    final formData = FormData.fromMap({
      'file': await _multipartFile(file),
      'type': 'user_profile_image',
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
    final url = res.data?['file_url']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: '프로필 이미지 업로드 URL이 비어 있습니다.',
      );
    }
    return url;
  }

  Future<void> updateMyProfileImage({required String profileImageUrl}) async {
    await _apiClient.dio.patch<Map<String, dynamic>>(
      '/me/account',
      data: {'profile_image_url': profileImageUrl.trim()},
    );
  }

  /// 근로자 개인공간 채팅 목록: 계약서별 목록이 아니라 지점-근로자 1:1 통합 채팅방 목록
  Future<RecruitmentChatPage> getRecruitmentChats() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/chats');
    return RecruitmentChatPage.fromJson(res.data ?? const {});
  }

  Future<RecruitmentChatMessagePage> getRecruitmentChatMessages({
    required int chatId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/chats/$chatId/messages',
    );
    return RecruitmentChatMessagePage.fromJson(res.data ?? const {});
  }

  /// 채팅방 상세 진입 후 상대방 메시지를 읽음 처리
  Future<void> markRecruitmentChatRead({required int chatId}) async {
    await _apiClient.dio.patch<Map<String, dynamic>>('/chats/$chatId/read');
  }

  Future<RecruitmentChatMessage> sendRecruitmentChatMessage({
    required int chatId,
    required String text,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      data: {'text': text},
    );
    final data = res.data ?? const {};
    final rawMessage = data['message'];
    if (rawMessage is Map) {
      return RecruitmentChatMessage.fromJson(
        Map<String, dynamic>.from(rawMessage),
      );
    }
    if (data.isNotEmpty) {
      return RecruitmentChatMessage.fromJson(data);
    }
    return RecruitmentChatMessage(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      senderRole: 'worker',
      messageType: 'text',
      text: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> deleteRecruitmentChat({required int chatId}) async {
    await _apiClient.dio.delete<Map<String, dynamic>>('/chats/$chatId');
  }

  Future<WorkerResumeFormData> createResume({
    String? educationLevel,
    String? educationStatus,
    String? careerType,
    String? selfIntroduction,
    String? resumeRegionPath,
    String? resumeAddressDetail,
    required List<Map<String, dynamic>> careerEntries,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/worker/resumes',
      data: {
        if (educationLevel != null && educationLevel.trim().isNotEmpty)
          'education_level': educationLevel.trim(),
        if (educationStatus != null && educationStatus.trim().isNotEmpty)
          'education_status': educationStatus.trim(),
        if (careerType != null && careerType.trim().isNotEmpty)
          'career_type': careerType.trim(),
        if (selfIntroduction != null)
          'self_introduction': selfIntroduction.trim(),
        if (resumeRegionPath != null && resumeRegionPath.trim().isNotEmpty)
          'resume_region_path': resumeRegionPath.trim(),
        if (resumeAddressDetail != null && resumeAddressDetail.trim().isNotEmpty)
          'resume_address_detail': resumeAddressDetail.trim(),
        'career_entries': careerEntries,
      },
    );
    return WorkerResumeFormData.fromJson(res.data ?? const {});
  }

  Future<WorkerResumeFormData> updateResume({
    required int resumeId,
    String? educationLevel,
    String? educationStatus,
    String? careerType,
    String? selfIntroduction,
    String? resumeRegionPath,
    String? resumeAddressDetail,
    required List<Map<String, dynamic>> careerEntries,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/worker/resumes/$resumeId',
      data: {
        if (educationLevel != null && educationLevel.trim().isNotEmpty)
          'education_level': educationLevel.trim(),
        if (educationStatus != null && educationStatus.trim().isNotEmpty)
          'education_status': educationStatus.trim(),
        if (careerType != null && careerType.trim().isNotEmpty)
          'career_type': careerType.trim(),
        if (selfIntroduction != null)
          'self_introduction': selfIntroduction.trim(),
        if (resumeRegionPath != null && resumeRegionPath.trim().isNotEmpty)
          'resume_region_path': resumeRegionPath.trim(),
        if (resumeAddressDetail != null && resumeAddressDetail.trim().isNotEmpty)
          'resume_address_detail': resumeAddressDetail.trim(),
        'career_entries': careerEntries,
      },
    );
    return WorkerResumeFormData.fromJson(res.data ?? const {});
  }

  Future<void> deleteResume({required int resumeId}) async {
    await _apiClient.dio.delete<Map<String, dynamic>>(
      '/worker/resumes/$resumeId',
    );
  }

  Future<WorkerContractChatPage> getContractChats({
    int? branchId,
    int? employeeId,
    String? chatStatus,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/contract-chats',
      queryParameters: {
        if (branchId != null) 'branch_id': branchId,
        if (employeeId != null) 'employee_id': employeeId,
        if (chatStatus != null && chatStatus.trim().isNotEmpty)
          'chat_status': chatStatus.trim(),
      },
    );
    return WorkerContractChatPage.fromJson(res.data ?? const {});
  }

  Future<WorkerContractChatDetail> getContractChatDetail({
    required int contractId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/contract-chats/$contractId',
    );
    return WorkerContractChatDetail.fromJson(res.data ?? const {});
  }

  /// 계약 채팅 삭제 — `DELETE /contract-chats/{contract_id}` (`api_spec_contract_chat.md` §3-1)
  Future<WorkerContractChatDeleteResult> deleteContractChat({
    required int contractId,
  }) async {
    final res = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/contract-chats/$contractId',
    );
    final data = res.data;
    if (data == null || data.isEmpty) {
      return const WorkerContractChatDeleteResult(deleted: true);
    }
    final result = WorkerContractChatDeleteResult.fromJson(data);
    if (!result.deleted) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: '계약 채팅 삭제에 실패했습니다.',
      );
    }
    return result;
  }

  Future<WorkerContractChatDocument> getContractChatDocument({
    required int contractId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/contract-chats/$contractId/document',
    );
    return WorkerContractChatDocument.fromJson(res.data ?? const {});
  }

  Future<WorkerContractChatDocument> patchContractChatDocument({
    required int contractId,
    required String action,
    required Map<String, dynamic> formValues,
    bool mergeFormValues = true,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/contract-chats/$contractId/document',
      data: {
        'action': action,
        'form_values': formValues,
        'merge_form_values': mergeFormValues,
      },
    );
    return WorkerContractChatDocument.fromJson(res.data ?? const {});
  }

  /// 계약 채팅에 메시지 전송
  Future<WorkerContractChatMessage> sendContractChatMessage({
    required int contractId,
    required String text,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/contract-chats/$contractId/messages',
      data: {'text': text},
    );
    final data = res.data ?? const {};
    final rawMessage = data['message'];
    if (rawMessage is Map) {
      return WorkerContractChatMessage.fromJson(
        Map<String, dynamic>.from(rawMessage),
      );
    }
    if (data.isNotEmpty) {
      return WorkerContractChatMessage.fromJson(data);
    }
    return WorkerContractChatMessage(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      senderRole: 'worker',
      messageType: 'text',
      text: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<WorkerContractChatDownloadResult> downloadContractChatDocument({
    required int contractId,
  }) async {
    final res = await _apiClient.dio.get(
      '/contract-chats/$contractId/download',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
      ),
    );
    final raw = res.data;
    final bytes = raw is Uint8List
        ? raw
        : raw is List<int>
            ? Uint8List.fromList(raw)
            : Uint8List(0);
    final contentType = res.headers.value(Headers.contentTypeHeader);
    final contentDisposition = res.headers.value('content-disposition');
    final fileName = _extractFileName(contentDisposition);
    return WorkerContractChatDownloadResult(
      bytes: bytes,
      contentType: contentType,
      fileName: fileName,
    );
  }

  static String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;
    final utf8Match =
        RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
            .firstMatch(contentDisposition);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1) ?? '');
    }
    final quotedMatch =
        RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(contentDisposition);
    if (quotedMatch != null) return quotedMatch.group(1);
    final plainMatch =
        RegExp(r'filename=([^;]+)', caseSensitive: false).firstMatch(contentDisposition);
    if (plainMatch != null) return plainMatch.group(1)?.trim();
    return null;
  }

  static Future<MultipartFile> _multipartFile(PlatformFile file) async {
    final name = file.name.trim().isEmpty ? 'profile_image' : file.name.trim();
    final contentType = _multipartMediaType(name);
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
    throw StateError('프로필 이미지를 읽을 수 없습니다. 다시 선택해 주세요.');
  }

  static DioMediaType? _multipartMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return DioMediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    return null;
  }
}

class WorkerContractChatDownloadResult {
  const WorkerContractChatDownloadResult({
    required this.bytes,
    this.contentType,
    this.fileName,
  });

  final Uint8List bytes;
  final String? contentType;
  final String? fileName;
}
