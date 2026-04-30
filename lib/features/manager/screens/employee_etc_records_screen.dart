import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employee_etc_record_add_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 기타자료 목록 (records/etc)
class EmployeeEtcRecordsScreen extends StatefulWidget {
  const EmployeeEtcRecordsScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
  });

  final int branchId;
  final int employeeId;

  @override
  State<EmployeeEtcRecordsScreen> createState() =>
      _EmployeeEtcRecordsScreenState();
}

class _EmployeeEtcRecordsScreenState extends State<EmployeeEtcRecordsScreen> {
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
      final data = await repo.getEmployeeRecordsEtc(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
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
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  static String _formatListDate(Map<String, dynamic> r) {
    final raw = (r['issued_date'] ?? r['created_at'])?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}.$m.$day';
  }

  Future<void> _openAdd() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmployeeEtcRecordAddScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
        ),
      ),
    );
    if (ok == true && mounted) _load();
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
        title: const Text('기타'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.appBarTitle,
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
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '등록된 기타 자료가 없습니다.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLargeM.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                  final r = _items[i];
                  final title = r['title']?.toString() ?? '-';
                  final dateLine = _formatListDate(r);
                  return Material(
                    color: AppColors.grey0,
                    child: InkWell(
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => EmployeeEtcRecordAddScreen(
                              branchId: widget.branchId,
                              employeeId: widget.employeeId,
                              viewRecord: r,
                            ),
                          ),
                        );
                        if (changed == true && mounted) _load();
                      },
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
                                  if (dateLine.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      '작성일 $dateLine',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 13.sp,
                                        height: 18 / 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
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
                    borderRadius: BorderRadius.circular(8.r),
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
