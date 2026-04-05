import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class WorkerContractDocumentScreen extends StatefulWidget {
  const WorkerContractDocumentScreen({
    super.key,
    required this.contractId,
    this.roomTitle,
  });

  final int contractId;

  /// 채팅방(지점)명 — 있으면 앱바에 표시하고 본문 상단에 계약서 제목 구역을 둠 (Figma 계약채팅)
  final String? roomTitle;

  @override
  State<WorkerContractDocumentScreen> createState() =>
      _WorkerContractDocumentScreenState();
}

class _WorkerContractDocumentScreenState extends State<WorkerContractDocumentScreen> {
  static const Color _autoFillOrange = Color(0xFFFF8D28);
  static const String _autoFillMarker = '자동 기입';

  static const Map<String, String> _defaultLabels = <String, String>{
    'worker_address': '근로자 주소',
    'worker_phone': '근로자 연락처',
    'worker_signature_text': '근로자 서명',
  };

  bool _loading = true;
  bool _submitting = false;
  bool _downloading = false;
  bool _changed = false;
  String? _error;
  WorkerContractChatDocument? _document;
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await context
          .read<WorkerRecruitmentRepository>()
          .getContractChatDocument(contractId: widget.contractId);
      if (!mounted) return;
      _syncControllers(doc);
      setState(() {
        _document = doc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _syncControllers(WorkerContractChatDocument doc) {
    for (final key in doc.workerFieldKeys) {
      final current = _controllers[key];
      final nextValue = doc.formValues[key]?.toString() ?? '';
      if (current == null) {
        _controllers[key] = TextEditingController(text: nextValue);
      } else if (current.text != nextValue) {
        current.text = nextValue;
      }
    }
  }

  String _labelFor(String key, WorkerContractChatDocument doc) {
    return doc.requiredFieldLabels[key] ?? _defaultLabels[key] ?? key;
  }

  /// `____` 구간은 검은 밑줄, `자동 기입`은 주황 글자+밑줄 (Figma 표준 근로 계약서)
  static List<TextSpan> _previewSpans(String text, TextStyle base) {
    final orangeStyle = base.copyWith(
      color: _autoFillOrange,
      decoration: TextDecoration.underline,
      decorationColor: _autoFillOrange,
    );
    TextStyle underlinedUnderscore(TextStyle s) => s.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textPrimary,
        );

    List<TextSpan> underlineUnderscores(String chunk) {
      final reg = RegExp(r'_+');
      final out = <TextSpan>[];
      var i = 0;
      for (final m in reg.allMatches(chunk)) {
        if (m.start > i) {
          out.add(TextSpan(text: chunk.substring(i, m.start), style: base));
        }
        out.add(TextSpan(
          text: chunk.substring(m.start, m.end),
          style: underlinedUnderscore(base),
        ));
        i = m.end;
      }
      if (i < chunk.length) {
        out.add(TextSpan(text: chunk.substring(i), style: base));
      }
      return out;
    }

    final result = <TextSpan>[];
    var rest = text;
    while (true) {
      final idx = rest.indexOf(_autoFillMarker);
      if (idx < 0) {
        result.addAll(underlineUnderscores(rest));
        break;
      }
      if (idx > 0) {
        result.addAll(underlineUnderscores(rest.substring(0, idx)));
      }
      result.add(TextSpan(text: _autoFillMarker, style: orangeStyle));
      rest = rest.substring(idx + _autoFillMarker.length);
    }
    return result;
  }

  String _prettyAction(String? action) {
    switch (action) {
      case 'complete':
        return '전송';
      case 'send_to_worker':
        return '전송';
      case 'save_draft':
        return '저장';
      default:
        return '전송';
    }
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is Map) {
          final msg = detail['message']?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
        final msg = data['message']?.toString() ?? data['detail']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return error.message ?? '요청에 실패했습니다.';
    }
    return error.toString();
  }

  Future<void> _submit() async {
    final doc = _document;
    if (doc == null) return;
    final action = doc.primaryAction ?? 'complete';
    final formValues = Map<String, dynamic>.from(doc.formValues);

    for (final entry in _controllers.entries) {
      formValues[entry.key] = entry.value.text.trim();
    }

    setState(() => _submitting = true);
    try {
      final next = await context.read<WorkerRecruitmentRepository>().patchContractChatDocument(
            contractId: widget.contractId,
            action: action,
            formValues: formValues,
            mergeFormValues: true,
          );
      if (!mounted) return;
      _syncControllers(next);
      _changed = true;
      setState(() {
        _document = next;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.primaryAction == 'complete' ? '작성이 완료되었습니다.' : '저장되었습니다.')),
      );
      if (next.chatStatus == 'completed') {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final result = await context
          .read<WorkerRecruitmentRepository>()
          .downloadContractChatDocument(contractId: widget.contractId);
      if (!mounted) return;
      final contentType = result.contentType?.toLowerCase() ?? '';
      final fileName = result.fileName ??
          (contentType.contains('text') ? 'contract_${widget.contractId}.txt' : 'contract_${widget.contractId}.pdf');
      await Printing.sharePdf(bytes: result.bytes, filename: fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드에 실패했습니다: ${_messageFromError(error)}')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    final canSubmit = doc != null &&
        doc.primaryAction != null &&
        doc.chatStatus != 'completed' &&
        doc.editableFieldKeys.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_changed),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          _appBarTitle(doc),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyLargeM.copyWith(
            fontSize: 18.sp,
            height: 24 / 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : _buildContent(doc!),
      bottomNavigationBar: doc == null
          ? null
          : SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: SizedBox(
                height: 56.h,
                child: doc.chatStatus == 'completed'
                    ? OutlinedButton(
                        onPressed: _downloading ? null : _download,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          foregroundColor: AppColors.primary,
                        ),
                        child: _downloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                '다운로드',
                                style: AppTypography.bodyLargeB.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                      )
                    : FilledButton(
                        onPressed: (canSubmit && !_submitting) ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.grey100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.grey0,
                                ),
                              )
                            : Text(
                                doc.primaryActionLabel ?? _prettyAction(doc.primaryAction),
                                style: AppTypography.bodyLargeB.copyWith(
                                  color: AppColors.grey0,
                                ),
                              ),
                      ),
              ),
            ),
    );
  }

  String _appBarTitle(WorkerContractChatDocument? doc) {
    final room = widget.roomTitle?.trim();
    if (room != null && room.isNotEmpty) return room;
    return doc?.title ?? '표준 근로 계약서';
  }

  Widget _buildContent(WorkerContractChatDocument doc) {
    final editableKeys = doc.editableFieldKeys;
    final showRoomHeader =
        widget.roomTitle != null && widget.roomTitle!.trim().isNotEmpty;
    final previewRaw = (doc.documentPreviewText ?? '').trim();
    final previewStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.textPrimary,
      height: 25 / 14,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showRoomHeader)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              decoration: const BoxDecoration(
                color: AppColors.grey0,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Text(
                doc.title,
                style: AppTypography.bodyLargeM.copyWith(
                  fontSize: 18.sp,
                  height: 24 / 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showRoomHeader) ...[
                  Text(
                    doc.title,
                    style: AppTypography.bodyLargeM.copyWith(
                      fontSize: 18.sp,
                      height: 24 / 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                Text.rich(
                  TextSpan(
                    style: previewStyle,
                    children: previewRaw.isEmpty
                        ? [
                            TextSpan(
                              text: '문서 미리보기를 불러오는 중입니다.',
                              style: previewStyle,
                            ),
                          ]
                        : _previewSpans(previewRaw, previewStyle),
                  ),
                ),
                if (editableKeys.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  Text(
                    '입력 항목',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...editableKeys.map((key) {
              final required = doc.requiredFieldKeys.contains(key);
              final controller = _controllers[key] ?? TextEditingController();
              _controllers[key] = controller;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      required ? '${_labelFor(key, doc)} *' : _labelFor(key, doc),
                      style: AppTypography.bodySmallM.copyWith(
                        color: required ? const Color(0xFFFF8D28) : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: controller,
                      minLines: key == 'worker_address' ? 2 : 1,
                      maxLines: key == 'worker_address' ? 3 : 1,
                      decoration: InputDecoration(
                        hintText: _labelFor(key, doc),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.grey0,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
                  }),
                ],
                if (doc.chatStatus == 'completed') ...[
                  SizedBox(height: 10.h),
                  Text(
                    '작성이 완료된 문서입니다.',
                    style: AppTypography.bodySmallR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
