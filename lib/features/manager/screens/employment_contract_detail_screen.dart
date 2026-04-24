import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../data/repositories/staff_management_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_styled_confirm_dialog.dart';
import '../../../widgets/contract_signature.dart';
import 'employment_contract_attachment_helpers.dart';
import 'employment_contract_pdf_export.dart';
import 'employee_etc_record_inline_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  static TextStyle get _docBodyStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 19 / 14,
    color: Color(0xFF000000),
  );

  static TextStyle get _docHeadingStyle => TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18.sp,
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

  /// 공유·저장 파일명: `제목_이름.pdf` (예: 근로계약서_김테스트)
  static String _sanitizeFileNameSegment(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _pdfFileName() {
    // 목록/메뉴 제목(예: 근로계약서) + 근로자명 → `근로계약서_김테스트.pdf`
    final titleRaw = widget.listTitle.trim().isNotEmpty
        ? widget.listTitle
        : _documentTitle();
    final title = _sanitizeFileNameSegment(titleRaw);
    final name = _sanitizeFileNameSegment(widget.employeeName);
    if (title.isEmpty && name.isEmpty) {
      return '근로계약서.pdf';
    }
    if (name.isEmpty) return '$title.pdf';
    if (title.isEmpty) return '$name.pdf';
    return '${title}_$name.pdf';
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
        filename: _pdfFileName(),
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
    final ok = await showAppStyledDeleteDialog(
      context,
      message: '이 근로계약서를 삭제할까요?',
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
          SizedBox(height: 2.h),
          Container(height: 1, color: _underlineColor),
        ],
      ),
    );
  }

  /// 서명(data URL PNG) 또는 기존 텍스트 서명
  Widget _uSignature(String value, {String placeholder = '　　　'}) {
    return IntrinsicWidth(
      child: contractSignatureReadonlyInline(
        raw: value,
        textStyle: _docBodyStyle,
        underlineColor: _underlineColor,
        placeholder: placeholder,
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
        SizedBox(height: 2.h),
        Container(height: 1, color: _underlineColor),
      ],
    );
  }

  Widget _t(String text) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
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
        title: Text(widget.listTitle),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
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
    final row = _row!;
    if (EmploymentContractAttachmentHelpers.isFileOnlyRegistration(row)) {
      return _buildFileOnlyContractContent(row);
    }

    final fv = (row['form_values'] as Map?)?.cast<String, dynamic>() ?? {};
    final tv = _templateVersion();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 20.h),
          decoration: BoxDecoration(
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
                onPressed: _delete,
                icon: Image.asset(
                  'assets/icons/png/common/trash_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tv == 'guardian_consent_v1')
                  _buildGuardianReadBody(fv)
                else
                  _buildStandardContractReadBody(fv, tv == 'minor_standard_v1'),
                SizedBox(height: 28.h),
                OutlinedButton(
                  onPressed: (_pdfBusy || _loading) ? null : _downloadPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
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
                            fontSize: 16.sp,
                            height: 24 / 16,
                          ),
                        ),
                ),
                SizedBox(height: 20 + bottomInset),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 스펙 ##23-1: 제목·첨부만 등록 — 양식 본문 대신 파일 미리보기 (바이트는 ##26-1 스트리밍)
  Widget _buildFileOnlyContractContent(Map<String, dynamic> row) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final url = EmploymentContractAttachmentHelpers.primaryFileUrl(row);
    final name = EmploymentContractAttachmentHelpers.primaryFileName(row);
    final hasFile = EmploymentContractAttachmentHelpers.hasAttachment(row);
    final repo = context.read<StaffManagementRepository>();
    final fid = EmploymentContractAttachmentHelpers.primaryFileId(row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 20.h),
          decoration: BoxDecoration(
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
                onPressed: _delete,
                icon: Image.asset(
                  'assets/icons/png/common/trash_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasFile)
                  EtcRecordInlineFilePreview(
                    fileUrl: url ?? '',
                    height: 360,
                    displayFileName: name ?? _documentTitle(),
                    loadBytes: () => repo.getEmploymentContractAttachmentBytes(
                      branchId: widget.branchId,
                      employeeId: widget.employeeId,
                      contractId: widget.contractId,
                      fileId: fid,
                    ),
                  )
                else
                  Text(
                    '등록된 첨부가 없습니다. 목록에서 새로고침 후 다시 시도해 주세요.',
                    style: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                SizedBox(height: 20 + bottomInset),
              ],
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
        SizedBox(height: 16.h),
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
        SizedBox(height: 12.h),
        Text('2. 근 무 장 소 :', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(_fv(fv, 'work_place')),
        SizedBox(height: 12.h),
        Text('3. 업 무 내 용 :', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(_fv(fv, 'job_description')),
        SizedBox(height: 12.h),
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
          SizedBox(height: 6.h),
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
        SizedBox(height: 12.h),
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
        SizedBox(height: 12.h),
        _t('6. 임 금'),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 4.w),
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
              SizedBox(height: 8.h),
              _t(
                ' · 상여금 : 있음(${bonusOn ? '✓' : ' '}) '
                '${bonusOn && bonusAmt.isNotEmpty ? '$bonusAmt원' : ''}',
              ),
              if (bonusOn && bonusAmt.isEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 12.w, top: 2.h),
                  child: _u(''),
                ),
              _t('   없음(${!bonusOn ? '✓' : ' '})'),
              SizedBox(height: 6.h),
              _t(
                ' · 기타급여(제수당 등) : 있음(${otherOn ? '✓' : ' '}) '
                '${otherOn && otherAmt.isNotEmpty ? '$otherAmt원' : ''}',
              ),
              if (otherOn && otherAmt.isEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 12.w, top: 2.h),
                  child: _u(''),
                ),
              _t('   없음(${!otherOn ? '✓' : ' '})'),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 식대(비과세) ', style: _docBodyStyle),
                  _u(meal, placeholder: '　　　'),
                  Text('원', style: _docBodyStyle),
                ],
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 교통비 ', style: _docBodyStyle),
                  _u(transport, placeholder: '　　　'),
                  Text('원', style: _docBodyStyle),
                ],
              ),
              SizedBox(height: 6.h),
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
              SizedBox(height: 6.h),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(' · 임금지급일 : 매월(매주 또는 매일) ', style: _docBodyStyle),
                  _u(payDay, placeholder: '　　'),
                  Text('일 (휴일의 경우는 전일 지급)', style: _docBodyStyle),
                ],
              ),
              SizedBox(height: 6.h),
              _t(' · $payMethodLine'),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _t('7. 연차유급휴가'),
        _t(' · 연차유급휴가는 근로기준법에서 정하는 바에 따라 부여함'),
        SizedBox(height: 12.h),
        if (isMinor) ...[
          _t('8. 가족관계증명서 및 동의서'),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                ' · 가족관계기록사항에 관한 증명서 제출 여부 : ',
                style: _docBodyStyle,
              ),
              _u(_fv(fv, 'family_relation_certificate_submitted')),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                ' · 친권자 또는 후견인의 동의서 구비 여부 : ',
                style: _docBodyStyle,
              ),
              _u(_fv(fv, 'guardian_consent_submitted')),
            ],
          ),
          SizedBox(height: 12.h),
          _t('9. 근로계약서 교부'),
          _t(
            ' · 사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 '
            '근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조, 제67조 이행)',
          ),
          SizedBox(height: 12.h),
          _t('10. 기 타'),
          _t(
            ' · 13세 이상 15세 미만인 자에 대해서는 고용노동부장관으로부터 취직인허증을 교부받아야 하며, 이 계약에 정함이 없는 사항은 근로기준법령에 의함',
          ),
        ] else ...[
          _t('8. 근로계약서 교부'),
          _t(
            ' · 사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 '
            '근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조 이행)',
          ),
          SizedBox(height: 12.h),
          _t('9. 기 타'),
          _t(' · 이 계약에 정함이 없는 사항은 근로기준법령에 의함'),
        ],
        SizedBox(height: 16.h),
        _u(
          _fv(fv, 'contract_signed_date').isEmpty ? '' : signed,
          placeholder: '　　　　　　　',
        ),
        SizedBox(height: 16.h),
        Text('(사업주) 사업체명 :', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(biz),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('(전화 : ', style: _docBodyStyle),
            _u(phone, placeholder: '　　　　　'),
            Text(')', style: _docBodyStyle),
          ],
        ),
        SizedBox(height: 8.h),
        Text(' 주 소 :', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(addr),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 대표자 : ', style: _docBodyStyle),
            _u(rep),
            Text(' (서명) ', style: _docBodyStyle),
            _uSignature(esign, placeholder: '　　　'),
          ],
        ),
        SizedBox(height: 16.h),
        Text('(근로자) 주 소 :', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(waddr),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 연락처 : ', style: _docBodyStyle),
            _u(wphone, placeholder: '　　　　　'),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(' 성 명 : ', style: _docBodyStyle),
            _u(worker),
            Text(' (서명) ', style: _docBodyStyle),
            _uSignature(wsign, placeholder: '　　　'),
          ],
        ),
      ],
    );
  }

  Widget _guardianReadHeading(String s) => Padding(
        padding: EdgeInsets.only(top: 6.h, bottom: 10.h),
        child: Text(
          s,
          style: _docBodyStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildGuardianReadBody(Map<String, dynamic> fv) {
    bool any = _fv(fv, 'guardian_name').isNotEmpty ||
        _fv(fv, 'minor_name').isNotEmpty ||
        _fv(fv, 'business_name').isNotEmpty;

    if (!any) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _t('친권자(후견인) 동의서'),
          SizedBox(height: 12.h),
          Text(
            '등록된 내용이 없습니다.',
            style: _docBodyStyle.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final consentName = _fv(fv, 'consent_minor_name');
    final signed = _formatKoreanDate(_fv(fv, 'consent_signed_date'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _guardianReadHeading('친권자(후견인) 인적사항'),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('성 명 : ', style: _docBodyStyle),
              _u(_fv(fv, 'guardian_name')),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('주민등록번호 : ', style: _docBodyStyle),
              _u(_fv(fv, 'guardian_resident_id_masked')),
            ],
          ),
        ),
        Text('주 소 : ', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(_fv(fv, 'guardian_address')),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('연락처 : ', style: _docBodyStyle),
              _u(_fv(fv, 'guardian_phone_number')),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('연소근로자와의 관계 : ', style: _docBodyStyle),
              _u(_fv(fv, 'relation_to_minor_worker')),
            ],
          ),
        ),
        _guardianReadHeading('연소근로자 인적사항'),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('성 명 : ', style: _docBodyStyle),
              _u(_fv(fv, 'minor_name')),
              Text(' (만 ', style: _docBodyStyle),
              _u(_fv(fv, 'minor_age')),
              Text(' 세)', style: _docBodyStyle),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('주민등록번호 : ', style: _docBodyStyle),
              _u(_fv(fv, 'minor_resident_id_masked')),
            ],
          ),
        ),
        Text('주 소 : ', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(_fv(fv, 'minor_address')),
        SizedBox(height: 8.h),
        _guardianReadHeading('사업장 개요'),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('회사명 : ', style: _docBodyStyle),
              _u(_fv(fv, 'business_name')),
            ],
          ),
        ),
        Text('회사주소 : ', style: _docBodyStyle),
        SizedBox(height: 4.h),
        _uBlock(_fv(fv, 'business_address')),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('대표 자 : ', style: _docBodyStyle),
              _u(_fv(fv, 'business_representative_name')),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('회사전화 : ', style: _docBodyStyle),
              _u(_fv(fv, 'business_phone_number')),
            ],
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text('본인은 위 연소근로자 ', style: _docBodyStyle),
            _u(consentName),
            Text(
              ' 가 위 사업장에서 근로를 하는 것에 대하여 동의합니다.',
              style: _docBodyStyle,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Center(child: Text(signed, style: _docBodyStyle)),
        SizedBox(height: 16.h),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text('친권자(후견인) ', style: _docBodyStyle),
            _uSignature(_fv(fv, 'guardian_signature_name')),
            Text(' (인)', style: _docBodyStyle),
          ],
        ),
        SizedBox(height: 12.h),
        Text('첨 부 : 가족관계증명서 1부', style: _docBodyStyle),
      ],
    );
  }
}
