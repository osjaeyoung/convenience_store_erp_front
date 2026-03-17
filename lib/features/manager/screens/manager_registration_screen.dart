import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/owner_home_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/auth_input_field.dart';
import '../../auth/widgets/mint_add_button.dart';

class ManagerRegistrationScreen extends StatefulWidget {
  const ManagerRegistrationScreen({
    super.key,
    required this.branchId,
  });

  final int branchId;

  @override
  State<ManagerRegistrationScreen> createState() => _ManagerRegistrationScreenState();
}

class _ManagerRegistrationScreenState extends State<ManagerRegistrationScreen> {
  bool _loading = true;
  bool _saving = false;
  List<_RegistrationRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<OwnerHomeRepository>();
      final items = await repo.getManagerRegistrations(widget.branchId);
      final mapped = items
          .map(
            (e) => _RegistrationRow(
              registrationId: _toInt(e['registration_id']),
              managerName: e['manager_name']?.toString() ?? '',
              managerPhoneNumber: e['manager_phone_number']?.toString() ?? '',
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _rows = mapped;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 점장 목록을 불러오지 못했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '점장 등록',
                    textAlign: TextAlign.center,
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '이름',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: nameController,
                    hintText: '이름을 입력해주세요.',
                    focusedBorderColor: AppColors.primary,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '이름을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '전화번호',
                    style: AppTypography.bodyLargeB.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: phoneController,
                    hintText: '전화번호를 입력해주세요.',
                    keyboardType: TextInputType.phone,
                    focusedBorderColor: AppColors.primary,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '전화번호를 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.grey25,
                            foregroundColor: AppColors.grey150,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.grey0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _saving = true);
      await context.read<OwnerHomeRepository>().postManager(
            branchId: widget.branchId,
            managerName: nameController.text.trim(),
            managerPhoneNumber: phoneController.text.trim(),
          );
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('점장 등록에 실패했습니다.')),
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(_RegistrationRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '알림',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox.square(
                    dimension: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: AppColors.grey0Alt,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/png/common/warding_icon.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '삭제하시겠습니까?\n해당 권한이 사라지게 됩니다.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumM.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.grey25,
                          foregroundColor: AppColors.grey150,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.grey0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
      },
    );
    if (ok != true) return;

    try {
      setState(() => _saving = true);
      await context.read<OwnerHomeRepository>().deleteManagerRegistration(
            branchId: widget.branchId,
            registrationId: row.registrationId,
          );
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
          '등록된 점장',
          style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_rows.isEmpty)
                            Container()
                          else
                            ..._rows.map(
                              (row) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ManagerInfoCard(
                                  row: row,
                                  onDelete: () => _confirmDelete(row),
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          MintAddButton(
                            label: '추가하기',
                            onPressed: _saving ? null : _showAddDialog,
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: FilledButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '확인',
                  style: AppTypography.bodyLargeB.copyWith(color: AppColors.grey0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerInfoCard extends StatelessWidget {
  const _ManagerInfoCard({
    required this.row,
    required this.onDelete,
  });

  final _RegistrationRow row;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('이름', style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _ReadonlyField(text: row.managerName),
          const SizedBox(height: 14),
          Text('전화번호', style: AppTypography.bodyLargeB.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _ReadonlyField(text: row.managerPhoneNumber),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4834),
                  foregroundColor: AppColors.grey0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '삭제',
                  style: AppTypography.bodySmallB.copyWith(color: AppColors.grey0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey50),
        color: AppColors.grey0Alt,
      ),
      child: Text(
        text,
        style: AppTypography.bodyLargeM.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _RegistrationRow {
  const _RegistrationRow({
    required this.registrationId,
    required this.managerName,
    required this.managerPhoneNumber,
  });

  final int registrationId;
  final String managerName;
  final String managerPhoneNumber;
}
