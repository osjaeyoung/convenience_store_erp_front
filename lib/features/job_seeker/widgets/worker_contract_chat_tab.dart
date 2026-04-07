import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../account/account_dio_message.dart';
import '../screens/worker_contract_chat_detail_screen.dart';
import 'worker_common.dart';
import 'worker_contract_chat_leave_dialog.dart';

class WorkerContractChatTab extends StatefulWidget {
  const WorkerContractChatTab({super.key});

  @override
  State<WorkerContractChatTab> createState() => _WorkerContractChatTabState();
}

class _WorkerContractChatTabState extends State<WorkerContractChatTab> {
  bool _loading = true;
  Object? _error;
  List<WorkerContractChatSummary> _items = const <WorkerContractChatSummary>[];
  String _emptyTitle = '아직 계약 채팅이 없어요.';
  String _emptyDescription = '점장 또는 경영주가 계약서를 전송하면\n이곳에 표시됩니다.';

  /// API가 한 줄로 내려줄 때도 Figma와 동일하게 두 줄로 보이도록 보정
  static String _normalizeEmptyDescription(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('\n')) return raw;
    return trimmed.replaceFirst('전송하면 이곳', '전송하면\n이곳');
  }

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
      final page = await context.read<WorkerRecruitmentRepository>().getContractChats();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _emptyTitle = page.emptyTitle ?? _emptyTitle;
        _emptyDescription = page.emptyDescription != null
            ? _normalizeEmptyDescription(page.emptyDescription!)
            : _emptyDescription;
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

  Future<void> _openDetail(WorkerContractChatSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerContractChatDetailScreen(contractId: item.contractId),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _onMorePressed(WorkerContractChatSummary item) async {
    final confirmed = await showWorkerContractChatLeaveDialog(context);
    if (!confirmed || !mounted) return;
    try {
      await context.read<WorkerRecruitmentRepository>().deleteContractChat(
            contractId: item.contractId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약 채팅이 삭제되었습니다.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountDioMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        Widget scrollableChild;
        if (_loading && _items.isEmpty) {
          scrollableChild = SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (_error != null && _items.isEmpty) {
          scrollableChild = SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: workerErrorView(
                message: accountDioMessage(_error!),
                onRetry: _load,
              ),
            ),
          );
        } else if (_items.isEmpty) {
          scrollableChild = SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: workerEmptyView(
                message: _emptyTitle,
                description: _emptyDescription,
              ),
            ),
          );
        } else {
          // Figma 2534:11025 — 계약 채팅 목록 (36 아바타·14/12 타이포·빨간 읽지않음·⋯)
          scrollableChild = ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            itemCount: _items.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.border,
              height: 1,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              final preview = workerDisplayValue(
                item.lastMessagePreview,
                fallback: item.title,
              );
              final unread = item.unreadCount;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openDetail(item),
                        child: Row(
                          children: [
                            Container(
                              width: 36.r,
                              height: 36.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.grey0,
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.textTertiary,
                                size: 22.r,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerDisplayValue(
                                      item.counterpartyName,
                                      fallback: '상대방',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMediumM.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 16 / 14,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmallR.copyWith(
                                      color: AppColors.textTertiary,
                                      height: 18 / 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (unread > 0) ...[
                              SizedBox(width: 12.w),
                              Container(
                                constraints: BoxConstraints(
                                  minWidth: 20.r,
                                  minHeight: 20.r,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4834),
                                  borderRadius: BorderRadius.circular(100.r),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: AppTypography.bodySmallB.copyWith(
                                    color: AppColors.grey0,
                                    fontSize: 12.sp,
                                    height: 16 / 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () => _onMorePressed(item),
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
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
              );
            },
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: scrollableChild,
        );
      },
    );
  }
}
