import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';

/// 근로계약서 작성·수정 (표준/연소: 법정 문구 + 인라인 입력 칩, 친권: 단일 폼)
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

  /// 모달 하단 취소·확인 (Figma 8px)
  static final OutlinedBorder _modalActionButtonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  static const String _svgPickerChevronDown =
      'assets/icons/svg/icon/contract_picker_chevron_down.svg';
  static const String _svgPickerChevronUp =
      'assets/icons/svg/icon/contract_picker_chevron_up.svg';

  /// Figma Heading_3 — 근로계약기간 / 소정근로시간 제목
  static const TextStyle _figmaModalHeading = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    color: Color(0xFF000000),
  );

  /// 시작·종료 (body medium_M)
  static const TextStyle _figmaSectionLabel = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: -0.3,
    color: Color(0xFF1D1D1F),
  );

  /// 년도·월·일 / 근무시작 등 라벨 pill (Body Small_M)
  static const TextStyle _figmaPillLabel = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.0,
    color: Color(0xFFA3A4AF),
  );

  /// Inter-regular-18 숫자
  static const TextStyle _figmaInterValue18 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: Color(0xFF454545),
  );

  /// · 중복 입력 가능 (body medium_M, muted)
  static const TextStyle _figmaWorkTimeSubnote = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: -0.3,
    color: Color(0xFFA3A4AF),
  );

  /// Figma 2534-14920 — 본문 (grey8 #000, 14 / 25)
  static const TextStyle _contractFigmaBody = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 25 / 14,
    color: Color(0xFF000000),
  );

  /// Figma Accents-Orange — 자동 기입 안내
  static const TextStyle _contractFigmaAccent = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
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
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(child: pic),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(18),
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
        'family_relation_certificate_attached',
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
          'work_day_${i}_enabled',
          'work_day_${i}_start',
          'work_day_${i}_end',
          'work_day_${i}_break_has',
          'work_day_${i}_break_start',
          'work_day_${i}_break_end',
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
      final fv = (d['form_values'] as Map?)?.cast<String, dynamic>();
      if (fv != null) {
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
      return int.tryParse(t);
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
    } else {
      final age = pi('minor_age');
      if (age != null) out['minor_age'] = age;
    }
    return out;
  }

  bool _fieldNonEmpty(String key) => (_c[key]?.text.trim().isNotEmpty ?? false);

  /// `docs/api_spec_staff_management.md` §23 `standard_v1` / `minor_standard_v1` 완료 필수
  List<String> _missingFieldsForStandardCompletion() {
    final m = <String>[];
    if (widget.isGuardian) return m;

    if (!_fieldNonEmpty('employer_name') && !_fieldNonEmpty('employer_business_name')) {
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

    final wageTxt = _c['wage_amount']?.text.trim() ?? '';
    final wageAmt = int.tryParse(wageTxt);
    if (wageTxt.isEmpty || wageAmt == null || wageAmt < 0) {
      m.add('임금 금액(원)');
    }

    final pd = int.tryParse(_c['payment_day']?.text.trim() ?? '');
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

  void _showStandardCompletionMissingDialog(List<String> missing) {
    if (!mounted || missing.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '입력이 필요합니다',
          style: AppTypography.heading3.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '완료 저장 전 아래 항목을 채워 주세요. (직원관리 API 근로계약서 완료 필수 항목 기준)',
                style: AppTypography.bodyMediumR.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...missing.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: AppTypography.bodyMediumM.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e,
                          style: AppTypography.bodyMediumR.copyWith(
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.grey0,
              shape: _modalActionButtonShape,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({required bool completed}) async {
    if (completed && !widget.isGuardian) {
      final missing = _missingFieldsForStandardCompletion();
      if (missing.isNotEmpty) {
        _showStandardCompletionMissingDialog(missing);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final repo = context.read<StaffManagementRepository>();
      final fv = _collectFormValues();
      final title = _titleCtrl.text.trim();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
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

  Widget _tf(String label, String key, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTypography.bodySmallB.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          AuthInputField(
            controller: _c[key]!,
            hintText: hint ?? '입력해주세요',
            fillColor: AppColors.grey25,
            focusedBorderColor: AppColors.primaryDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '문서 제목',
          style: AppTypography.bodySmallB.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        AuthInputField(
          controller: _titleCtrl,
          hintText: '제목 (비우면 자동 생성)',
          fillColor: AppColors.grey25,
          focusedBorderColor: AppColors.primaryDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '친권자·연소근로자',
          style: AppTypography.bodyMediumB.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _tf('친권자(후견인) 성명', 'guardian_name'),
        _tf('친권자 주민번호(마스킹)', 'guardian_resident_id_masked',
            hint: '800101-2******'),
        _tf('친권자 주소', 'guardian_address'),
        _tf('친권자 연락처', 'guardian_phone_number'),
        _tf('연소근로자와의 관계', 'relation_to_minor_worker'),
        _tf('연소근로자 성명', 'minor_name'),
        _tf('만 나이', 'minor_age', hint: '14'),
        _tf('연소근로자 주민번호(마스킹)', 'minor_resident_id_masked'),
        _tf('연소근로자 주소', 'minor_address'),
        const SizedBox(height: 16),
        Text(
          '사업장',
          style: AppTypography.bodyMediumB.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _tf('회사명', 'business_name'),
        _tf('회사 주소', 'business_address'),
        _tf('대표자', 'business_representative_name'),
        _tf('회사 전화', 'business_phone_number'),
        const SizedBox(height: 16),
        Text(
          '동의·서명',
          style: AppTypography.bodyMediumB.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _tf('동의문 연소근로자명', 'consent_minor_name'),
        _tf('작성일', 'consent_signed_date', hint: 'YYYY-MM-DD'),
        _tf('친권자 서명', 'guardian_signature_name'),
        _tf('가족관계증명서', 'family_relation_certificate_attached', hint: '첨부'),
        const SizedBox(height: 100),
      ],
    );
  }

  TextStyle get _contractBodyStyle => _contractFigmaBody;

  TextStyle get _contractNoteStyle => _contractFigmaBody.copyWith(
        color: AppColors.textTertiary,
      );

  /// Figma: 민트/오렌지 라운드 칩, 비어 있으면 「입력」
  Widget _inputChip({
    required String? display,
    required VoidCallback onTap,
    bool worker = false,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  }) {
    final t = display?.trim() ?? '';
    final empty = t.isEmpty;
    final bg = worker ? _workerChipBg : _mintChipBg;
    final fg = worker ? _workerChipFg : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fg.withValues(alpha: 0.45)),
          ),
          child: Text(
            empty ? '입력' : t,
            style: _contractFigmaBody.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 20 / 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleToggle({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
    DateTime? initial = DateTime.tryParse(_c['contract_signed_date']?.text ?? '');
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

  Future<void> _openWorkTimesDialog() async {
    const dayKor = ['월', '화', '수', '목', '금', '토', '일'];
    String two(int n) => n.toString().padLeft(2, '0');

    (int, int) parseHm(String? raw, int fh, int fm) {
      final t = raw?.trim() ?? '';
      if (!t.contains(':')) return (fh, fm);
      final p = t.split(':');
      if (p.length < 2) return (fh, fm);
      return (
        int.tryParse(p[0].trim()) ?? fh,
        int.tryParse(p[1].trim()) ?? fm,
      );
    }

    final slots = List<_DayWorkSlot>.generate(7, (_) => _DayWorkSlot());
    var hadStoredDay = false;
    for (var i = 0; i < 7; i++) {
      final en = _c['work_day_${i}_enabled']?.text.trim();
      if (en == '1' || en == '0') {
        hadStoredDay = true;
        slots[i].open = en == '1';
      }
      final ws = _c['work_day_${i}_start']?.text ?? '';
      final we = _c['work_day_${i}_end']?.text ?? '';
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
      final bh = _c['work_day_${i}_break_has']?.text.trim();
      if (bh == '1' || bh == '0') {
        slots[i].breakHas = bh == '1';
      }
      final bs = _c['work_day_${i}_break_start']?.text ?? '';
      final be = _c['work_day_${i}_break_end']?.text ?? '';
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
        final brk = (_c['break_start_time']?.text.trim().isNotEmpty ?? false) ||
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(18),
            child: _pickerChevron(up: true, whiteCircle: true),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              two(value % modulus),
              maxLines: 1,
              style: _figmaInterValue18,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onDown,
            borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: AppTypography.bodyLargeM.copyWith(
                fontSize: 20,
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
                    const SizedBox(height: 8),
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
                padding: const EdgeInsets.only(top: 20),
                child: Text('~', style: AppTypography.bodyLargeM),
              ),
              Expanded(
                child: Column(
                  children: [
                    workTimeFieldLabel('근무종료시간'),
                    const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          Text('휴게시간', style: AppTypography.bodyMediumM),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => apply(() => s.breakHas = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      color: !s.breakHas ? AppColors.primaryLight : AppColors.grey25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !s.breakHas
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: !s.breakHas ? AppColors.primary : AppColors.grey100,
                        ),
                        const SizedBox(width: 6),
                        Text('없음', style: AppTypography.bodyMediumM),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => apply(() => s.breakHas = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      color: s.breakHas ? AppColors.primaryLight : AppColors.grey25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          s.breakHas
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: s.breakHas ? AppColors.primary : AppColors.grey100,
                        ),
                        const SizedBox(width: 6),
                        Text('있음', style: AppTypography.bodyMediumM),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (s.breakHas) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      workTimeFieldLabel('휴게시작시간'),
                      const SizedBox(height: 8),
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
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('~', style: AppTypography.bodyLargeM),
                ),
                Expanded(
                  child: Column(
                    children: [
                      workTimeFieldLabel('휴게종료시간'),
                      const SizedBox(height: 8),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 320,
                maxHeight: maxH,
                maxWidth: 360,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '· 중복 입력 가능',
                        style: _figmaWorkTimeSubnote,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var i = 0; i < 7; i++) ...[
                              if (!slots[i].open)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: AppColors.grey0,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap: () => setLocal(() => slots[i].open = true),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: double.infinity,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.grey50),
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
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3FBF8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: () => setLocal(() => slots[i].open = false),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                dayKor[i],
                                                style: AppTypography.bodyMediumM.copyWith(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.expand_less_rounded,
                                                size: 22,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        workTimeBlock(slots[i], (fn) => slot(i, fn)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 10),
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
          _c['work_day_${i}_enabled']!.text = s.open ? '1' : '0';
          if (!s.open) {
            _c['work_day_${i}_start']!.text = '';
            _c['work_day_${i}_end']!.text = '';
            _c['work_day_${i}_break_has']!.text = '0';
            _c['work_day_${i}_break_start']!.text = '';
            _c['work_day_${i}_break_end']!.text = '';
          } else {
            _c['work_day_${i}_start']!.text = '${two(s.sh)}:${two(s.sm)}';
            _c['work_day_${i}_end']!.text = '${two(s.eh)}:${two(s.em)}';
            _c['work_day_${i}_break_has']!.text = s.breakHas ? '1' : '0';
            _c['work_day_${i}_break_start']!.text =
                s.breakHas ? '${two(s.bsh)}:${two(s.bsm)}' : '';
            _c['work_day_${i}_break_end']!.text =
                s.breakHas ? '${two(s.beh)}:${two(s.bem)}' : '';
          }
        }

        final firstOpen = slots.indexWhere((e) => e.open);
        if (firstOpen >= 0) {
          final s = slots[firstOpen];
          _c['scheduled_work_start_time']!.text = '${two(s.sh)}:${two(s.sm)}';
          _c['scheduled_work_end_time']!.text = '${two(s.eh)}:${two(s.em)}';
          _c['break_start_time']!.text =
              s.breakHas ? '${two(s.bsh)}:${two(s.bsm)}' : '';
          _c['break_end_time']!.text =
              s.breakHas ? '${two(s.beh)}:${two(s.bem)}' : '';
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
    DateTime start = DateTime.tryParse(_c['contract_start_date']?.text ?? '') ??
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _figmaPillLabel,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onUp,
            borderRadius: BorderRadius.circular(18),
            child: _pickerChevron(up: true, whiteCircle: false),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Text(
              '$value',
              maxLines: 1,
              softWrap: false,
              style: _figmaInterValue18,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onDown,
            borderRadius: BorderRadius.circular(18),
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
            const SizedBox(height: 8),
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
                const SizedBox(width: 16),
                dateSpinner(
                  label: '월',
                  value: month,
                  onUp: monthUp,
                  onDown: monthDown,
                ),
                const SizedBox(width: 16),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                  const SizedBox(height: 20),
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
                        final ny = start.month == 12 ? start.year + 1 : start.year;
                        final nd = start.day.clamp(1, dayMax(ny, nm));
                        start = DateTime(ny.clamp(2000, 2100), nm, nd);
                      });
                    },
                    monthDown: () {
                      setLocal(() {
                        final nm = start.month == 1 ? 12 : start.month - 1;
                        final ny = start.month == 1 ? start.year - 1 : start.year;
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 24),
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
                      const SizedBox(width: 12),
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
    final amountCtrl = TextEditingController(text: _c['wage_amount']?.text ?? '');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('임금', style: AppTypography.heading3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _wageOptionTile(
                        selected: localType == 'hourly',
                        label: '시급',
                        onTap: () => setLocal(() => localType = 'hourly'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _wageOptionTile(
                        selected: localType == 'monthly',
                        label: '월급',
                        onTap: () => setLocal(() => localType = 'monthly'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AuthInputField(
                  controller: amountCtrl,
                  hintText: switch (localType) {
                    'hourly' => '시급을 입력해주세요.',
                    'daily' => '일급을 입력해주세요.',
                    _ => '월급을 입력해주세요.',
                  },
                  keyboardType: TextInputType.number,
                  fillColor: AppColors.grey25,
                  focusedBorderColor: AppColors.primaryDark,
                  suffixText: '원',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                const SizedBox(height: 24),
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
                    const SizedBox(width: 12),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.grey50),
          color: selected ? AppColors.primary.withValues(alpha: 0.16) : AppColors.grey25,
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTypography.bodyMediumM),
      ),
    );
  }

  Future<void> _showSendDialogAndComplete() async {
    final missing = _missingFieldsForStandardCompletion();
    if (missing.isNotEmpty) {
      _showStandardCompletionMissingDialog(missing);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('알림', style: AppTypography.heading3),
              const SizedBox(height: 14),
              Text(
                '해당 계약서를 근로자에게 전송하시겠습니까?',
                style: AppTypography.bodyMediumM.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 22),
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
                  const SizedBox(width: 12),
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
      final en = _c['work_day_${i}_enabled']?.text.trim();
      if (en == '0' || en == '1') return true;
      final ws = _c['work_day_${i}_start']?.text.trim();
      if (ws != null && ws.isNotEmpty) return true;
    }
    return false;
  }

  /// 근무로 설정된 요일만 (인덱스 0=월 … 6=일)
  List<({int i, String start, String end})> _enabledWorkDaySlots() {
    final out = <({int i, String start, String end})>[];
    for (var i = 0; i < 7; i++) {
      final en = _c['work_day_${i}_enabled']?.text.trim();
      if (en == '0') continue;
      final ws = _c['work_day_${i}_start']?.text.trim() ?? '';
      final we = _c['work_day_${i}_end']?.text.trim() ?? '';
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
        if (_c['work_day_${o.i}_break_has']?.text.trim() != '1') continue;
        final bs = _c['work_day_${o.i}_break_start']?.text.trim() ?? '';
        final be = _c['work_day_${o.i}_break_end']?.text.trim() ?? '';
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
        parts.add('${_formatDayIndexRuns(List<int>.from(e.value)..sort())} ${e.key}');
      }
      return Text(parts.join(' / '), style: _contractFigmaBody);
    }
    return _legacyContractBreakTimeBody();
  }

  Widget? _legacyContractBreakTimeBody() {
    final bs = _c['break_start_time']?.text.trim() ?? '';
    final be = _c['break_end_time']?.text.trim() ?? '';
    if (bs.isEmpty && be.isEmpty) return null;
    if (bs.isNotEmpty && be.isNotEmpty) return Text('$bs~$be', style: _contractFigmaBody);
    if (bs.isNotEmpty) return Text(bs, style: _contractFigmaBody);
    return Text(be, style: _contractFigmaBody);
  }

  Widget _contractNumbered(int index, Widget body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    final wageChipText =
        wageAmount.isEmpty ? '' : '$wageLabel $wageAmount';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          '표준 근로 계약서',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            height: 24 / 18,
          ),
        ),
        const SizedBox(height: 16),
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
              worker: true,
              onTap: () => _openInlineInput('근로자명', 'worker_name'),
            ),
            Text('(이하 "근로자"라 함)은', style: _contractBodyStyle),
          ],
        ),
        Text('다음과 같이 근로계약을 체결한다.', style: _contractBodyStyle),
        const SizedBox(height: 20),
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
              const SizedBox(height: 6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
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
                          display:
                              wageChipText.isEmpty ? null : wageChipText,
                          onTap: _openWageDialog,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        Text(' 원', style: _contractBodyStyle),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
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
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('임금지급일 : 매월(매주 또는 매일) ',
                            style: _contractBodyStyle),
                        _inputChip(
                          display: _c['payment_day']?.text,
                          onTap: () =>
                              _openInlineInput('임금 지급일(일)', 'payment_day'),
                        ),
                        Text('일 (휴일의 경우는 전일 지급)',
                            style: _contractBodyStyle),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('· ', style: _contractBodyStyle),
                        Text('지급방법 : 근로자에게 직접지급(',
                            style: _contractBodyStyle),
                        _circleToggle(
                          selected: _paymentMethod == 'direct',
                          onTap: () =>
                              setState(() => _paymentMethod = 'direct'),
                        ),
                        Text('), 근로자 명의 예금통장에 입금(',
                            style: _contractBodyStyle),
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
              const SizedBox(height: 4),
              Text(
                '연차유급휴가는 근로기준법에서 정하는 바에 따라 부여함',
                style: _contractBodyStyle,
              ),
            ],
          ),
        ),
        _contractNumbered(
          8,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('근로계약서 교부', style: _contractBodyStyle),
              const SizedBox(height: 4),
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
              const SizedBox(height: 4),
              Text(
                '이 계약에 정함이 없는 사항은 근로기준법령에 의함',
                style: _contractBodyStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Builder(
            builder: (context) {
              final d = DateTime.tryParse(_c['contract_signed_date']?.text ?? '');
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
        const SizedBox(height: 24),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('(사업주) 사업체명 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_business_name']?.text,
              onTap: () =>
                  _openInlineInput('사업체명', 'employer_business_name'),
            ),
            Text('(전화 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_phone']?.text,
              onTap: () => _openInlineInput('사업주 전화', 'employer_phone'),
            ),
            Text(')', style: _contractBodyStyle),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('주 소 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['employer_address']?.text,
              onTap: () => _openInlineInput('사업주 주소', 'employer_address'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              onTap: () => _openInlineInput('사업주 서명', 'employer_signature_text'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('(근로자) 주 소 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_address']?.text,
              worker: true,
              onTap: () => _openInlineInput('근로자 주소', 'worker_address'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('연락처 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_phone']?.text,
              worker: true,
              onTap: () => _openInlineInput('근로자 연락처', 'worker_phone'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('성 명 : ', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_name']?.text,
              worker: true,
              onTap: () => _openInlineInput('근로자 성명', 'worker_name'),
            ),
            Text('(서명)', style: _contractBodyStyle),
            _inputChip(
              display: _c['worker_signature_text']?.text,
              worker: true,
              onTap: () =>
                  _openInlineInput('근로자 서명', 'worker_signature_text'),
            ),
          ],
        ),
        if (widget.isMinor) ...[
          const SizedBox(height: 20),
          Text('연소근로자 추가', style: AppTypography.bodyMediumB),
          const SizedBox(height: 8),
          _inputChip(
            display: _c['family_relation_certificate_submitted']?.text,
            onTap: () => _openInlineInput(
              '가족관계증명서 제출',
              'family_relation_certificate_submitted',
            ),
          ),
          const SizedBox(height: 8),
          _inputChip(
            display: _c['guardian_consent_submitted']?.text,
            onTap: () => _openInlineInput(
              '친권자 동의서 구비',
              'guardian_consent_submitted',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openInlineInput(String label, String key) async {
    final ctrl = TextEditingController(text: _c[key]?.text ?? '');
    final val = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: AppTypography.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 14),
              AuthInputField(
                controller: ctrl,
                hintText: '입력해주세요.',
                fillColor: AppColors.grey25,
                focusedBorderColor: AppColors.primaryDark,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
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
      setState(() => _c[key]?.text = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootLoading) {
      return Scaffold(
        backgroundColor: AppColors.grey0Alt,
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
      backgroundColor:
          widget.isGuardian ? AppColors.grey0Alt : AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.listTitle,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        actions: widget.isGuardian
            ? [
                TextButton(
                  onPressed: _loading ? null : () => _save(completed: false),
                  child: Text(
                    '임시저장',
                    style: AppTypography.bodyMediumM.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ]
            : const [],
      ),
      body: Column(
        children: [
          if (!widget.isGuardian)
            Expanded(child: _buildStandardContractBody())
          else
            Expanded(child: _buildGuardianBody()),
          if (widget.isGuardian)
            _guardianBottom()
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _showSendDialogAndComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _guardianBottom() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _loading ? null : () => _save(completed: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('작성 완료'),
          ),
        ),
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
