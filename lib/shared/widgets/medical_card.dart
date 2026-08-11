import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';

class MedicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final BorderSide? border;

  const MedicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppTheme.radiusMd,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: border?.color ?? AppTheme.borderLight,
          width: border?.width ?? 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark ? 0.16 : 0.045,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
