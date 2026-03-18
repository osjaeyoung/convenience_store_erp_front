import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/repositories/staff_management_repository.dart';

/// 직원 상세 화면 - 직원정보 탭에서 직원 클릭 시 별도 화면으로 표시
class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
  });

  final int branchId;
  final int employeeId;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;
  String? _editableHireDate;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getEmployeeDetail(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
      if (mounted) {
        final emp = (data['employee'] as Map?)?.cast<String, dynamic>();
        setState(() {
          _detail = data;
          _editableHireDate = emp?['hire_date'] as String?;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detail = null;
          _isLoading = false;
          _error = e.toString();
        });
      }
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
          '직원정보',
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 16 / 14,
          ),
        ),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/png/common/trash_icon.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('삭제 기능은 곧 연결됩니다.')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _detail == null
                  ? const Center(child: Text('데이터를 불러올 수 없습니다.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildDetailContent(),
                    ),
    );
  }

  Widget _buildDetailContent() {
    final employee =
        (_detail!['employee'] as Map?)?.cast<String, dynamic>() ?? {};
    final reviews = (_detail!['reviews'] as List?) ?? const [];
    final avgRating = reviews.isNotEmpty
        ? reviews
                .map((r) => (r as Map)['rating'] as num? ?? 0)
                .reduce((a, b) => a + b) /
            reviews.length
        : 0.0;
    final ratingInt = avgRating.round().clamp(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9FEDD4),
                Color(0xFFE1F0B8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1D1F).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.grey25,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 32,
                      color: AppColors.grey150,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/png/common/star_icon.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '근무자명  ',
                              style: AppTypography.bodyMediumM.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 16 / 14,
                              ),
                            ),
                            Text(
                              employee['name'] as String? ?? '-',
                              style: AppTypography.bodyMediumM.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 16 / 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildHireDateInput(
                          _editableHireDate ?? employee['hire_date'] as String? ?? '',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '연락처',
                          style: AppTypography.bodyMediumM.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 16 / 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildContactInput(
                          employee['phone_number'] as String? ?? '-',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정 기능은 곧 연결됩니다.')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.grey0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('수정'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < ratingInt;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: filled
                  ? Image.asset(
                      'assets/icons/png/common/star_icon.png',
                      width: 24,
                      height: 24,
                    )
                  : Image.asset(
                      'assets/icons/png/common/star_empty_icon.png',
                      width: 24,
                      height: 24,
                    ),
            );
          }),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('리뷰작성 기능은 곧 연결됩니다.')),
            );
          },
          child: Center(
            child: Text(
              '리뷰작성',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentList(),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('퇴사 처리 기능은 곧 연결됩니다.')),
            );
          },
          child: Center(
            child: Text(
              '퇴사',
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHireDateInput(String currentValue) {
    return GestureDetector(
      onTap: () async {
        final initial = DateTime.tryParse(currentValue) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && mounted) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          setState(() => _editableHireDate = formatted);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('입사일 수정 기능은 곧 API와 연결됩니다.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey0Alt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.grey150),
            const SizedBox(width: 12),
            Text(
              currentValue.isEmpty ? '입사일 설정' : currentValue,
              style: AppTypography.bodyMediumR.copyWith(
                color: currentValue.isEmpty ? AppColors.grey100 : AppColors.textPrimary,
                fontSize: 14,
                height: 19 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInput(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? '연락처 입력' : value,
              style: AppTypography.bodyMediumR.copyWith(
                color: value.isEmpty ? AppColors.grey100 : AppColors.textPrimary,
                fontSize: 14,
                height: 19 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    const items = [
      '근로계약서',
      '근무이력',
      '급여명세',
      '인사자료',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: items.map((title) {
          return ListTile(
            title: Text(
              title,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey100,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title 기능은 곧 연결됩니다.')),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
