import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/repositories/staff_management_repository.dart';

/// 근무자 등록 화면
/// - 연락처 검색 → 결과 시 확인 모달 → 등록 → 직원정보 형태로 표시
class WorkerRegistrationScreen extends StatefulWidget {
  const WorkerRegistrationScreen({
    super.key,
    required this.branchId,
    this.onRegistered,
  });

  final int branchId;
  final VoidCallback? onRegistered;

  @override
  State<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _searchResult; // 검색 결과 (있으면 버튼이 '등록'으로 변경)
  Map<String, dynamic>? _registeredEmployee;
  String? _errorMessage;
  String? _editableHireDate; // 등록 후 수정 가능한 입사일
  int _starRating = 0; // 0~3, 클릭 가능한 별점
  bool _isSavingEdit = false;
  bool _isProcessingRetirement = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final phone = _phoneController.text.trim().replaceAll('-', '');
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = '전화번호를 입력해주세요.';
      });
      return;
    }
    final branchId = widget.branchId;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.searchUsersByPhone(
        branchId: branchId,
        phone: phone,
      );
      final users = (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (users.isEmpty) {
        setState(() {
          _searchResult = null;
          _errorMessage = '검색 결과가 없습니다.';
        });
      } else {
        setState(() {
          _searchResult = users.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _searchResult = null;
        _errorMessage = '검색 중 오류가 발생했습니다. (API 미구현 시 발생)';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onRegister() {
    if (_searchResult == null) return;
    _showConfirmModal(_searchResult!);
  }

  void _showConfirmModal(Map<String, dynamic> user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ConfirmRegistrationDialog(
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          Navigator.pop(ctx);
          await _registerEmployee(user);
        },
      ),
    );
  }

  Future<void> _registerEmployee(Map<String, dynamic> user) async {
    final branchId = widget.branchId;

    final userId = (user['user_id'] as num?)?.toInt();
    if (userId == null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<StaffManagementRepository>();
      final hireDate = _hireDateController.text.trim();
      final data = await repo.registerEmployee(
        branchId: branchId,
        userId: userId,
        hireDate: hireDate.isEmpty ? null : hireDate,
      );
      setState(() {
        _registeredEmployee = data;
        _editableHireDate = data['hire_date'] as String?;
        _errorMessage = null;
      });
      widget.onRegistered?.call();
    } catch (e) {
      setState(() {
        _errorMessage = '등록 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _onSaveEdit() async {
    final emp = _registeredEmployee;
    if (emp == null) return;

    final employeeId = (emp['employee_id'] as num?)?.toInt();
    if (employeeId == null) return;

    final hireDate = _editableHireDate ?? emp['hire_date'] as String? ?? '';
    if (hireDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입사일을 설정해 주세요.')),
      );
      return;
    }

    setState(() => _isSavingEdit = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.patchEmployee(
        branchId: widget.branchId,
        employeeId: employeeId,
        data: {'hire_date': hireDate},
      );
      if (_starRating > 0) {
        await repo.createReview(
          branchId: widget.branchId,
          employeeId: employeeId,
          rating: _starRating,
          comment: '등록 시 평가',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다.')),
        );
        widget.onRegistered?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingEdit = false);
      }
    }
  }

  Future<void> _onRetirementTap() async {
    final emp = _registeredEmployee;
    if (emp == null) return;

    final employeeId = (emp['employee_id'] as num?)?.toInt();
    if (employeeId == null) return;

    final isRetired = (emp['employment_status'] as String?) == 'retired';
    if (isRetired) return;

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

    setState(() => _isProcessingRetirement = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      await repo.patchEmployee(
        branchId: widget.branchId,
        employeeId: employeeId,
        data: {
          'resignation_date': resignationDate,
          'employment_status': 'retired',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퇴사 처리되었습니다.')),
        );
        widget.onRegistered?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퇴사 처리 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRetirement = false);
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
          '근무자 등록',
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
      body: _registeredEmployee != null
          ? _buildRegisteredView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRegistrationCard(),
                  const SizedBox(height: 16),
                  _buildDocumentList(),
                ],
              ),
            ),
    );
  }

  Widget _buildRegistrationCard() {
    return Container(
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
          Text(
            '근무자',
            style: AppTypography.bodyMediumM.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: '앱내 가입된 근무자 연락처를 검색해주세요.',
              hintStyle: AppTypography.bodyMediumR.copyWith(
                color: AppColors.grey100,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 19 / 13,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  'assets/icons/svg/icon/search_mint_20.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              filled: true,
              fillColor: AppColors.grey0Alt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey50),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.phone,
            onSubmitted: (_) => _searchResult == null ? _onSearch() : _onRegister(),
          ),
          if (_searchResult != null) ...[
            const SizedBox(height: 8),
            Text(
              _searchResult!['name'] as String? ?? '-',
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSearching
                  ? null
                  : () => _searchResult != null ? _onRegister() : _onSearch(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _searchResult != null ? '등록' : '검색',
                style: AppTypography.bodyLargeB.copyWith(
                  color: AppColors.grey0,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 24 / 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                    onPressed: () {
                      final formatted =
                          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                      Navigator.pop(ctx);
                      if (mounted) {
                        setState(() => _editableHireDate = formatted);
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

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    color: Color(0xFF666874),
  );

  static const TextStyle _valueStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 19 / 14,
    color: Color(0xFF000000),
  );

  static const TextStyle _hireDateButtonStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 20 / 12,
    letterSpacing: -0.3,
    color: Color(0xFFA3A4AF),
  );

  /// YYYY-MM-DD → YYYY년 M월 D일 (한국어)
  static String _formatDateToKorean(String isoDate) {
    if (isoDate.isEmpty) return '';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return '${d.year}년 ${d.month}월 ${d.day}일';
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

  Widget _buildDocumentList() {
    const items = [
      '근무이력',
      '급여명세',
      '근로계약서',
      '연소근로자(18세 미만) 표준근로계약',
      '친권동의서',
      '기타',
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

  Widget _buildRegisteredView() {
    final emp = _registeredEmployee!;
    final name = emp['name'] as String? ?? '-';
    final hireDate = _editableHireDate ?? emp['hire_date'] as String? ?? '';
    final phone = emp['phone_number'] as String? ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/svg/icon/profile_default_80.svg',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('근무자명', style: _labelStyle),
                              Text(name, style: _valueStyle),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('입사일', style: _labelStyle),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildHireDateInput(hireDate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('연락처', style: _labelStyle),
                              Text(
                                phone.isEmpty ? '-' : phone,
                                style: _valueStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final filled = i < _starRating;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _starRating = (_starRating == i + 1) ? 0 : i + 1;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
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
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('평가작성 기능은 곧 연결됩니다.')),
                    );
                  },
                  child: Center(
                    child: Text(
                      '평가작성',
                      style: AppTypography.bodyMediumB.copyWith(
                        color: AppColors.grey150,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 16 / 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.grey150,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSavingEdit ? null : _onSaveEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSavingEdit
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.grey0,
                            ),
                          )
                        : const Text('수정'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentList(),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: (emp['employment_status'] as String?) == 'retired' ||
                    _isProcessingRetirement
                ? null
                : _onRetirementTap,
            child: Center(
              child: Text(
                '퇴사',
                style: AppTypography.bodyMediumB.copyWith(
                  color: (emp['employment_status'] as String?) == 'retired'
                      ? AppColors.grey100
                      : AppColors.grey150,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 16 / 14,
                  decoration: TextDecoration.underline,
                  decorationColor: (emp['employment_status'] as String?) == 'retired'
                      ? AppColors.grey100
                      : AppColors.grey150,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRegistrationDialog extends StatelessWidget {
  const _ConfirmRegistrationDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/svg/icon/question_mint_60.svg',
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '해당 근무자를 등록하시겠습니까?',
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.grey25,
                      foregroundColor: AppColors.grey150,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.grey0,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

