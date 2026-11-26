import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Navigasi bawah bergaya aplikasi perjalanan: satu pil gelap mengambang di
/// atas kanvas putih, berisi empat tujuan dengan ikon dan label.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<FloatingNavItem> destinations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Color(0x2E000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavButton(
                  item: destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.selectedIcon : item.icon, size: 21, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.label(
              10,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
