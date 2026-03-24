/// 근로계약서 조회·PDF보내기용 평문 (화면과 동일한 내용)
library employment_contract_read_plain_text;

String _fv(Map<String, dynamic> fv, String key) =>
    fv[key]?.toString().trim() ?? '';

String _formatKoreanDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '____년 ____월 ____일';
  return '${d.year}년 ${d.month}월 ${d.day}일';
}

String _wageTypeKo(String? t) => switch (t) {
      'hourly' => '시급',
      'daily' => '일급',
      _ => '월급',
    };

String _paymentMethodLine(Map<String, dynamic> fv) {
  final t = _fv(fv, 'payment_method');
  if (t.isEmpty) {
    return '지급방법 : 근로자에게 직접지급(   ), 근로자 명의 예금통장에 입금(   )';
  }
  final d = t == 'direct' ? '✓' : ' ';
  final b = t == 'bank_transfer' ? '✓' : ' ';
  return '지급방법 : 근로자에게 직접지급($d), 근로자 명의 예금통장에 입금($b)';
}

String _workPlaceLine(String s) =>
    s.isEmpty ? '____________________________________________' : s;

/// 표준·연소 근로계약서 본문 (PDF/공유용)
String buildStandardEmploymentContractPlainText(
  Map<String, dynamic> fv, {
  required bool isMinor,
}) {
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
  final wageLine =
      wageAmt.isEmpty ? '_______ 원' : '$wageLabel $wageAmt 원';
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

  final buf = StringBuffer();
  buf.writeln(
    '${employer.isEmpty ? '_______' : employer}(이하 "사업주"라 함)과(와) '
    '${worker.isEmpty ? '_______' : worker}(이하 "근로자"라 함)은',
  );
  buf.writeln('다음과 같이 근로계약을 체결한다.');
  buf.writeln();
  buf.writeln(
    '1. 근로계약기간 : $periodStart부터 $periodEnd까지',
  );
  buf.writeln('※ 근로계약기간을 정하지 않는 경우에는 "근로개시일"만 기재');
  buf.writeln();
  buf.writeln('2. 근 무 장 소 : ${_workPlaceLine(_fv(fv, 'work_place'))}');
  buf.writeln();
  buf.writeln('3. 업 무 내 용 : ${_workPlaceLine(_fv(fv, 'job_description'))}');
  buf.writeln();
  buf.writeln(
    '4. 소정근로시간 : ${sws.isEmpty ? '____' : sws}부터 ${swe.isEmpty ? '____' : swe}까지',
  );
  if (bs.isNotEmpty || be.isNotEmpty) {
    buf.writeln(
      '(휴게시간: ${bs.isEmpty ? '____' : bs} ~ ${be.isEmpty ? '____' : be})',
    );
  }
  buf.writeln();
  buf.writeln(
    '5. 근무일/휴일 : 매주 ${wd.isEmpty ? '____' : wd}일(또는 매일단위)근무, 주휴일 매주 ${wh.isEmpty ? '____' : wh}요일',
  );
  buf.writeln();
  buf.writeln('6. 임 금');
  buf.writeln(' · 월(일, 시간)급 : $wageLine');
  buf.writeln(
    ' · 상여금 : 있음(${bonusOn ? '✓' : ' '}) '
    '${bonusOn && bonusAmt.isNotEmpty ? '$bonusAmt원' : '_______원'}, 없음(${!bonusOn ? '✓' : ' '})',
  );
  buf.writeln(
    ' · 기타급여(제수당 등) : 있음(${otherOn ? '✓' : ' '}) '
    '${otherOn && otherAmt.isNotEmpty ? '$otherAmt원' : '_______원'}, 없음(${!otherOn ? '✓' : ' '})',
  );
  buf.writeln(' · 식대(비과세) ${meal.isEmpty ? '_______' : meal}원');
  buf.writeln(' · 교통비 ${transport.isEmpty ? '_______' : transport}원');
  buf.writeln(
    ' · 기타(${extraName.isEmpty ? ' ' : extraName}) ${extraAmt.isEmpty ? '_______' : extraAmt}원',
  );
  buf.writeln(
    ' · 임금지급일 : 매월(매주 또는 매일) ${payDay.isEmpty ? '____' : payDay}일 (휴일의 경우는 전일 지급)',
  );
  buf.writeln(' · $payMethodLine');
  buf.writeln();
  buf.writeln('7. 연차유급휴가');
  buf.writeln(' · 연차유급휴가는 근로기준법에서 정하는 바에 따라 부여함');
  buf.writeln();
  if (isMinor) {
    buf.writeln('8. 가족관계증명서 및 동의서');
    buf.writeln(
      ' · 가족관계기록사항에 관한 증명서 제출 여부 : '
      '${_fv(fv, 'family_relation_certificate_submitted').isEmpty ? '____' : _fv(fv, 'family_relation_certificate_submitted')}',
    );
    buf.writeln(
      ' · 친권자 또는 후견인의 동의서 구비 여부 : '
      '${_fv(fv, 'guardian_consent_submitted').isEmpty ? '____' : _fv(fv, 'guardian_consent_submitted')}',
    );
    buf.writeln();
    buf.writeln('9. 근로계약서 교부');
    buf.writeln(
      ' · 사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조, 제67조 이행)',
    );
    buf.writeln();
    buf.writeln('10. 기 타');
    buf.writeln(
      ' · 13세 이상 15세 미만인 자에 대해서는 고용노동부장관으로부터 취직인허증을 교부받아야 하며, 이 계약에 정함이 없는 사항은 근로기준법령에 의함',
    );
  } else {
    buf.writeln('8. 근로계약서 교부');
    buf.writeln(
      ' · 사업주는 근로계약을 체결함과 동시에 본 계약서를 사본하여 근로자의 교부요구와 관계없이 근로자에게 교부함(근로기준법 제17조 이행)',
    );
    buf.writeln();
    buf.writeln('9. 기 타');
    buf.writeln(' · 이 계약에 정함이 없는 사항은 근로기준법령에 의함');
  }
  buf.writeln();
  buf.writeln(signed);
  buf.writeln();
  buf.writeln(
    '(사업주) 사업체명 : ${biz.isEmpty ? '_________________________' : biz} (전화 : ${phone.isEmpty ? '___________' : phone})',
  );
  buf.writeln(
    ' 주 소 : ${addr.isEmpty ? '____________________________________' : addr}',
  );
  buf.writeln(
    ' 대표자 : ${rep.isEmpty ? '__________' : rep} (서명) ${esign.isNotEmpty ? esign : ''}',
  );
  buf.writeln();
  buf.writeln(
    '(근로자) 주 소 : ${waddr.isEmpty ? '____________________________________' : waddr}',
  );
  buf.writeln(' 연락처 : ${wphone.isEmpty ? '__________' : wphone}');
  buf.writeln(
    ' 성 명 : ${worker.isEmpty ? '__________' : worker} (서명) ${wsign.isNotEmpty ? wsign : ''}',
  );
  return buf.toString();
}

String buildGuardianConsentPlainText(Map<String, dynamic> fv) {
  final g = _fv(fv, 'guardian_name');
  final m = _fv(fv, 'minor_name');
  final b = _fv(fv, 'business_name');
  if (g.isEmpty && m.isEmpty && b.isEmpty) {
    return '친권자(후견인) 동의서\n\n등록된 내용이 없습니다.\n';
  }

  final buf = StringBuffer();
  buf.writeln('친권자(후견인) 동의서');
  buf.writeln();
  buf.writeln('친권자(후견인) 인적사항');
  buf.writeln('성 명 : ${_fv(fv, 'guardian_name')}');
  buf.writeln('주민등록번호 : ${_fv(fv, 'guardian_resident_id_masked')}');
  buf.writeln('주 소 : ${_fv(fv, 'guardian_address')}');
  buf.writeln('연락처 : ${_fv(fv, 'guardian_phone_number')}');
  buf.writeln('연소근로자와의 관계 : ${_fv(fv, 'relation_to_minor_worker')}');
  buf.writeln();
  buf.writeln('연소근로자 인적사항');
  buf.writeln(
    '성 명 : ${_fv(fv, 'minor_name')} (만 ${_fv(fv, 'minor_age')} 세)',
  );
  buf.writeln('주민등록번호 : ${_fv(fv, 'minor_resident_id_masked')}');
  buf.writeln('주 소 : ${_fv(fv, 'minor_address')}');
  buf.writeln();
  buf.writeln('사업장 개요');
  buf.writeln('회사명 : ${_fv(fv, 'business_name')}');
  buf.writeln('회사주소 : ${_fv(fv, 'business_address')}');
  buf.writeln('대표 자 : ${_fv(fv, 'business_representative_name')}');
  buf.writeln('회사전화 : ${_fv(fv, 'business_phone_number')}');
  buf.writeln();
  buf.writeln(
    '본인은 위 연소근로자 ${_fv(fv, 'consent_minor_name')} 가 위 사업장에서 근로를 하는 것에 대하여 동의합니다.',
  );
  buf.writeln();
  buf.writeln(_formatKoreanDate(_fv(fv, 'consent_signed_date')));
  buf.writeln();
  buf.writeln(
    '친권자(후견인) ${_fv(fv, 'guardian_signature_name')} (인)',
  );
  buf.writeln();
  buf.writeln(
    '첨 부 : 가족관계증명서 1부 ${_fv(fv, 'family_relation_certificate_attached')}',
  );
  return buf.toString();
}
