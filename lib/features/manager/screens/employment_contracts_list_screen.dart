import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employment_contract_add_method_screen.dart';
import 'employment_contract_attachment_helpers.dart';
import 'employment_contract_detail_screen.dart';
import 'employment_contract_file_attach_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 근로계약서 목록 (템플릿별 필터 + 추가하기 + 상세)
class EmploymentContractsListScreen extends StatefulWidget {
  const EmploymentContractsListScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.screenTitle,
    this.templateVersion,
    this.fileOnly = false,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final String screenTitle;
  final String? templateVersion;
  final bool fileOnly;

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
    final completed = EmploymentContractAttachmentHelpers.isCompleted(c);
    if (completed) {
      final at = c['finalized_at'] ?? c['updated_at'] ?? c['created_at'];
      return '완료일 ${_formatYmd(at)}';
    }
    final incompleteLabel =
        EmploymentContractAttachmentHelpers.chatStatusLabel(c) ?? '계약미완료';
    final at = c['updated_at'];
    if (at != null) {
      return '$incompleteLabel · ${_formatYmd(at)}';
    }
    return incompleteLabel;
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
        builder: (_) => widget.fileOnly
            ? EmploymentContractFileAttachScreen(
                branchId: widget.branchId,
                employeeId: widget.employeeId,
                templateVersion: tv,
                screenTitle: widget.screenTitle,
              )
            : EmploymentContractAddMethodScreen(
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

  bool get _isGuardianList => widget.templateVersion == 'guardian_consent_v1';

  String get _emptyMessage =>
      _isGuardianList ? '등록된 친권자(후견인) 동의서가 없습니다' : '등록된 근로계약서가 없습니다.';

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
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120.h),
                  const Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(24.r),
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
                          _emptyMessage,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLargeM.copyWith(
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
                padding: EdgeInsets.only(bottom: 12.h),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, i) {
                  final c = _items[i];
                  final title = c['title']?.toString() ?? '-';
                  final completed =
                      EmploymentContractAttachmentHelpers.isCompleted(c);
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMediumM.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      height: 22 / 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _listSubtitle(c),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 13.sp,
                                      height: 18 / 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            _ContractStatusChip(completed: completed),
                            SizedBox(width: 4.w),
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
      bottomNavigationBar: Material(
        color: AppColors.grey0,
        child: SafeArea(
          minimum: EdgeInsets.only(bottom: 8.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _isGuardianList ? 20 : 16,
              8,
              _isGuardianList ? 20 : 16,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _openAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _isGuardianList ? 8 : 12,
                    ),
                  ),
                ),
                child: Text(
                  '추가하기',
                  style: AppTypography.bodyMediumB.copyWith(
                    color: AppColors.grey0,
                    fontSize: 16.sp,
                    height: 24 / 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 우측 상태 뱃지 (Figma: Main 계약완료 / Accents-Red 계약미완료)
class _ContractStatusChip extends StatelessWidget {
  const _ContractStatusChip({required this.completed});

  final bool completed;

  /// Figma Accents-Red
  static const Color _accentRed = Color(0xFFFF383C);

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Text(
          '계약완료',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmallB.copyWith(
            height: 16 / 12,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 72, 52, 0.05),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: _accentRed, width: 1),
      ),
      child: Text(
        '계약미완료',
        textAlign: TextAlign.center,
        style: AppTypography.bodySmallB.copyWith(
          height: 16 / 12,
          color: _accentRed,
        ),
      ),
    );
  }
}
