import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 급여명세 첨부 파일 메타 생성(S3).
/// 백엔드가 요구하는 `file_key`, `file_url`, `file_name` 형태를 만든다.
///
/// 참고:
/// - 실제 파일 업로드(예: presigned PUT)는 별도 업로드 API 연동이 필요하다.
/// - `S3_PUBLIC_BASE_URL`이 설정되어 있으면 `file_url`을 자동 구성한다.
class PayrollFileStorageService {
  PayrollFileStorageService();

  /// 스펙 예시와 유사한 경로: `payroll/branch-{id}/employee-{id}/...`
  PayrollUploadedAttachment buildAttachmentMetadata({
    required int branchId,
    required int employeeId,
    required PlatformFile file,
  }) {
    final originalName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final safeSegment = _safeFileName(originalName);
    final objectName = '${DateTime.now().millisecondsSinceEpoch}_$safeSegment';
    final fileKey = 'payroll/branch-$branchId/employee-$employeeId/$objectName';

    final base = dotenv.env['S3_PUBLIC_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) {
      throw StateError(
        'S3_PUBLIC_BASE_URL이 비어 있습니다. '
        'presigned 업로드 API 연동 또는 공개 URL 베이스 설정이 필요합니다.',
      );
    }
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final fileUrl = '$normalizedBase/$fileKey';

    return PayrollUploadedAttachment(
      fileKey: fileKey,
      fileUrl: fileUrl,
      fileName: originalName,
    );
  }

  /// 근로계약서 등 S3 object key — `contracts/branch-{id}/employee-{id}/...`
  PayrollUploadedAttachment buildContractsAttachmentMetadata({
    required int branchId,
    required int employeeId,
    required PlatformFile file,
  }) {
    final originalName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final safeSegment = _safeFileName(originalName);
    final objectName = '${DateTime.now().millisecondsSinceEpoch}_$safeSegment';
    final fileKey =
        'contracts/branch-$branchId/employee-$employeeId/$objectName';

    final base = dotenv.env['S3_PUBLIC_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) {
      throw StateError(
        'S3_PUBLIC_BASE_URL이 비어 있습니다. '
        'presigned 업로드 API 연동 또는 공개 URL 베이스 설정이 필요합니다.',
      );
    }
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final fileUrl = '$normalizedBase/$fileKey';

    return PayrollUploadedAttachment(
      fileKey: fileKey,
      fileUrl: fileUrl,
      fileName: originalName,
    );
  }

  static String _safeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[/\\]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

class PayrollUploadedAttachment {
  const PayrollUploadedAttachment({
    required this.fileKey,
    required this.fileUrl,
    required this.fileName,
  });

  final String fileKey;
  final String fileUrl;
  final String fileName;

  Map<String, dynamic> toApiMap() => {
        'file_key': fileKey,
        'file_url': fileUrl,
        'file_name': fileName,
      };
}
