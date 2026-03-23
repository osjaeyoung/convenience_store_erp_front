import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../payroll/payroll_formatters.dart';
import 'payroll_add_method_screen.dart';
import 'payroll_statement_detail_screen.dart';

/// 급여명세 목록 (빈 목록 / 리스트 + 하단 추가하기)
class PayrollStatementListScreen extends StatefulWidget {
  const PayrollStatementListScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    this.initialItemsPayload,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  /// 직원 상세 API 등에서 넘긴 `payroll_statements` 또는 `{ "items": [...] }` 형태
  final Map<String, dynamic>? initialItemsPayload;

  @override
  State<PayrollStatementListScreen> createState() =>
      _PayrollStatementListScreenState();
}

class _PayrollStatementListScreenState extends State<PayrollStatementListScreen> {
  /// Figma Body medium_M — 목록 행 제목 (`2025년 12월 급여명세`)
  static const TextStyle _rowTitleStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    color: Color(0xFF000000),
  );

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final seed = PayrollFormatters.parseItemList(widget.initialItemsPayload);
    if (seed.isNotEmpty) {
      _items = seed;
      PayrollFormatters.sortPayrollItems(_items);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getPayrollStatements(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
      if (!mounted) return;
      final list = PayrollFormatters.parseItemList(data);
      PayrollFormatters.sortPayrollItems(list);
      setState(() {
        _items = list;
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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PayrollAddMethodScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
        ),
      ),
    );
    if (changed == true && mounted) {
      _dirty = true;
      _load();
    }
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final id = (row['payroll_id'] as num?)?.toInt();
    if (id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PayrollStatementDetailScreen(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          payrollId: id,
          summaryRow: row,
        ),
      ),
    );
    if (changed == true && mounted) {
      _dirty = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, _dirty),
        ),
        title: Text(
          '급여명세',
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 16 / 14,
          ),
        ),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 급여명세서가 없습니다.',
                              style: AppTypography.bodyMediumR.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 0),
                            itemBuilder: (context, i) {
                              final row = _items[i];
                              final y = (row['year'] as num?)?.toInt() ?? 0;
                              final m = (row['month'] as num?)?.toInt() ?? 0;
                              return Material(
                                color: AppColors.grey0,
                                child: InkWell(
                                  onTap: () => _openDetail(row),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.grey0Alt,
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          alignment: Alignment.center,
                                          child: SvgPicture.asset(
                                            'assets/icons/svg/icon/payroll_document_24.svg',
                                            width: 22,
                                            height: 22,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '$y년 $m월 급여명세',
                                            style: _rowTitleStyle,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.grey100,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _openAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
    );
  }
}
