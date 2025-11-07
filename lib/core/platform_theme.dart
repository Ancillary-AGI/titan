import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

/// Platform-adaptive theme system
/// Uses Material Design for Android/Linux/Windows
/// Uses Cupertino for iOS/macOS
class PlatformTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color accentColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  
  // Spacing system
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  
  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  
  // Elevation levels
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;
  
  /// Check if platform uses Cupertino design
  static bool get isCupertinoPlatform {
    return Platform.isIOS || Platform.isMacOS;
  }
  
  /// Check if platform uses Material design
  static bool get isMaterialPlatform {
    return Platform.isAndroid || Platform.isLinux || Platform.isWindows || Platform.isFuchsia;
  }
  
  /// Get Material theme
  static ThemeData getMaterialLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        scrolledUnderElevation: elevationSm,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceMd),
      ),
      cardTheme: CardThemeData(
        elevation: elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }
  
  static ThemeData getMaterialDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        scrolledUnderElevation: elevationSm,
      ),
      cardTheme: CardThemeData(
        elevation: elevationSm,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }
  
  /// Get Cupertino theme
  static CupertinoThemeData getCupertinoLightTheme() {
    return const CupertinoThemeData(
      primaryColor: primaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
      barBackgroundColor: CupertinoColors.systemBackground,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          color: CupertinoColors.label,
        ),
      ),
    );
  }
  
  static CupertinoThemeData getCupertinoDarkTheme() {
    return const CupertinoThemeData(
      primaryColor: primaryColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
      barBackgroundColor: CupertinoColors.systemBackground,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          color: CupertinoColors.label,
        ),
      ),
    );
  }
}

/// Platform-adaptive color scheme
class PlatformColors {
  final BuildContext context;
  
  PlatformColors(this.context);
  
  Color get primary {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoTheme.of(context).primaryColor;
    }
    return Theme.of(context).colorScheme.primary;
  }
  
  Color get background {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoTheme.of(context).scaffoldBackgroundColor;
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }
  
  Color get surface {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoColors.systemBackground.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.surface;
  }
  
  Color get onSurface {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoColors.label.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.onSurface;
  }
  
  Color get error {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoColors.systemRed.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.error;
  }
}
