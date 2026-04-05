import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';

class AccountInquiryFormScreen extends StatefulWidget {
  const AccountInquiryFormScreen({super.key});

  @override
  State<AccountInquiryFormScreen> createState() => _AccountInquiryFormScreenState();
}

class _AccountInquiryFormScreenState extends State<AccountInquiryFormScreen> {
  static const Map<String, String> _typeLabels = {
    'account': '계정',
    'service': '서비스',
    'recruitment': '채용',
    'payment': '결제',
    'etc': '기타',
  };

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'account';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 유형, 제목, 내용을 모두 입력해주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final inquiry = await context.read<AuthRepository>().createInquiry(
            inquiryType: _selectedType,
            title: title,
            content: content,
          );
      if (!mounted) return;
      Navigator.of(context).pop(inquiry);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountDioMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: accountFigmaAppBar(context: context, title: '문의하기'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              children: [
                Text(
                  '문의 내용을 남겨주시면\n확인 후 답변드릴게요.',
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 28.h),
                Text('문의 유형', style: AccountFigmaStyles.fieldCaption),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _typeLabels.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.grey25,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text('제목', style: AccountFigmaStyles.fieldCaption),
                SizedBox(height: 8.h),
                TextField(
                  controller: _titleController,
                  enabled: !_submitting,
                  style: AppTypography.bodyMediumR,
                  decoration: InputDecoration(
                    hintText: '문의 제목을 입력해주세요.',
                    filled: true,
                    fillColor: AppColors.grey25,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text('내용', style: AccountFigmaStyles.fieldCaption),
                SizedBox(height: 8.h),
                TextField(
                  controller: _contentController,
                  enabled: !_submitting,
                  minLines: 8,
                  maxLines: 12,
                  style: AppTypography.bodyMediumR,
                  decoration: InputDecoration(
                    hintText: '문의 내용을 자세히 입력해주세요.',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.grey25,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('등록하기'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
