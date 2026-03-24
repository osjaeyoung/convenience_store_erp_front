import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'employment_contract_read_plain_text.dart';

/// `MultiPage`는 **한 위젯**이 페이지 높이를 넘으면 예외가 납니다.
/// 본문을 줄 단위로 나눠 배치해 여러 페이지에 자연스럽게 이어지게 합니다.
List<pw.Widget> _bodyLinesToWidgets(
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
  for (final raw in body.split('\n')) {
    final line = raw;
    if (line.isEmpty) {
      widgets.add(pw.SizedBox(height: fontSize * 0.35));
    } else {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1),
          child: pw.Text(line, style: style),
        ),
      );
    }
  }
  return widgets;
}

/// 화면과 동일한 본문을 A4 PDF로 저장합니다.
/// 한글은 Pretendard OTF가 아닌 Noto Sans KR TTF를 사용합니다 (`pdf` 패키지 제약).
Future<Uint8List> buildEmploymentContractPdfBytes({
  required String templateVersion,
  required Map<String, dynamic> formValues,
  required String documentTitle,
}) async {
  final font = await PdfGoogleFonts.notoSansKRRegular();
  final fontMedium = await PdfGoogleFonts.notoSansKRMedium();

  final isGuardian = templateVersion == 'guardian_consent_v1';
  final isMinor = templateVersion == 'minor_standard_v1';
  final body = isGuardian
      ? buildGuardianConsentPlainText(formValues)
      : buildStandardEmploymentContractPlainText(
          formValues,
          isMinor: isMinor,
        );

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          documentTitle,
          style: pw.TextStyle(font: fontMedium, fontSize: 14),
        ),
        pw.SizedBox(height: 14),
        ..._bodyLinesToWidgets(body, font),
      ],
    ),
  );
  return pdf.save();
}
