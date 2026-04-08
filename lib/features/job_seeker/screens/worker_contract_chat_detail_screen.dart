import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';
import '../widgets/worker_contract_chat_leave_dialog.dart';
import 'worker_contract_document_screen.dart';

/// Figma: 계약채팅 상세 — 앱바·문서 말풍선(밑줄)·타임스탬프
class WorkerContractChatDetailScreen extends StatefulWidget {
  const WorkerContractChatDetailScreen({super.key, required this.contractId});

  final int contractId;

  @override
  State<WorkerContractChatDetailScreen> createState() =>
      _WorkerContractChatDetailScreenState();
}

class _WorkerContractChatDetailScreenState
    extends State<WorkerContractChatDetailScreen> {
  static final DateFormat _timeFormat = DateFormat('a h:mm', 'ko_KR');

  bool _loading = true;
  bool _changed = false;
  bool _deleting = false;
  Object? _error;
  WorkerContractChatDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await context
          .read<WorkerRecruitmentRepository>()
          .getContractChatDetail(contractId: widget.contractId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return _timeFormat.format(dt.toLocal());
  }

  Future<void> _openDocument() async {
    final room = _detail?.thread.branchName;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerContractDocumentScreen(
          contractId: widget.contractId,
          roomTitle: (room != null && room.isNotEmpty) ? room : null,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showWorkerContractChatLeaveDialog(context);
    if (!confirmed || !mounted) return;
    await _deleteChatRoom();
  }

  Future<void> _deleteChatRoom() async {
    setState(() => _deleting = true);
    try {
      await context.read<WorkerRecruitmentRepository>().deleteContractChat(
            contractId: widget.contractId,
          );
      if (!mounted) return;
      _changed = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약 채팅이 삭제되었습니다.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountDioMessage(error))),
      );
    }
  }

  static TextStyle get _appBarTitleStyle => AppTypography.appBarTitle;

  static TextStyle get _timeStyle => AppTypography.bodyXSmallM.copyWith(
        color: const Color(0xFFC7C9D7),
        height: 16 / 10,
      );

  /// 말풍선이 화면을 넘지 않도록 상한만 둔다. 너비는 글자 길이(본질적 폭)에 맞춘다.
  double _maxBubbleWidth(BuildContext context, {required bool incoming}) {
    final w = MediaQuery.sizeOf(context).width;
    final listPad = 20.w * 2;
    final avatar = incoming ? (36.r + 10.w) : 0.0;
    final timeReserve = 56.w;
    return (w - listPad - avatar - timeReserve).clamp(72.w, w);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final isCompleted = detail?.thread.isCompleted == true;
    return Scaffold(
      backgroundColor: isCompleted ? AppColors.grey0 : AppColors.grey0Alt,
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
          detail?.thread.branchName ?? '계약채팅',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _appBarTitleStyle,
        ),
        actions: [
          IconButton(
            onPressed: _deleting ? null : _showDeleteDialog,
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 24,
              color: AppColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            workerErrorView(
              message: accountDioMessage(_error!),
              onRetry: _load,
            )
          else
            _buildContent(detail!),
          if (_deleting)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(WorkerContractChatDetail detail) {
    final messages = detail.messages;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        20.w,
        detail.thread.isCompleted ? 45.h : 24.h,
        20.w,
        24.h,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final workerMessage = message.fromWorker;
        final time = _formatTime(message.createdAt);
        final isDocument = message.messageType == 'document';
        final canOpenDocument =
            isDocument &&
            (message.canOpenDocument || detail.canOpenDocument);

        if (workerMessage) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty) ...[
                  Text(time, style: _timeStyle),
                  SizedBox(width: 6.w),
                ],
                _WorkerOutgoingBubble(
                  maxBubbleWidth: _maxBubbleWidth(context, incoming: false),
                  text: message.text,
                  isDocument: isDocument,
                  onTapDocument: canOpenDocument ? _openDocument : null,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CounterpartyAvatar(),
              SizedBox(width: 10.w),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _WorkerIncomingBubble(
                        maxBubbleWidth:
                            _maxBubbleWidth(context, incoming: true),
                        text: message.text,
                        isDocument: isDocument,
                        onTapDocument: canOpenDocument ? _openDocument : null,
                      ),
                      if (time.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Text(
                          time,
                          textAlign: TextAlign.center,
                          style: _timeStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CounterpartyAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey0,
        border: Border.all(color: AppColors.textDisabled, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Icon(
        Icons.person_rounded,
        size: 22.r,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// Figma 2534:10737 — 흰 말풍선, 그림자, 문서 문구는 검정 밑줄
class _WorkerIncomingBubble extends StatelessWidget {
  const _WorkerIncomingBubble({
    required this.maxBubbleWidth,
    required this.text,
    required this.isDocument,
    this.onTapDocument,
  });

  final double maxBubbleWidth;
  final String text;
  final bool isDocument;
  final VoidCallback? onTapDocument;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.textPrimary,
      height: 19 / 14,
    );
    final textStyle = baseStyle;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: IntrinsicWidth(
        child: SizedBox(
          height: 40.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapDocument,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2.r),
                topRight: Radius.circular(10.r),
                bottomLeft: Radius.circular(10.r),
                bottomRight: Radius.circular(10.r),
              ),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: AppColors.grey0,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(2.r),
                    topRight: Radius.circular(10.r),
                    bottomLeft: Radius.circular(10.r),
                    bottomRight: Radius.circular(10.r),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: isDocument
                      ? _DocumentUnderlinedText(
                          text: text,
                          style: textStyle,
                          underlineColor: AppColors.textPrimary,
                        )
                      : Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerOutgoingBubble extends StatelessWidget {
  const _WorkerOutgoingBubble({
    required this.maxBubbleWidth,
    required this.text,
    required this.isDocument,
    this.onTapDocument,
  });

  final double maxBubbleWidth;
  final String text;
  final bool isDocument;
  final VoidCallback? onTapDocument;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.grey0,
      height: 19 / 14,
    );
    final textStyle = baseStyle;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: IntrinsicWidth(
        child: SizedBox(
          height: 40.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapDocument,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                topRight: Radius.circular(2.r),
                bottomLeft: Radius.circular(10.r),
                bottomRight: Radius.circular(10.r),
              ),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    topRight: Radius.circular(2.r),
                    bottomLeft: Radius.circular(10.r),
                    bottomRight: Radius.circular(10.r),
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: isDocument
                      ? _DocumentUnderlinedText(
                          text: text,
                          style: textStyle,
                          underlineColor: AppColors.grey0,
                        )
                      : Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 문서 메시지 밑줄은 글자와 약간 간격을 두어 표시한다.
class _DocumentUnderlinedText extends StatelessWidget {
  const _DocumentUnderlinedText({
    required this.text,
    required this.style,
    required this.underlineColor,
  });

  final String text;
  final TextStyle style;
  final Color underlineColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: underlineColor, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
