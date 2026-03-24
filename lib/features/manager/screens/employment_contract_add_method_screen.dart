import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'employment_contract_file_attach_screen.dart';
import 'employment_contract_form_screen.dart';

/// 근로계약서 추가: 직접 작성 vs 파일 첨부 (급여명세 추가와 동일 패턴)
class EmploymentContractAddMethodScreen extends StatelessWidget {
  const EmploymentContractAddMethodScreen({
    super.key,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.templateVersion,
    required this.listTitle,
  });

  final int branchId;
  final int employeeId;
  final String employeeName;
  final String templateVersion;
  final String listTitle;

  String get _directWriteTitle {
    switch (templateVersion) {
      case 'minor_standard_v1':
        return '연소근로자 표준근로계약 작성';
      case 'guardian_consent_v1':
        return '친권동의서 작성';
      default:
        return '표준 근로계약서 작성';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(listTitle),
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
                imageAsset: 'assets/icons/png/common/box_green_icon.png',
                title: _directWriteTitle,
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => EmploymentContractFormScreen(
                        branchId: branchId,
                        employeeId: employeeId,
                        employeeName: employeeName,
                        templateVersion: templateVersion,
                        listTitle: listTitle,
                      ),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.grey50),
              _MethodRow(
                svgAsset: 'assets/icons/svg/icon/payroll_add_folder_16.svg',
                title: '파일로 첨부',
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => EmploymentContractFileAttachScreen(
                        branchId: branchId,
                        employeeId: employeeId,
                        templateVersion: templateVersion,
                        screenTitle: listTitle,
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
    this.svgAsset,
    this.imageAsset,
    required this.title,
    required this.onTap,
  }) : assert(svgAsset != null || imageAsset != null);

  final String? svgAsset;
  final String? imageAsset;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              if (imageAsset != null)
                Image.asset(imageAsset!, width: 16, height: 16)
              else
                SvgPicture.asset(svgAsset!, width: 16, height: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMediumM.copyWith(
                    fontSize: 14,
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
