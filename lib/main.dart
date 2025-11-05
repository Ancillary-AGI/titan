import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/theme.dart';
import 'core/service_locator.dart';
import 'screens/browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for storage
  await Hive.initFlutter();
  
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
    return MaterialApp(
      title: 'Titan Browser',
      theme: TitanTheme.lightTheme,
      darkTheme: TitanTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const BrowserScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}