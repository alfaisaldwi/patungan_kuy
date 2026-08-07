import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;
  const SmallIconButton({
    super.key,
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: c),
          ),
        ),
      ),
    );
  }
}
