import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobileMax = 700;
  static const double tabletMax = 1100;
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobileMax;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobileMax &&
        width < ResponsiveBreakpoints.tabletMax;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tabletMax;
  }

  static int getStatCardCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 2;
    return 1;
  }

  static int getObatGridCrossAxisCount(double width) {
    if (width >= 1300) return 3;
    if (width >= 900) return 2;
    return 1;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget desktop;
  final Widget? tablet;
  final Widget? mobile;

  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax) {
          return desktop;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax) {
          return tablet ?? desktop;
        }
        return mobile ?? tablet ?? desktop;
      },
    );
  }
}
