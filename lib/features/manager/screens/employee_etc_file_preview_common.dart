import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_config.dart';
import 'employee_etc_record_file_bytes.dart';
import 'employee_etc_record_share.dart';

/// 기타자료 첨부 미리보기 공통 로직
class EtcFilePreviewCommon {
  EtcFilePreviewCommon._();

  /// 서버가 `file_url`을 `/static/uploads/...` 같이 **호스트 없는 경로**로 줄 때가 있음.
  /// [ApiConfig.baseUrl]의 origin(`http://host:port`)과 이어 절대 URL을 만듦.
  /// (`/api/v1` 아래가 아니라 서버 루트 기준 정적 경로)
  static String toAbsoluteFileUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    try {
      final base = Uri.parse(ApiConfig.baseUrl.trim());
      final origin = base.origin;
      if (t.startsWith('/')) return '$origin$t';
      return base.resolve(t).toString();
    } catch (_) {
      return t;
    }
  }

  static String _httpAccessDeniedUserMessage(String absoluteUrl, int? code) {
    final u = absoluteUrl.toLowerCase();
    final isS3 =
        u.contains('amazonaws.com') || u.contains('.s3.') || u.contains('s3://');
    final tail = code != null ? ' (HTTP $code)' : '';
    if (isS3) {
      return '저장된 파일 주소(S3)로는 앱에서 바로 열 수 없습니다$tail.\n'
          '버킷이 비공개인 경우 서버에서 조회용 presigned URL을 내려주거나, '
          'Bearer 인증으로 파일을 내려주는 프록시 API가 필요합니다. '
          '(업로드만 되고 열람 URL이 공개 읽기가 아니면 이 오류가 납니다.)';
    }
    return '파일 열람이 거부되었습니다$tail.\n'
        '저장소 접근 정책 또는 서버에서 내려주는 URL 형식을 확인해 주세요.';
  }

  static Future<Uint8List> fetchBytes(String url) async {
    final absolute = toAbsoluteFileUrl(url);
    final dio = Dio();
    try {
      final res = await dio.get<List<int>>(
        absolute,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      final data = res.data;
      if (data == null) throw StateError('빈 응답입니다.');
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403 || code == 401) {
        throw StateError(_httpAccessDeniedUserMessage(absolute, code));
      }
      if (e.type == DioExceptionType.badResponse && code != null) {
        throw StateError(
          '파일을 불러오지 못했습니다. (HTTP $code)\n${e.message ?? ''}',
        );
      }
      throw StateError(
        '파일을 불러오지 못했습니다.\n${e.message ?? e.toString()}',
      );
    }
  }

  static bool looksLikePdf(Uint8List b) {
    if (b.length < 5) return false;
    return String.fromCharCodes(b.sublist(0, 5)) == '%PDF-';
  }

  static bool isPdfUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.pdf');
  }

  static bool isImageUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  /// 로컬 파일명(또는 경로 끝단) 기준 이미지 여부
  static bool isImageFileName(String name) {
    final path = name.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  static String? _mimeForFileName(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.png')) return 'image/png';
    if (l.endsWith('.jpg') || l.endsWith('.jpeg')) return 'image/jpeg';
    if (l.endsWith('.gif')) return 'image/gif';
    if (l.endsWith('.webp')) return 'image/webp';
    return null;
  }

  static Future<bool> canDecodeAsImage(Uint8List bytes) async {
    try {
      await ui.instantiateImageCodec(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String sanitizeFileNameSegment(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String suggestedDownloadName({
    required String fileUrl,
    required String recordTitle,
  }) {
    if (fileUrl.isNotEmpty) {
      final seg = Uri.tryParse(fileUrl)?.pathSegments;
      if (seg != null && seg.isNotEmpty) {
        final last = seg.last;
        if (last.isNotEmpty) return sanitizeFileNameSegment(last);
      }
    }
    final base = sanitizeFileNameSegment(recordTitle);
    if (isPdfUrl(fileUrl)) {
      return '${base.isEmpty ? 'document' : base}.pdf';
    }
    return '${base.isEmpty ? 'attachment' : base}.dat';
  }

  /// 서버 [fileUrl] 첨부 — 시스템 공유 시트(저장/다운로드)로 내보냄
  static Future<void> downloadAttachment({
    required String fileUrl,
    required String recordTitle,
    Future<Uint8List>? cachedBytesFuture,
  }) async {
    final name = suggestedDownloadName(
      fileUrl: fileUrl,
      recordTitle: recordTitle,
    );

    Future<Uint8List> ensureBytes() async {
      final cached = cachedBytesFuture;
      if (cached != null) return cached;
      return fetchBytes(fileUrl);
    }

    if (isPdfUrl(fileUrl)) {
      final bytes = await ensureBytes();
      await Printing.sharePdf(bytes: bytes, filename: name);
      return;
    }

    if (isImageUrl(fileUrl)) {
      if (kIsWeb) {
        await shareEtcDownload(
          fileUrl: toAbsoluteFileUrl(fileUrl),
          bytes: null,
          fileName: name,
          subject: recordTitle,
        );
      } else {
        final bytes = await ensureBytes();
        await shareEtcDownload(
          fileUrl: fileUrl,
          bytes: bytes,
          fileName: name,
          subject: recordTitle,
        );
      }
      return;
    }

    final bytes = await ensureBytes();
    if (looksLikePdf(bytes)) {
      final pdfName =
          name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
      await Printing.sharePdf(bytes: bytes, filename: pdfName);
      return;
    }
    if (await canDecodeAsImage(bytes)) {
      if (kIsWeb) {
        await shareEtcDownload(
          fileUrl: toAbsoluteFileUrl(fileUrl),
          bytes: null,
          fileName: name,
          subject: recordTitle,
        );
      } else {
        await shareEtcDownload(
          fileUrl: fileUrl,
          bytes: bytes,
          fileName: name,
          subject: recordTitle,
        );
      }
      return;
    }

    final uri = Uri.parse(toAbsoluteFileUrl(fileUrl));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 방금 고른 로컬 파일 — 공유 시트로 내보냄(다운로드/저장)
  static Future<void> downloadLocalPickedFile(
    PlatformFile file, {
    String? subject,
  }) async {
    final raw = await readEtcPickedFileBytes(file);
    if (raw == null) {
      throw StateError('파일을 읽을 수 없습니다. 다시 선택해 주세요.');
    }
    final bytes = Uint8List.fromList(raw);
    var name =
        file.name.trim().isEmpty ? 'attachment' : sanitizeFileNameSegment(file.name);
    final lower = name.toLowerCase();

    if (lower.endsWith('.pdf') || looksLikePdf(bytes)) {
      final fn = lower.endsWith('.pdf') ? name : '$name.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fn);
      return;
    }
    if (isImageFileName(name) || await canDecodeAsImage(bytes)) {
      if (!lower.contains('.')) name = '$name.jpg';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: name,
            mimeType: _mimeForFileName(name),
          ),
        ],
        subject: subject,
      );
      return;
    }
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: name)],
      subject: subject,
    );
  }
}
