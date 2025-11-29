import 'package:get_it/get_it.dart';
import '../services/browser_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';
import '../services/network_service.dart';
import '../services/extension_service.dart';
import '../services/account_service.dart';
import '../services/download_manager_service.dart';
import '../services/bookmark_manager_service.dart';
import 'error_handler.dart';
import 'logger.dart';

final GetIt serviceLocator = GetIt.instance;

/// Service locator for dependency injection
class ServiceLocator {
  static Future<void> initialize() async {
    try {
      // Initialize core systems first
      ErrorHandler.initialize();
      await Logger.instance.initialize();
      
      Logger.instance.info('Initializing Titan Browser services...');
      
      // Core services
      serviceLocator.registerLazySingleton<StorageService>(() => StorageService());
      serviceLocator.registerLazySingleton<NetworkService>(() => NetworkService());
      serviceLocator.registerLazySingleton<SecurityService>(() => SecurityService());
      
      // Browser services
      serviceLocator.registerLazySingleton<BrowserService>(() => BrowserService());
      // AI service is static, no need to register
      serviceLocator.registerLazySingleton<ExtensionService>(() => ExtensionService());
      // Account service is static, initialize directly
      await AccountService.init();
      
      // Initialize services in order
      await StorageService.init();
      Logger.instance.info('Storage service initialized');
      
      await serviceLocator<NetworkService>().initialize();
      Logger.instance.info('Network service initialized');
      
      await serviceLocator<SecurityService>().initialize();
      Logger.instance.info('Security service initialized');
      
      await serviceLocator<BrowserService>().initialize();
      Logger.instance.info('Browser service initialized');
      
      await AIService.init();
      Logger.instance.info('AI service initialized');
      
      await serviceLocator<ExtensionService>().initialize();
      Logger.instance.info('Extension service initialized');
      
      await DownloadManagerService.initialize();
      Logger.instance.info('Download manager service initialized');
      
      await BookmarkManagerService.initialize();
      Logger.instance.info('Bookmark manager service initialized');
      
      Logger.instance.info('All services initialized successfully');
    } catch (e, stackTrace) {
      ErrorHandler.reportError(
        e,
        stackTrace: stackTrace,
        type: ErrorType.general,
        context: {'phase': 'service_initialization'},
      );
      rethrow;
    }
  }
  
  static T get<T extends Object>() {
    try {
      return serviceLocator<T>();
    } catch (e) {
      ErrorHandler.reportError(
        e,
        type: ErrorType.general,
        context: {'service': T.toString()},
      );
      rethrow;
    }
  }
  
  static void reset() {
    Logger.instance.info('Resetting service locator');
    serviceLocator.reset();
  }
}