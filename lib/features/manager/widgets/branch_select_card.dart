import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/widgets/mint_add_button.dart';

class BranchSelectCard extends StatelessWidget {
  const BranchSelectCard({
    super.key,
    required this.selectedName,
    required this.branches,
    required this.isExpanded,
    required this.isOwner,
    required this.onHeaderTap,
    required this.onBranchTap,
    required this.onAddTap,
  });

  final String? selectedName;
  final List<({int id, String name, String? status})> branches;
  final bool isExpanded;
  final bool isOwner;
  final VoidCallback onHeaderTap;
  final ValueChanged<int> onBranchTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedName ?? '점포를 선택해주세요.',
                      textAlign: TextAlign.left,
                      style: AppTypography.bodyMediumR.copyWith(
                        color: selectedName == null
                            ? const Color(0xFFA3A4AF)
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 19 / 14,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.grey150,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.grey50),
            const SizedBox(height: 4),
            ...List.generate(branches.length, (index) {
              final branch = branches[index];
              return InkWell(
                onTap: () => onBranchTap(branch.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          style: AppTypography.bodyMediumR.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 19 / 14,
                          ),
                        ),
                      ),
                      if ((branch.status ?? '').toLowerCase() == 'pending')
                        Text(
                          '심사 중',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMediumR.copyWith(
                            color: const Color(0xFFFF8E2B),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 19 / 14,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (isOwner) ...[
              const SizedBox(height: 6),
              MintAddButton(
                label: '점포 추가하기',
                onPressed: onAddTap,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
