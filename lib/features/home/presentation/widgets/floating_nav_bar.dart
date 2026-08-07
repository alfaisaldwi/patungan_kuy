import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../../core/theme/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  final NavBarConfig navBarConfig;
  const FloatingNavBar({super.key, required this.navBarConfig});

  @override
  Widget build(BuildContext context) {
    final items = navBarConfig.items;
    final selectedIndex = navBarConfig.selectedIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [AppTheme.shadowMd],
        border: Border.all(color: AppTheme.border.withAlpha(128)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          return Expanded(
            child: _NavItem(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => navBarConfig.onItemSelected(i),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ItemConfig item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? item.activeForegroundColor
        : item.inactiveForegroundColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),

        decoration: BoxDecoration(
          color: selected ? item.activeForegroundColor.withAlpha(28) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: item.iconSize - 6),
              child: selected ? item.icon : item.inactiveIcon,
            ),
            if (item.title != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.title!,
                  overflow: TextOverflow.ellipsis,
                  style: item.textStyle.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
