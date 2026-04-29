import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/chat/recruitment_chat_read_store.dart';
import '../../../core/datetime/api_datetime_format.dart';
import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../../../widgets/recruitment_inquiry_chat_composer.dart';
import '../../account/account_dio_message.dart';
import 'employment_contract_detail_screen.dart';

class ManagerRecruitmentInquiryChatScreen extends StatefulWidget {
  const ManagerRecruitmentInquiryChatScreen({
    super.key,
    this.chatId,
    required this.branchId,
    required this.employeeId,
    this.employeeName,
    this.profileImageUrl,
  });

  final int? chatId;
  final int branchId;
  final int employeeId;
  final String? employeeName;
  final String? profileImageUrl;

  @override
  State<ManagerRecruitmentInquiryChatScreen> createState() =>
      _ManagerRecruitmentInquiryChatScreenState();
}

class _ManagerRecruitmentInquiryChatScreenState
    extends State<ManagerRecruitmentInquiryChatScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _chatId;
  bool _loading = true;
  bool _deleting = false;
  bool _changed = false;
  Object? _error;
  RecruitmentChatSummary? _chat;
  String _currentUserRole = 'business';
  List<RecruitmentChatMessage> _messages = const [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
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

  Future<int> _ensureChatId() async {
    final existing = _chatId;
    if (existing != null && existing > 0) return existing;

    final chat = await context
        .read<ManagerHomeRepository>()
        .createOrGetRecruitmentChat(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
        );
    _chatId = chat.chatId;
    _chat = chat;
    return chat.chatId;
  }

  Future<void> _load() async {
    await _refreshMessages(showLoading: true, jumpToBottom: true);
  }

  Future<void> _refreshMessages({
    bool showLoading = false,
    bool jumpToBottom = false,
  }) async {
    if (!showLoading && _loading) return;
    final repository = context.read<ManagerHomeRepository>();
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final chatId = await _ensureChatId();
      final page = await repository.getRecruitmentChatMessages(chatId: chatId);
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
      await _markRead(chatId);
      await RecruitmentChatReadStore.markReadThrough(
        chatId: chatId,
        lastMessageAt: _latestMessageAt(page),
      );
      if (hadUnread) _changed = true;
      if (jumpToBottom || changed) {
        _scrollToBottom(jump: jumpToBottom);
      }
      if (changed && !showLoading) _changed = true;
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
      await context.read<ManagerHomeRepository>().markRecruitmentChatRead(
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
    final repository = context.read<ManagerHomeRepository>();
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
      _chat = _updatedChatWithLastMessage(optimisticMessage);
    });
    _changed = true;
    _scrollToBottom();

    try {
      final chatId = await _ensureChatId();
      final sentMessage = await repository.sendRecruitmentChatMessage(
        chatId: chatId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (message) =>
                  message.messageId == optimisticId ? sentMessage : message,
            )
            .toList();
        _chat = _updatedChatWithLastMessage(sentMessage);
      });
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
        builder: (_) => EmploymentContractDetailScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: _title(),
          contractId: contractId,
          listTitle: '근로계약서',
        ),
      ),
    );
    if (changed == true && mounted) {
      _load();
    }
  }

  Future<void> _deleteChat() async {
    final chatId = _chatId;
    if (chatId == null || chatId <= 0 || _deleting) return;
    final confirmed = await showAppStyledDeleteDialog(
      context,
      message: '해당 채팅방을\n삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<ManagerHomeRepository>().deleteRecruitmentChat(
        chatId: chatId,
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
    return int.tryParse(matches.last.group(1) ?? '');
  }

  RecruitmentChatSummary? _updatedChatWithLastMessage(
    RecruitmentChatMessage message,
  ) {
    final chat = _chat;
    if (chat == null) return null;
    return RecruitmentChatSummary(
      chatId: chat.chatId,
      branchId: chat.branchId,
      employeeId: chat.employeeId,
      branchName: chat.branchName,
      counterpartyName: chat.counterpartyName,
      counterpartyRole: chat.counterpartyRole,
      counterpartyProfileImageUrl: chat.counterpartyProfileImageUrl,
      status: chat.status,
      lastMessage: message.text,
      lastMessageAt: message.createdAt,
      unreadCount: chat.unreadCount,
      createdAt: chat.createdAt,
    );
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

  String _title() {
    final name = _chat?.counterpartyName ?? widget.employeeName;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : '채팅';
  }

  String? _counterpartyImageUrl() {
    final url = _chat?.counterpartyProfileImageUrl ?? widget.profileImageUrl;
    final trimmed = url?.trim();
    return trimmed != null && trimmed.isNotEmpty ? trimmed : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
        titleSpacing: 0,
        title: Text(
          _title(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 24 / 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _deleting ? null : _deleteChat,
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 30,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ChatErrorView(
                    message: accountDioMessage(_error!),
                    onRetry: _load,
                  )
                : _MessageList(
                    messages: _messages,
                    currentUserRole: _currentUserRole,
                    counterpartyImageUrl: _counterpartyImageUrl(),
                    controller: _scrollController,
                    onOpenDocument: _openDocumentMessage,
                  ),
          ),
          RecruitmentInquiryChatComposer(onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserRole,
    this.counterpartyImageUrl,
    required this.controller,
    required this.onOpenDocument,
  });

  final List<RecruitmentChatMessage> messages;
  final String currentUserRole;
  final String? counterpartyImageUrl;
  final ScrollController controller;
  final ValueChanged<RecruitmentChatMessage> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.expand();
    }

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20.w, 45.h, 20.w, 24.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe =
            message.senderRole == currentUserRole ||
            (currentUserRole == 'business' && message.senderRole == 'manager');
        final previous = index > 0 ? messages[index - 1] : null;
        final next = index + 1 < messages.length ? messages[index + 1] : null;
        final showDateDivider =
            previous == null ||
            !isSameRecruitmentChatDate(previous.createdAt, message.createdAt);
        final isGroupedWithPrevious =
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
              padding: EdgeInsets.only(
                bottom: isGroupedWithPrevious ? 5.h : 19.h,
              ),
              child: isMe
                  ? _OutgoingMessageRow(
                      message: message,
                      showTime: showTime,
                      onOpenDocument: () => onOpenDocument(message),
                    )
                  : _IncomingMessageRow(
                      message: message,
                      imageUrl:
                          message.senderProfileImageUrl ?? counterpartyImageUrl,
                      showAvatar: !isGroupedWithPrevious,
                      showTime: showTime,
                      onOpenDocument: () => onOpenDocument(message),
                    ),
            ),
          ],
        );
      },
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
                Text(time, style: _bubbleTimeStyle),
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
          Text(time, style: _bubbleTimeStyle),
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
    final bubble = Container(
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
          decorationThickness: 1,
        ),
      ),
    );

    if (!isDocument) return bubble;
    return InkWell(
      onTap: onOpenDocument,
      borderRadius: BorderRadius.circular(10.r),
      child: bubble,
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

class _ChatErrorView extends StatelessWidget {
  const _ChatErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

TextStyle get _bubbleTimeStyle => AppTypography.bodyXSmallM.copyWith(
  color: AppColors.textDisabled,
  fontSize: 10.sp,
  height: 16 / 10,
);
