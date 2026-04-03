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
import 'worker_contract_document_screen.dart';

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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerContractDocumentScreen(contractId: widget.contractId),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
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
          detail?.thread.branchName ?? '계약채팅',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_horiz_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? workerErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : _buildContent(detail!),
    );
  }

  Widget _buildContent(WorkerContractChatDetail detail) {
    final messages = detail.messages;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final workerMessage = message.fromWorker;
        final time = _formatTime(message.createdAt);
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment:
                workerMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!workerMessage) ...[
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey25,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              if (workerMessage && time.isNotEmpty) ...[
                Text(
                  time,
                  style: AppTypography.bodyXSmallM.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: InkWell(
                  onTap: message.messageType == 'document' ? _openDocument : null,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 248.w),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: workerMessage ? AppColors.primary : AppColors.grey0,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(workerMessage ? 10 : 2),
                        topRight: Radius.circular(workerMessage ? 2 : 10),
                        bottomLeft: Radius.circular(10.r),
                        bottomRight: Radius.circular(10.r),
                      ),
                      boxShadow: workerMessage
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Text(
                      message.text,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: workerMessage ? AppColors.grey0 : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              if (!workerMessage && time.isNotEmpty) ...[
                SizedBox(width: 6.w),
                Text(
                  time,
                  style: AppTypography.bodyXSmallM.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
