import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

/// 웹: 파일 URL을 외부 브라우저로 엽니다.
Future<void> shareEtcDownload({
  required String fileUrl,
  required Uint8List? bytes,
  required String fileName,
  String? subject,
}) async {
  final uri = Uri.parse(fileUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
