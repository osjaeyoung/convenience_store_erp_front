import 'package:file_picker/file_picker.dart';

Future<List<int>?> readEtcPickedFileBytes(PlatformFile f) async => f.bytes;
