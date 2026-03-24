import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../payroll/payroll_formatters.dart';
import '../widgets/validated_auth_input_field.dart';

/// 급여명세 작성 (API: calculate → create)
class PayrollStatementFormScreen extends StatefulWidget {
  const PayrollStatementFormScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;

  @override
  State<PayrollStatementFormScreen> createState() =>
      _PayrollStatementFormScreenState();
}

class _PayrollStatementFormScreenState extends State<PayrollStatementFormScreen> {
  static const TextStyle _heading2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 26 / 20,
    color: Color(0xFF000000),
  );

  final _formKey = GlobalKey<FormState>();
  final _residentCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _hourlyCtrl = TextEditingController();
  final _basePayCtrl = TextEditingController();
  final _weeklyCountCtrl = TextEditingController();
  final _weeklyCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController(text: '0');

  final _dedNationalCtrl = TextEditingController();
  final _dedHealthCtrl = TextEditingController();
  final _dedEmployCtrl = TextEditingController();
  final _dedLongTermCtrl = TextEditingController();
  final _dedIncomeCtrl = TextEditingController();
  final _dedLocalCtrl = TextEditingController();
  final _dedOtherCtrl = TextEditingController();

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _deductionFillLoading = false;
  bool _deductionAmountsLoaded = false;
  final List<bool> _deductionChecked =
      List<bool>.generate(7, (_) => false);

  bool _submitting = false;
  bool _autoFillLoading = false;
  int _autoFillSeq = 0;

  static const EdgeInsets _payrollInputPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);

  @override
  void initState() {
    super.initState();
    _hoursCtrl.addListener(_updateBasePayDisplay);
    _hourlyCtrl.addListener(_updateBasePayDisplay);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAutoFill());
  }

  @override
  void dispose() {
    _hoursCtrl.removeListener(_updateBasePayDisplay);
    _hourlyCtrl.removeListener(_updateBasePayDisplay);
    _residentCtrl.dispose();
    _hoursCtrl.dispose();
    _hourlyCtrl.dispose();
    _basePayCtrl.dispose();
    _weeklyCountCtrl.dispose();
    _weeklyCtrl.dispose();
    _overtimeCtrl.dispose();
    _dedNationalCtrl.dispose();
    _dedHealthCtrl.dispose();
    _dedEmployCtrl.dispose();
    _dedLongTermCtrl.dispose();
    _dedIncomeCtrl.dispose();
    _dedLocalCtrl.dispose();
    _dedOtherCtrl.dispose();
    super.dispose();
  }

  void _updateBasePayDisplay() {
    final h = PayrollFormatters.parseDigits(_hoursCtrl.text) ?? 0;
    final w = PayrollFormatters.parseDigits(_hourlyCtrl.text) ?? 0;
    final base = h * w;
    _basePayCtrl.text = base > 0 ? base.toString() : '';
  }

  void _applyAutoFill(Map<String, dynamic> d) {
    _hoursCtrl.removeListener(_updateBasePayDisplay);
    _hourlyCtrl.removeListener(_updateBasePayDisplay);
    try {
      final minutes = (d['total_work_minutes'] as num?)?.toInt();
      final hourly = (d['hourly_wage'] as num?)?.toInt();
      final base = (d['base_pay'] as num?)?.toInt();
      final weekly = (d['weekly_allowance'] as num?)?.toInt();
      final overtime = (d['overtime_pay'] as num?)?.toInt() ?? 0;
      final resident = d['resident_id_masked'];

      if (minutes != null && minutes > 0) {
        _hoursCtrl.text = (minutes / 60).round().toString();
      }
      if (hourly != null) _hourlyCtrl.text = hourly.toString();
      if (base != null) {
        _basePayCtrl.text = base.toString();
      } else {
        _updateBasePayDisplay();
      }
      if (weekly != null) _weeklyCtrl.text = weekly.toString();
      _overtimeCtrl.text = overtime > 0 ? overtime.toString() : '0';
      if (resident is String && resident.isNotEmpty) {
        _residentCtrl.text = resident;
      }
      _deductionAmountsLoaded = false;
    } finally {
      _hoursCtrl.addListener(_updateBasePayDisplay);
      _hourlyCtrl.addListener(_updateBasePayDisplay);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadAutoFill() async {
    final seq = ++_autoFillSeq;
    if (mounted) setState(() => _autoFillLoading = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getPayrollStatementAutoFill(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        year: _year,
        month: _month,
      );
      if (!mounted || seq != _autoFillSeq) return;
      _applyAutoFill(data);
    } catch (_) {
      // 자동 채우기 미지원·네트워크 오류 시 수동 입력 유지
    } finally {
      if (mounted && seq == _autoFillSeq) {
        setState(() => _autoFillLoading = false);
      }
    }
  }

  List<TextEditingController> get _deductionControllers => [
        _dedNationalCtrl,
        _dedHealthCtrl,
        _dedEmployCtrl,
        _dedLongTermCtrl,
        _dedIncomeCtrl,
        _dedLocalCtrl,
        _dedOtherCtrl,
      ];

  static const List<String> _deductionLabels = [
    '국민연금',
    '건강보험',
    '고용보험',
    '장기요양보험료',
    '소득세',
    '지방소득세',
    '기타정산금',
  ];

  Map<String, dynamic> _buildBody() {
    final hours = PayrollFormatters.parseDigits(_hoursCtrl.text) ?? 0;
    final totalMinutes = hours * 60;
    return {
      'year': _year,
      'month': _month,
      'resident_id_masked': _residentCtrl.text.trim(),
      'total_work_minutes': totalMinutes,
      'hourly_wage': PayrollFormatters.parseDigits(_hourlyCtrl.text) ?? 0,
      'weekly_allowance': PayrollFormatters.parseDigits(_weeklyCtrl.text) ?? 0,
      'overtime_pay': PayrollFormatters.parseDigits(_overtimeCtrl.text) ?? 0,
      'taxable_salary': null,
      'gross_salary': null,
    };
  }

  static String _amountToFieldText(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toInt().toString();
    return '';
  }

  Future<void> _fillDeductionsFromCalculate() async {
    setState(() => _deductionFillLoading = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.calculatePayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        body: _buildBody(),
      );
      if (!mounted) return;
      setState(() {
        _dedNationalCtrl.text = _amountToFieldText(data['national_pension']);
        _dedHealthCtrl.text = _amountToFieldText(data['health_insurance']);
        _dedEmployCtrl.text = _amountToFieldText(data['employment_insurance']);
        _dedLongTermCtrl.text =
            _amountToFieldText(data['long_term_care_insurance']);
        _dedIncomeCtrl.text = _amountToFieldText(data['income_tax']);
        _dedLocalCtrl.text = _amountToFieldText(data['local_income_tax']);
        _deductionAmountsLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공제액 자동 입력을 위해 급여 정보를 확인해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deductionFillLoading = false);
    }
  }

  Future<void> _onDeductionCheckChanged(int index, bool? value) async {
    final on = value ?? false;
    setState(() => _deductionChecked[index] = on);

    if (!on) return;

    // 기타정산금(7번째): 서버 미리계산 항목 없음 → 입력만
    if (index == 6) return;

    if (!_deductionAmountsLoaded) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위 급여 정보를 먼저 입력해 주세요.'),
            ),
          );
        }
        setState(() => _deductionChecked[index] = false);
        return;
      }
      await _fillDeductionsFromCalculate();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final body = _buildBody();
      await repo.calculatePayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        body: body,
      );
      await repo.createPayrollStatement(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        body: body,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('급여명세가 저장되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _pickWorker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.grey0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '근무자 선택',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumB.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(widget.employeeName),
                  subtitle: const Text('현재 직원'),
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(6, (i) => DateTime.now().year - i);
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('급여명세 작성'),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('급여명세', style: _heading2),
                    const SizedBox(height: 16),
                    if (_autoFillLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '근무·급여 정보를 불러오는 중…',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text('근무자', style: _labelStyle),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickWorker,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _fieldDecoration('근무자를 선택해주세요'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.employeeName,
                                style: AppTypography.bodyMediumR.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.grey150),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('년도', style: _labelStyle),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: _year,
                                decoration: _fieldDecoration('선택해주세요.'),
                                items: years
                                    .map((y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y년'),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _year = v ?? _year);
                                  _loadAutoFill();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('월', style: _labelStyle),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                value: _month,
                                decoration: _fieldDecoration('선택해주세요.'),
                                items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text('${i + 1}월'),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() => _month = v ?? _month);
                                  _loadAutoFill();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('주민번호', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _residentCtrl,
                      hintText: '선택 입력',
                      keyboardType: TextInputType.text,
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                    ),
                    const SizedBox(height: 14),
                    Text('총 근무 시간', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _hoursCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 시간',
                      validator: (v) {
                        if (PayrollFormatters.parseDigits(v ?? '') == null) {
                          return '근무 시간을 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('시급', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _hourlyCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 원',
                      validator: (v) {
                        if (PayrollFormatters.parseDigits(v ?? '') == null) {
                          return '시급을 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('기본급', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _basePayCtrl,
                      hintText: '',
                      readOnly: true,
                      fillColor: AppColors.grey25,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 원',
                    ),
                    const SizedBox(height: 14),
                    Text('주휴횟수', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _weeklyCountCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 회',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '주휴수당 (원)',
                      style: _labelStyle,
                    ),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _weeklyCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 원',
                      validator: (v) {
                        if (PayrollFormatters.parseDigits(v ?? '') == null) {
                          return '주휴수당을 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('연장·야간·휴일 수당', style: _labelStyle),
                    const SizedBox(height: 6),
                    ValidatedAuthInputField(
                      controller: _overtimeCtrl,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      fillColor: AppColors.grey0,
                      contentPadding: _payrollInputPadding,
                      suffixText: ' 원',
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        if (PayrollFormatters.parseDigits(t) == null) {
                          return '숫자만 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(height: 1, thickness: 1, color: AppColors.grey50),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('공제항목', style: _heading2),
                        if (_deductionFillLoading) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_deductionLabels.length, (i) {
                      final isOther = i == 6;
                      final expanded = _deductionChecked[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _deductionLabels[i],
                                      style: AppTypography.bodyMediumM.copyWith(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: _deductionChecked[i],
                                  onChanged: _deductionFillLoading
                                      ? null
                                      : (v) => _onDeductionCheckChanged(i, v),
                                  checkColor: AppColors.grey0,
                                  fillColor:
                                      WidgetStateProperty.resolveWith((s) {
                                    if (s.contains(WidgetState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return Colors.transparent;
                                  }),
                                  side: BorderSide(
                                    color: AppColors.grey100,
                                    width: 1.5,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox(width: double.infinity),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ValidatedAuthInputField(
                                  controller: _deductionControllers[i],
                                  hintText: isOther
                                      ? '기타 정산금을 입력해주세요.'
                                      : '자동 입력 후 수정가능',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  fillColor: AppColors.grey0,
                                  contentPadding: _payrollInputPadding,
                                  focusedBorderColor: AppColors.primaryDark,
                                  hintStyle:
                                      AppTypography.bodyMediumR.copyWith(
                                    color: isOther
                                        ? AppColors.textTertiary
                                        : AppColors.primary,
                                    fontSize: 14,
                                    height: 19 / 14,
                                  ),
                                ),
                              ),
                              crossFadeState: expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                              sizeCurve: Curves.easeInOut,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
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
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
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
      ),
    );
  }

  TextStyle get _labelStyle => AppTypography.bodySmallB.copyWith(
        color: AppColors.textSecondary,
        fontSize: 13,
      );

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.grey0,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey50),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey50),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
    );
  }
}
