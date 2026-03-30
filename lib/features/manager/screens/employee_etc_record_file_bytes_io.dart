import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';

Future<List<int>?> readEtcPickedFileBytes(PlatformFile f) async {
  if (f.bytes != null) return f.bytes;
  final p = f.path;
  if (p == null || p.isEmpty) return null;
  try {
    return await File(p).readAsBytes();
  } catch (_) {
    return null;
  }
}
