import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design guidelines
class Breakpoints {
  static const double mobileSmall = 360;   // Small phones
  static const double mobile = 600;         // Phones
  static const double tabletSmall = 840;    // Small tablets
  static const double tablet = 1024;        // Tablets
  static const double desktop = 1280;       // Desktop
  static const double desktopLarge = 1920;  // Large desktop
  static const double desktopXL = 2560;     // Extra large desktop
}

/// Device type enumeration
enum DeviceType {
  mobileSmall,
  mobile,
  tabletSmall,
  tablet,
  desktop,
  desktopLarge,
  desktopXL,
}

/// Screen orientation
enum ScreenOrientation {
  portrait,
  landscape,
}

/// Responsive helper class for adaptive layouts
class Responsive {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < Breakpoints.mobileSmall) {
      return DeviceType.mobileSmall;
    } else if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tabletSmall) {
      return DeviceType.tabletSmall;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width < Breakpoints.desktopLarge) {
      return DeviceType.desktopLarge;
    } else {
      return DeviceType.desktopXL;
    }
  }
  
  static ScreenOrientation getOrientation(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height 
        ? ScreenOrientation.landscape 
        : ScreenOrientation.portrait;
  }
  
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == ScreenOrientation.portrait;
  }
  
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == ScreenOrientation.landscape;
  }
  
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  static EdgeInsets getSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  static double getBottomInset(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
  
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.desktop || type == DeviceType.desktopLarge || type == DeviceType.desktopXL;
  }
  
  static bool isMobileOrTablet(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }
  
  /// Get responsive value based on device type
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tabletSmall:
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.desktopLarge:
      case DeviceType.desktopXL:
        return desktopLarge ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    return getValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }
  
  /// Get responsive margin
  static EdgeInsets getMargin(BuildContext context) {
    return getValue(
      context,
      mobile: const EdgeInsets.all(8),
      tablet: const EdgeInsets.all(12),
      desktop: const EdgeInsets.all(16),
    );
  }
  
  /// Get responsive font size
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    return getValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
  }
  
  /// Get minimum touch target size
  static double getTouchTargetSize(BuildContext context) {
    return getValue(
      context,
      mobile: 48.0,
      tablet: 44.0,
      desktop: 40.0,
    );
  }
  
  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    return getValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      desktopLarge: 4,
    );
  }
  
  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    return getValue(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
      desktopLarge: 1400,
    );
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout widget for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopLarge;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.desktopLarge,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobileSmall:
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tabletSmall:
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.desktopLarge:
          case DeviceType.desktopXL:
            return desktopLarge ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Adaptive container with responsive constraints
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final Alignment alignment;
  
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.alignment = Alignment.center,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: padding ?? Responsive.getPadding(context),
      margin: margin ?? Responsive.getMargin(context),
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? Responsive.getMaxContentWidth(context),
      ),
      child: child,
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.forceColumns,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = forceColumns ?? Responsive.getGridColumns(context);
    
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                 (spacing * (columns - 1)) - 
                 (Responsive.getPadding(context).horizontal)) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}