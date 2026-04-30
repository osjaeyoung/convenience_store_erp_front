import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';

import '../../../data/models/worker/worker_recruitment_models.dart';
import '../../../data/repositories/worker_recruitment_repository.dart';
import '../../../utils/contract_work_day_form.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/contract_signature.dart';
import '../../auth/widgets/auth_input_field.dart';

enum _ContractChipTone { mint, worker }

class WorkerContractDocumentScreen extends StatefulWidget {
  const WorkerContractDocumentScreen({
    super.key,
    required this.contractId,
    this.roomTitle,
  });

  final int contractId;

  /// 채팅방(지점)명 — 있으면 앱바에 표시하고 본문 상단에 계약서 제목 구역을 둠 (Figma 계약채팅)
  final String? roomTitle;

  @override
  State<WorkerContractDocumentScreen> createState() =>
      _WorkerContractDocumentScreenState();
}

class _WorkerContractDocumentScreenState
    extends State<WorkerContractDocumentScreen> {
  static const Color _autoFillOrange = Color(0xFFFF8D28);
  static const String _autoFillMarker = '자동 기입';
  static const Color _mintChipBg = Color(0xFFE2F6F0);
  static const Color _workerChipBg = Color(0xFFFFF6ED);
  static const Color _workerChipFg = Color(0xFFFF8D28);

  static const Map<String, String> _defaultLabels = <String, String>{
    'worker_address': '근로자 주소',
    'worker_phone': '근로자 연락처',
    'worker_signature_text': '근로자 서명',
    'family_relation_certificate_submitted': '가족관계기록사항에 관한 증명서 제출 여부',
    'guardian_consent_submitted': '친권자 또는 후견인의 동의서 구비 여부',
    'minor_name': '연소근로자 성명',
    'minor_age': '만 나이',
    'minor_resident_id_masked': '연소근로자 주민등록번호(마스킹)',
    'minor_address': '연소근로자 주소',
    'consent_minor_name': '동의문 속 연소근로자명',
    'guardian_signature_name': '친권자(후견인) 서명',
    'consent_signed_date': '동의서 작성일',
  };

  static const Set<String> _multiLineKeys = <String>{
    'worker_address',
    'minor_address',
    'guardian_address',
    'business_address',
    'employer_address',
    'work_place',
    'job_description',
  };

  static const Set<String> _digitsOnlyKeys = <String>{
    'worker_phone',
    'minor_age',
    'guardian_phone_number',
    'business_phone_number',
    'employer_phone',
    'guardian_resident_id_masked',
    'minor_resident_id_masked',
  };

  static const Set<String> _dateKeys = <String>{
    'contract_signed_date',
    'consent_signed_date',
  };

  bool _loading = true;
  bool _submitting = false;
  bool _downloading = false;
  bool _changed = false;
  String? _error;
  WorkerContractChatDocument? _document;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await context
          .read<WorkerRecruitmentRepository>()
          .getContractChatDocument(contractId: widget.contractId);
      if (!mounted) return;
      _syncControllers(doc);
      setState(() {
        _document = doc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _syncControllers(WorkerContractChatDocument doc) {
    final fv = migrateLegacyWorkDayKeysInMap(
      Map<String, dynamic>.from(doc.formValues),
    );
    final keys = <String>{...doc.workerFieldKeys, ...doc.editableFieldKeys};
    for (final key in keys) {
      final current = _controllers[key];
      final nextValue = fv[key]?.toString() ?? '';
      if (current == null) {
        _controllers[key] = TextEditingController(text: nextValue);
      } else if (current.text != nextValue) {
        current.text = nextValue;
      }
    }
  }

  String _labelFor(String key, WorkerContractChatDocument doc) {
    return doc.requiredFieldLabels[key] ?? _defaultLabels[key] ?? key;
  }

  TextStyle get _contractBodyStyle => AppTypography.bodyMediumR.copyWith(
    color: AppColors.textPrimary,
    fontSize: 14.sp,
    height: 25 / 14,
  );

  TextStyle get _contractNoteStyle =>
      _contractBodyStyle.copyWith(color: AppColors.textSecondary);

  bool get _canUseInlineWorkerContractBody {
    final doc = _document;
    if (doc == null || doc.chatStatus == 'completed') return false;
    return doc.templateVersion == 'standard_v1' ||
        doc.templateVersion == 'minor_standard_v1';
  }

  bool get _canUseGuardianConsentBody {
    final doc = _document;
    if (doc == null || doc.chatStatus == 'completed') return false;
    return doc.templateVersion == 'guardian_consent_v1';
  }

  String _formValue(String key, WorkerContractChatDocument doc) {
    return doc.formValues[key]?.toString().trim() ?? '';
  }

  String _controllerOrFormValue(String key, WorkerContractChatDocument doc) {
    final controller = _controllers[key];
    if (controller != null) return controller.text.trim();
    return _formValue(key, doc);
  }

  String _formatKoreanDateFromIso(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return '';
    return '${dt.year}년 ${dt.month}월 ${dt.day}일';
  }

  String _formatNumber(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    final parsed = int.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return text;
    return NumberFormat('#,###', 'ko_KR').format(parsed);
  }

  bool _boolValue(String key, WorkerContractChatDocument doc) {
    final value = doc.formValues[key];
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  String _wageTypeLabel(WorkerContractChatDocument doc) {
    switch (_formValue('wage_type', doc)) {
      case 'hourly':
        return '시급';
      case 'daily':
        return '일급';
      default:
        return '월급';
    }
  }

  String _paymentMethodLabel(WorkerContractChatDocument doc) {
    switch (_formValue('payment_method', doc)) {
      case 'direct':
        return '직접 지급';
      case 'bank_transfer':
        return '예금통장에 입금';
      default:
        return '';
    }
  }

  String _periodChipDisplay(WorkerContractChatDocument doc) {
    final start = _formatKoreanDateFromIso(
      _formValue('contract_start_date', doc),
    );
    final end = _formatKoreanDateFromIso(_formValue('contract_end_date', doc));
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start부터 $end까지';
    return start.isNotEmpty ? start : end;
  }

  String _scheduledWorkTimeDisplay(WorkerContractChatDocument doc) {
    final start = _formValue('scheduled_work_start_time', doc);
    final end = _formValue('scheduled_work_end_time', doc);
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start~$end';
    return start.isNotEmpty ? start : end;
  }

  String _breakTimeDisplay(WorkerContractChatDocument doc) {
    final start = _formValue('break_start_time', doc);
    final end = _formValue('break_end_time', doc);
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start~$end';
    return start.isNotEmpty ? start : end;
  }

  ({String year, String month, String day}) _signingDateParts(
    WorkerContractChatDocument doc,
  ) {
    final dt = DateTime.tryParse(_formValue('contract_signed_date', doc));
    if (dt == null) {
      return (year: '', month: '', day: '');
    }
    return (year: '${dt.year}', month: '${dt.month}', day: '${dt.day}');
  }

  ({String year, String month, String day}) _datePartsFromKey(
    String key,
    WorkerContractChatDocument doc,
  ) {
    final dt = DateTime.tryParse(_controllerOrFormValue(key, doc));
    if (dt == null) {
      return (year: '', month: '', day: '');
    }
    return (year: '${dt.year}', month: '${dt.month}', day: '${dt.day}');
  }

  String _formatIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openDateInput(String key) async {
    final initial = DateTime.tryParse(_controllerOrFormValue(key, _document!));
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _controllers[key]?.text = _formatIsoDate(picked);
    });
  }

  Future<void> _openInlineInput(String label, String key) async {
    final initialRaw = _controllerOrFormValue(key, _document!);
    if (isContractSignatureDataUrl(initialRaw)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전자서명 데이터는 여기서 편집할 수 없습니다.')),
      );
      return;
    }

    final ctrl = TextEditingController(text: initialRaw);
    final isAddress = _multiLineKeys.contains(key);
    final isDigitsOnly = _digitsOnlyKeys.contains(key);

    final value = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final maxDialogH = MediaQuery.sizeOf(dialogContext).height * 0.85;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogH),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      style: AppTypography.heading3.copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 14.h),
                    AuthInputField(
                      controller: ctrl,
                      hintText: '입력해주세요.',
                      keyboardType: isDigitsOnly
                          ? TextInputType.number
                          : TextInputType.text,
                      inputFormatters: isDigitsOnly
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              if (key == 'worker_phone' ||
                                  key == 'guardian_phone_number' ||
                                  key == 'business_phone_number' ||
                                  key == 'employer_phone')
                                LengthLimitingTextInputFormatter(11),
                              if (key == 'minor_age')
                                LengthLimitingTextInputFormatter(2),
                            ]
                          : null,
                      minLines: isAddress ? 3 : 1,
                      maxLines: isAddress ? 4 : 1,
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
                            onPressed: () => Navigator.pop(dialogContext),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.grey25,
                              foregroundColor: AppColors.textTertiary,
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
                            onPressed: () =>
                                Navigator.pop(dialogContext, ctrl.text.trim()),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.grey0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
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
      },
    );

    // 다이얼로그 라우트가 완전히 내려간 뒤 dispose (used-after-dispose 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.dispose();
    });

    if (value == null || !mounted) return;
    setState(() {
      _controllers[key]?.text = value;
    });
  }

  Future<void> _openFieldEditor(String label, String key) async {
    if (_dateKeys.contains(key)) {
      await _openDateInput(key);
      return;
    }
    if (key == 'employer_signature_text') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사업주 서명은 근로자 단계에서 수정할 수 없습니다.')),
      );
      return;
    }
    if (key == 'worker_signature_text' || key == 'guardian_signature_name') {
      final val = await showContractSignatureDialog(context, label: label);
      if (val != null && mounted) {
        setState(() {
          _controllers[key]?.text = val;
        });
      }
      return;
    }
    await _openInlineInput(label, key);
  }

  Widget _contractChip({
    required String? display,
    required _ContractChipTone tone,
    VoidCallback? onTap,
    EdgeInsets? padding,
    bool signatureField = false,
  }) {
    final text = display?.trim() ?? '';
    final empty = text.isEmpty;
    final chipPadding =
        padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h);
    final (bg, fg, emptyLabel) = switch (tone) {
      _ContractChipTone.mint => (_mintChipBg, AppColors.primary, '입력'),
      _ContractChipTone.worker => (_workerChipBg, _workerChipFg, '근로자'),
    };
    final chipTextStyle = _contractBodyStyle.copyWith(
      color: fg,
      fontWeight: FontWeight.w500,
      fontSize: 12.sp,
      height: 18 / 12,
    );
    if (signatureField && !empty && isContractSignatureDataUrl(text)) {
      final signed = Padding(
        padding: chipPadding,
        child: contractSignatureImageWithUnderline(
          dataUrl: text,
          underlineColor: AppColors.textPrimary,
        ),
      );
      if (onTap == null) return signed;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.r),
          child: signed,
        ),
      );
    }
    final child = Container(
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
              textStyle: chipTextStyle,
            )
          : Text(empty ? emptyLabel : text, style: chipTextStyle),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: child,
      ),
    );
  }

  Widget _workerInputChip({
    required String key,
    required String label,
    required WorkerContractChatDocument doc,
    EdgeInsets? padding,
  }) {
    final rawDisplay = _controllerOrFormValue(key, doc);
    final display = _dateKeys.contains(key)
        ? (() {
            final dt = DateTime.tryParse(rawDisplay);
            if (dt == null) return rawDisplay;
            return '${dt.year}.${dt.month}.${dt.day}';
          })()
        : rawDisplay;
    final editable = doc.canEditField(key) && doc.chatStatus != 'completed';
    if (!editable) {
      final raw = display.trim();
      if (raw.isNotEmpty && isContractSignatureDataUrl(raw)) {
        return contractSignatureImageWithUnderline(
          dataUrl: raw,
          underlineColor: AppColors.textPrimary,
          maxHeight: 32.h,
          maxWidth: 150.w,
        );
      }
      final text = raw.isNotEmpty ? raw : '______';
      return Text(
        text,
        style: _contractBodyStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textPrimary,
        ),
      );
    }
    return _contractChip(
      display: display,
      tone: _ContractChipTone.worker,
      onTap: editable ? () => _openFieldEditor(label, key) : null,
      padding: padding,
      signatureField:
          key == 'worker_signature_text' || key == 'guardian_signature_name',
    );
  }

  Widget _readonlyMintChip(
    String? display, {
    EdgeInsets? padding,
    bool signature = false,
  }) {
    final raw = display?.trim() ?? '';
    final empty = raw.isEmpty;
    if (signature && !empty && isContractSignatureDataUrl(raw)) {
      final signed = contractSignatureImageWithUnderline(
        dataUrl: raw,
        underlineColor: AppColors.textPrimary,
        maxHeight: 32.h,
        maxWidth: 150.w,
      );
      if (padding != null) {
        return Padding(padding: padding, child: signed);
      }
      return signed;
    }
    final text = empty ? '______' : raw;
    final textWidget = Text(
      text,
      style: _contractBodyStyle.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textPrimary,
      ),
    );
    if (padding != null) {
      return Padding(padding: padding, child: textWidget);
    }
    return textWidget;
  }

  Widget _readonlyWorkerChip(String? display) {
    final text = (display?.trim().isNotEmpty ?? false)
        ? display!.trim()
        : '______';
    return Text(
      text,
      style: _contractBodyStyle.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textPrimary,
      ),
    );
  }

  Widget _contractNumbered(int index, Widget body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22.w,
            child: Text('$index.', style: _contractBodyStyle),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _readonlyChoiceCircle(bool selected) {
    return Container(
      width: 18.r,
      height: 18.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.grey100,
          width: selected ? 2 : 1.2,
        ),
        color: selected ? AppColors.primary : AppColors.grey0,
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check_rounded, size: 11, color: AppColors.grey0)
          : null,
    );
  }

  String _documentFormTitle(WorkerContractChatDocument doc) {
    switch (doc.templateVersion) {
      case 'standard_v1':
        return '표준 근로 계약서';
      case 'minor_standard_v1':
        return '연소근로자(18세 미만) 표준 근로계약서';
      case 'guardian_consent_v1':
        return '친권자(후견인) 동의서';
      default:
        return doc.title;
    }
  }

  Widget _buildInlineWorkerContractBody(
    WorkerContractChatDocument doc, {
    bool showDocumentTitle = true,
    bool showCompletionNotice = true,
    double? bottomPadding,
  }) {
    final isMinor = doc.templateVersion == 'minor_standard_v1';
    final wageAmount = _formatNumber(doc.formValues['wage_amount']);
    final bonusAmount = _formatNumber(doc.formValues['bonus_amount']);
    final otherAllowanceAmount = _formatNumber(
      doc.formValues['other_allowance_amount'],
    );
    final mealAllowance = _formatNumber(doc.formValues['meal_allowance']);
    final transportAllowance = _formatNumber(
      doc.formValues['transport_allowance'],
    );
    final extraAllowanceAmount = _formatNumber(
      doc.formValues['extra_allowance_amount'],
    );
    final paymentDay = _formatNumber(doc.formValues['payment_day']);
    final periodText = _periodChipDisplay(doc);
    final signedParts = _signingDateParts(doc);
    final workDaysPerWeek = _formValue('work_days_per_week', doc);
    final weeklyHolidayDay = _formValue('weekly_holiday_day', doc);
    final scheduledWorkTime = _scheduledWorkTimeDisplay(doc);
    final breakTime = _breakTimeDisplay(doc);
    final bonusIncluded = _boolValue('bonus_included', doc);
    final otherAllowanceIncluded = _boolValue('other_allowance_included', doc);

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding ?? 120.h),
      children: [
        if (showDocumentTitle) ...[
          Text(
            _documentFormTitle(doc),
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
              height: 24 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 10,
          children: [
            _readonlyMintChip(_formValue('employer_name', doc)),
            Text('(이하 "사업주"라 함)과(와) ', style: _contractBodyStyle),
            _readonlyWorkerChip(_formValue('worker_name', doc)),
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
                  _readonlyMintChip(periodText),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                '※ 근로계약기간을 정하지 않는 경우에는 "근로개시일"만 기재',
                style: AppTypography.bodySmallR.copyWith(
                  color: AppColors.textSecondary,
                ),
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
              _readonlyMintChip(
                _formValue('work_place', doc),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
              _readonlyMintChip(
                _formValue('job_description', doc),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              ),
            ],
          ),
        ),
        _contractNumbered(
          4,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: [
              Text('소정근로시간 : ', style: _contractBodyStyle),
              _readonlyMintChip(
                scheduledWorkTime,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              ),
              if (breakTime.isNotEmpty) ...[
                Text(' (휴게시간: ', style: _contractBodyStyle),
                Text(breakTime, style: _contractBodyStyle),
                Text(')', style: _contractBodyStyle),
              ],
            ],
          ),
        ),
        _contractNumbered(
          5,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: [
              Text('근무일/휴일 : 매주 ', style: _contractBodyStyle),
              if (workDaysPerWeek.isEmpty)
                Text(
                  '소정 근로 시간 입력시 자동 기입',
                  style: _contractBodyStyle.copyWith(color: _autoFillOrange),
                )
              else
                _readonlyMintChip(workDaysPerWeek),
              Text('일(또는 매일단위)근무, 주휴일 매주 ', style: _contractBodyStyle),
              if (weeklyHolidayDay.isEmpty)
                Text(
                  '자동 기입',
                  style: _contractBodyStyle.copyWith(color: _autoFillOrange),
                )
              else
                _readonlyMintChip(weeklyHolidayDay),
              Text('요일', style: _contractBodyStyle),
            ],
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
                        _readonlyMintChip(
                          wageAmount.isEmpty
                              ? ''
                              : '${_wageTypeLabel(doc)} $wageAmount',
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
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
                        _readonlyChoiceCircle(bonusIncluded),
                        Text(')', style: _contractBodyStyle),
                        if (bonusIncluded) ...[
                          _readonlyMintChip(bonusAmount),
                          Text('원', style: _contractBodyStyle),
                        ],
                        Text(', 없음(', style: _contractBodyStyle),
                        _readonlyChoiceCircle(!bonusIncluded),
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
                        _readonlyChoiceCircle(otherAllowanceIncluded),
                        Text(')', style: _contractBodyStyle),
                        if (otherAllowanceIncluded) ...[
                          _readonlyMintChip(otherAllowanceAmount),
                          Text('원', style: _contractBodyStyle),
                        ],
                        Text(', 없음(', style: _contractBodyStyle),
                        _readonlyChoiceCircle(!otherAllowanceIncluded),
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
                              _readonlyMintChip(mealAllowance),
                              Text('원', style: _contractBodyStyle),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('· 교통비 ', style: _contractBodyStyle),
                              _readonlyMintChip(transportAllowance),
                              Text('원', style: _contractBodyStyle),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('· 기타(', style: _contractBodyStyle),
                              _readonlyMintChip(
                                _formValue('extra_allowance_name', doc),
                              ),
                              Text(') ', style: _contractBodyStyle),
                              _readonlyMintChip(extraAllowanceAmount),
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
                        _readonlyMintChip(paymentDay),
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
                        _readonlyChoiceCircle(
                          _paymentMethodLabel(doc) == '직접 지급',
                        ),
                        Text('), 근로자 명의 예금통장에 입금(', style: _contractBodyStyle),
                        _readonlyChoiceCircle(
                          _paymentMethodLabel(doc) == '예금통장에 입금',
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
        if (isMinor) ...[
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
                    _readonlyMintChip(
                      _formValue('family_relation_certificate_submitted', doc),
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
                    _readonlyMintChip(
                      _formValue('guardian_consent_submitted', doc),
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
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _readonlyMintChip(signedParts.year),
              Text('년 ', style: _contractBodyStyle),
              _readonlyMintChip(signedParts.month),
              Text('월 ', style: _contractBodyStyle),
              _readonlyMintChip(signedParts.day),
              Text('일', style: _contractBodyStyle),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('(사업주) 사업체명 : ', style: _contractBodyStyle),
            _readonlyMintChip(_formValue('employer_business_name', doc)),
            Text('(전화 : ', style: _contractBodyStyle),
            _readonlyMintChip(_formValue('employer_phone', doc)),
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
            _readonlyMintChip(
              _formValue('employer_address', doc),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
            _readonlyMintChip(_formValue('employer_representative_name', doc)),
            Text('(서명)', style: _contractBodyStyle),
            _readonlyMintChip(
              _formValue('employer_signature_text', doc),
              signature: true,
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
            _workerInputChip(
              key: 'worker_address',
              label: '근로자 주소',
              doc: doc,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
            _workerInputChip(key: 'worker_phone', label: '근로자 연락처', doc: doc),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('성명 : ', style: _contractBodyStyle),
            _readonlyWorkerChip(_formValue('worker_name', doc)),
            Text('(서명)', style: _contractBodyStyle),
            _workerInputChip(
              key: 'worker_signature_text',
              label: '근로자 서명',
              doc: doc,
            ),
          ],
        ),
        if (doc.chatStatus == 'completed' && showCompletionNotice) ...[
          SizedBox(height: 16.h),
          Text(
            '작성이 완료된 문서입니다.',
            style: AppTypography.bodySmallR.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _guardianDocHeading(String text) => Padding(
    padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
    child: Text(
      text,
      style: _contractBodyStyle.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _guardianLabeledValueRow(
    String prefix,
    String key,
    WorkerContractChatDocument doc, {
    String? label,
    bool wide = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          Text(prefix, style: _contractBodyStyle),
          _workerInputChip(
            key: key,
            label: label ?? _labelFor(key, doc),
            doc: doc,
            padding: wide
                ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianConsentBody(
    WorkerContractChatDocument doc, {
    bool showDocumentTitle = true,
    bool showCompletionNotice = true,
    double? bottomPadding,
  }) {
    final signedParts = _datePartsFromKey('consent_signed_date', doc);

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding ?? 120.h),
      children: [
        if (showDocumentTitle) ...[
          Text(
            _documentFormTitle(doc),
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
              height: 24 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        _guardianDocHeading('친권자(후견인) 인적사항'),
        _guardianLabeledValueRow(
          '성 명 : ',
          'guardian_name',
          doc,
          label: '친권자(후견인) 성명',
        ),
        _guardianLabeledValueRow(
          '주민등록번호 : ',
          'guardian_resident_id_masked',
          doc,
          label: '주민등록번호(마스킹)',
        ),
        _guardianLabeledValueRow(
          '주 소 : ',
          'guardian_address',
          doc,
          label: '주소',
          wide: true,
        ),
        _guardianLabeledValueRow(
          '연락처 : ',
          'guardian_phone_number',
          doc,
          label: '연락처',
        ),
        _guardianLabeledValueRow(
          '연소근로자와의 관계 : ',
          'relation_to_minor_worker',
          doc,
          label: '연소근로자와의 관계',
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
              _workerInputChip(key: 'minor_name', label: '연소근로자 성명', doc: doc),
              Text(' (만 ', style: _contractBodyStyle),
              _workerInputChip(key: 'minor_age', label: '만 나이', doc: doc),
              Text(' 세)', style: _contractBodyStyle),
            ],
          ),
        ),
        _guardianLabeledValueRow(
          '주민등록번호 : ',
          'minor_resident_id_masked',
          doc,
          label: '연소근로자 주민등록번호(마스킹)',
        ),
        _guardianLabeledValueRow(
          '주 소 : ',
          'minor_address',
          doc,
          label: '연소근로자 주소',
          wide: true,
        ),
        SizedBox(height: 8.h),
        _guardianDocHeading('사업장 개요'),
        _guardianLabeledValueRow('회사명 : ', 'business_name', doc, label: '회사명'),
        _guardianLabeledValueRow(
          '회사주소 : ',
          'business_address',
          doc,
          label: '회사주소',
          wide: true,
        ),
        _guardianLabeledValueRow(
          '대표 자 : ',
          'business_representative_name',
          doc,
          label: '대표자',
        ),
        _guardianLabeledValueRow(
          '회사전화 : ',
          'business_phone_number',
          doc,
          label: '회사전화',
        ),
        SizedBox(height: 16.h),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: [
            Text('본인은 위 연소근로자 ', style: _contractBodyStyle),
            _workerInputChip(
              key: 'consent_minor_name',
              label: '동의문 속 연소근로자명',
              doc: doc,
            ),
            Text(' 가 위 사업장에서 근로를 하는 것에 대하여 동의합니다.', style: _contractBodyStyle),
          ],
        ),
        SizedBox(height: 20.h),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _workerInputChip(
                key: 'consent_signed_date',
                label: '동의서 작성일',
                doc: doc,
              ),
              if (signedParts.year.isNotEmpty ||
                  signedParts.month.isNotEmpty ||
                  signedParts.day.isNotEmpty)
                Text(
                  '(${signedParts.year}.${signedParts.month}.${signedParts.day})',
                  style: _contractNoteStyle,
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: [
            Text('친권자(후견인) ', style: _contractBodyStyle),
            _workerInputChip(
              key: 'guardian_signature_name',
              label: '친권자(후견인) 서명',
              doc: doc,
            ),
            Text(' (인)', style: _contractBodyStyle),
          ],
        ),
        SizedBox(height: 16.h),
        Text('첨 부 : 가족관계증명서 1부', style: _contractBodyStyle),
        if (doc.chatStatus == 'completed' && showCompletionNotice) ...[
          SizedBox(height: 16.h),
          Text(
            '작성이 완료된 문서입니다.',
            style: AppTypography.bodySmallR.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// `____` 구간은 검은 밑줄, `자동 기입`은 주황 글자+밑줄 (Figma 표준 근로 계약서)
  static List<TextSpan> _previewSpans(String text, TextStyle base) {
    final orangeStyle = base.copyWith(
      color: _autoFillOrange,
      decoration: TextDecoration.underline,
      decorationColor: _autoFillOrange,
    );
    TextStyle underlinedUnderscore(TextStyle s) => s.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.textPrimary,
    );

    List<TextSpan> underlineUnderscores(String chunk) {
      final reg = RegExp(r'_+');
      final out = <TextSpan>[];
      var i = 0;
      for (final m in reg.allMatches(chunk)) {
        if (m.start > i) {
          out.add(TextSpan(text: chunk.substring(i, m.start), style: base));
        }
        out.add(
          TextSpan(
            text: chunk.substring(m.start, m.end),
            style: underlinedUnderscore(base),
          ),
        );
        i = m.end;
      }
      if (i < chunk.length) {
        out.add(TextSpan(text: chunk.substring(i), style: base));
      }
      return out;
    }

    final result = <TextSpan>[];
    var rest = text;
    while (true) {
      final idx = rest.indexOf(_autoFillMarker);
      if (idx < 0) {
        result.addAll(underlineUnderscores(rest));
        break;
      }
      if (idx > 0) {
        result.addAll(underlineUnderscores(rest.substring(0, idx)));
      }
      result.add(TextSpan(text: _autoFillMarker, style: orangeStyle));
      rest = rest.substring(idx + _autoFillMarker.length);
    }
    return result;
  }

  String _prettyAction(String? action) {
    switch (action) {
      case 'complete':
        return '전송';
      case 'send_to_worker':
        return '전송';
      case 'save_draft':
        return '저장';
      default:
        return '전송';
    }
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is Map) {
          final msg = detail['message']?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
        final msg = data['message']?.toString() ?? data['detail']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return error.message ?? '요청에 실패했습니다.';
    }
    return userFriendlyErrorMessage(error);
  }

  Future<void> _submit() async {
    final doc = _document;
    if (doc == null) return;
    final action = doc.primaryAction ?? 'complete';
    final formValues = migrateLegacyWorkDayKeysInMap(
      Map<String, dynamic>.from(doc.formValues),
    );

    for (final entry in _controllers.entries) {
      formValues[entry.key] = entry.value.text.trim();
    }

    setState(() => _submitting = true);
    try {
      final next = await context
          .read<WorkerRecruitmentRepository>()
          .patchContractChatDocument(
            contractId: widget.contractId,
            action: action,
            formValues: formValues,
            mergeFormValues: true,
          );
      if (!mounted) return;
      _syncControllers(next);
      _changed = true;
      setState(() {
        _document = next;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.primaryAction == 'complete' ? '작성이 완료되었습니다.' : '저장되었습니다.',
          ),
        ),
      );
      if (next.chatStatus == 'completed') {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final result = await context
          .read<WorkerRecruitmentRepository>()
          .downloadContractChatDocument(contractId: widget.contractId);
      if (!mounted) return;
      final contentType = result.contentType?.toLowerCase() ?? '';
      final isText = contentType.contains('text');
      final fileName =
          result.fileName ??
          (isText
              ? 'contract_${widget.contractId}.txt'
              : 'contract_${widget.contractId}.pdf');
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '근로계약서 저장',
        fileName: fileName,
        bytes: result.bytes,
        type: FileType.custom,
        allowedExtensions: isText ? const ['txt'] : const ['pdf'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savedPath == null ? '저장이 취소되었습니다.' : '근로계약서가 저장되었습니다.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드에 실패했습니다: ${_messageFromError(error)}')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    final isCompleted = doc?.chatStatus == 'completed';
    final canSubmit =
        doc != null &&
        doc.primaryAction != null &&
        doc.chatStatus != 'completed' &&
        doc.editableFieldKeys.isNotEmpty;

    return Scaffold(
      backgroundColor: isCompleted ? AppColors.grey0 : AppColors.grey0Alt,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_changed),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          _appBarTitle(doc),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyLargeM.copyWith(
            fontSize: 18.sp,
            height: 24 / 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : _buildContent(doc!),
      bottomNavigationBar: doc == null
          ? null
          : Container(
              color: AppColors.grey0,
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  20.w,
                  16.h,
                  20.w,
                  doc.chatStatus == 'completed' ? 36.h : 16.h,
                ),
                child: SizedBox(
                  height: 56.h,
                  child: doc.chatStatus == 'completed'
                      ? OutlinedButton(
                          onPressed: _downloading ? null : _download,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            foregroundColor: AppColors.primary,
                          ),
                          child: _downloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '다운로드',
                                  style: AppTypography.bodyLargeB.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                        )
                      : FilledButton(
                          onPressed: (canSubmit && !_submitting)
                              ? _submit
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.grey100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.grey0,
                                  ),
                                )
                              : Text(
                                  doc.primaryActionLabel ??
                                      _prettyAction(doc.primaryAction),
                                  style: AppTypography.bodyLargeB.copyWith(
                                    color: AppColors.grey0,
                                  ),
                                ),
                        ),
                ),
              ),
            ),
    );
  }

  String _appBarTitle(WorkerContractChatDocument? doc) {
    if (doc?.chatStatus == 'completed') {
      return doc?.title ?? '표준 근로 계약서';
    }
    final room = widget.roomTitle?.trim();
    if (room != null && room.isNotEmpty) return room;
    return doc?.title ?? '표준 근로 계약서';
  }

  Widget _buildCompletedDocumentContent(WorkerContractChatDocument doc) {
    if (doc.templateVersion == 'standard_v1' ||
        doc.templateVersion == 'minor_standard_v1') {
      return _buildInlineWorkerContractBody(
        doc,
        showDocumentTitle: false,
        showCompletionNotice: false,
        bottomPadding: 12.h,
      );
    }

    if (doc.templateVersion == 'guardian_consent_v1') {
      return _buildGuardianConsentBody(
        doc,
        showDocumentTitle: false,
        showCompletionNotice: false,
        bottomPadding: 12.h,
      );
    }

    final previewRaw = (doc.documentPreviewText ?? '').trim();
    final previewStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.textPrimary,
      fontSize: 14.sp,
      height: 19 / 14,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
      child: Text.rich(
        TextSpan(
          style: previewStyle,
          children: previewRaw.isEmpty
              ? [TextSpan(text: '문서 미리보기를 불러오는 중입니다.', style: previewStyle)]
              : _previewSpans(previewRaw, previewStyle),
        ),
      ),
    );
  }

  Widget _buildContent(WorkerContractChatDocument doc) {
    if (doc.chatStatus == 'completed') {
      return _buildCompletedDocumentContent(doc);
    }

    final editableKeys = doc.editableFieldKeys;
    final showRoomHeader =
        widget.roomTitle != null && widget.roomTitle!.trim().isNotEmpty;
    final previewRaw = (doc.documentPreviewText ?? '').trim();
    final previewStyle = AppTypography.bodyMediumR.copyWith(
      color: AppColors.textPrimary,
      height: 25 / 14,
    );

    if (_canUseInlineWorkerContractBody) {
      return _buildInlineWorkerContractBody(doc);
    }

    if (_canUseGuardianConsentBody) {
      return _buildGuardianConsentBody(doc);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showRoomHeader)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              decoration: const BoxDecoration(
                color: AppColors.grey0,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Text(
                doc.title,
                style: AppTypography.bodyLargeM.copyWith(
                  fontSize: 18.sp,
                  height: 24 / 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showRoomHeader) ...[
                  Text(
                    doc.title,
                    style: AppTypography.bodyLargeM.copyWith(
                      fontSize: 18.sp,
                      height: 24 / 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                Text.rich(
                  TextSpan(
                    style: previewStyle,
                    children: previewRaw.isEmpty
                        ? [
                            TextSpan(
                              text: '문서 미리보기를 불러오는 중입니다.',
                              style: previewStyle,
                            ),
                          ]
                        : _previewSpans(previewRaw, previewStyle),
                  ),
                ),
                if (editableKeys.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  Text(
                    '입력 항목',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...editableKeys.map((key) {
                    final required = doc.requiredFieldKeys.contains(key);
                    final controller =
                        _controllers[key] ?? TextEditingController();
                    _controllers[key] = controller;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            required
                                ? '${_labelFor(key, doc)} *'
                                : _labelFor(key, doc),
                            style: AppTypography.bodySmallM.copyWith(
                              color: required
                                  ? const Color(0xFFFF8D28)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: controller,
                            minLines: key == 'worker_address' ? 2 : 1,
                            maxLines: key == 'worker_address' ? 3 : 1,
                            decoration: InputDecoration(
                              hintText: _labelFor(key, doc),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.grey0,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (doc.chatStatus == 'completed') ...[
                  SizedBox(height: 10.h),
                  Text(
                    '작성이 완료된 문서입니다.',
                    style: AppTypography.bodySmallR.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
