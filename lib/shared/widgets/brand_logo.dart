import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';

enum BrandLogoVariant { mark, full }

class BrandLogo extends StatelessWidget {
  final BrandLogoVariant variant;
  final double size;
  final double? width;
  final bool shadow;

  const BrandLogo.mark({super.key, this.size = 48, this.shadow = false})
    : variant = BrandLogoVariant.mark,
      width = null;

  const BrandLogo.full({
    super.key,
    this.width,
    this.size = 160,
    this.shadow = false,
  }) : variant = BrandLogoVariant.full;

  @override
  Widget build(BuildContext context) {
    if (variant == BrandLogoVariant.full) {
      return Image.asset(
        AppConstants.appLogoAsset,
        width: width ?? size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.72,
          child: Image.asset(
            AppConstants.appLogoAsset,
            width: size,
            height: size / 0.72,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
