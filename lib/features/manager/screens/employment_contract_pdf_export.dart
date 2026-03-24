import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'employment_contract_read_plain_text.dart';

/// 화면과 동일한 본문을 A4 PDF로 저장합니다.
Future<Uint8List> buildEmploymentContractPdfBytes({
  required String templateVersion,
  required Map<String, dynamic> formValues,
  required String documentTitle,
}) async {
  final regularData =
      await rootBundle.load('assets/fonts/Pretendard-Regular.otf');
  final mediumData = await rootBundle.load('assets/fonts/Pretendard-Medium.otf');
  final font = pw.Font.ttf(regularData);
  final fontMedium = pw.Font.ttf(mediumData);

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
        pw.Text(
          body,
          style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 3),
        ),
      ],
    ),
  );
  return pdf.save();
}
