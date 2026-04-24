import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/thousands_separator_input_formatter.dart';
import '../../../data/repositories/staff_management_repository.dart';
import '../../../utils/contract_work_day_form.dart';
import '../../../utils/modal_title_format.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/contract_signature.dart';
import '../../auth/widgets/auth_input_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

String _stripCommaNumber(String s) => s.replaceAll(',', '').trim();

/// 친권 동의서 칩: 색은 민트(사업장)·주황(후견인·연소)만. 빈 칩 문구만 「입력」「근로자」「후견인 입력」.
enum _ContractChipTone { mint, worker, guardian }

/// 근로계약서 작성·수정 (표준/연소/친권: 법정 문구 + 인라인 입력 칩)
class EmploymentContractFormScreen extends StatefulWidget {
  const EmploymentContractFormScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.templateVersion,
    required this.listTitle,
    this.contractId,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final String templateVersion;
  final String listTitle;
  final int? contractId;

  bool get isGuardian => templateVersion == 'guardian_consent_v1';
  bool get isMinor => templateVersion == 'minor_standard_v1';

  @override
  State<EmploymentContractFormScreen> createState() =>
      _EmploymentContractFormScreenState();
}

class _EmploymentContractFormScreenState
    extends State<EmploymentContractFormScreen> {
  /// 근로자 구간 입력 칩 (Figma Accents-Orange #FF8D28)
  static const Color _workerChipBg = Color(0xFFFFF6ED);
  static const Color _workerChipFg = Color(0xFFFF8D28);

  /// 사업주·일반 입력 칩 배경 (Figma light mint)
  static const Color _mintChipBg = Color(0xFFE2F6F0);

  /// 표준·연소·친권 인라인 칩 공통 패딩 (민트/오렌지, 높이 절약)
  static EdgeInsets get _contractChipPadding =>
      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h);
  static EdgeInsets get _contractChipPaddingWide =>
      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h);

  /// 모달 하단 취소·확인 (Figma 8px)
  static final OutlinedBorder _modalActionButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8.r),
  );

  static const String _svgPickerChevronDown =
      'assets/icons/svg/icon/contract_picker_chevron_down.svg';
  static const String _svgPickerChevronUp =
      'assets/icons/svg/icon/contract_picker_chevron_up.svg';

  /// Figma Heading_3 — 근로계약기간 / 소정근로시간 제목
  static TextStyle get _figmaModalHeading => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    color: Color(0xFF000000),
  );

  /// 시작·종료 (body medium_M)
  static TextStyle get _figmaSectionLabel => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: -0.3,
    color: Color(0xFF1D1D1F),
  );

  /// 년도·월·일 / 근무시작 등 라벨 pill (Body Small_M)
  static TextStyle get _figmaPillLabel => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.0,
    color: Color(0xFFA3A4AF),
  );

  /// Inter-regular-18 숫자
  static TextStyle get _figmaInterValue18 => TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.sp,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: Color(0xFF454545),
  );

  /// · 중복 입력 가능 (body medium_M, muted)
  static TextStyle get _figmaWorkTimeSubnote => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: -0.3,
    color: Color(0xFFA3A4AF),
  );

  /// Figma 2534-14920 — 본문 (grey8 #000, 14 / 25)
  static TextStyle get _contractFigmaBody => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 25 / 14,
    color: Color(0xFF000000),
  );

  /// Figma Accents-Orange — 자동 기입 안내
  static TextStyle get _contractFigmaAccent => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 25 / 14,
    color: Color(0xFFFF8D28),
  );

  Widget _pickerChevron({required bool up, required bool whiteCircle}) {
    final asset = up ? _svgPickerChevronUp : _svgPickerChevronDown;
    final pic = SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
    if (!whiteCircle) {
      return SizedBox(width: 36, height: 36, child: Center(child: pic));
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(18.r),
      ),
      alignment: Alignment.center,
      child: pic,
    );
  }

  final _titleCtrl = TextEditingController();
  final Map<String, TextEditingController> _c = {};

  int? _contractId;
  bool _loading = false;
  bool _bootLoading = true;

  String _wageType = 'monthly';
  String _paymentMethod = 'bank_transfer';
  bool _bonusIncluded = false;
  bool _otherAllowanceIncluded = false;
  bool _contractDelivery = false;
  bool _lawReference = false;

  @override
  void initState() {
    super.initState();
    _contractId = widget.contractId;
    _initControllers();
    _bootstrap();
  }

  void _initControllers() {
    void reg(Iterable<String> keys) {
      for (final k in keys) {
        _c.putIfAbsent(k, TextEditingController.new);
      }
    }

    if (widget.isGuardian) {
      reg(const [
        'guardian_name',
        'guardian_resident_id_masked',
        'guardian_address',
        'guardian_phone_number',
        'relation_to_minor_worker',
        'minor_name',
        'minor_age',
        'minor_resident_id_masked',
        'minor_address',
        'business_name',
        'business_address',
        'business_representative_name',
        'business_phone_number',
        'consent_minor_name',
        'consent_signed_date',
        'guardian_signature_name',
      ]);
    } else {
      reg(const [
        'employer_name',
        'worker_name',
        'contract_start_date',
        'contract_end_date',
        'work_place',
        'job_description',
        'scheduled_work_start_time',
        'scheduled_work_end_time',
        'break_start_time',
        'break_end_time',
        'work_days_per_week',
        'weekly_holiday_day',
        'wage_amount',
        'bonus_amount',
        'other_allowance_amount',
        'meal_allowance',
        'transport_allowance',
        'extra_allowance_name',
        'extra_allowance_amount',
        'payment_day',
        'annual_leave_note',
        'contract_signed_date',
        'employer_business_name',
        'employer_phone',
        'employer_address',
        'employer_representative_name',
        'employer_signature_text',
        'worker_address',
        'worker_phone',
        'worker_signature_text',
        'family_relation_certificate_submitted',
        'guardian_consent_submitted',
      ]);
      for (var i = 0; i < 7; i++) {
        reg([
          contractWorkDayFormFieldKey(i, 'enabled'),
          contractWorkDayFormFieldKey(i, 'start'),
          contractWorkDayFormFieldKey(i, 'end'),
          contractWorkDayFormFieldKey(i, 'break_has'),
          contractWorkDayFormFieldKey(i, 'break_start'),
          contractWorkDayFormFieldKey(i, 'break_end'),
        ]);
      }
    }
  }

  Future<void> _bootstrap() async {
    _c['worker_name']?.text = widget.employeeName;
    if (_contractId == null) {
      if (mounted) setState(() => _bootLoading = false);
      return;
    }
    try {
      final repo = context.read<StaffManagementRepository>();
      final d = await repo.getEmploymentContractDetail(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        contractId: _contractId!,
      );
      _titleCtrl.text = d['title']?.toString() ?? '';
      final fvRaw = (d['form_values'] as Map?)?.cast<String, dynamic>();
      if (fvRaw != null) {
        final fv = migrateLegacyWorkDayKeysInMap(fvRaw);
        for (final e in fv.entries) {
          final key = e.key;
          final val = e.value;
          if (val == null) continue;
          if (key == 'bonus_included') {
            _bonusIncluded = val == true || val == 'true';
            continue;
          }
          if (key == 'other_allowance_included') {
            _otherAllowanceIncluded = val == true || val == 'true';
            continue;
          }
          if (key == 'contract_delivery_confirmed') {
            _contractDelivery = val == true || val == 'true';
            continue;
          }
          if (key == 'law_reference_confirmed') {
            _lawReference = val == true || val == 'true';
            continue;
          }
          if (key == 'wage_type' && val is String) {
            _wageType = val;
            continue;
          }
          if (key == 'payment_method' && val is String) {
            _paymentMethod = val;
            continue;
          }
          _c[key]?.text = val.toString();
        }
      }
      for (final k in _wonAmountFieldKeys) {
        final c = _c[k];
        if (c != null && c.text.trim().isNotEmpty) {
          final f = _formatWonForDisplay(c.text);
          if (f.isNotEmpty) c.text = f;
        }
      }
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _bootLoading = false);
    }
  }

  static const _numericKeys = {
    'work_days_per_week',
    'wage_amount',
    'bonus_amount',
    'other_allowance_amount',
    'meal_allowance',
    'transport_allowance',
    'extra_allowance_amount',
    'payment_day',
    'minor_age',
  };

  /// 임금·수당 등 원 단위(화면·저장 시 콤마 제거 후 정수)
  static const Set<String> _wonAmountFieldKeys = {
    'wage_amount',
    'bonus_amount',
    'other_allowance_amount',
    'meal_allowance',
    'transport_allowance',
    'extra_allowance_amount',
  };

  String _formatWonForDisplay(String? raw) {
    final cleaned = _stripCommaNumber(raw ?? '');
    if (cleaned.isEmpty) return '';
    final n = int.tryParse(cleaned);
    if (n == null) return (raw ?? '').trim();
    return NumberFormat('#,###', 'ko_KR').format(n);
  }

  Map<String, dynamic> _collectFormValues() {
    final out = <String, dynamic>{};
    for (final e in _c.entries) {
      if (_numericKeys.contains(e.key)) continue;
      final t = e.value.text.trim();
      if (t.isNotEmpty) {
        out[e.key] = t;
      }
    }
    int? pi(String k) {
      final t = _c[k]?.text.trim() ?? '';
      if (t.isEmpty) return null;
      return int.tryParse(t.replaceAll(',', ''));
    }

    if (!widget.isGuardian) {
      out['wage_type'] = _wageType;
      out['payment_method'] = _paymentMethod;
      out['bonus_included'] = _bonusIncluded;
      out['other_allowance_included'] = _otherAllowanceIncluded;
      out['contract_delivery_confirmed'] = _contractDelivery;
      out['law_reference_confirmed'] = _lawReference;
      final wd = pi('work_days_per_week');
      if (wd != null) out['work_days_per_week'] = wd;
      final wa = pi('wage_amount');
      if (wa != null) out['wage_amount'] = wa;
      if (_bonusIncluded) {
        final ba = pi('bonus_amount');
        if (ba != null) out['bonus_amount'] = ba;
      }
      if (_otherAllowanceIncluded) {
        final oa = pi('other_allowance_amount');
        if (oa != null) out['other_allowance_amount'] = oa;
      }
      final ma = pi('meal_allowance');
      if (ma != null) out['meal_allowance'] = ma;
      final ta = pi('transport_allowance');
      if (ta != null) out['transport_allowance'] = ta;
      final ea = pi('extra_allowance_amount');
      if (ea != null) out['extra_allowance_amount'] = ea;
      final pd = pi('payment_day');
      if (pd != null) out['payment_day'] = pd;
      final ww = <int>[];
      for (var i = 0; i < 7; i++) {
        if (_c[contractWorkDayFormFieldKey(i, 'enabled')]?.text.trim() ==
            '1') {
          ww.add(i + 1);
        }
      }
      if (ww.isNotEmpty) {
        out['work_weekdays'] = ww;
      }
    } else {
      final age = pi('minor_age');
      if (age != null) out['minor_age'] = age;
    }
    return out;
  }

  bool _fieldNonEmpty(String key) => (_c[key]?.text.trim().isNotEmpty ?? false);

  bool _isWorkerOwnedField(String key) => switch (key) {
    'worker_name' ||
    'worker_address' ||
    'worker_phone' ||
    'worker_signature_text' ||
    'minor_name' ||
    'minor_age' ||
    'minor_resident_id_masked' ||
    'minor_address' => true,
    _ => false,
  };

  /// `docs/api_spec_staff_management.md` §28 `guardian_consent_v1` 완료 필수 필드(16개)만 검사.
  /// 가족관계증명서 **파일**은 완료 시점에 필수 아님(이후 PATCH file). 화면 문구는 양식대로 유지.
  List<String> _missingFieldsForGuardianCompletion() {
    final m = <String>[];
    if (!widget.isGuardian) return m;
    if (!_fieldNonEmpty('guardian_name')) m.add('친권자(후견인) 성명');
    if (!_fieldNonEmpty('guardian_resident_id_masked')) {
      m.add('친권자 주민등록번호(마스킹)');
    }
    if (!_fieldNonEmpty('guardian_address')) m.add('친권자 주소');
    if (!_fieldNonEmpty('guardian_phone_number')) m.add('친권자 연락처');
    if (!_fieldNonEmpty('relation_to_minor_worker')) {
      m.add('연소근로자와의 관계');
    }
    if (!_fieldNonEmpty('business_name')) m.add('회사명');
    if (!_fieldNonEmpty('business_address')) m.add('회사주소');
    if (!_fieldNonEmpty('business_representative_name')) m.add('대표자');
    if (!_fieldNonEmpty('business_phone_number')) m.add('회사전화');
    if (!_fieldNonEmpty('consent_minor_name')) m.add('동의문 속 연소근로자명');
    final signed = _c['consent_signed_date']?.text.trim() ?? '';
    if (signed.isEmpty || DateTime.tryParse(signed) == null) {
      m.add('동의서 작성일(연·월·일)');
    }
    if (!_fieldNonEmpty('guardian_signature_name')) {
      m.add('친권자(후견인) 서명');
    }
    return m;
  }

  /// `docs/api_spec_staff_management.md` §23 `standard_v1` / `minor_standard_v1` 완료 필수
  List<String> _missingFieldsForStandardCompletion() {
    final m = <String>[];
    if (widget.isGuardian) return m;

    if (!_fieldNonEmpty('employer_name') &&
        !_fieldNonEmpty('employer_business_name')) {
      m.add('사업주명(상단) 또는 사업체명(하단) 중 하나 이상');
    }
    if (!_fieldNonEmpty('worker_name')) m.add('근로자명');

    final startDate = _c['contract_start_date']?.text.trim() ?? '';
    if (startDate.isEmpty) {
      m.add('근로개시일(근로계약기간 시작일)');
    } else if (DateTime.tryParse(startDate) == null) {
      m.add('근로개시일(날짜 형식 확인)');
    }

    if (!_fieldNonEmpty('work_place')) m.add('근무 장소');
    if (!_fieldNonEmpty('job_description')) m.add('업무 내용');

    final sws = _c['scheduled_work_start_time']?.text.trim() ?? '';
    final swe = _c['scheduled_work_end_time']?.text.trim() ?? '';
    if (sws.isEmpty || swe.isEmpty) {
      m.add('소정근로시간(시작·종료 시각)');
    }

    final wdpw = int.tryParse(_c['work_days_per_week']?.text.trim() ?? '');
    if (wdpw == null || wdpw < 1 || wdpw > 7) {
      m.add('주당 근무일 수(1~7)');
    }

    if (!_fieldNonEmpty('weekly_holiday_day')) m.add('주휴일 요일');

    final wageTxt = _stripCommaNumber(_c['wage_amount']?.text ?? '');
    final wageAmt = int.tryParse(wageTxt);
    if (wageTxt.isEmpty || wageAmt == null || wageAmt < 0) {
      m.add('임금 금액(원)');
    }

    final pd = int.tryParse(_stripCommaNumber(_c['payment_day']?.text ?? ''));
    if (pd == null || pd < 1 || pd > 31) {
      m.add('임금지급일(매월 1~31일)');
    }

    final signed = _c['contract_signed_date']?.text.trim() ?? '';
    if (signed.isEmpty || DateTime.tryParse(signed) == null) {
      m.add('계약 체결일(연·월·일)');
    }

    if (!_fieldNonEmpty('employer_business_name')) {
      m.add('사업체명(하단 사업주)');
    }
    if (!_fieldNonEmpty('employer_representative_name')) {
      m.add('대표자 성명');
    }

    if (widget.isMinor) {
      if (!_fieldNonEmpty('family_relation_certificate_submitted')) {
        m.add('가족관계증명서 제출 여부');
      }
      if (!_fieldNonEmpty('guardian_consent_submitted')) {
        m.add('친권자·후견인 동의서 구비 여부');
      }
    }

    return m;
  }

  void _showStandardCompletionMissingDialog(
    List<String> missing, {
    String? title,
    String? subtitle,
  }) {
    if (!mounted || missing.isEmpty) return;
    
    final barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(dialogContext),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.48),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Material(
                  color: AppColors.grey0,
                  borderRadius: BorderRadius.circular(22.r),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? '입력이 필요합니다',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 18.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            subtitle ?? '완료 저장 전 아래 항목을 채워 주세요. (직원관리 API 근로계약서 완료 필수 항목 기준)',
                            style: AppTypography.bodyMediumR.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: missing.map((e) => Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h, right: 6.w),
                                        child: Container(
                                          width: 4.w,
                                          height: 4.w,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          e,
                                          style: AppTypography.bodyMediumR.copyWith(
                                            fontSize: 14.sp,
                                            color: AppColors.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 40.h,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.grey0,
                                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  '확인',
                                  style: AppTypography.bodyMediumB.copyWith(
                                    color: AppColors.grey0,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  /// 친권 동의서는 문서 제목 입력 없이 저장 시 목록용 자동 제목
  String _resolvedSaveTitle() {
    final t = _titleCtrl.text.trim();
    if (t.isNotEmpty) return t;
    if (widget.isGuardian) {
      return '${widget.employeeName}_친권자(후견인) 동의서';
    }
    return '';
  }

  Future<void> _save({required bool completed}) async {
    if (completed) {
      final missing = widget.isGuardian
          ? _missingFieldsForGuardianCompletion()
          : _missingFieldsForStandardCompletion();
      if (missing.isNotEmpty) {
        _showStandardCompletionMissingDialog(missing);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final fv = _collectFormValues();
      final title = _resolvedSaveTitle();
      if (_contractId == null) {
        final res = await repo.createEmploymentContract(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          body: {
            'template_version': widget.templateVersion,
            'status': completed ? 'completed' : 'draft',
            if (title.isNotEmpty) 'title': title,
            'form_values': fv,
          },
        );
        _contractId = (res['contract_id'] as num?)?.toInt();
      } else {
        await repo.patchEmploymentContract(
          branchId: widget.branchId,
          employeeId: widget.employeeId,
          contractId: _contractId!,
          data: {
            'status': completed ? 'completed' : 'draft',
            if (title.isNotEmpty) 'title': title,
            'form_values': fv,
            'merge_form_values': true,
          },
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(completed ? '저장되었습니다.' : '임시저장되었습니다.')),
      );
      if (completed) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errMsg = '저장 실패';
        if (e is DioException && e.response?.statusCode == 400) {
          final data = e.response?.data;
          if (data != null && data is Map<String, dynamic> && data['detail'] != null) {
            final detail = data['detail'];
            if (detail is Map<String, dynamic>) {
              if (detail['missing_fields_labels'] != null) {
                final labelsMap = detail['missing_fields_labels'] as Map<String, dynamic>;
                final labels = labelsMap.values.map((e) => e.toString()).toList();
                if (labels.isNotEmpty) {
                  _showStandardCompletionMissingDialog(
                    labels,
                    title: '알림',
                    subtitle: detail['message']?.toString(),
                  );
                  setState(() => _loading = false);
                  return;
                }
              }
              if (detail['message'] != null) {
                errMsg = detail['message'].toString();
              }
            } else if (detail is String) {
              errMsg = detail;
            }
          }
        } else {
          errMsg = '$errMsg: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _guardianDocHeading(String s) => Padding(
    padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
    child: Text(
      s,
      style: _contractBodyStyle.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildGuardianBody() {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.grey25)),
          ),
          child: Text(
            '친권자(후견인) 동의서',
            style: AppTypography.bodyLargeM.copyWith(
              fontSize: 18.sp,
              height: 24 / 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _guardianDocHeading('친권자(후견인) 인적사항'),
              _guardianLabeledChipRow('성 명 : ', '친권자(후견인) 성명', 'guardian_name'),
              _guardianLabeledChipRow(
                '주민등록번호 : ',
                '주민등록번호(마스킹)',
                'guardian_resident_id_masked',
              ),
              _guardianLabeledChipRow(
                '주 소 : ',
                '주소',
                'guardian_address',
                wideChip: true,
              ),
              _guardianLabeledChipRow('연락처 : ', '연락처', 'guardian_phone_number'),
              _guardianLabeledChipRow(
                '연소근로자와의 관계 : ',
                '연소근로자와의 관계',
                'relation_to_minor_worker',
              ),
              SizedBox(height: 8.h),
              _guardianDocHeading('연소근로자 인적사항'),
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    Text('성 명 : ', style: _contractBodyStyle),
                    _inputChip(
                      display: _c['minor_name']?.text,
                      tone: _ContractChipTone.worker,
                      onTap: () => _openInlineInput('연소근로자 성명', 'minor_name'),
                    ),
                    Text(' (만 ', style: _contractBodyStyle),
                    _inputChip(
                      display: _c['minor_age']?.text,
                      tone: _ContractChipTone.worker,
                      onTap: () => _openInlineInput('만 나이', 'minor_age'),
                    ),
                    Text(' 세)', style: _contractBodyStyle),
                  ],
                ),
              ),
              _guardianLabeledChipRow(
                '주민등록번호 : ',
                '연소근로자 주민등록번호(마스킹)',
                'minor_resident_id_masked',
                tone: _ContractChipTone.worker,
              ),
              _guardianLabeledChipRow(
                '주 소 : ',
                '연소근로자 주소',
                'minor_address',
                tone: _ContractChipTone.worker,
                wideChip: true,
              ),
              SizedBox(height: 8.h),
              _guardianDocHeading('사업장 개요'),
              _guardianLabeledChipRow(
                '회사명 : ',
                '회사명',
                'business_name',
                tone: _ContractChipTone.mint,
              ),
              _guardianLabeledChipRow(
                '회사주소 : ',
                '회사주소',
                'business_address',
                tone: _ContractChipTone.mint,
                wideChip: true,
              ),
              _guardianLabeledChipRow(
                '대표 자 : ',
                '대표자',
                'business_representative_name',
                tone: _ContractChipTone.mint,
              ),
              _guardianLabeledChipRow(
                '회사전화 : ',
                '회사전화',
                'business_phone_number',
                tone: _ContractChipTone.mint,
              ),
              SizedBox(height: 16.h),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  Text('본인은 위 연소근로자 ', style: _contractBodyStyle),
                  _inputChip(
                    display: _c['consent_minor_name']?.text,
                    tone: _ContractChipTone.guardian,
                    onTap: () =>
                        _openInlineInput('동의문 속 연소근로자명', 'consent_minor_name'),
                  ),
                  Text(
                    ' 가 위 사업장에서 근로를 하는 것에 대하여 동의합니다.',
                    style: _contractBodyStyle,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Center(
                child: Builder(
                  builder: (context) {
                    final d = DateTime.tryParse(
                      _c['consent_signed_date']?.text ?? '',
                    );
                    return Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _inputChip(
                          display: d == null ? null : '${d.year}',
                          tone: _ContractChipTone.guardian,
                          onTap: _openConsentSignedDateDialog,
                        ),
                        Text('년 ', style: _contractBodyStyle),
                        _inputChip(
                          display: d == null ? null : '${d.month}',
                          tone: _ContractChipTone.guardian,
                          onTap: _openConsentSignedDateDialog,
                        ),
                        Text('월 ', style: _contractBodyStyle),
                        _inputChip(
                          display: d == null ? null : '${d.day}',
                          tone: _ContractChipTone.guardian,
                          onTap: _openConsentSignedDateDialog,
                        ),
                        Text('일', style: _contractBodyStyle),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  Text('친권자(후견인) ', style: _contractBodyStyle),
                  _inputChip(
                    display: _c['guardian_signature_name']?.text,
                    tone: _ContractChipTone.guardian,
                    onTap: () => _openInlineInput(
                      '친권자(후견인) 서명',
                      'guardian_signature_name',
                    ),
                  ),
                  Text(' (인)', style: _contractBodyStyle),
                ],
              ),
              SizedBox(height: 16.h),
              Text('첨 부 : 가족관계증명서 1부', style: _contractBodyStyle),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _showSendDialogAndComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.grey0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '다음',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.grey0,
                      fontSize: 16.sp,
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 + bottomInset),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guardianLabeledChipRow(
    String label,
    String dialogLabel,
    String key, {
    _ContractChipTone tone = _ContractChipTone.guardian,
    bool wideChip = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          Text(label, style: _contractBodyStyle),
          _inputChip(
            display: _c[key]?.text,
            tone: tone,
            padding: wideChip ? _contractChipPaddingWide : _contractChipPadding,
            onTap: _isWorkerOwnedField(key)
                ? null
                : () => _openInlineInput(dialogLabel, key),
          ),
        ],
      ),
    );
  }

  TextStyle get _contractBodyStyle => _contractFigmaBody;

  TextStyle get _contractNoteStyle =>
      _contractFigmaBody.copyWith(color: AppColors.textTertiary);

  /// Figma: 민트/오렌지 라운드 칩. 빈 칩: 사업장 「입력」, 연소 「근로자」, 후견 「후견인 입력」
  Widget _inputChip({
    required String? display,
    VoidCallback? onTap,
    _ContractChipTone tone = _ContractChipTone.mint,
    EdgeInsets? padding,
    bool signatureField = false,
  }) {
    final chipPadding = padding ?? _contractChipPadding;
    final effectiveOnTap = tone == _ContractChipTone.worker ? null : onTap;
    final t = display?.trim() ?? '';
    final empty = t.isEmpty;
    final String emptyLabel = switch (tone) {
      _ContractChipTone.mint => '입력',
      _ContractChipTone.worker => '근로자',
      _ContractChipTone.guardian => '후견인 입력',
    };
    final (Color bg, Color fg) = switch (tone) {
      _ContractChipTone.mint => (_mintChipBg, AppColors.primary),
      _ContractChipTone.worker => (_workerChipBg, _workerChipFg),
      // 후견인·연소 모두 주황 팔레트, 빈 칩 문구만 다름
      _ContractChipTone.guardian => (_workerChipBg, _workerChipFg),
    };
    if (signatureField && isContractSignatureDataUrl(t)) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(4.r),
          child: Padding(
            padding: chipPadding,
            child: contractSignatureImageWithUnderline(
              dataUrl: t,
              underlineColor: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: chipPadding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: fg.withValues(alpha: 0.45)),
          ),
          child: signatureField
              ? contractSignatureChipChild(
                  value: display,
                  emptyLabel: emptyLabel,
                  textStyle: _contractFigmaBody.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    height: 18 / 12,
                  ),
                )
              : Text(
                  empty ? emptyLabel : t,
                  style: _contractFigmaBody.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    height: 18 / 12,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _circleToggle({required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey100,
            width: selected ? 2 : 1.2,
          ),
          color: selected ? AppColors.primary : AppColors.grey0,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 12, color: AppColors.grey0)
            : null,
      ),
    );
  }

  String _formatKoreanDateFromIso(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    if (d == null) return '';
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  Future<void> _openSigningDateDialog() async {
    DateTime? initial = DateTime.tryParse(
      _c['contract_signed_date']?.text ?? '',
    );
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _c['contract_signed_date']!.text = _formatDate(picked));
    }
  }

  Future<void> _openConsentSignedDateDialog() async {
    DateTime? initial = DateTime.tryParse(
      _c['consent_signed_date']?.text ?? '',
    );
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _c['consent_signed_date']!.text = _formatDate(picked));
    }
  }

  Future<void> _openWorkTimesDialog() async {
    const dayKor = ['월', '화', '수', '목', '금', '토', '일'];
    String two(int n) => n.toString().padLeft(2, '0');

    (int, int) parseHm(String? raw, int fh, int fm) {
      final t = raw?.trim() ?? '';
      if (!t.contains(':')) return (fh, fm);
      final p = t.split(':');
      if (p.length < 2) return (fh, fm);
      return (int.tryParse(p[0].trim()) ?? fh, int.tryParse(p[1].trim()) ?? fm);
    }

    final slots = List<_DayWorkSlot>.generate(7, (_) => _DayWorkSlot());
    var hadStoredDay = false;
    for (var i = 0; i < 7; i++) {
      final en =
          _c[contractWorkDayFormFieldKey(i, 'enabled')]?.text.trim();
      if (en == '1' || en == '0') {
        hadStoredDay = true;
        slots[i].open = en == '1';
      }
      final ws = _c[contractWorkDayFormFieldKey(i, 'start')]?.text ?? '';
      final we = _c[contractWorkDayFormFieldKey(i, 'end')]?.text ?? '';
      if (ws.isNotEmpty) {
        final a = parseHm(ws, 9, 0);
        slots[i].sh = a.$1;
        slots[i].sm = a.$2;
      }
      if (we.isNotEmpty) {
        final b = parseHm(we, 18, 0);
        slots[i].eh = b.$1;
        slots[i].em = b.$2;
      }
      final bh =
          _c[contractWorkDayFormFieldKey(i, 'break_has')]?.text.trim();
      if (bh == '1' || bh == '0') {
        slots[i].breakHas = bh == '1';
      }
      final bs =
          _c[contractWorkDayFormFieldKey(i, 'break_start')]?.text ?? '';
      final be = _c[contractWorkDayFormFieldKey(i, 'break_end')]?.text ?? '';
      if (bs.isNotEmpty) {
        final c = parseHm(bs, 13, 0);
        slots[i].bsh = c.$1;
        slots[i].bsm = c.$2;
      }
      if (be.isNotEmpty) {
        final d = parseHm(be, 14, 0);
        slots[i].beh = d.$1;
        slots[i].bem = d.$2;
      }
    }

    if (!hadStoredDay) {
      final wss = _c['scheduled_work_start_time']?.text ?? '';
      final wse = _c['scheduled_work_end_time']?.text ?? '';
      if (wss.isNotEmpty) {
        final sh = parseHm(wss, 9, 0);
        final eh = parseHm(wse, 18, 0);
        final brk =
            (_c['break_start_time']?.text.trim().isNotEmpty ?? false) ||
            (_c['break_end_time']?.text.trim().isNotEmpty ?? false);
        final b1 = parseHm(_c['break_start_time']?.text, 13, 0);
        final b2 = parseHm(_c['break_end_time']?.text, 14, 0);
        for (var i = 0; i < 5; i++) {
          slots[i]
            ..open = true
            ..sh = sh.$1
            ..sm = sh.$2
            ..eh = eh.$1
            ..em = eh.$2
            ..breakHas = brk
            ..bsh = b1.$1
            ..bsm = b1.$2
            ..beh = b2.$1
            ..bem = b2.$2;
        }
      }
    }

    Widget workTimeFieldLabel(String text) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _figmaPillLabel,
          ),
        ),
      );
    }

    Widget digitSpinner({
      required int value,
      required int modulus,
      required VoidCallback onUp,
      required VoidCallback onDown,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onUp,
            borderRadius: BorderRadius.circular(18.r),
            child: _pickerChevron(up: true, whiteCircle: true),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Text(
              two(value % modulus),
              maxLines: 1,
              style: _figmaInterValue18,
            ),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: onDown,
            borderRadius: BorderRadius.circular(18.r),
            child: _pickerChevron(up: false, whiteCircle: true),
          ),
        ],
      );
    }

    Widget hmRow({
      required int h,
      required int m,
      required void Function(int nh, int nm) onChanged,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          digitSpinner(
            value: h,
            modulus: 24,
            onUp: () => onChanged((h + 1) % 24, m),
            onDown: () => onChanged((h + 23) % 24, m),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              ':',
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 20.sp,
                color: const Color(0xFF454545),
              ),
            ),
          ),
          digitSpinner(
            value: m,
            modulus: 60,
            onUp: () => onChanged(h, (m + 1) % 60),
            onDown: () => onChanged(h, (m + 59) % 60),
          ),
        ],
      );
    }

    Widget workTimeBlock(
      _DayWorkSlot s,
      void Function(VoidCallback mutation) apply,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    workTimeFieldLabel('근무시작시간'),
                    SizedBox(height: 8.h),
                    hmRow(
                      h: s.sh,
                      m: s.sm,
                      onChanged: (nh, nm) => apply(() {
                        s.sh = nh;
                        s.sm = nm;
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Text('~', style: AppTypography.bodyLargeM),
              ),
              Expanded(
                child: Column(
                  children: [
                    workTimeFieldLabel('근무종료시간'),
                    SizedBox(height: 8.h),
                    hmRow(
                      h: s.eh,
                      m: s.em,
                      onChanged: (nh, nm) => apply(() {
                        s.eh = nh;
                        s.em = nm;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('휴게시간', style: AppTypography.bodyMediumM),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => apply(() => s.breakHas = false),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      color: !s.breakHas
                          ? AppColors.primaryLight
                          : AppColors.grey25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !s.breakHas
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: !s.breakHas
                              ? AppColors.primary
                              : AppColors.grey100,
                        ),
                        SizedBox(width: 6.w),
                        Text('없음', style: AppTypography.bodyMediumM),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkWell(
                  onTap: () => apply(() => s.breakHas = true),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      color: s.breakHas
                          ? AppColors.primaryLight
                          : AppColors.grey25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          s.breakHas
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: s.breakHas
                              ? AppColors.primary
                              : AppColors.grey100,
                        ),
                        SizedBox(width: 6.w),
                        Text('있음', style: AppTypography.bodyMediumM),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (s.breakHas) ...[
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      workTimeFieldLabel('휴게시작시간'),
                      SizedBox(height: 8.h),
                      hmRow(
                        h: s.bsh,
                        m: s.bsm,
                        onChanged: (nh, nm) => apply(() {
                          s.bsh = nh;
                          s.bsm = nm;
                        }),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Text('~', style: AppTypography.bodyLargeM),
                ),
                Expanded(
                  child: Column(
                    children: [
                      workTimeFieldLabel('휴게종료시간'),
                      SizedBox(height: 8.h),
                      hmRow(
                        h: s.beh,
                        m: s.bem,
                        onChanged: (nh, nm) => apply(() {
                          s.beh = nh;
                          s.bem = nm;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void slot(int i, VoidCallback fn) {
            setLocal(() {
              fn();
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 320,
                maxHeight: maxH,
                maxWidth: 360,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        '소정근로시간',
                        textAlign: TextAlign.center,
                        style: _figmaModalHeading,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('· 중복 입력 가능', style: _figmaWorkTimeSubnote),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var i = 0; i < 7; i++) ...[
                              if (!slots[i].open)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Material(
                                    color: AppColors.grey0,
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: InkWell(
                                      onTap: () =>
                                          setLocal(() => slots[i].open = true),
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Container(
                                        width: double.infinity,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.grey50,
                                          ),
                                        ),
                                        child: Text(
                                          dayKor[i],
                                          style: AppTypography.bodyMediumM,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      12.w,
                                      10.h,
                                      12.w,
                                      12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3FBF8),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: () => setLocal(
                                            () => slots[i].open = false,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                dayKor[i],
                                                style: AppTypography.bodyMediumM
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Icon(
                                                Icons.expand_less_rounded,
                                                size: 22,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        workTimeBlock(
                                          slots[i],
                                          (fn) => slot(i, fn),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.grey25,
                              foregroundColor: AppColors.textTertiary,
                              shape: _modalActionButtonShape,
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.grey0,
                              shape: _modalActionButtonShape,
                            ),
                            child: const Text('확인'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (ok == true && mounted) {
      setState(() {
        for (var i = 0; i < 7; i++) {
          final s = slots[i];
          _c[contractWorkDayFormFieldKey(i, 'enabled')]!.text =
              s.open ? '1' : '0';
          if (!s.open) {
            _c[contractWorkDayFormFieldKey(i, 'start')]!.text = '';
            _c[contractWorkDayFormFieldKey(i, 'end')]!.text = '';
            _c[contractWorkDayFormFieldKey(i, 'break_has')]!.text = '0';
            _c[contractWorkDayFormFieldKey(i, 'break_start')]!.text = '';
            _c[contractWorkDayFormFieldKey(i, 'break_end')]!.text = '';
          } else {
            _c[contractWorkDayFormFieldKey(i, 'start')]!.text =
                '${two(s.sh)}:${two(s.sm)}';
            _c[contractWorkDayFormFieldKey(i, 'end')]!.text =
                '${two(s.eh)}:${two(s.em)}';
            _c[contractWorkDayFormFieldKey(i, 'break_has')]!.text =
                s.breakHas ? '1' : '0';
            _c[contractWorkDayFormFieldKey(i, 'break_start')]!.text =
                s.breakHas ? '${two(s.bsh)}:${two(s.bsm)}' : '';
            _c[contractWorkDayFormFieldKey(i, 'break_end')]!.text =
                s.breakHas ? '${two(s.beh)}:${two(s.bem)}' : '';
          }
        }

        final firstOpen = slots.indexWhere((e) => e.open);
        if (firstOpen >= 0) {
          final s = slots[firstOpen];
          _c['scheduled_work_start_time']!.text = '${two(s.sh)}:${two(s.sm)}';
          _c['scheduled_work_end_time']!.text = '${two(s.eh)}:${two(s.em)}';
          _c['break_start_time']!.text = s.breakHas
              ? '${two(s.bsh)}:${two(s.bsm)}'
              : '';
          _c['break_end_time']!.text = s.breakHas
              ? '${two(s.beh)}:${two(s.bem)}'
              : '';
        } else {
          _c['scheduled_work_start_time']!.text = '';
          _c['scheduled_work_end_time']!.text = '';
          _c['break_start_time']!.text = '';
          _c['break_end_time']!.text = '';
        }

        final openCount = slots.where((e) => e.open).length;
        if (openCount > 0) {
          _c['work_days_per_week']!.text = '$openCount';
        }
        final restIdx = slots.indexWhere((e) => !e.open);
        if (restIdx >= 0) {
          _c['weekly_holiday_day']!.text = dayKor[restIdx];
        } else if (openCount == 7) {
          _c['weekly_holiday_day']!.text = '';
        }
      });
    }
  }

  String _formatDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }

  Future<void> _openPeriodDialog() async {
    DateTime start =
        DateTime.tryParse(_c['contract_start_date']?.text ?? '') ??
        DateTime.now();
    DateTime end =
        DateTime.tryParse(_c['contract_end_date']?.text ?? '') ?? start;

    int dayMax(int y, int m) => DateTime(y, m + 1, 0).day;

    Widget dateSpinner({
      required String label,
      required int value,
      required VoidCallback onUp,
      required VoidCallback onDown,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _figmaPillLabel,
            ),
          ),
          SizedBox(height: 10.h),
          InkWell(
            onTap: onUp,
            borderRadius: BorderRadius.circular(18.r),
            child: _pickerChevron(up: true, whiteCircle: false),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
            child: Text(
              '$value',
              maxLines: 1,
              softWrap: false,
              style: _figmaInterValue18,
            ),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: onDown,
            borderRadius: BorderRadius.circular(18.r),
            child: _pickerChevron(up: false, whiteCircle: false),
          ),
        ],
      );
    }

    Widget datePanel({
      required String title,
      required int year,
      required int month,
      required int day,
      required VoidCallback yearUp,
      required VoidCallback yearDown,
      required VoidCallback monthUp,
      required VoidCallback monthDown,
      required VoidCallback dayUp,
      required VoidCallback dayDown,
    }) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _figmaSectionLabel),
            SizedBox(height: 8.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                dateSpinner(
                  label: '년도',
                  value: year,
                  onUp: yearUp,
                  onDown: yearDown,
                ),
                SizedBox(width: 16.w),
                dateSpinner(
                  label: '월',
                  value: month,
                  onUp: monthUp,
                  onDown: monthDown,
                ),
                SizedBox(width: 16.w),
                dateSpinner(
                  label: '일',
                  value: day,
                  onUp: dayUp,
                  onDown: dayDown,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '근로계약기간',
                      textAlign: TextAlign.center,
                      style: _figmaModalHeading,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  datePanel(
                    title: '시작',
                    year: start.year,
                    month: start.month,
                    day: start.day,
                    yearUp: () {
                      setLocal(() {
                        final ny = (start.year + 1).clamp(2000, 2100);
                        final nd = start.day.clamp(1, dayMax(ny, start.month));
                        start = DateTime(ny, start.month, nd);
                      });
                    },
                    yearDown: () {
                      setLocal(() {
                        final ny = (start.year - 1).clamp(2000, 2100);
                        final nd = start.day.clamp(1, dayMax(ny, start.month));
                        start = DateTime(ny, start.month, nd);
                      });
                    },
                    monthUp: () {
                      setLocal(() {
                        final nm = start.month == 12 ? 1 : start.month + 1;
                        final ny = start.month == 12
                            ? start.year + 1
                            : start.year;
                        final nd = start.day.clamp(1, dayMax(ny, nm));
                        start = DateTime(ny.clamp(2000, 2100), nm, nd);
                      });
                    },
                    monthDown: () {
                      setLocal(() {
                        final nm = start.month == 1 ? 12 : start.month - 1;
                        final ny = start.month == 1
                            ? start.year - 1
                            : start.year;
                        final nd = start.day.clamp(1, dayMax(ny, nm));
                        start = DateTime(ny.clamp(2000, 2100), nm, nd);
                      });
                    },
                    dayUp: () {
                      setLocal(() {
                        final max = dayMax(start.year, start.month);
                        final nd = start.day >= max ? 1 : start.day + 1;
                        start = DateTime(start.year, start.month, nd);
                      });
                    },
                    dayDown: () {
                      setLocal(() {
                        final max = dayMax(start.year, start.month);
                        final nd = start.day <= 1 ? max : start.day - 1;
                        start = DateTime(start.year, start.month, nd);
                      });
                    },
                  ),
                  SizedBox(height: 14.h),
                  datePanel(
                    title: '종료',
                    year: end.year,
                    month: end.month,
                    day: end.day,
                    yearUp: () {
                      setLocal(() {
                        final ny = (end.year + 1).clamp(2000, 2100);
                        final nd = end.day.clamp(1, dayMax(ny, end.month));
                        end = DateTime(ny, end.month, nd);
                      });
                    },
                    yearDown: () {
                      setLocal(() {
                        final ny = (end.year - 1).clamp(2000, 2100);
                        final nd = end.day.clamp(1, dayMax(ny, end.month));
                        end = DateTime(ny, end.month, nd);
                      });
                    },
                    monthUp: () {
                      setLocal(() {
                        final nm = end.month == 12 ? 1 : end.month + 1;
                        final ny = end.month == 12 ? end.year + 1 : end.year;
                        final nd = end.day.clamp(1, dayMax(ny, nm));
                        end = DateTime(ny.clamp(2000, 2100), nm, nd);
                      });
                    },
                    monthDown: () {
                      setLocal(() {
                        final nm = end.month == 1 ? 12 : end.month - 1;
                        final ny = end.month == 1 ? end.year - 1 : end.year;
                        final nd = end.day.clamp(1, dayMax(ny, nm));
                        end = DateTime(ny.clamp(2000, 2100), nm, nd);
                      });
                    },
                    dayUp: () {
                      setLocal(() {
                        final max = dayMax(end.year, end.month);
                        final nd = end.day >= max ? 1 : end.day + 1;
                        end = DateTime(end.year, end.month, nd);
                      });
                    },
                    dayDown: () {
                      setLocal(() {
                        final max = dayMax(end.year, end.month);
                        final nd = end.day <= 1 ? max : end.day - 1;
                        end = DateTime(end.year, end.month, nd);
                      });
                    },
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.grey25,
                            foregroundColor: AppColors.textTertiary,
                            shape: _modalActionButtonShape,
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.grey0,
                            shape: _modalActionButtonShape,
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
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _c['contract_start_date']!.text = _formatDate(start);
        _c['contract_end_date']!.text = _formatDate(end);
      });
    }
  }

  Future<void> _openWageDialog() async {
    String localType = _wageType;
    final amountCtrl = TextEditingController(
      text: _formatWonForDisplay(_c['wage_amount']?.text),
    );
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('임금', style: AppTypography.heading3),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _wageOptionTile(
                        selected: localType == 'hourly',
                        label: '시급',
                        onTap: () => setLocal(() => localType = 'hourly'),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: _wageOptionTile(
                        selected: localType == 'monthly',
                        label: '월급',
                        onTap: () => setLocal(() => localType = 'monthly'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                AuthInputField(
                  controller: amountCtrl,
                  hintText: switch (localType) {
                    'hourly' => '시급을 입력해주세요.',
                    'daily' => '일급을 입력해주세요.',
                    _ => '월급을 입력해주세요.',
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  fillColor: AppColors.grey25,
                  focusedBorderColor: AppColors.primaryDark,
                  suffixText: '원',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.textTertiary,
                          shape: _modalActionButtonShape,
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: _modalActionButtonShape,
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _wageType = localType;
        _c['wage_amount']!.text = amountCtrl.text.trim();
      });
    }
  }

  Widget _wageOptionTile({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey50,
          ),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.grey25,
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTypography.bodyMediumM),
      ),
    );
  }

  Future<void> _showSendDialogAndComplete() async {
    final missing = widget.isGuardian
        ? _missingFieldsForGuardianCompletion()
        : _missingFieldsForStandardCompletion();
    if (missing.isNotEmpty) {
      _showStandardCompletionMissingDialog(missing);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '알림',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLargeM.copyWith(
                  fontSize: 18.sp,
                  height: 24 / 18,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                widget.isGuardian
                    ? '친권자(후견인) 동의서를 완료로 저장하시겠습니까?'
                    : '해당 계약서를 근로자에게 전송하시겠습니까?',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumM.copyWith(
                  fontSize: 14.sp,
                  height: 16 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.textTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 16.sp,
                            height: 24 / 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '확인',
                          style: AppTypography.bodyLargeB.copyWith(
                            color: AppColors.grey0,
                            fontSize: 16.sp,
                            height: 24 / 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      _save(completed: true);
    }
  }

  String _wageTypeLabelKo() {
    return switch (_wageType) {
      'hourly' => '시급',
      'daily' => '일급',
      _ => '월급',
    };
  }

  String _periodChipDisplay() {
    final s = _formatKoreanDateFromIso(_c['contract_start_date']?.text);
    final e = _formatKoreanDateFromIso(_c['contract_end_date']?.text);
    if (s.isEmpty && e.isEmpty) return '';
    if (s.isNotEmpty && e.isNotEmpty) return '$s부터 $e까지';
    if (s.isNotEmpty) return s;
    return e;
  }

  static const List<String> _weekdayKor = ['월', '화', '수', '목', '금', '토', '일'];

  bool _hasPerDayWorkSchedule() {
    for (var i = 0; i < 7; i++) {
      final en =
          _c[contractWorkDayFormFieldKey(i, 'enabled')]?.text.trim();
      if (en == '0' || en == '1') return true;
      final ws = _c[contractWorkDayFormFieldKey(i, 'start')]?.text.trim();
      if (ws != null && ws.isNotEmpty) return true;
    }
    return false;
  }

  /// 근무로 설정된 요일만 (인덱스 0=월 … 6=일)
  List<({int i, String start, String end})> _enabledWorkDaySlots() {
    final out = <({int i, String start, String end})>[];
    for (var i = 0; i < 7; i++) {
      final en =
          _c[contractWorkDayFormFieldKey(i, 'enabled')]?.text.trim();
      if (en == '0') continue;
      final ws =
          _c[contractWorkDayFormFieldKey(i, 'start')]?.text.trim() ?? '';
      final we = _c[contractWorkDayFormFieldKey(i, 'end')]?.text.trim() ?? '';
      if (en != '1' && ws.isEmpty) continue;
      if (ws.isEmpty && we.isEmpty) continue;
      out.add((i: i, start: ws, end: we));
    }
    return out;
  }

  String _formatDayIndexRuns(List<int> indices) {
    if (indices.isEmpty) return '';
    indices.sort();
    if (indices.length == 7 && indices.first == 0 && indices.last == 6) {
      return '매일';
    }
    if (indices.length == 5 &&
        indices[0] == 0 &&
        indices[1] == 1 &&
        indices[2] == 2 &&
        indices[3] == 3 &&
        indices[4] == 4) {
      return '월~금';
    }
    final runs = <List<int>>[];
    for (final i in indices) {
      if (runs.isEmpty || i != runs.last.last + 1) {
        runs.add([i]);
      } else {
        runs.last.add(i);
      }
    }
    return runs
        .map((r) {
          if (r.length == 1) return _weekdayKor[r.first];
          return '${_weekdayKor[r.first]}~${_weekdayKor[r.last]}';
        })
        .join('·');
  }

  String? _legacyScheduledWorkSummary() {
    final a = _c['scheduled_work_start_time']?.text.trim() ?? '';
    final b = _c['scheduled_work_end_time']?.text.trim() ?? '';
    if (a.isEmpty && b.isEmpty) return null;
    if (a.isNotEmpty && b.isNotEmpty) return '$a~$b';
    if (a.isNotEmpty) return a;
    return b;
  }

  String? _scheduledWorkTimeChipDisplay() {
    if (_hasPerDayWorkSchedule()) {
      final slots = _enabledWorkDaySlots();
      if (slots.isEmpty) return _legacyScheduledWorkSummary();
      final groups = <String, List<int>>{};
      for (final o in slots) {
        final key = '${o.start}~${o.end}';
        groups.putIfAbsent(key, () => []).add(o.i);
      }
      final parts = <String>[];
      for (final e in groups.entries) {
        final days = _formatDayIndexRuns(List<int>.from(e.value));
        parts.add('$days ${e.key}');
      }
      return parts.join(' / ');
    }
    return _legacyScheduledWorkSummary();
  }

  /// 휴게 없으면 null → 괄호 문구 생략
  Widget? _contractBreakTimeBody() {
    if (_hasPerDayWorkSchedule()) {
      final slots = _enabledWorkDaySlots();
      if (slots.isEmpty) return _legacyContractBreakTimeBody();
      final workSet = slots.map((s) => s.i).toSet();
      final byRange = <String, List<int>>{};
      for (final o in slots) {
        if (_c[contractWorkDayFormFieldKey(o.i, 'break_has')]?.text.trim() !=
            '1') {
          continue;
        }
        final bs =
            _c[contractWorkDayFormFieldKey(o.i, 'break_start')]?.text.trim() ??
                '';
        final be =
            _c[contractWorkDayFormFieldKey(o.i, 'break_end')]?.text.trim() ??
                '';
        if (bs.isEmpty && be.isEmpty) continue;
        final key = '$bs~$be';
        byRange.putIfAbsent(key, () => []).add(o.i);
      }
      if (byRange.isEmpty) return null;
      if (byRange.length == 1) {
        final e = byRange.entries.first;
        final days = e.value.toSet();
        if (days.length == workSet.length && workSet.every(days.contains)) {
          return Text(e.key, style: _contractFigmaBody);
        }
      }
      final parts = <String>[];
      for (final e in byRange.entries) {
        parts.add(
          '${_formatDayIndexRuns(List<int>.from(e.value)..sort())} ${e.key}',
        );
      }
      return Text(parts.join(' / '), style: _contractFigmaBody);
    }
    return _legacyContractBreakTimeBody();
  }

  Widget? _legacyContractBreakTimeBody() {
    final bs = _c['break_start_time']?.text.trim() ?? '';
    final be = _c['break_end_time']?.text.trim() ?? '';
    if (bs.isEmpty && be.isEmpty) return null;
    if (bs.isNotEmpty && be.isNotEmpty) {
      return Text('$bs~$be', style: _contractFigmaBody);
    }
    if (bs.isNotEmpty) return Text(bs, style: _contractFigmaBody);
    return Text(be, style: _contractFigmaBody);
  }

  Widget _contractNumbered(int index, Widget body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text('$index.', style: _contractBodyStyle),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildStandardContractBody() {
    final wageLabel = _wageTypeLabelKo();
    final wageAmount = _c['wage_amount']?.text.trim() ?? '';
    final wageChipText = wageAmount.isEmpty ? '' : '$wageLabel $wageAmount';

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 120.h),
      children: [
        Text(
          widget.isMinor ? '연소근로자(18세 미만) 표준 근로계약서' : '표준 근로 계약서',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 18.sp,
            height: 24 / 18,
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 10,
          children: [
            _inputChip(
              display: _c['employer_name']?.text,
              onTap: () => _openInlineInput('사업주명', 'employer_name'),
            ),
            Text('(이하 "사업주"라 함)과(와) ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_name']?.text,
              tone: _ContractChipTone.worker,
              onTap: () => _openInlineInput('근로자명', 'worker_name'),
            ),
            Text('(이하 "근로자"라 함)은', style: _contractBodyStyle),
          ],
        ),
        Text('다음과 같이 근로계약을 체결한다.', style: _contractBodyStyle),
        SizedBox(height: 20.h),
        _contractNumbered(
          1,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  Text('근로계약기간 : ', style: _contractBodyStyle),
                  _inputChip(
                    display: _periodChipDisplay().isEmpty
                        ? null
                        : _periodChipDisplay(),
                    onTap: _openPeriodDialog,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                '※ 근로계약기간을 정하지 않는 경우에는 "근로개시일"만 기재',
                style: _contractNoteStyle,
              ),
            ],
          ),
        ),
        _contractNumbered(
          2,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              Text('근 무 장 소 : ', style: _contractBodyStyle),
              _inputChip(
                display: _c['work_place']?.text,
                onTap: () => _openInlineInput('근무 장소', 'work_place'),
                padding: _contractChipPaddingWide,
              ),
            ],
          ),
        ),
        _contractNumbered(
          3,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              Text('업 무 내 용 : ', style: _contractBodyStyle),
              _inputChip(
                display: _c['job_description']?.text,
                onTap: () => _openInlineInput('업무 내용', 'job_description'),
                padding: _contractChipPaddingWide,
              ),
            ],
          ),
        ),
        _contractNumbered(
          4,
          Builder(
            builder: (context) {
              final breakBody = _contractBreakTimeBody();
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  Text('소정근로시간 : ', style: _contractBodyStyle),
                  _inputChip(
                    display: _scheduledWorkTimeChipDisplay(),
                    onTap: _openWorkTimesDialog,
                    padding: _contractChipPaddingWide,
                  ),
                  if (breakBody != null) ...[
                    Text(' (휴게시간: ', style: _contractBodyStyle),
                    breakBody,
                    Text(')', style: _contractBodyStyle),
                  ],
                ],
              );
            },
          ),
        ),
        _contractNumbered(
          5,
          Builder(
            builder: (context) {
              final wd = _c['work_days_per_week']?.text.trim() ?? '';
              final wh = _c['weekly_holiday_day']?.text.trim() ?? '';
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  Text('근무일/휴일 : 매주 ', style: _contractBodyStyle),
                  if (wd.isEmpty)
                    GestureDetector(
                      onTap: _openWorkTimesDialog,
                      child: Text(
                        '소정 근로 시간 입력시 자동 기입',
                        style: _contractFigmaAccent,
                      ),
                    )
                  else
                    _inputChip(
                      display: wd,
                      onTap: () =>
                          _openInlineInput('주당 근무일 수', 'work_days_per_week'),
                    ),
                  Text('일(또는 매일단위)근무, 주휴일 매주 ', style: _contractBodyStyle),
                  if (wh.isEmpty)
                    GestureDetector(
                      onTap: _openWorkTimesDialog,
                      child: Text('자동 기입', style: _contractFigmaAccent),
                    )
                  else
                    _inputChip(
                      display: wh,
                      onTap: () =>
                          _openInlineInput('주휴일 요일', 'weekly_holiday_day'),
                    ),
                  Text('요일', style: _contractBodyStyle),
                ],
              );
            },
          ),
        ),
        _contractNumbered(
          6,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('임 금', style: _contractBodyStyle),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('월(일, 시간)급 : ', style: _contractBodyStyle),
                        _inputChip(
                          display: wageChipText.isEmpty ? null : wageChipText,
                          onTap: _openWageDialog,
                          padding: _contractChipPaddingWide,
                        ),
                        Text(' 원', style: _contractBodyStyle),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('상여금 : 있음(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: _bonusIncluded,
                          onTap: () => setState(() => _bonusIncluded = true),
                        ),
                        Text(')', style: _contractBodyStyle),
                        if (_bonusIncluded) ...[
                          _inputChip(
                            display: _c['bonus_amount']?.text,
                            onTap: () =>
                                _openInlineInput('상여금 금액', 'bonus_amount'),
                          ),
                          Text('원', style: _contractBodyStyle),
                        ],
                        Text(', 없음(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: !_bonusIncluded,
                          onTap: () => setState(() {
                            _bonusIncluded = false;
                            _c['bonus_amount']?.clear();
                          }),
                        ),
                        Text(')', style: _contractBodyStyle),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('기타급여(제수당 등) : 있음(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: _otherAllowanceIncluded,
                          onTap: () =>
                              setState(() => _otherAllowanceIncluded = true),
                        ),
                        Text(')', style: _contractBodyStyle),
                        if (_otherAllowanceIncluded) ...[
                          _inputChip(
                            display: _c['other_allowance_amount']?.text,
                            onTap: () => _openInlineInput(
                              '기타급여 금액',
                              'other_allowance_amount',
                            ),
                          ),
                          Text('원', style: _contractBodyStyle),
                        ],
                        Text(', 없음(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: !_otherAllowanceIncluded,
                          onTap: () => setState(() {
                            _otherAllowanceIncluded = false;
                            _c['other_allowance_amount']?.clear();
                          }),
                        ),
                        Text(')', style: _contractBodyStyle),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('· 식대(비과세) ', style: _contractBodyStyle),
                              _inputChip(
                                display: _c['meal_allowance']?.text,
                                onTap: () =>
                                    _openInlineInput('식대(원)', 'meal_allowance'),
                              ),
                              Text('원', style: _contractBodyStyle),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('· 교통비', style: _contractBodyStyle),
                              _inputChip(
                                display: _c['transport_allowance']?.text,
                                onTap: () => _openInlineInput(
                                  '교통비(원)',
                                  'transport_allowance',
                                ),
                              ),
                              Text('원', style: _contractBodyStyle),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('· 기타(', style: _contractBodyStyle),
                              _inputChip(
                                display: _c['extra_allowance_name']?.text,
                                onTap: () => _openInlineInput(
                                  '기타 수당 항목명',
                                  'extra_allowance_name',
                                ),
                              ),
                              Text(') ', style: _contractBodyStyle),
                              _inputChip(
                                display: _c['extra_allowance_amount']?.text,
                                onTap: () => _openInlineInput(
                                  '기타 수당 금액(원)',
                                  'extra_allowance_amount',
                                ),
                              ),
                              Text('원', style: _contractBodyStyle),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text(
                          '임금지급일 : 매월(매주 또는 매일) ',
                          style: _contractBodyStyle,
                        ),
                        _inputChip(
                          display: _c['payment_day']?.text,
                          onTap: () =>
                              _openInlineInput('임금 지급일(일)', 'payment_day'),
                        ),
                        Text('일 (휴일의 경우는 전일 지급)', style: _contractBodyStyle),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('지급방법 : 근로자에게 직접지급(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: _paymentMethod == 'direct',
                          onTap: () =>
                              setState(() => _paymentMethod = 'direct'),
                        ),
                        Text('), 근로자 명의 예금통장에 입금(', style: _contractBodyStyle),
                        _circleToggle(
                          selected: _paymentMethod == 'bank_transfer',
                          onTap: () =>
                              setState(() => _paymentMethod = 'bank_transfer'),
                        ),
                        Text(')', style: _contractBodyStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _contractNumbered(
          7,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('연차유급휴가', style: _contractBodyStyle),
              SizedBox(height: 4.h),
              Text('연차유급휴가는 근로기준법에서 정하는 바에 따라 부여함', style: _contractBodyStyle),
            ],
          ),
        ),
        if (widget.isMinor) ...[
          _contractNumbered(
            8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가족관계증명서 및 동의서', style: _contractBodyStyle),
                SizedBox(height: 10.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    Text(
                      '가족관계기록사항에 관한 증명서 제출 여부 : ',
                      style: _contractBodyStyle,
                    ),
                    _inputChip(
                      display:
                          _c['family_relation_certificate_submitted']?.text,
                      onTap: () => _openInlineInput(
                        '가족관계기록사항에 관한 증명서 제출 여부',
                        'family_relation_certificate_submitted',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    Text('친권자 또는 후견인의 동의서 구비 여부 : ', style: _contractBodyStyle),
                    _inputChip(
                      display: _c['guardian_consent_submitted']?.text,
                      tone: _ContractChipTone.worker,
                      onTap: () => _openInlineInput(
                        '친권자 또는 후견인의 동의서 구비 여부',
                        'guardian_consent_submitted',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _contractNumbered(
            9,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('근로계약서 교부', style: _contractBodyStyle),
                SizedBox(height: 4.h),
                Text(
                  '사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조, 제67조 이행)',
                  style: _contractBodyStyle,
                ),
              ],
            ),
          ),
          _contractNumbered(
            10,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기 타', style: _contractBodyStyle),
                SizedBox(height: 8.h),
                Text(
                  '13세 이상 15세 미만인 자에 대해서는 고용노동부장관으로부터 취직인허증을 교부받아야 하며, 이 계약에 정함이 없는 사항은 근로기준법령에 의함',
                  style: _contractBodyStyle,
                ),
              ],
            ),
          ),
        ] else ...[
          _contractNumbered(
            8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('근로계약서 교부', style: _contractBodyStyle),
                SizedBox(height: 4.h),
                Text(
                  '사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조 이행)',
                  style: _contractBodyStyle,
                ),
              ],
            ),
          ),
          _contractNumbered(
            9,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기 타', style: _contractBodyStyle),
                SizedBox(height: 4.h),
                Text('이 계약에 정함이 없는 사항은 근로기준법령에 의함', style: _contractBodyStyle),
              ],
            ),
          ),
        ],
        SizedBox(height: 24.h),
        Center(
          child: Builder(
            builder: (context) {
              final d = DateTime.tryParse(
                _c['contract_signed_date']?.text ?? '',
              );
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _inputChip(
                    display: d == null ? null : '${d.year}',
                    onTap: _openSigningDateDialog,
                  ),
                  Text('년 ', style: _contractBodyStyle),
                  _inputChip(
                    display: d == null ? null : '${d.month}',
                    onTap: _openSigningDateDialog,
                  ),
                  Text('월 ', style: _contractBodyStyle),
                  _inputChip(
                    display: d == null ? null : '${d.day}',
                    onTap: _openSigningDateDialog,
                  ),
                  Text('일', style: _contractBodyStyle),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 24.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('(사업주) 사업체명 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_business_name']?.text,
              onTap: () => _openInlineInput('사업체명', 'employer_business_name'),
            ),
            Text('(전화 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_phone']?.text,
              onTap: () => _openInlineInput('사업주 전화', 'employer_phone'),
            ),
            Text(')', style: _contractBodyStyle),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('주 소 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_address']?.text,
              onTap: () => _openInlineInput('사업주 주소', 'employer_address'),
              padding: _contractChipPaddingWide,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('대표자 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_representative_name']?.text,
              onTap: () =>
                  _openInlineInput('대표자 성명', 'employer_representative_name'),
            ),
            Text('(서명)', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_signature_text']?.text,
              signatureField: true,
              onTap: () =>
                  _openInlineInput('사업주 서명', 'employer_signature_text'),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('(근로자) 주 소 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_address']?.text,
              tone: _ContractChipTone.worker,
              onTap: () => _openInlineInput('근로자 주소', 'worker_address'),
              padding: _contractChipPaddingWide,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('연락처 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_phone']?.text,
              tone: _ContractChipTone.worker,
              onTap: () => _openInlineInput('근로자 연락처', 'worker_phone'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('성 명 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_name']?.text,
              tone: _ContractChipTone.worker,
              onTap: () => _openInlineInput('근로자 성명', 'worker_name'),
            ),
            Text('(서명)', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_signature_text']?.text,
              tone: _ContractChipTone.worker,
              signatureField: true,
              onTap: () => _openInlineInput('근로자 서명', 'worker_signature_text'),
            ),
          ],
        ),
      ],
    );
  }

  /// 만 나이·연락처·주민등록번호(마스킹) 등 숫자만 받는 필드
  static const Set<String> _inlineDigitsOnlyKeys = {
    'minor_age',
    'guardian_resident_id_masked',
    'minor_resident_id_masked',
    'guardian_phone_number',
    'business_phone_number',
    'employer_phone',
    'worker_phone',
  };

  Future<void> _openInlineInput(String label, String key) async {
    if (key == 'employer_signature_text' || key == 'worker_signature_text') {
      final val = await showContractSignatureDialog(context, label: label);
      if (val != null && mounted) {
        setState(() {
          _c[key]?.text = val;
        });
      }
      return;
    }
    final initial = _wonAmountFieldKeys.contains(key)
        ? _formatWonForDisplay(_c[key]?.text)
        : (_c[key]?.text ?? '');
    final ctrl = TextEditingController(text: initial);
    final modalTitle = modalTitleWithoutParenthetical(label);
    final digitsOnly = _inlineDigitsOnlyKeys.contains(key);
    final paymentDay = key == 'payment_day';
    final wonAmount = _wonAmountFieldKeys.contains(key);

    List<TextInputFormatter>? formatters;
    TextInputType keyboardType = TextInputType.text;
    if (paymentDay) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ];
      keyboardType = TextInputType.number;
    } else if (wonAmount) {
      formatters = [ThousandsSeparatorInputFormatter()];
      keyboardType = TextInputType.number;
    } else if (digitsOnly) {
      formatters = [FilteringTextInputFormatter.digitsOnly];
      keyboardType = TextInputType.number;
    }

    final val = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                modalTitle,
                style: AppTypography.heading3.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 14.h),
              AuthInputField(
                controller: ctrl,
                hintText: '입력해주세요.',
                keyboardType: keyboardType,
                inputFormatters: formatters,
                fillColor: AppColors.grey25,
                focusedBorderColor: AppColors.primaryDark,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey25,
                        foregroundColor: AppColors.textTertiary,
                        shape: _modalActionButtonShape,
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final text = ctrl.text.trim();
                        if (paymentDay) {
                          final v = int.tryParse(text);
                          if (v == null || v < 1 || v > 31) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '임금 지급일은 매월 1일~31일만 입력할 수 있습니다.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        Navigator.pop(ctx, text);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.grey0,
                        shape: _modalActionButtonShape,
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (val != null && mounted) {
      setState(() {
        if (wonAmount) {
          _c[key]?.text = _formatWonForDisplay(val);
        } else {
          _c[key]?.text = val;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootLoading) {
      return Scaffold(
        backgroundColor: AppColors.grey0,
        appBar: AppBar(
          backgroundColor: AppColors.grey0,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.isGuardian
            ? Text(
                '친권자(후견인) 동의서 작성',
                style: AppTypography.bodyMediumM.copyWith(
                  fontSize: 14.sp,
                  height: 16 / 14,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(widget.listTitle),
        backgroundColor: AppColors.grey0,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!widget.isGuardian)
            Expanded(child: _buildStandardContractBody())
          else
            Expanded(child: _buildGuardianBody()),
          if (!widget.isGuardian)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _showSendDialogAndComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('다음'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 소정근로시간 모달 — 요일별 펼침/접힘 (Figma 2534:18090 계열)
class _DayWorkSlot {
  bool open = false;
  int sh = 9;
  int sm = 0;
  int eh = 18;
  int em = 0;
  bool breakHas = false;
  int bsh = 13;
  int bsm = 0;
  int beh = 14;
  int bem = 0;
}
