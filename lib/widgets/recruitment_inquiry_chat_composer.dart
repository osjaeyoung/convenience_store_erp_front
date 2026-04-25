import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RecruitmentInquiryChatComposer extends StatefulWidget {
  const RecruitmentInquiryChatComposer({
    super.key,
    required this.onSend,
  });

  final ValueChanged<String> onSend;

  @override
  State<RecruitmentInquiryChatComposer> createState() =>
      _RecruitmentInquiryChatComposerState();
}

class _RecruitmentInquiryChatComposerState
    extends State<RecruitmentInquiryChatComposer> {
  static const String _sendIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
  <path d="M16.863 9.49762L4.37654 2.28912C4.19893 2.18488 3.97499 2.18488 3.79739 2.28912C3.61978 2.39337 3.50781 2.58256 3.50781 2.79105V8.45901C3.50781 8.74086 3.71245 8.9841 3.9943 9.03044L9.86689 9.99569L3.9943 10.9416C3.71245 10.988 3.50781 11.2273 3.50781 11.5131V17.2119C3.50781 17.4204 3.61978 17.6096 3.79739 17.7138C3.88619 17.764 3.98658 17.7911 4.08696 17.7911C4.18735 17.7911 4.28774 17.764 4.37654 17.7138L16.863 10.5053C17.0406 10.4011 17.1526 10.2119 17.1526 10.0034C17.1526 9.79491 17.0406 9.60573 16.863 9.50148V9.49762Z" fill="#70D2B3"/>
</svg>
''';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (_canSend != text.isNotEmpty) {
      setState(() => _canSend = text.isNotEmpty);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey0,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grey0Alt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.fromLTRB(15.w, 10.h, 10.w, 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: AppTypography.bodyMediumR.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: '메세지 쓰기',
                    hintStyle: AppTypography.bodyMediumR.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 14.sp,
                      height: 19 / 14,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              InkWell(
                onTap: _handleSend,
                borderRadius: BorderRadius.circular(20.r),
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: SvgPicture.string(
                    _sendIconSvg,
                    width: 20.r,
                    height: 20.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
