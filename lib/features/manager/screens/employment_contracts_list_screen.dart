import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employment_contract_add_method_screen.dart';
import 'employment_contract_detail_screen.dart';

/// 근로계약서 목록 (템플릿별 필터 + 추가하기 + 상세)
class EmploymentContractsListScreen extends StatefulWidget {
  const EmploymentContractsListScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.screenTitle,
    this.templateVersion,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final String screenTitle;
  final String? templateVersion;

  @override
  State<EmploymentContractsListScreen> createState() =>
      _EmploymentContractsListScreenState();
}

class _EmploymentContractsListScreenState
    extends State<EmploymentContractsListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  static String _formatYmd(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }

  static String _listSubtitle(Map<String, dynamic> c) {
    final status = c['status']?.toString();
    if (status == 'completed') {
      final at = c['finalized_at'] ?? c['updated_at'];
      return '완료일 ${_formatYmd(at)}';
    }
    final at = c['updated_at'];
    if (at != null) {
      return '임시저장 · ${_formatYmd(at)}';
    }
    return '임시저장';
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
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getEmploymentContracts(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        templateVersion: widget.templateVersion,
      );
      final items =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAdd() async {
    final tv = widget.templateVersion ?? 'standard_v1';
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmploymentContractAddMethodScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          templateVersion: tv,
          listTitle: widget.screenTitle,
        ),
      ),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final id = (row['contract_id'] as num?)?.toInt();
    if (id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmploymentContractDetailScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          contractId: id,
          listTitle: widget.screenTitle,
          summaryRow: row,
        ),
      ),
    );
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.screenTitle),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMediumR.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : _items.isEmpty
                          ? CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: ColoredBox(
                                    color: AppColors.grey0,
                                    child: Center(
                                      child: Text(
                                        '등록된 근로계약서가 없습니다.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyLargeM
                                            .copyWith(
                                          color: AppColors.textTertiary,
                                          height: 20 / 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 0, 0, 100),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.divider,
                              ),
                              itemBuilder: (context, i) {
                                final c = _items[i];
                                final title = c['title']?.toString() ?? '-';
                                final status = c['status']?.toString() ?? '';
                                final completed = status == 'completed';
                                return Material(
                                  color: AppColors.grey0,
                                  child: InkWell(
                                    onTap: () => _openDetail(c),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography
                                                      .bodyMediumM
                                                      .copyWith(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    height: 22 / 15,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _listSubtitle(c),
                                                  style: AppTypography
                                                      .bodySmall
                                                      .copyWith(
                                                    fontSize: 13,
                                                    height: 18 / 13,
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _ContractStatusChip(
                                              completed: completed),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.textTertiary,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _openAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '추가하기',
                    style: AppTypography.bodyMediumB.copyWith(
                      color: AppColors.grey0,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목록 우측 상태 뱃지 (Figma: 초록 계약완료 / 빨강 계약미완료)
class _ContractStatusChip extends StatelessWidget {
  const _ContractStatusChip({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.error;
    final label = completed ? '계약완료' : '계약미완료';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
          color: color,
        ),
      ),
    );
  }
}
