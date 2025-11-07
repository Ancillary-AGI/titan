import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/platform_theme.dart';
import 'core/service_locator.dart';
import 'core/localization/app_localizations.dart';
import 'screens/browser_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for storage
  await Hive.initFlutter();
  
  // Initialize storage service first
  await StorageService.init();
  
  // Initialize all services through service locator
  await ServiceLocator.initialize();
  
  // Desktop window setup
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Titan Browser');
    await windowManager.setMinimumSize(const Size(1200, 800));
    await windowManager.show();
    await windowManager.focus();
  }
  
  runApp(const ProviderScope(child: TitanBrowserApp()));
}

class TitanBrowserApp extends ConsumerWidget {
  const TitanBrowserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use platform-specific app widget
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoApp(
        title: 'Titan Browser',
        theme: PlatformTheme.getCupertinoLightTheme(),
        home: const BrowserScreen(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }
    
    return MaterialApp(
      title: 'Titan Browser',
      theme: PlatformTheme.getMaterialLightTheme(),
      darkTheme: PlatformTheme.getMaterialDarkTheme(),
      themeMode: ThemeMode.system,
      home: const BrowserScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
