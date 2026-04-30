import 'package:file_picker/file_picker.dart';
import 'package:convenience_store_erp_front/core/errors/user_friendly_error_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum UploadSourceType { file, gallery }

Future<PlatformFile?> pickSingleFileOrGallery({
  required BuildContext context,
  required List<String> allowedExtensions,
  bool readBytesFromFilePicker = false,
}) async {
  final source = await _showUploadSourceSheet(context);
  if (source == null || !context.mounted) return null;

  try {
    switch (source) {
      case UploadSourceType.file:
        FilePickerResult? result;
        try {
          result = await FilePicker.platform.pickFiles(
            type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
            allowedExtensions: allowedExtensions.isEmpty
                ? null
                : allowedExtensions,
            allowMultiple: false,
            withData: kIsWeb || readBytesFromFilePicker,
          );
        } on MissingPluginException {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
            withData: kIsWeb || readBytesFromFilePicker,
          );
        }
        if (result == null || result.files.isEmpty) return null;
        return result.files.first;
      case UploadSourceType.gallery:
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return null;
        final bytes = await picked.readAsBytes();
        return PlatformFile(
          name: picked.name.trim().isEmpty ? 'image.jpg' : picked.name.trim(),
          size: bytes.length,
          bytes: bytes,
          path: picked.path.isEmpty ? null : picked.path,
        );
    }
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 실행 환경에서 이 기능을 사용할 수 없습니다.')),
      );
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 실패: ${userFriendlyErrorMessage(e)}')),
      );
    }
    return null;
  }
}

Future<List<PlatformFile>?> pickMultipleFilesOrGallery({
  required BuildContext context,
  required List<String> allowedExtensions,
  bool readBytesFromFilePicker = false,
}) async {
  final source = await _showUploadSourceSheet(context);
  if (source == null || !context.mounted) return null;

  try {
    switch (source) {
      case UploadSourceType.file:
        FilePickerResult? result;
        try {
          result = await FilePicker.platform.pickFiles(
            type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
            allowedExtensions: allowedExtensions.isEmpty
                ? null
                : allowedExtensions,
            allowMultiple: true,
            withData: kIsWeb || readBytesFromFilePicker,
          );
        } on MissingPluginException {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
            withData: kIsWeb || readBytesFromFilePicker,
          );
        }
        if (result == null || result.files.isEmpty) return null;
        return result.files;
      case UploadSourceType.gallery:
        final picker = ImagePicker();
        final pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isEmpty) return null;

        List<PlatformFile> result = [];
        for (final picked in pickedFiles) {
          final bytes = await picked.readAsBytes();
          result.add(
            PlatformFile(
              name: picked.name.trim().isEmpty
                  ? 'image.jpg'
                  : picked.name.trim(),
              size: bytes.length,
              bytes: bytes,
              path: picked.path.isEmpty ? null : picked.path,
            ),
          );
        }
        return result;
    }
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 실행 환경에서 이 기능을 사용할 수 없습니다.')),
      );
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 실패: ${userFriendlyErrorMessage(e)}')),
      );
    }
    return null;
  }
}

Future<UploadSourceType?> _showUploadSourceSheet(BuildContext context) {
  return showModalBottomSheet<UploadSourceType>(
    context: context,
    backgroundColor: AppColors.grey0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
            SizedBox(height: 12.h),
            _UploadSourceTile(
              icon: Icons.folder_open_rounded,
              label: '파일 선택',
              onTap: () => Navigator.of(context).pop(UploadSourceType.file),
            ),
            _UploadSourceTile(
              icon: Icons.photo_library_outlined,
              label: '갤러리 선택',
              onTap: () => Navigator.of(context).pop(UploadSourceType.gallery),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      );
    },
  );
}

class _UploadSourceTile extends StatelessWidget {
  const _UploadSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        label,
        style: AppTypography.bodyMediumR.copyWith(color: AppColors.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
