import 'dart:typed_data';
import 'dart:ui';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employee_etc_file_preview_common.dart';
import 'employee_etc_record_file_bytes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 파일 선택 직후(로컬 [PlatformFile]) 인라인 미리보기 — 이미지·PDF
class PickedFileInlinePreview extends StatefulWidget {
  const PickedFileInlinePreview({
    super.key,
    required this.file,
    this.height = 320,
    this.onTapReplace,
    this.showFileName = true,
  });

  final PlatformFile file;
  final double height;
  final bool showFileName;

  /// 지정 시 미리보기 탭 → 블러 위에 「파일 변경」 표시
  final VoidCallback? onTapReplace;

  @override
  State<PickedFileInlinePreview> createState() =>
      _PickedFileInlinePreviewState();
}

class _PickedFileInlinePreviewState extends State<PickedFileInlinePreview> {
  Future<Uint8List?>? _bytesFuture;
  bool _showReplaceOverlay = false;

  Future<Uint8List?> _ensureBytes() {
    return _bytesFuture ??= () async {
      final raw = await readEtcPickedFileBytes(widget.file);
      if (raw == null) return null;
      return Uint8List.fromList(raw);
    }();
  }

  @override
  void didUpdateWidget(PickedFileInlinePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.name != widget.file.name ||
        oldWidget.file.size != widget.file.size) {
      _bytesFuture = null;
      _showReplaceOverlay = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.file.name.trim().isEmpty
        ? '첨부 파일'
        : widget.file.name.trim();
    final lower = displayName.toLowerCase();

    Widget body;
    if (EtcFilePreviewCommon.isImageFileName(lower)) {
      body = FutureBuilder<Uint8List?>(
        future: _ensureBytes(),
        builder: (context, snap) {
          if (snap.hasError) return _errorText(snap.error!);
          if (!snap.hasData || snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(child: Image.memory(snap.data!, fit: BoxFit.contain)),
          );
        },
      );
    } else if (lower.endsWith('.pdf')) {
      body = _pdfPreview();
    } else {
      body = FutureBuilder<Uint8List?>(
        future: _ensureBytes(),
        builder: (context, snap) {
          if (snap.hasError) return _errorText(snap.error!);
          if (!snap.hasData || snap.data == null) {
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
                child: Center(child: Image.memory(b, fit: BoxFit.contain)),
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
        if (widget.showFileName) ...[
          Text(
            displayName,
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
              child: widget.onTapReplace == null
                  ? body
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        body,
                        if (_showReplaceOverlay)
                          Positioned.fill(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _showReplaceOverlay = false,
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  child: ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FilledButton(
                                    onPressed: () {
                                      setState(
                                        () => _showReplaceOverlay = false,
                                      );
                                      widget.onTapReplace!();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.grey0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '파일 변경',
                                      style: AppTypography.bodyMediumB.copyWith(
                                        color: AppColors.grey0,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _showReplaceOverlay = true),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pdfPreview({Uint8List? bytes}) {
    final w = MediaQuery.sizeOf(context).width - 32;
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
    return FutureBuilder<Uint8List?>(
      future: _ensureBytes(),
      builder: (context, snap) {
        if (snap.hasError) return _errorText(snap.error!);
        if (!snap.hasData || snap.data == null) {
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

  Widget _errorText(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Text(
          '불러오지 못했습니다.\n${userFriendlyErrorMessage(e)}',
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
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
