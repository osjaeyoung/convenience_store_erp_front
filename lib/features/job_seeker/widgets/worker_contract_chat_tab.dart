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

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return workerErrorView(
        message: accountDioMessage(_error!),
        onRetry: _load,
      );
    }
    if (_items.isEmpty) {
      return workerEmptyView(
        message: _emptyTitle,
        description: _emptyDescription,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(
          color: AppColors.border,
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          final preview =
              workerDisplayValue(item.lastMessagePreview, fallback: item.title);
          final unread = item.unreadCount;
          return InkWell(
            onTap: () => _openDetail(item),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.grey25,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workerDisplayValue(item.counterpartyName, fallback: '상대방'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMediumM.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmallR.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unread > 0) ...[
                        Container(
                          constraints: BoxConstraints(minWidth: 20.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4834),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread.toString(),
                            style: AppTypography.bodySmallB.copyWith(
                              color: AppColors.grey0,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                      ],
                      Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textPrimary,
                        size: 24.r,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
