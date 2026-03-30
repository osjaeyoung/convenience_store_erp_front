import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// 모바일/데스크톱: 임시 파일로 저장 후 시스템 공유 시트(다운로드/저장 시트).
Future<void> shareEtcDownload({
  required String fileUrl,
  required Uint8List? bytes,
  required String fileName,
  String? subject,
}) async {
  if (bytes == null) return;
  final f = File('${Directory.systemTemp.path}/$fileName');
  await f.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(f.path)],
    subject: subject,
  );
}
