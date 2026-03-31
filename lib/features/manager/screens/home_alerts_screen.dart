import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/manager_home/manager_alert.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../data/repositories/owner_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class HomeAlertsScreen extends StatefulWidget {
  const HomeAlertsScreen({
    super.key,
    required this.branchId,
    required this.isOwner,
  });

  final int branchId;
  final bool isOwner;

  @override
  State<HomeAlertsScreen> createState() => _HomeAlertsScreenState();
}

class _HomeAlertsScreenState extends State<HomeAlertsScreen> {
  bool _loading = true;
  String? _error;
  List<ManagerAlert> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ownerRepo = context.read<OwnerHomeRepository>();
    final managerRepo = context.read<ManagerHomeRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = widget.isOwner
          ? (await ownerRepo.getAlerts(widget.branchId))
              .map(ManagerAlert.fromJson)
              .toList()
          : await managerRepo.getAlerts(widget.branchId);
      if (!mounted) return;
      setState(() {
        _alerts = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alerts = const [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleOpen(ManagerAlert alert, bool isOpen) async {
    final ownerRepo = context.read<OwnerHomeRepository>();
    final managerRepo = context.read<ManagerHomeRepository>();
    try {
      if (widget.isOwner) {
        await ownerRepo.patchAlert(
              branchId: widget.branchId,
              alertId: alert.alertId,
              isOpen: isOpen,
            );
      } else {
        await managerRepo.patchAlert(
              branchId: widget.branchId,
              alertId: alert.alertId,
              isOpen: isOpen,
            );
      }
      if (!mounted) return;
      setState(() {
        _alerts = _alerts
            .map(
              (item) => item.alertId == alert.alertId
                  ? ManagerAlert(
                      alertId: item.alertId,
                      title: item.title,
                      content: item.content,
                      priority: item.priority,
                      isOpen: isOpen,
                      createdAt: item.createdAt,
                    )
                  : item,
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림 상태 변경 실패: $e')),
      );
    }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          '알림',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _alerts.isEmpty
                  ? Center(
                      child: Text(
                        '알림이 없습니다.',
                        style: AppTypography.bodyMediumR.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        itemCount: _alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey0,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.grey50),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                initiallyExpanded: alert.isOpen,
                                onExpansionChanged: (expanded) => _toggleOpen(alert, expanded),
                                title: Text(
                                  alert.title,
                                  style: AppTypography.bodyLargeM.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    height: 20 / 16,
                                  ),
                                ),
                                subtitle: alert.createdAt == null
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          alert.createdAt!,
                                          style: AppTypography.bodySmallR.copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 12,
                                            height: 18 / 12,
                                          ),
                                        ),
                                      ),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      alert.content,
                                      style: AppTypography.bodyMediumR.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        height: 20 / 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
