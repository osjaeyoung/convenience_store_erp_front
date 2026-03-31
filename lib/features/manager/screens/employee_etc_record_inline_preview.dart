import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employee_etc_file_preview_common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 기타자료 조회 — 파일을 테두리 없이 바로 표시
class EtcRecordInlineFilePreview extends StatefulWidget {
  const EtcRecordInlineFilePreview({
    super.key,
    required this.fileUrl,
    this.height = 320,
    this.displayFileName,
    this.loadBytes,
  });

  final String fileUrl;
  final double height;
  final String? displayFileName;

  /// 지정 시 S3 URL 대신 이 콜백으로 바이트 로드 (예: Bearer 스트리밍 API — 스펙 ##26-1)
  final Future<Uint8List> Function()? loadBytes;

  @override
  State<EtcRecordInlineFilePreview> createState() =>
      _EtcRecordInlineFilePreviewState();
}

class _EtcRecordInlineFilePreviewState extends State<EtcRecordInlineFilePreview> {
  Future<Uint8List>? _bytesFuture;

  Future<Uint8List> _ensureBytes() =>
      _bytesFuture ??= widget.loadBytes?.call() ??
          EtcFilePreviewCommon.fetchBytes(widget.fileUrl);

  @override
  void didUpdateWidget(EtcRecordInlineFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUrl != widget.fileUrl ||
        oldWidget.loadBytes != widget.loadBytes) {
      _bytesFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = EtcFilePreviewCommon.toAbsoluteFileUrl(widget.fileUrl);
    final name = widget.displayFileName?.trim();

    Widget body;
    if (widget.loadBytes != null) {
      body = FutureBuilder<Uint8List>(
        future: _ensureBytes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _errorText(snap.error!);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data!;
          if (EtcFilePreviewCommon.looksLikePdf(b)) {
            return _pdfPreview(bytes: b);
          }
          return FutureBuilder<bool>(
            future: EtcFilePreviewCommon.canDecodeAsImage(b),
            builder: (context, imgSnap) {
              if (!imgSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (imgSnap.data != true) {
                return _unsupported();
              }
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.memory(b, fit: BoxFit.contain),
                ),
              );
            },
          );
        },
      );
    } else if (EtcFilePreviewCommon.isImageUrl(url)) {
      body = InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Padding(
                padding: EdgeInsets.all(32.r),
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _bytesFallbackPreview();
            },
          ),
        ),
      );
    } else if (EtcFilePreviewCommon.isPdfUrl(url)) {
      body = _pdfPreview();
    } else {
      body = FutureBuilder<Uint8List>(
        future: _ensureBytes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _errorText(snap.error!);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data!;
          if (EtcFilePreviewCommon.looksLikePdf(b)) {
            return _pdfPreview(bytes: b);
          }
          return FutureBuilder<bool>(
            future: EtcFilePreviewCommon.canDecodeAsImage(b),
            builder: (context, imgSnap) {
              if (!imgSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (imgSnap.data != true) {
                return _unsupported();
              }
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.memory(b, fit: BoxFit.contain),
                ),
              );
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null && name.isNotEmpty) ...[
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: ColoredBox(
              color: AppColors.grey25,
              child: body,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pdfPreview({Uint8List? bytes}) {
    final w = MediaQuery.sizeOf(context).width - 40;
    if (bytes != null) {
      return PdfPreview(
        build: (_) async => bytes,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: w,
        pdfFileName: 'document.pdf',
      );
    }
    return FutureBuilder<Uint8List>(
      future: _ensureBytes(),
      builder: (context, snap) {
        if (snap.hasError) return _errorText(snap.error!);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: (_) async => snap.data!,
          allowPrinting: false,
          allowSharing: false,
          useActions: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          maxPageWidth: w,
          pdfFileName: 'document.pdf',
        );
      },
    );
  }

  Widget _bytesFallbackPreview() {
    return FutureBuilder<Uint8List>(
      future: _ensureBytes(),
      builder: (context, snap) {
        if (snap.hasError) return _errorText(snap.error!);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: Image.memory(snap.data!, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  Widget _errorText(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Text(
          '불러오지 못했습니다.\n$e',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _unsupported() {
    return Center(
      child: Text(
        '이 형식은 미리보기를 지원하지 않습니다.',
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
