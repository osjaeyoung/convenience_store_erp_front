import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

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
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '기타',
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        '등록된 기타 자료가 없습니다.',
                        style: AppTypography.bodyMediumR.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grey50,
                      ),
                      itemBuilder: (context, i) {
                        final r = _items[i];
                        final title = r['title']?.toString() ?? '-';
                        final note = r['note']?.toString();
                        return ListTile(
                          title: Text(
                            title,
                            style: AppTypography.bodyMediumM.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: note != null && note.isNotEmpty
                              ? Text(
                                  note,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
    );
  }
}
