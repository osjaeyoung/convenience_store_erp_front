import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employment_contract_pdf_export.dart';

/// 근로계약서 조회 (Figma 2534-18557, 읽기 전용 · 입력값 밑줄 · PDF 다운로드)
class EmploymentContractDetailScreen extends StatefulWidget {
  const EmploymentContractDetailScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.contractId,
    required this.listTitle,
    this.summaryRow,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final int contractId;
  final String listTitle;
  final Map<String, dynamic>? summaryRow;

  @override
  State<EmploymentContractDetailScreen> createState() =>
      _EmploymentContractDetailScreenState();
}

class _EmploymentContractDetailScreenState
    extends State<EmploymentContractDetailScreen> {
  bool _loading = true;
  bool _pdfBusy = false;
  String? _error;
  Map<String, dynamic>? _row;

  static const TextStyle _docBodyStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 19 / 14,
    color: Color(0xFF000000),
  );

  static const TextStyle _docHeadingStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    color: Color(0xFF000000),
  );

  static const Color _underlineColor = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _row = widget.summaryRow;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<StaffManagementRepository>();
      final data = await repo.getEmploymentContractDetail(
        branchId: widget.branchId,
        employeeId: widget.employeeId,
        contractId: widget.contractId,
      );
      if (!mounted) return;
      setState(() {
        _row = data;
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

  Future<void> _downloadPdf() async {
    final fv =
        (_row!['form_values'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    setState(() => _pdfBusy = true);
    try {
      final bytes = await buildEmploymentContractPdfBytes(
        templateVersion: _templateVersion(),
        formValues: fv,
        documentTitle: _documentTitle(),
      );
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'employment_contract_${widget.contractId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 저장에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 근로계약서를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<StaffManagementRepository>().deleteEmploymentContract(
            branchId: widget.branchId,
            employeeId: widget.employeeId,
            contractId: widget.contractId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  String _documentTitle() {
    final t = _row?['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    return widget.listTitle;
  }

  String _templateVersion() =>
      _row?['template_version']?.toString() ?? 'standard_v1';

  /// 짧은 인라인 값 — 글자 위, 밑줄
  Widget _u(String value, {String placeholder = '　　　　'}) {
    final has = value.trim().isNotEmpty;
    final display = has ? value : placeholder;
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            display,
            style: _docBodyStyle.copyWith(
              color: has
                  ? _underlineColor
                  : _underlineColor.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: _underlineColor),
        ],
      ),
    );
  }

  /// 여러 줄·긴 값 — 본문 위, 전체 너비 밑줄
  Widget _uBlock(String value) {
    final has = value.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          has ? value : ' ',
          style: _docBodyStyle.copyWith(
            color: has
                ? _underlineColor
                : _underlineColor.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 2),
        Container(height: 1, color: _underlineColor),
      ],
    );
  }

  Widget _t(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: _docBodyStyle),
      );

  static String _fv(Map<String, dynamic> fv, String key) =>
      fv[key]?.toString().trim() ?? '';

  static String _formatKoreanDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '____년 ____월 ____일';
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  static String _wageTypeKo(String? t) => switch (t) {
        'hourly' => '시급',
        'daily' => '일급',
        _ => '월급',
      };

  static String _paymentMethodLine(Map<String, dynamic> fv) {
    final t = _fv(fv, 'payment_method');
    if (t.isEmpty) {
      return '지급방법 : 근로자에게 직접지급(   ), 근로자 명의 예금통장에 입금(   )';
    }
    final d = t == 'direct' ? '✓' : ' ';
    final b = t == 'bank_transfer' ? '✓' : ' ';
    return '지급방법 : 근로자에게 직접지급($d), 근로자 명의 예금통장에 입금($b)';
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
        title: Text(
          widget.listTitle,
          style: AppTypography.bodyLargeB.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final fv = (_row!['form_values'] as Map?)?.cast<String, dynamic>() ?? {};
    final tv = _templateVersion();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF5F5F7)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _documentTitle(),
                  style: _docHeadingStyle,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 28,
                color: AppColors.textPrimary,
                onPressed: _delete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: tv == 'guardian_consent_v1'
                ? _buildGuardianReadBody(fv)
                : _buildStandardContractReadBody(fv, tv == 'minor_standard_v1'),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_pdfBusy || _loading) ? null : _downloadPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _pdfBusy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        '다운로드',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.primary,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardContractReadBody(
    Map<String, dynamic> fv,
    bool isMinor,
  ) {
    final employer = _fv(fv, 'employer_name').isEmpty
        ? _fv(fv, 'employer_business_name')
        : _fv(fv, 'employer_name');
    final worker = _fv(fv, 'worker_name');
    final periodStart = _formatKoreanDate(_fv(fv, 'contract_start_date'));
    final periodEnd = _formatKoreanDate(_fv(fv, 'contract_end_date'));
    final sws = _fv(fv, 'scheduled_work_start_time');
    final swe = _fv(fv, 'scheduled_work_end_time');
    final bs = _fv(fv, 'break_start_time');
    final be = _fv(fv, 'break_end_time');
    final wd = _fv(fv, 'work_days_per_week');
    final wh = _fv(fv, 'weekly_holiday_day');
    final wageAmt = _fv(fv, 'wage_amount');
    final wageLabel = _wageTypeKo(_fv(fv, 'wage_type'));
    final wageLine = wageAmt.isEmpty ? '' : '$wageLabel $wageAmt 원';
    final bonusOn =
        fv['bonus_included'] == true || _fv(fv, 'bonus_included') == 'true';
    final bonusAmt = _fv(fv, 'bonus_amount');
    final otherOn = fv['other_allowance_included'] == true ||
        _fv(fv, 'other_allowance_included') == 'true';
    final otherAmt = _fv(fv, 'other_allowance_amount');
    final meal = _fv(fv, 'meal_allowance');
    final transport = _fv(fv, 'transport_allowance');
    final extraName = _fv(fv, 'extra_allowance_name');
    final extraAmt = _fv(fv, 'extra_allowance_amount');
    final payDay = _fv(fv, 'payment_day');
    final payMethodLine = _paymentMethodLine(fv);
    final signed = _formatKoreanDate(_fv(fv, 'contract_signed_date'));
    final biz = _fv(fv, 'employer_business_name');
    final phone = _fv(fv, 'employer_phone');
    final addr = _fv(fv, 'employer_address');
    final rep = _fv(fv, 'employer_representative_name');
    final esign = _fv(fv, 'employer_signature_text');
    final waddr = _fv(fv, 'worker_address');
    final wphone = _fv(fv, 'worker_phone');
    final wsign = _fv(fv, 'worker_signature_text');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _u(employer),
            Text('(이하 "사업주"라 함)과(와) ', style: _docBodyStyle),
            _u(worker),
            Text('(이하 "근로자"라 함)은', style: _docBodyStyle),
          ],
        ),
        _t('다음과 같이 근로계약을 체결한다.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('1. 근로계약기간 : ', style: _docBodyStyle),
            _u(
              _fv(fv, 'contract_start_date').isEmpty ? '' : periodStart,
              placeholder: '　　　　　　　',
            ),
            Text('부터 ', style: _docBodyStyle),
            _u(
              _fv(fv, 'contract_end_date').isEmpty ? '' : periodEnd,
              placeholder: '　　　　　　　',
            ),
            Text('까지', style: _docBodyStyle),
          ],
        ),
        _t('※ 근로계약기간을 정하지 않는 경우에는 "근로개시일"만 기재'),
        const SizedBox(height: 12),
        Text('2. 근 무 장 소 :', style: _docBodyStyle),
        const SizedBox(height: 4),
        _uBlock(_fv(fv, 'work_place')),
        const SizedBox(height: 12),
        Text('3. 업 무 내 용 :', style: _docBodyStyle),
        const SizedBox(height: 4),
        _uBlock(_fv(fv, 'job_description')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('4. 소정근로시간 : ', style: _docBodyStyle),
            _u(sws),
            Text('부터 ', style: _docBodyStyle),
            _u(swe),
            Text('까지', style: _docBodyStyle),
          ],
        ),
        if (bs.isNotEmpty || be.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text('(휴게시간: ', style: _docBodyStyle),
              _u(bs),
              Text(' ~ ', style: _docBodyStyle),
              _u(be),
              Text(')', style: _docBodyStyle),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('5. 근무일/휴일 : 매주 ', style: _docBodyStyle),
            _u(wd, placeholder: '　　'),
            Text('일(또는 매일단위)근무, 주휴일 매주 ', style: _docBodyStyle),
            _u(wh, placeholder: '　　'),
            Text('요일', style: _docBodyStyle),
          ],
        ),
        const SizedBox(height: 12),
        _t('6. 임 금'),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(' · 월(일, 시간)급 : ', style: _docBodyStyle),
                  Expanded(child: _uBlock(wageLine.isEmpty ? '' : wageLine)),
                ],
              ),
              const SizedBox(height: 8),
              _t(
                ' · 상여금 : 있음(${bonusOn ? '✓' : ' '}) '
                '${bonusOn && bonusAmt.isNotEmpty ? '$bonusAmt원' : ''}',
              ),
              if (bonusOn && bonusAmt.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: _u(''),
                ),
              _t('   없음(${!bonusOn ? '✓' : ' '})'),
              const SizedBox(height: 6),
              _t(
                ' · 기타급여(제수당 등) : 있음(${otherOn ? '✓' : ' '}) '
                '${otherOn && otherAmt.isNotEmpty ? '$otherAmt원' : ''}',
              ),
              if (otherOn && otherAmt.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: _u(''),
                ),
              _t('   없음(${!otherOn ? '✓' : ' '})'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 식대(비과세) ', style: _docBodyStyle),
                  _u(meal, placeholder: '　　　'),
                  Text('원', style: _docBodyStyle),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 교통비 ', style: _docBodyStyle),
                  _u(transport, placeholder: '　　　'),
                  Text('원', style: _docBodyStyle),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 기타(', style: _docBodyStyle),
                  _u(extraName, placeholder: '　　'),
                  Text(') ', style: _docBodyStyle),
                  _u(extraAmt, placeholder: '　　　'),
                  Text('원', style: _docBodyStyle),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 임금지급일 : 매월(매주 또는 매일) ', style: _docBodyStyle),
                  _u(payDay, placeholder: '　　'),
                  Text('일 (휴일의 경우는 전일 지급)', style: _docBodyStyle),
                ],
              ),
              const SizedBox(height: 6),
              _t(' · $payMethodLine'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _t('7. 연차유급휴가'),
        _t(' · 연차유급휴가는 근로기준법에서 정하는 바에 따라 부여함'),
        const SizedBox(height: 12),
        _t('8. 근로계약서 교부'),
        _t(
          ' · 사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 '
          '근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조 이행)',
        ),
        const SizedBox(height: 12),
        _t('9. 기 타'),
        _t(' · 이 계약에 정함이 없는 사항은 근로기준법령에 의함'),
        const SizedBox(height: 16),
        _u(
          _fv(fv, 'contract_signed_date').isEmpty ? '' : signed,
          placeholder: '　　　　　　　',
        ),
        const SizedBox(height: 16),
        Text('(사업주) 사업체명 :', style: _docBodyStyle),
        const SizedBox(height: 4),
        _uBlock(biz),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('(전화 : ', style: _docBodyStyle),
            _u(phone, placeholder: '　　　　　'),
            Text(')', style: _docBodyStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text(' 주 소 :', style: _docBodyStyle),
        const SizedBox(height: 4),
        _uBlock(addr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 대표자 : ', style: _docBodyStyle),
            _u(rep),
            Text(' (서명) ', style: _docBodyStyle),
            _u(esign, placeholder: '　　　'),
          ],
        ),
        const SizedBox(height: 16),
        Text('(근로자) 주 소 :', style: _docBodyStyle),
        const SizedBox(height: 4),
        _uBlock(waddr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 연락처 : ', style: _docBodyStyle),
            _u(wphone, placeholder: '　　　　　'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 성 명 : ', style: _docBodyStyle),
            _u(worker),
            Text(' (서명) ', style: _docBodyStyle),
            _u(wsign, placeholder: '　　　'),
          ],
        ),
        if (isMinor) ...[
          const SizedBox(height: 20),
          _uBlock(
            '가족관계증명서 ${_fv(fv, 'family_relation_certificate_submitted').isEmpty ? '—' : _fv(fv, 'family_relation_certificate_submitted')}',
          ),
          const SizedBox(height: 8),
          _uBlock(
            '친권자 동의서 ${_fv(fv, 'guardian_consent_submitted').isEmpty ? '—' : _fv(fv, 'guardian_consent_submitted')}',
          ),
        ],
      ],
    );
  }

  static const _guardianKeys = <String, String>{
    'guardian_name': '친권자(후견인) 성명',
    'guardian_resident_id_masked': '친권자 주민등록번호(마스킹)',
    'guardian_address': '친권자 주소',
    'guardian_phone_number': '친권자 연락처',
    'relation_to_minor_worker': '근로자와의 관계',
    'minor_name': '연소근로자 성명',
    'minor_age': '연소근로자 만 나이',
    'minor_resident_id_masked': '연소근로자 주민등록번호(마스킹)',
    'minor_address': '연소근로자 주소',
    'business_name': '사업체명',
    'business_address': '사업장 주소',
    'business_representative_name': '대표자',
    'business_phone_number': '사업장 연락처',
    'consent_minor_name': '동의서 상 근로자명',
    'consent_signed_date': '작성일',
    'guardian_signature_name': '친권자 서명',
    'family_relation_certificate_attached': '가족관계증명서',
  };

  Widget _buildGuardianReadBody(Map<String, dynamic> fv) {
    final children = <Widget>[
      _t('친권자(후견인) 동의서'),
      const SizedBox(height: 12),
    ];
    var any = false;
    for (final e in _guardianKeys.entries) {
      final v = _fv(fv, e.key);
      if (v.isEmpty) continue;
      any = true;
      children.add(Text('${e.value} :', style: _docBodyStyle));
      children.add(const SizedBox(height: 4));
      children.add(_uBlock(v));
      children.add(const SizedBox(height: 12));
    }
    if (!any) {
      children.add(
        Text(
          '등록된 내용이 없습니다.',
          style: _docBodyStyle.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
