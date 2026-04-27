import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/recruitment/recruitment_models.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../../account/account_dio_message.dart';
import '../bloc/selected_branch_cubit.dart';
import '../screens/recruitment_inquiry_chat_screen.dart';

class ManagerRecruitmentInquiryChatTab extends StatefulWidget {
  const ManagerRecruitmentInquiryChatTab({super.key});

  @override
  State<ManagerRecruitmentInquiryChatTab> createState() =>
      _ManagerRecruitmentInquiryChatTabState();
}

class _ManagerRecruitmentInquiryChatTabState
    extends State<ManagerRecruitmentInquiryChatTab> {
  bool _loading = false;
  Object? _error;
  int? _loadedBranchId;
  List<RecruitmentChatSummary> _chats = const [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load(int branchId) async {
    setState(() {
      _loading = true;
      _error = null;
      _loadedBranchId = branchId;
    });
    try {
      final page = await context
          .read<ManagerHomeRepository>()
          .getRecruitmentChats(branchId: branchId);
      if (!mounted) return;
      setState(() {
        _chats = page.items;
        _loading = false;
      });
      _startPolling(branchId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _startPolling(int branchId) {
    if (_pollTimer?.isActive == true && _loadedBranchId == branchId) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshSilently(branchId);
    });
  }

  Future<void> _refreshSilently(int branchId) async {
    if (!mounted || _loading) return;
    try {
      final page = await context
          .read<ManagerHomeRepository>()
          .getRecruitmentChats(branchId: branchId);
      if (!mounted || _loadedBranchId != branchId) return;
      setState(() {
        _chats = page.items;
        _error = null;
      });
    } catch (_) {
      // 실시간성 보강용 polling 실패는 기존 화면을 유지한다.
    }
  }

  Future<void> _openChat(RecruitmentChatSummary chat) async {
    setState(() {
      _chats = _chats
          .map(
            (item) => item.chatId == chat.chatId
                ? item.copyWith(unreadCount: 0)
                : item,
          )
          .toList();
    });
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManagerRecruitmentInquiryChatScreen(
          chatId: chat.chatId,
          branchId: chat.branchId,
          employeeId: chat.employeeId,
          employeeName: chat.counterpartyName,
          profileImageUrl: chat.counterpartyProfileImageUrl,
        ),
      ),
    );
    if (changed == true && mounted && _loadedBranchId != null) {
      await _load(_loadedBranchId!);
    }
  }

  Future<void> _onMorePressed(RecruitmentChatSummary chat) async {
    final confirmed = await showAppStyledDeleteDialog(
      context,
      message: '해당 채팅방을\n삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<ManagerHomeRepository>().deleteRecruitmentChat(
        chatId: chat.chatId,
      );
      if (!mounted) return;
      setState(() {
        _chats = _chats.where((item) => item.chatId != chat.chatId).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('채팅방이 삭제되었습니다.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(accountDioMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = context.watch<SelectedBranchCubit>().state;
    if (branchId == null) {
      _pollTimer?.cancel();
      return Center(
        child: Text(
          '지점을 선택해주세요.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (_loadedBranchId != branchId && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(branchId);
      });
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              accountDioMessage(_error!),
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: () => _load(branchId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Text(
          '진행 중인 채팅이 없습니다.',
          style: AppTypography.bodyMediumR.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      itemCount: _chats.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.border, height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final unread = chat.unreadCount;

        return InkWell(
          onTap: () => _openChat(chat),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Row(
              children: [
                _ChatAvatar(imageUrl: chat.counterpartyProfileImageUrl),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    chat.counterpartyName.isEmpty
                        ? '상대방'
                        : chat.counterpartyName,
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      height: 16 / 14,
                    ),
                  ),
                ),
                if (unread > 0)
                  Container(
                    width: 20.r,
                    height: 20.r,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF4834), // AppColors.red or custom
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: AppTypography.bodySmallB.copyWith(
                        color: AppColors.grey0,
                        fontSize: 12.sp,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => _onMorePressed(chat),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textPrimary,
                    size: 30,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        );
      },
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
        border: Border.all(color: AppColors.grey25),
        color: AppColors.grey25,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DefaultChatAvatarIcon(),
            )
          : const _DefaultChatAvatarIcon(),
    );
  }
}

class _DefaultChatAvatarIcon extends StatelessWidget {
  const _DefaultChatAvatarIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.person, color: AppColors.grey150, size: 20.r),
    );
  }
}
