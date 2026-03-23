import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/repositories/staff_management_repository.dart';
import '../widgets/employee_profile_box.dart';
import 'employee_review_screen.dart';
import 'employee_work_history_screen.dart';
import 'payroll_statement_list_screen.dart';

/// 직원 상세 화면 - 직원정보 탭에서 직원 클릭 시 별도 화면으로 표시
class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    this.initialMyRating,
  });

  final int branchId;
  final int employeeId;
  /// 목록(compare API)에서 전달한 내 별점 (있으면 리뷰 작성 시 초기값으로 사용)
  final int? initialMyRating;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;
  String? _editableHireDate;
  bool _isEditMode = false;
  bool _needsRefresh = false; // 리뷰 등록 등으로 목록 갱신 필요 시 true

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _onDeleteTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('근무자 삭제'),
        content: const Text(
          '이 근무자를 삭제하시겠습니까?\n근로계약, 근무일정, 리뷰 등 관련 데이터가 모두 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.deleteEmployee(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('근무자가 삭제되었습니다.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _onRetirementTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('퇴사 처리'),
        content: const Text(
          '이 근무자를 퇴사 처리하시겠습니까?\n퇴사일은 오늘 날짜로 등록됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final today = DateTime.now();
    final resignationDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.patchEmployee(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        data: {
          'resignation_date': resignationDate,
          'employment_status': 'retired',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퇴사 처리되었습니다.')),
        );
        setState(() => _needsRefresh = true);
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퇴사 처리 실패: $e')),
        );
      }
    }
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
          onPressed: () => Navigator.pop(context, _needsRefresh),
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
            onPressed: _detail != null ? _onDeleteTap : null,
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
    // 상세 API에는 별점 필드 없음 → reviews에서 평균 계산 (compare API만 average_rating 제공)
    final avgRating = reviews.isNotEmpty
        ? reviews
                .map((r) => (r as Map)['rating'] as num? ?? 0)
                .reduce((a, b) => a + b) /
            reviews.length
        : 0.0;
    final ratingInt = avgRating.round().clamp(0, 3);

    // my_rating, my_comment, my_review_id: 현재 사용자가 작성한 리뷰 (없으면 null)
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    int? myRating;
    String? myComment;
    int? myReviewId;
    if (currentUserId != null) {
      final myId = int.tryParse(currentUserId);
      if (myId != null) {
        for (final r in reviews) {
          final authorId = (r as Map)['author_user_id'] as num?;
          if (authorId != null && authorId.toInt() == myId) {
            final rVal = r['rating'] as num?;
            myRating = rVal?.round().clamp(1, 3);
            myComment = r['comment'] as String?;
            myReviewId = (r['review_id'] as num?)?.toInt();
            break;
          }
        }
      }
    }

    final empName = employee['name'] as String? ?? '-';
    final empHireDate =
        _editableHireDate ?? employee['hire_date'] as String? ?? '';
    final empContact = employee['phone_number'] as String? ?? '-';
    final empResignDate = employee['resignation_date'] as String?;
    final isRetired = (employee['employment_status'] as String?) == 'retired';

    final branchDisplayName = _branchNameFromDetail(_detail!);
    final workHistoriesRaw =
        ((_detail!['work_histories'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final workHistoriesForUi = branchDisplayName.isEmpty
        ? workHistoriesRaw
        : workHistoriesRaw.map((m) {
            final existing = (m['branch_name'] as String?)?.trim();
            if (existing != null && existing.isNotEmpty) return m;
            return Map<String, dynamic>.from(m)
              ..['branch_name'] = branchDisplayName;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeProfileBox(
          name: empName,
          hireDate: empHireDate,
          contact: empContact,
          resignationDate: isRetired ? empResignDate : null,
          showEditButton: true,
          starCount: ratingInt > 0 ? ratingInt : null,
          isEditMode: _isEditMode,
          hireDateInputWidget: _isEditMode ? _buildHireDateInput(empHireDate) : null,
          onEditTap: () {
            if (_isEditMode) {
              setState(() => _isEditMode = false);
            } else {
              setState(() => _isEditMode = true);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < ratingInt;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  filled
                      ? 'assets/icons/png/common/star_icon.png'
                      : 'assets/icons/png/common/star_empty_icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                    ),
            );
          }),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => EmployeeReviewScreen(
                  branchId: widget.branchId,
                  employeeId: widget.employeeId,
                  employeeName: empName,
                  hireDate: empHireDate,
                  contact: empContact,
                  resignationDate: isRetired ? empResignDate : null,
                  initialMyRating: widget.initialMyRating ?? myRating,
                  initialComment: myComment,
                  existingReviewId: myReviewId,
                ),
              ),
            );
            if (refreshed == true && mounted) {
              setState(() => _needsRefresh = true);
              _loadDetail();
            }
          },
          child: Center(
            child: Text(
              '리뷰작성',
              style: AppTypography.bodyMediumB.copyWith(
                color: const Color(0xFFA3A4AF),
                fontSize: 14,
                height: 16 / 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.solid,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentList(
          branchName: branchDisplayName,
          employeeName: empName,
          hireDate: empHireDate,
          contact: empContact,
          resignationDate: isRetired ? empResignDate : null,
          starCount: ratingInt > 0 ? ratingInt : null,
          workHistories: workHistoriesForUi,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isRetired ? null : _onRetirementTap,
          child: Center(
            child: Text(
              '퇴사',
              style: AppTypography.bodyMediumR.copyWith(
                color: isRetired
                    ? AppColors.grey100
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 상세 API 루트의 근무지(점포)명 — `work_histories` 행에 없을 때 표시용으로 병합한다.
  static String _branchNameFromDetail(Map<String, dynamic> detail) {
    final raw = detail['branch_name'] ?? detail['branchName'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    final s = raw?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
    return '';
  }

  /// YYYY-MM-DD → YYYY년 M월 D일 (한국어)
  static String _formatDateToKorean(String isoDate) {
    if (isoDate.isEmpty) return '';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  static const TextStyle _hireDateButtonStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 20 / 12,
    letterSpacing: -0.3,
    color: Color(0xFFA3A4AF),
  );

  void _showDatePickerBottomSheet(String currentValue) {
    var selected = DateTime.tryParse(currentValue) ?? DateTime.now();
    selected = DateTime(selected.year, selected.month, selected.day);

    showModalBottomSheet<void>(
          context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 280,
        decoration: const BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '취소',
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.grey150,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final formatted =
                          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      try {
                        final repo = context.read<StaffManagementRepository>();
                        await repo.patchEmployee(
                          branchId: widget.branchId,
                          employeeId: widget.employeeId,
                          data: {'hire_date': formatted},
                        );
                        if (mounted) {
                          setState(() {
                            _editableHireDate = formatted;
                            _isEditMode = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('입사일이 수정되었습니다.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('입사일 수정 실패: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      '확인',
                      style: AppTypography.bodyMediumB.copyWith(
                        color: AppColors.primaryDark,
                fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: AppTypography.bodyMediumR.copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selected,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (v) => selected = v,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHireDateInput(String currentValue) {
    final displayText = currentValue.isEmpty
        ? '입사일 설정'
        : _formatDateToKorean(currentValue);
    return GestureDetector(
      onTap: () => _showDatePickerBottomSheet(currentValue),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
        children: [
              SvgPicture.asset(
                'assets/icons/svg/icon/calendar_mint_18.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 8),
              Text(
                displayText,
                style: currentValue.isEmpty
                    ? _hireDateButtonStyle
                    : _hireDateButtonStyle.copyWith(
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w400,
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentList({
    required String branchName,
    required String employeeName,
    required String hireDate,
    required String contact,
    required String? resignationDate,
    required int? starCount,
    required List<Map<String, dynamic>> workHistories,
  }) {
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
              if (title == '근무이력') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmployeeWorkHistoryScreen(
                      branchName: branchName,
                      employeeName: employeeName,
                      hireDate: hireDate,
                      contact: contact,
                      resignationDate: resignationDate,
                      starCount: starCount,
                      workHistories: workHistories,
                    ),
                  ),
                );
                return;
              }
              if (title == '급여명세') {
                final payrollRaw = _detail!['payroll_statements'];
                Navigator.of(context)
                    .push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => PayrollStatementListScreen(
                      branchId: widget.branchId,
                      employeeId: widget.employeeId,
                      employeeName: employeeName,
                      initialItemsPayload: payrollRaw is List
                          ? {'payroll_statements': payrollRaw}
                          : null,
                    ),
                  ),
                )
                    .then((changed) {
                  if (changed == true && mounted) _loadDetail();
                });
                return;
              }
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
