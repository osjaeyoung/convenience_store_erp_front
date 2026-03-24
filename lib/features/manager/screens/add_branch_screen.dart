import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/enums/user_role.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../data/repositories/owner_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
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
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerPhoneController = TextEditingController();
  final TextEditingController _branchQueryController = TextEditingController();
  List<_ManagerLookupItem> _lookupItems = const [];

  bool _submitting = false;
  bool _lookuping = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _branchQueryController.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      context.read<AuthBloc>().state.user?.role == UserRole.manager;

  String _normalizePhone(String raw) => raw.replaceAll('-', '').trim();

  void _addDraft() {
    setState(() {
      _drafts.add(_BranchDraft());
    });
  }

  Future<void> _lookupBranches() async {
    final name = _managerNameController.text.trim();
    final phone = _normalizePhone(_managerPhoneController.text);
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 전화번호를 먼저 입력해주세요.')),
      );
      return;
    }

    setState(() => _lookuping = true);
    try {
      final repo = context.read<ManagerHomeRepository>();
      final items = await repo.lookupBranches(
        managerName: name,
        managerPhoneNumber: phone,
      );
      if (!mounted) return;
      setState(() {
        _lookupItems = items.map(_ManagerLookupItem.fromJson).toList();
      });
      if (_lookupItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사전등록된 점포가 없습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점포 조회에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _lookuping = false);
    }
  }

  Future<void> _joinOne(_ManagerLookupItem item) async {
    final phone = _normalizePhone(_managerPhoneController.text);
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = context.read<ManagerHomeRepository>();
      await repo.joinBranch(
        managerRegistrationId: item.registrationId,
        managerPhoneNumber: phone,
      );
      if (!mounted) return;
      setState(() {
        _lookupItems = _lookupItems
            .map(
              (e) => e.registrationId == item.registrationId
                  ? e.copyWith(registrationStatus: 'linked')
                  : e,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.branchName} 연결이 완료되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점포 연결에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit() async {
    if (_isOwner && !_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      if (_isOwner) {
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
      } else {
        final name = _managerNameController.text.trim();
        final phone = _normalizePhone(_managerPhoneController.text);
        if (name.isEmpty || phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이름과 전화번호를 입력해주세요.')),
          );
          return;
        }
        final repo = context.read<ManagerHomeRepository>();
        final res = await repo.joinBranchesBulk(
          managerName: name,
          managerPhoneNumber: phone,
        );
        if (!mounted) return;
        final linkedCount = (res['linked_count'] as num?)?.toInt() ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$linkedCount개 점포 권한을 연결했습니다.')),
        );
      }
      if (!mounted) return;
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
        title: const Text('점포 추가하기'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
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
                          TextSpan(text: '점포를 추가하기 위해\n해당 '),
                          TextSpan(
                            text: '내용',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(text: '을 입력해주세요.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_isOwner)
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildDraftFields(),
                            const SizedBox(height: 8),
                            MintAddButton(
                              label: '추가하기',
                              onPressed: _addDraft,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _buildFieldLabel('점장 이름'),
                      AuthInputField(
                        controller: _managerNameController,
                        hintText: '이름을 입력해주세요.',
                        focusedBorderColor: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('점장 전화번호'),
                      AuthInputField(
                        controller: _managerPhoneController,
                        hintText: '전화번호를 입력해주세요.',
                        keyboardType: TextInputType.phone,
                        focusedBorderColor: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('회사명'),
                      TextFormField(
                        controller: _branchQueryController,
                        decoration: InputDecoration(
                          hintText: '회사명을 검색해주세요',
                          hintStyle: AppTypography.bodyMediumR.copyWith(
                            color: AppColors.grey100,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/svg/icon/search_mint_20.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.grey0,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.grey50),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.grey50),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MintAddButton(
                        label: _lookuping ? '조회 중...' : '추가하기',
                        onPressed: _lookuping ? null : _lookupBranches,
                      ),
                      const SizedBox(height: 12),
                      ..._buildLookupItems(),
                    ],
                  ],
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

  List<Widget> _buildLookupItems() {
    final keyword = _branchQueryController.text.trim();
    final filtered = _lookupItems.where((item) {
      if (item.registrationStatus != 'pre_registered' &&
          item.registrationStatus != 'linked') {
        return false;
      }
      if (keyword.isEmpty) return true;
      return item.branchName.contains(keyword);
    }).toList();

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.grey0Alt,
            border: Border.all(color: AppColors.grey25),
          ),
          child: Text(
            '조회된 점포가 없습니다.',
            style: AppTypography.bodyMediumR.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ];
    }

    return filtered
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey50),
              color: AppColors.grey0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.branchName,
                        style: AppTypography.bodyMediumM.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.branchCode ?? '-',
                        style: AppTypography.bodySmallM.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.registrationStatus == 'linked')
                  Text(
                    '연결됨',
                    style: AppTypography.bodySmallM.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _joinOne(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      backgroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '추가',
                      style: AppTypography.bodySmallM.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
        .toList();
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

class _ManagerLookupItem {
  const _ManagerLookupItem({
    required this.registrationId,
    required this.branchId,
    required this.branchName,
    required this.registrationStatus,
    this.branchCode,
  });

  final int registrationId;
  final int branchId;
  final String branchName;
  final String? branchCode;
  final String registrationStatus;

  factory _ManagerLookupItem.fromJson(Map<String, dynamic> json) {
    return _ManagerLookupItem(
      registrationId: (json['registration_id'] as num?)?.toInt() ?? 0,
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name']?.toString() ?? '',
      branchCode: json['branch_code']?.toString(),
      registrationStatus: json['registration_status']?.toString() ?? '',
    );
  }

  _ManagerLookupItem copyWith({
    String? registrationStatus,
  }) {
    return _ManagerLookupItem(
      registrationId: registrationId,
      branchId: branchId,
      branchName: branchName,
      branchCode: branchCode,
      registrationStatus: registrationStatus ?? this.registrationStatus,
    );
  }
}
