import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'payroll_file_attach_screen.dart';
import 'payroll_statement_form_screen.dart';

/// 급여명세 추가: 작성 vs 파일 첨부 (Figma 카드 2행)
class PayrollAddMethodScreen extends StatelessWidget {
  const PayrollAddMethodScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('급여명세'),
        backgroundColor: AppColors.grey0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grey0,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey50),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MethodRow(
                asset: 'assets/icons/svg/icon/payroll_add_pencil_16.svg',
                title: '급여명세 작성',
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => PayrollStatementFormScreen(
                        branchId: branchId,
                        employeeId: employeeId,
                        employeeName: employeeName,
                      ),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              Divider(height: 1, thickness: 1, color: AppColors.grey50),
              _MethodRow(
                asset: 'assets/icons/svg/icon/payroll_add_folder_16.svg',
                title: '파일로 첨부',
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => PayrollFileAttachScreen(
                        branchId: branchId,
                        employeeId: employeeId,
                      ),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.asset,
    required this.title,
    required this.onTap,
  });

  final String asset;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grey0Alt,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  asset,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMediumM.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
