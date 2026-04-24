import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signature/signature.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/contract_signature_data.dart';
import '../utils/modal_title_format.dart';

export '../utils/contract_signature_data.dart'
    show
        contractSignaturePlainText,
        decodeContractSignatureDataUrl,
        isContractSignatureDataUrl;

/// 빈 칩·레거시 텍스트 서명. 전자서명(data URL)은 호출부에서 칩 밖 [contractSignatureImageWithUnderline]로 처리.
Widget contractSignatureChipChild({
  required String? value,
  required String emptyLabel,
  required TextStyle textStyle,
}) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) {
    return Text(emptyLabel, style: textStyle);
  }
  return Text(t, style: textStyle);
}

/// 입력 후 서명란: 싸인 이미지만 + 밑줄 (칩 배경·테두리 없음)
Widget contractSignatureImageWithUnderline({
  required String dataUrl,
  required Color underlineColor,
  double? maxHeight,
  double? maxWidth,
}) {
  final bytes = decodeContractSignatureDataUrl(dataUrl);
  if (bytes == null || bytes.isEmpty) {
    return SizedBox(height: 1.h);
  }
  final h = maxHeight ?? 36.h;
  final w = maxWidth ?? 160.w;
  // Wrap·Row 안에서 stretch가 부모 너비만큼 밑줄을 늘리지 않도록, 이미지 폭에 맞춤
  return IntrinsicWidth(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: h, maxWidth: w),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            gaplessPlayback: true,
          ),
        ),
        SizedBox(height: 2.h),
        Container(height: 1, color: underlineColor),
      ],
    ),
  );
}

/// 계약서 조회 화면의 밑줄 인라인 필드와 동일한 톤
Widget contractSignatureReadonlyInline({
  required String? raw,
  required TextStyle textStyle,
  required Color underlineColor,
  String placeholder = '　　　',
}) {
  final s = raw?.trim() ?? '';
  final has = s.isNotEmpty;
  if (has && isContractSignatureDataUrl(s)) {
    return contractSignatureImageWithUnderline(
      dataUrl: s,
      underlineColor: underlineColor,
      maxHeight: 44.h,
      maxWidth: 180.w,
    );
  }
  final display = has ? s : placeholder;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        display,
        style: textStyle.copyWith(
          color: has
              ? underlineColor
              : underlineColor.withValues(alpha: 0.35),
        ),
      ),
      SizedBox(height: 2.h),
      Container(height: 1, color: underlineColor),
    ],
  );
}

Future<String?> showContractSignatureDialog(
  BuildContext context, {
  required String label,
}) {
  final title = modalTitleWithoutParenthetical(label);
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _ContractSignatureDialog(title: title),
  );
}

final _signatureDialogButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8.r),
);

class _ContractSignatureDialog extends StatefulWidget {
  const _ContractSignatureDialog({required this.title});

  final String title;

  @override
  State<_ContractSignatureDialog> createState() =>
      _ContractSignatureDialogState();
}

class _ContractSignatureDialogState extends State<_ContractSignatureDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onConfirm(BuildContext dialogContext) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('서명을 입력해 주세요.')),
      );
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (!dialogContext.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('서명을 저장할 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }
    final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    if (!dialogContext.mounted) return;
    Navigator.pop(dialogContext, dataUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: AppTypography.heading3.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              '사인(서명)으로 작성해 주세요.',
              style: AppTypography.bodySmallR.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: 14.h),
            Material(
              color: Colors.white,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: AppColors.grey100),
              ),
              child: SizedBox(
                height: 200.h,
                width: double.infinity,
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _controller.clear()),
                child: Text(
                  '지우기',
                  style: AppTypography.bodySmallM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey25,
                      foregroundColor: AppColors.textTertiary,
                      shape: _signatureDialogButtonShape,
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _onConfirm(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.grey0,
                      shape: _signatureDialogButtonShape,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
