import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/chat/recruitment_chat_read_store.dart';
import '../../../core/datetime/api_datetime_format.dart';
import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/recruitment_inquiry_chat_composer.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';
import '../widgets/worker_contract_chat_leave_dialog.dart';
import 'worker_contract_document_screen.dart';

class WorkerRecruitmentChatScreen extends StatefulWidget {
  const WorkerRecruitmentChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.profileImageUrl,
  });

  final int chatId;
  final String title;
  final String? profileImageUrl;

  @override
  State<WorkerRecruitmentChatScreen> createState() =>
      _WorkerRecruitmentChatScreenState();
}

class _WorkerRecruitmentChatScreenState
    extends State<WorkerRecruitmentChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _deleting = false;
  Object? _error;
  RecruitmentChatSummary? _chat;
  String _currentUserRole = 'worker';
  List<RecruitmentChatMessage> _messages = const [];
  Timer? _pollTimer;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _refreshMessages(showLoading: true, jumpToBottom: true);
  }

  Future<void> _refreshMessages({
    bool showLoading = false,
    bool jumpToBottom = false,
  }) async {
    if (!showLoading && _loading) return;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await context
          .read<WorkerRecruitmentRepository>()
          .getRecruitmentChatMessages(chatId: widget.chatId);
      if (!mounted) return;
      final changed =
          _messageSignature(page.messages) != _messageSignature(_messages);
      final hadUnread = page.chat.unreadCount > 0;
      setState(() {
        _chat = page.chat.copyWith(unreadCount: 0);
        _currentUserRole = page.currentUserRole;
        _messages = page.messages;
        _loading = false;
        _error = null;
      });
      await _markRead(widget.chatId);
      await RecruitmentChatReadStore.markReadThrough(
        chatId: widget.chatId,
        lastMessageAt: _latestMessageAt(page),
      );
      if (hadUnread) _changed = true;
      if (jumpToBottom || changed) {
        _scrollToBottom(jump: jumpToBottom);
      }
    } catch (error) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _messageSignature(List<RecruitmentChatMessage> messages) {
    if (messages.isEmpty) return '0';
    final last = messages.last;
    return '${messages.length}:${last.messageId}:${last.createdAt}:${last.text}';
  }

  Future<void> _markRead(int chatId) async {
    try {
      await context.read<WorkerRecruitmentRepository>().markRecruitmentChatRead(
        chatId: chatId,
      );
    } catch (_) {
      // 읽음 처리 실패가 채팅 조회/응답 자체를 막지는 않도록 한다.
    }
  }

  String? _latestMessageAt(RecruitmentChatMessagePage page) {
    if (page.messages.isNotEmpty) {
      return page.messages.last.createdAt;
    }
    return page.chat.lastMessageAt;
  }

  Future<void> _sendMessage(String text) async {
    final optimisticId = 'optimistic-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMessage = RecruitmentChatMessage(
      messageId: optimisticId,
      senderRole: _currentUserRole,
      messageType: 'text',
      text: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    setState(() {
      _messages = [..._messages, optimisticMessage];
    });
    _changed = true;
    _scrollToBottom();

    try {
      final sentMessage = await context
          .read<WorkerRecruitmentRepository>()
          .sendRecruitmentChatMessage(chatId: widget.chatId, text: text);
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (message) =>
                  message.messageId == optimisticId ? sentMessage : message,
            )
            .toList();
      });
      _changed = true;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .where((message) => message.messageId != optimisticId)
            .toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  Future<void> _openDocumentMessage(RecruitmentChatMessage message) async {
    final contractId =
        message.contractId ?? _contractIdFromPath(message.openDocumentPath);
    if (contractId == null || contractId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('열 수 있는 계약서 정보가 없습니다.')));
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerContractDocumentScreen(
          contractId: contractId,
          roomTitle: _title,
        ),
      ),
    );
    if (changed == true && mounted) {
      _changed = true;
      _load();
    }
  }

  Future<void> _deleteChat() async {
    if (_deleting) return;
    final confirmed = await showWorkerContractChatLeaveDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<WorkerRecruitmentRepository>().deleteRecruitmentChat(
        chatId: widget.chatId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('채팅방이 삭제되었습니다.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  int? _contractIdFromPath(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final matches = RegExp(r'(\d+)').allMatches(path).toList();
    if (matches.isEmpty) return null;
    final match = matches.last;
    return int.tryParse(match.group(1) ?? '');
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String get _title {
    final name = _chat?.counterpartyName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return widget.title.trim().isEmpty ? '채팅' : widget.title.trim();
  }

  String? get _imageUrl {
    final url = _chat?.counterpartyProfileImageUrl ?? widget.profileImageUrl;
    final trimmed = url?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: _chatAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? workerErrorView(
                    message: accountDioMessage(_error!),
                    onRetry: _load,
                  )
                : _buildMessages(),
          ),
          RecruitmentInquiryChatComposer(onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) return const SizedBox.expand();
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderRole == _currentUserRole;
        final previous = index > 0 ? _messages[index - 1] : null;
        final next = index + 1 < _messages.length ? _messages[index + 1] : null;
        final showDateDivider =
            previous == null ||
            !isSameRecruitmentChatDate(previous.createdAt, message.createdAt);
        final grouped =
            previous != null &&
            previous.senderRole == message.senderRole &&
            isSameRecruitmentChatMinute(previous.createdAt, message.createdAt);
        final showTime =
            next == null ||
            next.senderRole != message.senderRole ||
            !isSameRecruitmentChatMinute(next.createdAt, message.createdAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateDivider) _ChatDateDivider(createdAt: message.createdAt),
            Padding(
              padding: EdgeInsets.only(bottom: grouped ? 5.h : 19.h),
              child: isMe
                  ? _OutgoingMessageRow(
                      message: message,
                      showTime: showTime,
                      onOpenDocument: () => _openDocumentMessage(message),
                    )
                  : _IncomingMessageRow(
                      message: message,
                      imageUrl: message.senderProfileImageUrl ?? _imageUrl,
                      showAvatar: !grouped,
                      showTime: showTime,
                      onOpenDocument: () => _openDocumentMessage(message),
                    ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _chatAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.grey0,
      surfaceTintColor: AppColors.grey0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(_changed),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      titleSpacing: 0,
      title: Text(_title, style: AppTypography.appBarTitle),
      actions: [
        IconButton(
          onPressed: _deleting ? null : _deleteChat,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textPrimary,
            size: 30,
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}

class _ChatDateDivider extends StatelessWidget {
  const _ChatDateDivider({required this.createdAt});

  final String? createdAt;

  @override
  Widget build(BuildContext context) {
    final label = formatRecruitmentChatDateDivider(createdAt);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.grey100.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            label,
            style: AppTypography.bodyXSmallM.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              height: 16 / 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingMessageRow extends StatelessWidget {
  const _IncomingMessageRow({
    required this.message,
    required this.onOpenDocument,
    this.imageUrl,
    this.showAvatar = true,
    required this.showTime,
  });

  final RecruitmentChatMessage message;
  final VoidCallback onOpenDocument;
  final String? imageUrl;
  final bool showAvatar;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final time = formatRecruitmentChatBubbleTime(message.createdAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar)
          _ChatAvatar(imageUrl: imageUrl)
        else
          SizedBox(width: 36.r),
        SizedBox(width: 10.w),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: _ChatBubble(
                  message: message,
                  isMe: false,
                  onOpenDocument: onOpenDocument,
                ),
              ),
              if (showTime && time.isNotEmpty) ...[
                SizedBox(width: 6.w),
                Text(time, style: _timeStyle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OutgoingMessageRow extends StatelessWidget {
  const _OutgoingMessageRow({
    required this.message,
    required this.onOpenDocument,
    required this.showTime,
  });

  final RecruitmentChatMessage message;
  final VoidCallback onOpenDocument;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final time = formatRecruitmentChatBubbleTime(message.createdAt);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showTime && time.isNotEmpty) ...[
          Text(time, style: _timeStyle),
          SizedBox(width: 6.w),
        ],
        Flexible(
          child: _ChatBubble(
            message: message,
            isMe: true,
            onOpenDocument: onOpenDocument,
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.onOpenDocument,
  });

  final RecruitmentChatMessage message;
  final bool isMe;
  final VoidCallback onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final isDocument = message.isDocument;
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: isDocument && !isMe ? 5.h : 7.h,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.grey0,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 10.r : 2.r),
          topRight: Radius.circular(isMe ? 2.r : 10.r),
          bottomLeft: Radius.circular(10.r),
          bottomRight: Radius.circular(10.r),
        ),
        boxShadow: isDocument && !isMe
            ? const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Text(
        message.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMediumR.copyWith(
          color: isMe ? AppColors.grey0 : AppColors.textPrimary,
          fontSize: 14.sp,
          height: 19 / 14,
          decoration: isDocument
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: isMe ? AppColors.grey0 : AppColors.textPrimary,
        ),
      ),
    );
    if (!isDocument) return content;
    return InkWell(
      onTap: onOpenDocument,
      borderRadius: BorderRadius.circular(10.r),
      child: content,
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey25,
        border: Border.all(color: AppColors.grey100),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DefaultAvatarIcon(),
            )
          : const _DefaultAvatarIcon(),
    );
  }
}

class _DefaultAvatarIcon extends StatelessWidget {
  const _DefaultAvatarIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 22.r,
        color: AppColors.textTertiary,
      ),
    );
  }
}

TextStyle get _timeStyle => AppTypography.bodyXSmallM.copyWith(
  color: AppColors.textDisabled,
  fontSize: 10.sp,
  height: 16 / 10,
);
