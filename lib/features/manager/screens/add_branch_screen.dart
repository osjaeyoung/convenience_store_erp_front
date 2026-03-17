import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/owner_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../../auth/widgets/mint_add_button.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_BranchDraft> _drafts = [_BranchDraft()];
  bool _submitting = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() {
      _drafts.add(_BranchDraft());
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final repo = context.read<OwnerHomeRepository>();
      for (final draft in _drafts) {
        final branchName = draft.companyNameController.text.trim();
        final branchCode = draft.businessNumberController.text.trim();
        if (branchName.isEmpty) continue;
        await repo.addBranch(
          branchName: branchName,
          branchCode: branchCode.isEmpty ? null : branchCode,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_drafts.length}개 점포가 추가되었습니다.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점포 추가에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        backgroundColor: AppColors.grey0,
        surfaceTintColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          '점포 추가하기',
          style: AppTypography.bodyLargeB.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            height: 32 / 24,
                            color: AppColors.textPrimary,
                          ),
                          children: const [
                            TextSpan(text: '점포를 추가하기 위해\n아래 '),
                            TextSpan(
                              text: '정보',
                              style: TextStyle(color: AppColors.primary),
                            ),
                            TextSpan(text: '를 입력해주세요.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ..._buildDraftFields(),
                      const SizedBox(height: 8),
                      MintAddButton(
                        label: '추가하기',
                        onPressed: _addDraft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.grey0,
                        ),
                      )
                    : Text(
                        '완료',
                        style: AppTypography.bodyLargeB.copyWith(
                          color: AppColors.grey0,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDraftFields() {
    final widgets = <Widget>[];
    for (var index = 0; index < _drafts.length; index++) {
      final draft = _drafts[index];
      widgets.add(_buildFieldLabel('회사명'));
      widgets.add(
        AuthInputField(
          controller: draft.companyNameController,
          hintText: '회사명을 입력해주세요.',
          focusedBorderColor: AppColors.primary,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return '*회사명을 입력해주세요.';
            return null;
          },
        ),
      );
      widgets.add(const SizedBox(height: 20));
      widgets.add(_buildFieldLabel('사업자 등록 번호'));
      widgets.add(
        AuthInputField(
          controller: draft.businessNumberController,
          hintText: '사업자 등록 번호를 입력해주세요.',
          keyboardType: TextInputType.number,
          focusedBorderColor: AppColors.primary,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return '*사업자 등록 번호를 입력해주세요.';
            return null;
          },
        ),
      );
      if (index != _drafts.length - 1) {
        widgets.add(const SizedBox(height: 18));
        widgets.add(const Divider(color: AppColors.grey25, height: 1));
        widgets.add(const SizedBox(height: 18));
      } else {
        widgets.add(const SizedBox(height: 20));
      }
    }
    return widgets;
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTypography.bodyLargeB.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BranchDraft {
  _BranchDraft()
      : companyNameController = TextEditingController(),
        businessNumberController = TextEditingController();

  final TextEditingController companyNameController;
  final TextEditingController businessNumberController;

  void dispose() {
    companyNameController.dispose();
    businessNumberController.dispose();
  }
}
