import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'core/app_router.dart';
import 'core/theme.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'services/system_integration_service.dart';
import 'services/mcp_server.dart';
import 'services/account_service.dart';
import 'services/window_manager_service.dart';
import 'services/networking_service.dart';
import 'services/autofill_service.dart';
import 'services/sandboxing_service.dart';
import 'services/rendering_engine_service.dart';
import 'services/agent_client_protocol.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  await StorageService.init();
  
  // Initialize AI Service
  await AIService.init();
  
  // Initialize Account Service
  await AccountService.init();
  
  // Initialize core services
  await NetworkingService.init();
  await AutofillService.init();
  SandboxingService.init();
  RenderingEngineService.init();
  await AgentClientProtocol.init();
  
  // Desktop window setup
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await WindowManagerService.init();
    await windowManager.setTitle('Titan Browser');
    await windowManager.setMinimumSize(const Size(1200, 800));
    
    // Initialize system integration
    await SystemIntegrationService.init();
    
    // Start MCP server
    try {
      await MCPServer.start();
    } catch (e) {
      print('Failed to start MCP server: $e');
    }
  }
  
  runApp(const ProviderScope(child: TitanBrowserApp()));
}

class TitanBrowserApp extends ConsumerWidget {
  const TitanBrowserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Titan Browser',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}