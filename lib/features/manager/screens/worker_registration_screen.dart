import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import '../../account/account_dio_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/repositories/staff_management_repository.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import 'employee_document_menu_actions.dart';
import 'guest_worker_registration_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser; // 선택된 검색 결과 (있으면 버튼이 '등록'으로 변경)
  Map<String, dynamic>? _registeredEmployee;
  String? _errorMessage;
  String? _editableHireDate; // 등록 후 수정 가능한 입사일
  int _starRating = 0; // 0~3, 클릭 가능한 별점
  bool _isSavingEdit = false;
  bool _isProcessingRetirement = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_selectedUser != null || _searchResults.isNotEmpty) {
      setState(() {
        _selectedUser = null;
        _searchResults = [];
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
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
      _searchResults = [];
      _selectedUser = null;
    });

    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.searchUsersByPhone(
        branchId: branchId,
        phone: phone,
      );
      final users =
          (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (users.isEmpty) {
        setState(() {
          _searchResults = [];
          _errorMessage = '검색 결과가 없습니다.';
        });
      } else {
        setState(() {
          _searchResults = users;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _errorMessage = '검색 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onRegister() {
    if (_selectedUser == null) return;
    _showConfirmModal(_selectedUser!);
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
    final phone = user['phone_number']?.toString();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<StaffManagementRepository>();
      final duplicate = await _findDuplicateEmployee(
        repo: repo,
        userId: userId,
        phone: phone,
      );
      if (duplicate != null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = _duplicateEmployeeMessage(duplicate);
        });
        return;
      }

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
        _errorMessage = accountDioMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _findDuplicateEmployee({
    required StaffManagementRepository repo,
    required int userId,
    String? phone,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final compare = await repo.getEmployeesCompare(
      branchId: widget.branchId,
      q: normalizedPhone.isEmpty ? phone : normalizedPhone,
    );
    final employees = [
      ...(compare['active_workers'] as List? ?? const []),
      ...(compare['retired_workers'] as List? ?? const []),
    ].whereType<Map>().map((item) => Map<String, dynamic>.from(item));

    for (final employee in employees) {
      final linkedUserId = (employee['linked_user_id'] as num?)?.toInt();
      final employeePhone = _normalizePhone(employee['phone_number']);
      if (linkedUserId == userId ||
          (normalizedPhone.isNotEmpty && employeePhone == normalizedPhone)) {
        return employee;
      }
    }
    return null;
  }

  String _duplicateEmployeeMessage(Map<String, dynamic> employee) {
    final name = employee['name']?.toString().trim();
    final status = employee['employment_status']?.toString();
    final statusLabel = status == 'retired' ? '퇴사자' : '현근무자';
    if (name != null && name.isNotEmpty) {
      return '$name님은 이미 $statusLabel로 등록되어 있습니다.';
    }
    return '이미 등록된 근로자입니다.';
  }

  String _normalizePhone(Object? value) {
    return value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  }

  Future<void> _onSaveEdit() async {
    final emp = _registeredEmployee;
    if (emp == null) return;

    final employeeId = (emp['employee_id'] as num?)?.toInt();
    if (employeeId == null) return;

    final hireDate = _editableHireDate ?? emp['hire_date'] as String? ?? '';
    if (hireDate.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입사일을 설정해 주세요.')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        widget.onRegistered?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${userFriendlyErrorMessage(e)}')),
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

    final confirmed = await showAppStyledConfirmDialog(
      context,
      message: '이 근무자를 퇴사 처리하시겠습니까?\n퇴사일은 오늘 날짜로 등록됩니다.',
      confirmLabel: '확인',
      confirmBackgroundColor: AppColors.primaryDark,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('퇴사 처리되었습니다.')));
        widget.onRegistered?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퇴사 처리 실패: ${userFriendlyErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRetirement = false);
      }
    }
  }

  Future<void> _openGuestWorkerRegistration() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GuestWorkerRegistrationScreen(
          branchId: widget.branchId,
          onRegistered: widget.onRegistered,
        ),
      ),
    );
    if (changed == true) {
      widget.onRegistered?.call();
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
        title: const Text('근무자 등록'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: _registeredEmployee != null
          ? _buildRegisteredView()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _GuestWorkerRegisterChip(
                      onTap: _openGuestWorkerRegistration,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildRegistrationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildRegistrationCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
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
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '앱내 가입된 근무자 연락처를 검색해주세요.',
              hintStyle: AppTypography.bodyMediumR.copyWith(
                color: AppColors.grey100,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 19 / 13,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.r),
                child: SvgPicture.asset(
                  'assets/icons/svg/icon/search_mint_20.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              filled: true,
              fillColor: AppColors.grey0Alt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.grey50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.grey50),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            onSubmitted: (_) =>
                _selectedUser == null ? _onSearch() : _onRegister(),
          ),
          if (_searchResults.isNotEmpty && _selectedUser == null) ...[
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey0,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.grey50),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.grey50),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final name = user['name'] as String? ?? '-';
                  final phone = user['phone_number'] as String? ?? '-';
                  return ListTile(
                    title: Text(name, style: AppTypography.bodyMediumM),
                    subtitle: Text(phone, style: AppTypography.bodySmall),
                    onTap: () {
                      setState(() {
                        _selectedUser = user;
                      });
                    },
                  );
                },
              ),
            ),
          ],
          if (_selectedUser != null) ...[
            SizedBox(height: 8.h),
            Text(
              _selectedUser!['name'] as String? ?? '-',
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSearching
                  ? null
                  : () => _selectedUser != null ? _onRegister() : _onSearch(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.grey0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                _selectedUser != null ? '등록' : '검색',
                style: AppTypography.bodyLargeB.copyWith(
                  color: AppColors.grey0,
                  fontSize: 16.sp,
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
        decoration: BoxDecoration(
          color: AppColors.grey0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '취소',
                      style: AppTypography.bodyMediumM.copyWith(
                        color: AppColors.grey150,
                        fontSize: 14.sp,
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
                        fontSize: 14.sp,
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
                      fontSize: 20.sp,
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

  static TextStyle get _labelStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    color: Color(0xFF666874),
  );

  static TextStyle get _valueStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 19 / 14,
    color: Color(0xFF000000),
  );

  static TextStyle get _hireDateButtonStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(5.r),
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
              SizedBox(width: 8.w),
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
    required bool registered,
    Map<String, dynamic>? employee,
  }) {
    const items = [
      '근무이력',
      '급여명세',
      '근로계약서',
      '연소근로자(18세 미만) 표준근로계약',
      '친권동의서',
      '기타',
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey50),
      ),
      child: Column(
        children: items.map((title) {
          return ListTile(
            title: Text(
              title,
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey100,
            ),
            onTap: () {
              if (!registered || employee == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('근무자 등록 후 이용할 수 있습니다.')),
                );
                return;
              }
              final employeeId = (employee['employee_id'] as num?)?.toInt();
              if (employeeId == null) return;
              final name = employee['name'] as String? ?? '-';
              final hireDate =
                  _editableHireDate ?? employee['hire_date'] as String? ?? '';
              final phone = employee['phone_number'] as String? ?? '-';
              openEmployeeDocumentMenuItem(
                context,
                title: title,
                branchId: widget.branchId,
                employeeId: employeeId,
                employeeName: name,
                branchName: '-',
                hireDate: hireDate,
                contact: phone,
                resignationDate:
                    (employee['employment_status'] as String?) == 'retired'
                    ? employee['resignation_date'] as String?
                    : null,
                starCount: null,
                workHistories: const <Map<String, dynamic>>[],
                payrollStatementsRaw: null,
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
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9FEDD4), Color(0xFFE1F0B8)],
              ),
              borderRadius: BorderRadius.circular(16.r),
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
                    SizedBox(width: 16.w),
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
                          SizedBox(height: 8.h),
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
                          SizedBox(height: 8.h),
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
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final filled = i < _starRating;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _starRating = (_starRating == i + 1) ? 0 : i + 1;
                      }),
                      child: Padding(
                        padding: EdgeInsets.only(right: 4.w),
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
                SizedBox(height: 4.h),
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
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        height: 16 / 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.grey150,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSavingEdit ? null : _onSaveEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
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
          SizedBox(height: 16.h),
          _buildDocumentList(registered: true, employee: emp),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap:
                (emp['employment_status'] as String?) == 'retired' ||
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 16 / 14,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      (emp['employment_status'] as String?) == 'retired'
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

class _GuestWorkerRegisterChip extends StatelessWidget {
  const _GuestWorkerRegisterChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.textSecondary,
      borderRadius: BorderRadius.circular(4.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Text(
            '비회원 근무자 등록',
            style: AppTypography.bodySmallB.copyWith(
              color: AppColors.grey0,
              fontSize: 12.sp,
              height: 16 / 12,
            ),
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/svg/icon/question_mint_60.svg',
              width: 60,
              height: 60,
            ),
            SizedBox(height: 16.h),
            Text(
              '해당 근무자를 등록하시겠습니까?',
              style: AppTypography.bodyMediumM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 16 / 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.grey25,
                      foregroundColor: AppColors.grey150,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.grey0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: AppTypography.bodyLargeB.copyWith(
                        color: AppColors.grey0,
                        fontSize: 16.sp,
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
