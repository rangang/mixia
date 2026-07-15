import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 900;
    if (width >= 800) return 700;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (size.width >= 1200 && desktop != null) {
      return desktop!;
    } else if (size.width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsivePadding {
  static EdgeInsets all(BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (Responsive.isDesktop(context)) {
      return EdgeInsets.all(desktop);
    } else if (Responsive.isTablet(context)) {
      return EdgeInsets.all(tablet);
    }
    return EdgeInsets.all(mobile);
  }

  static EdgeInsets symmetric(BuildContext context, {
    double mobileHorizontal = 16,
    double mobileVertical = 12,
    double tabletHorizontal = 24,
    double tabletVertical = 16,
    double desktopHorizontal = 32,
    double desktopVertical = 20,
  }) {
    if (Responsive.isDesktop(context)) {
      return EdgeInsets.symmetric(horizontal: desktopHorizontal, vertical: desktopVertical);
    } else if (Responsive.isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: tabletHorizontal, vertical: tabletVertical);
    }
    return EdgeInsets.symmetric(horizontal: mobileHorizontal, vertical: mobileVertical);
  }
}
