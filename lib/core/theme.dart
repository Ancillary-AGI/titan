import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'responsive.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color accentColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  
  // Responsive spacing system
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  
  // Responsive border radius
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
  
  static ThemeData lightTheme = ThemeData(
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
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      scrolledUnderElevation: elevationSm,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
        minimumSize: const Size(88, 48), // Minimum touch target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48), // Minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceSm),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48), // Minimum touch target
        padding: const EdgeInsets.all(spaceSm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: primaryColor, width: 2),
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
      margin: const EdgeInsets.all(spaceSm),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: elevationMd,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryColor,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: elevationMd,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: secondaryColor,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
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
      systemOverlayStyle: SystemUiOverlayStyle.light,
      scrolledUnderElevation: elevationSm,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
        minimumSize: const Size(88, 48), // Minimum touch target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48), // Minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceSm),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48), // Minimum touch target
        padding: const EdgeInsets.all(spaceSm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceMd),
    ),
    cardTheme: CardThemeData(
      elevation: elevationSm,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      margin: const EdgeInsets.all(spaceSm),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: elevationMd,
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryColor,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: elevationMd,
      height: 80,
      backgroundColor: const Color(0xFF1E293B),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: secondaryColor,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
    ),
  );
  
  /// Get responsive text theme based on device type
  static TextTheme getResponsiveTextTheme(BuildContext context, TextTheme base) {
    final scale = Responsive.getValue(
      context,
      mobile: 0.9,
      tablet: 1.0,
      desktop: 1.1,
    );
    
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57) * scale),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45) * scale),
      displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36) * scale),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32) * scale),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28) * scale),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24) * scale),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22) * scale),
      titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16) * scale),
      titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14) * scale),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * scale),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * scale),
      bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12) * scale),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * scale),
      labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12) * scale),
      labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11) * scale),
    );
  }
}