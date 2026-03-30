import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employee_etc_file_preview_common.dart';

/// 기타자료: 제목·작성일 + 파일 미리보기
class EmployeeEtcRecordPreviewScreen extends StatefulWidget {
  const EmployeeEtcRecordPreviewScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.summaryRow,
  });

  final int branchId;
  final int employeeId;
  final Map<String, dynamic> summaryRow;

  @override
  State<EmployeeEtcRecordPreviewScreen> createState() =>
      _EmployeeEtcRecordPreviewScreenState();
}

class _EmployeeEtcRecordPreviewScreenState
    extends State<EmployeeEtcRecordPreviewScreen> {
  Map<String, dynamic> _row = {};
  bool _metaLoading = true;
  String? _fileUrl;
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _row = Map<String, dynamic>.from(widget.summaryRow);
    _ensureMeta();
  }

  Future<void> _ensureMeta() async {
    var url = _row['file_url']?.toString().trim();
    if (url == null || url.isEmpty) {
      final id = _row['record_id'];
      final rid = id is int ? id : (id is num ? id.toInt() : null);
      if (rid != null && mounted) {
        try {
          final repo = context.read<StaffManagementRepository>();
          _row = await repo.getEmployeeRecord(
            branchId: widget.branchId,
            employeeId: widget.employeeId,
            recordType: 'etc',
            recordId: rid,
          );
          url = _row['file_url']?.toString().trim();
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _fileUrl = url;
      _metaLoading = false;
      final u = _fileUrl;
      if (u != null &&
          u.isNotEmpty &&
          !EtcFilePreviewCommon.isImageUrl(u) &&
          !EtcFilePreviewCommon.isPdfUrl(u)) {
        _bytesFuture = EtcFilePreviewCommon.fetchBytes(u);
      }
    });
  }

  static String _formatDateLine(Map<String, dynamic> r) {
    final raw =
        (r['issued_date'] ?? r['created_at'])?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}.$m.$day';
  }

  String get _title => _row['title']?.toString().trim().isNotEmpty == true
      ? _row['title'].toString().trim()
      : '기타 자료';

  String _suggestedDownloadName() => EtcFilePreviewCommon.suggestedDownloadName(
        fileUrl: _fileUrl ?? '',
        recordTitle: _title,
      );

  Widget _buildPreviewBody() {
    final url = _fileUrl;
    if (url == null || url.isEmpty) {
      return Center(
        child: Text(
          '첨부된 파일이 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (EtcFilePreviewCommon.isImageUrl(url)) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.network(
            EtcFilePreviewCommon.toAbsoluteFileUrl(url),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _bytesPreviewFallback(url);
            },
          ),
        ),
      );
    }

    if (EtcFilePreviewCommon.isPdfUrl(url)) {
      return FutureBuilder<Uint8List>(
        future: _bytesFuture ??= EtcFilePreviewCommon.fetchBytes(url),
        builder: (context, snap) {
          if (snap.hasError) {
            return _previewError(snap.error!);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final w = MediaQuery.sizeOf(context).width;
          return PdfPreview(
            build: (_) async => snap.data!,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            maxPageWidth: w - 24,
            pdfFileName: _suggestedDownloadName(),
          );
        },
      );
    }

    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= EtcFilePreviewCommon.fetchBytes(url),
      builder: (context, snap) {
        if (snap.hasError) {
          return _previewError(snap.error!);
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final b = snap.data!;
        if (EtcFilePreviewCommon.looksLikePdf(b)) {
          final w = MediaQuery.sizeOf(context).width;
          return PdfPreview(
            build: (_) async => b,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            maxPageWidth: w - 24,
            pdfFileName: _suggestedDownloadName(),
          );
        }
        return FutureBuilder<bool>(
          future: EtcFilePreviewCommon.canDecodeAsImage(b),
          builder: (context, imgSnap) {
            if (!imgSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (imgSnap.data != true) {
              return _unsupportedPreview(url);
            }
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.memory(
                  b,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _previewError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '미리보기를 불러오지 못했습니다.\n$e',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _bytesPreviewFallback(String url) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= EtcFilePreviewCommon.fetchBytes(url),
      builder: (context, snap) {
        if (snap.hasError) {
          return _previewError(snap.error!);
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(child: Image.memory(snap.data!, fit: BoxFit.contain)),
        );
      },
    );
  }

  Widget _unsupportedPreview(String url) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이 형식은 미리보기를 지원하지 않습니다.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final uri =
                    Uri.parse(EtcFilePreviewCommon.toAbsoluteFileUrl(url));
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('브라우저에서 열기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLine = _formatDateLine(_row);

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.appBarTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateLine.isNotEmpty)
                  Text(
                    '작성일 $dateLine',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (_row['note']?.toString().trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    _row['note'].toString().trim(),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Expanded(
            child: _metaLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPreviewBody(),
          ),
        ],
      ),
    );
  }
}
