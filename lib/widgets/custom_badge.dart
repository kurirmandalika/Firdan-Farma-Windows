import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const CustomBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory CustomBadge.success(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.successBg,
      textColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
  }

  factory CustomBadge.warning(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.warningBg,
      textColor: AppTheme.warningOrange,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory CustomBadge.danger(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.dangerBg,
      textColor: AppTheme.dangerRed,
      icon: Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
