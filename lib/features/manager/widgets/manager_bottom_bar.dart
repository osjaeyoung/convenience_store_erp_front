import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 경영자/점장용 바텀 네비게이션 바
/// 홈, 직원관리, 인건비, 매장·비용, 구인·채용
class ManagerBottomBar extends StatelessWidget {
  const ManagerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = [
    _NavItem(label: '홈', activeIcon: 'home_active', inactiveIcon: 'home_inactive'),
    _NavItem(
      label: '직원관리',
      activeIcon: 'management_active',
      inactiveIcon: 'management_inactive',
    ),
    _NavItem(
      label: '인건비',
      activeIcon: 'laborCost_active',
      inactiveIcon: 'laborCost_inactive',
    ),
    _NavItem(
      label: '매장·비용',
      activeIcon: 'shop_active',
      inactiveIcon: 'shop_inactive',
    ),
    _NavItem(
      label: '구인·채용',
      activeIcon: 'serch_active',
      inactiveIcon: 'serch_inactive',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (index) => _BottomNavItem(
                item: _items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final String activeIcon;
  final String inactiveIcon;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/png/common/bottomBar/${isSelected ? item.activeIcon : item.inactiveIcon}.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
