import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../account/account_dio_message.dart';
import '../screens/worker_recruitment_detail_screen.dart';
import '../../../theme/app_colors.dart';
import 'worker_common.dart';
import 'worker_recruitment_card.dart';

class WorkerApplicationsTab extends StatefulWidget {
  const WorkerApplicationsTab({
    super.key,
    required this.refreshToken,
    required this.onApplicationCreated,
  });

  final int refreshToken;
  final VoidCallback onApplicationCreated;

  @override
  State<WorkerApplicationsTab> createState() => _WorkerApplicationsTabState();
}

class _WorkerApplicationsTabState extends State<WorkerApplicationsTab> {
  List<WorkerRecruitmentApplicationSummary> _items =
      const <WorkerRecruitmentApplicationSummary>[];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkerApplicationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<WorkerRecruitmentRepository>()
          .getApplications();
      if (!mounted) return;
      setState(() {
        _items = page.items;
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

  Future<void> _openDetail(WorkerRecruitmentApplicationSummary item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkerRecruitmentDetailScreen(
          postingId: item.postingId,
          onApplicationCreated: widget.onApplicationCreated,
        ),
      ),
    );
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
        message: '지원한 공고가 없습니다.',
        description: '채용정보 탭에서 원하는 공고에 지원해 보세요.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final item = _items[index];
          return WorkerRecruitmentCard(
            badgeLabel: item.badgeLabel,
            companyName: item.companyName,
            title: item.title,
            regionSummary: item.regionSummary,
            payType: item.payType,
            payAmount: item.payAmount,
            footerLabel: item.appliedDateLabel,
            onTap: () => _openDetail(item),
          );
        },
      ),
    );
  }
}
