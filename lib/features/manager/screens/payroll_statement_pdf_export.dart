import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../payroll/payroll_formatters.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _deductionLabels = <String, String>{
  'national_pension': '국민연금',
  'health_insurance': '건강보험',
  'employment_insurance': '고용보험',
  'long_term_care_insurance': '장기요양보험',
  'income_tax': '소득세',
  'local_income_tax': '지방소득세',
};

int? _rowInt(Map<String, dynamic> row, String key) {
  final v = row[key];
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

String _payrollDetailsPlainText({
  required Map<String, dynamic> row,
  required String employeeName,
}) {
  final resident = row['resident_id_masked']?.toString() ?? '-';
  final minutes = _rowInt(row, 'total_work_minutes');
  final hourly = _rowInt(row, 'hourly_wage');
  final base = _rowInt(row, 'base_pay');
  final weeklyAllow = _rowInt(row, 'weekly_allowance');

  final deductions = <MapEntry<String, int>>[];
  for (final e in _deductionLabels.entries) {
    final amt = _rowInt(row, e.key) ?? 0;
    if (amt > 0) deductions.add(MapEntry(e.value, amt));
  }
  final totalDed = _rowInt(row, 'total_deduction') ?? 0;
  final hasDeductions = deductions.isNotEmpty || totalDed > 0;
  final netPay = _rowInt(row, 'net_pay') ?? 0;

  final b = StringBuffer();
  b.writeln('성명: $employeeName');
  b.writeln('주민번호: $resident');
  b.writeln('총 근무시간: ${PayrollFormatters.hoursFromMinutes(minutes)}');
  b.writeln('시급: ${PayrollFormatters.krwInt(hourly)}');
  b.writeln('기본급: ${PayrollFormatters.krwInt(base)}');
  b.writeln('주휴수당: ${PayrollFormatters.krwInt(weeklyAllow)}');
  b.writeln();
  b.writeln('[공제항목]');
  if (!hasDeductions) {
    b.writeln('공제항목이 없습니다.');
  } else {
    for (final d in deductions) {
      b.writeln('${d.key}: ${PayrollFormatters.krwInt(d.value)}');
    }
    if (totalDed > 0) {
      b.writeln('공제 합계: ${PayrollFormatters.krwInt(totalDed)}');
    }
  }
  if (netPay > 0) {
    b.writeln();
    b.writeln('실지급액: ${PayrollFormatters.krwInt(netPay)}');
  }
  return b.toString();
}

List<pw.Widget> _linesToPdfWidgets(
  String body,
  pw.Font font, {
  double fontSize = 10,
  double lineSpacing = 3,
}) {
  final style = pw.TextStyle(
    font: font,
    fontSize: fontSize,
    lineSpacing: lineSpacing,
  );
  final widgets = <pw.Widget>[];
  for (final line in body.split('\n')) {
    if (line.isEmpty) {
      widgets.add(pw.SizedBox(height: fontSize * 0.35));
    } else {
      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 1),
          child: pw.Text(line, style: style),
        ),
      );
    }
  }
  return widgets;
}

/// 급여명세 상세와 동일한 내용을 A4 PDF로 저장합니다.
Future<Uint8List> buildPayrollStatementPdfBytes({
  required Map<String, dynamic> row,
  required String employeeName,
}) async {
  final font = await PdfGoogleFonts.notoSansKRRegular();
  final fontMedium = await PdfGoogleFonts.notoSansKRMedium();
  final body = _payrollDetailsPlainText(row: row, employeeName: employeeName);
  final y = (row['year'] as num?)?.toInt() ?? 0;
  final m = (row['month'] as num?)?.toInt() ?? 0;
  final title = '$y.$m월 급여 명세';

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(font: fontMedium, fontSize: 14.sp),
        ),
        pw.SizedBox(height: 14),
        ..._linesToPdfWidgets(body, font),
      ],
    ),
  );
  return pdf.save();
}
