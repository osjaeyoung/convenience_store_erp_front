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
        title: Text(
          widget.screenTitle,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final c = _items[i];
                                final title = c['title']?.toString() ?? '-';
                                final status = c['status']?.toString() ?? '-';
                                final rate =
                                    (c['completion_rate'] as num?)?.toInt() ??
                                        0;
                                return Material(
                                  color: AppColors.grey0,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _openDetail(c),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.grey50,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: AppTypography.bodyMediumM
                                                .copyWith(
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            status == 'draft'
                                                ? '임시저장 · 입력 $rate%'
                                                : '완료 · 입력 $rate%',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
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
