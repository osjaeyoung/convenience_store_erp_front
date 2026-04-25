import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/datetime/api_datetime_format.dart';
import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/recruitment_inquiry_chat_composer.dart';
import '../../account/account_dio_message.dart';
import '../widgets/worker_common.dart';

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
  Object? _error;
  RecruitmentChatSummary? _chat;
  String _currentUserRole = 'worker';
  List<RecruitmentChatMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<WorkerRecruitmentRepository>()
          .getRecruitmentChatMessages(chatId: widget.chatId);
      if (!mounted) return;
      setState(() {
        _chat = page.chat.copyWith(unreadCount: 0);
        _currentUserRole = page.currentUserRole;
        _messages = page.messages;
        _loading = false;
      });
      _markRead(widget.chatId);
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int chatId) async {
    try {
      await context
          .read<WorkerRecruitmentRepository>()
          .markRecruitmentChatRead(chatId: chatId);
    } catch (_) {
      // 읽음 처리 실패가 채팅 조회/응답 자체를 막지는 않도록 한다.
    }
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
      appBar: workerSubPageAppBar(context, title: _title),
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
        final grouped = previous != null &&
            previous.senderRole == message.senderRole &&
            previous.createdAt == message.createdAt;
        return Padding(
          padding: EdgeInsets.only(bottom: grouped ? 5.h : 19.h),
          child: isMe
              ? _OutgoingMessageRow(message: message)
              : _IncomingMessageRow(
                  message: message,
                  imageUrl: _imageUrl,
                  showAvatar: !grouped,
                ),
        );
      },
    );
  }
}

class _IncomingMessageRow extends StatelessWidget {
  const _IncomingMessageRow({
    required this.message,
    this.imageUrl,
    this.showAvatar = true,
  });

  final RecruitmentChatMessage message;
  final String? imageUrl;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final time = formatContractChatBubbleTime(message.createdAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar) _ChatAvatar(imageUrl: imageUrl) else SizedBox(width: 36.r),
        SizedBox(width: 10.w),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: _ChatBubble(message: message, isMe: false)),
              if (time.isNotEmpty) ...[
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
  const _OutgoingMessageRow({required this.message});

  final RecruitmentChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = formatContractChatBubbleTime(message.createdAt);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (time.isNotEmpty) ...[
          Text(time, style: _timeStyle),
          SizedBox(width: 6.w),
        ],
        Flexible(child: _ChatBubble(message: message, isMe: true)),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMe});

  final RecruitmentChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDocument = message.isDocument;
    return Container(
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
          decoration: isDocument && !isMe
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: AppColors.textPrimary,
        ),
      ),
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
