import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/extension.dart';
import '../core/service_locator.dart';
import 'storage_service.dart';
import 'security_service.dart';

/// Consolidated extension service
class ExtensionService extends ChangeNotifier {
  final Map<String, Extension> _installedExtensions = {};
  final Map<String, ExtensionContext> _contexts = {};
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  List<Extension> get installedExtensions => _installedExtensions.values.toList();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadInstalledExtensions();
    _isInitialized = true;
    notifyListeners();
  }
  
  /// Install extension from package
  Future<bool> installExtension(String packagePath) async {
    try {
      final file = File(packagePath);
      if (!await file.exists()) {
        throw ExtensionException('Extension package not found');
      }
      
      // Validate extension package
      final manifest = await _validateExtensionPackage(file);
      if (manifest == null) {
        throw ExtensionException('Invalid extension package');
      }
      
      // Security check
      final securityService = ServiceLocator.get<SecurityService>();
      final isSecure = await _performSecurityScan(file);
      if (!isSecure) {
        throw ExtensionException('Extension failed security scan');
      }
      
      // Extract and install
      final extensionDir = await _extractExtension(file, manifest.name);
      final extension = Extension(
        id: manifest.name,
        manifest: manifest,
        status: ExtensionStatus.installed,
        securityRating: SecurityRating.unverified,
        installedAt: DateTime.now(),
        installPath: extensionDir,
      );
      
      _installedExtensions[extension.id] = extension;
      await _saveInstalledExtensions();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Extension installation failed: $e');
      return false;
    }
  }
  
  /// Uninstall extension
  Future<bool> uninstallExtension(String extensionId) async {
    try {
      final extension = _installedExtensions[extensionId];
      if (extension == null) return false;
      
      // Stop extension if running
      await stopExtension(extensionId);
      
      // Remove files
      final extensionDir = Directory(extension.path);
      if (await extensionDir.exists()) {
        await extensionDir.delete(recursive: true);
      }
      
      // Remove from registry
      _installedExtensions.remove(extensionId);
      _contexts.remove(extensionId);
      
      await _saveInstalledExtensions();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Extension uninstallation failed: $e');
      return false;
    }
  }
  
  /// Enable extension
  Future<void> enableExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) return;
    
    _installedExtensions[extensionId] = extension.copyWith(status: ExtensionStatus.enabled);
    await _saveInstalledExtensions();
    
    // Start extension
    await startExtension(extensionId);
    notifyListeners();
  }
  
  /// Disable extension
  Future<void> disableExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) return;
    
    _installedExtensions[extensionId] = extension.copyWith(status: ExtensionStatus.disabled);
    await _saveInstalledExtensions();
    
    // Stop extension
    await stopExtension(extensionId);
    notifyListeners();
  }
  
  /// Start extension
  Future<void> startExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null || !extension.isEnabled) return;
    
    try {
      final context = ExtensionContext(
        extensionId: extensionId,
        extension: extension,
      );
      
      // Load extension script
      await _loadExtensionScript(context);
      
      _contexts[extensionId] = context;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start extension $extensionId: $e');
    }
  }
  
  /// Stop extension
  Future<void> stopExtension(String extensionId) async {
    final context = _contexts[extensionId];
    
    if (context != null) {
      await context.dispose();
      _contexts.remove(extensionId);
    }
    
    notifyListeners();
  }
  
  /// Execute extension API call
  Future<dynamic> executeExtensionAPI(
    String extensionId,
    String method,
    Map<String, dynamic> params,
  ) async {
    final context = _contexts[extensionId];
    if (context == null) {
      throw ExtensionException('Extension not running: $extensionId');
    }
    
    return await context.executeAPI(method, params);
  }
  
  /// Get extension by ID
  Extension? getExtension(String extensionId) {
    return _installedExtensions[extensionId];
  }
  
  /// Search extensions in marketplace
  Future<List<Extension>> searchExtensions(String query) async {
    // Mock implementation - in production, this would call marketplace API
    return [];
  }
  
  Future<void> _loadInstalledExtensions() async {
    try {
      final storageService = ServiceLocator.get<StorageService>();
      final extensionsData = await storageService.getExtensions();
      
      for (final data in extensionsData) {
        final extension = Extension.fromJson(data);
        _installedExtensions[extension.id] = extension;
        
        // Auto-start enabled extensions
        if (extension.isEnabled) {
          await startExtension(extension.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to load installed extensions: $e');
    }
  }
  
  Future<void> _saveInstalledExtensions() async {
    try {
      final storageService = ServiceLocator.get<StorageService>();
      final extensionsData = _installedExtensions.values
          .map((ext) => ext.toJson())
          .toList();
      
      await storageService.saveExtensions(extensionsData);
    } catch (e) {
      debugPrint('Failed to save installed extensions: $e');
    }
  }
  
  Future<ExtensionManifest?> _validateExtensionPackage(File packageFile) async {
    // Mock validation - in production, extract and validate manifest
    return ExtensionManifest(
      id: 'test-extension',
      name: 'Test Extension',
      version: '1.0.0',
      description: 'Test extension',
      permissions: [],
    );
  }
  
  Future<bool> _performSecurityScan(File packageFile) async {
    // Mock security scan - in production, perform actual security checks
    return true;
  }
  
  Future<String> _extractExtension(File packageFile, String extensionId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extensionsDir = Directory('${appDir.path}/extensions');
    if (!await extensionsDir.exists()) {
      await extensionsDir.create(recursive: true);
    }
    
    final extensionDir = Directory('${extensionsDir.path}/$extensionId');
    if (!await extensionDir.exists()) {
      await extensionDir.create();
    }
    
    return extensionDir.path;
  }
  
  Future<void> _loadExtensionScript(ExtensionContext context) async {
    // Mock script loading - in production, load and execute extension script
    debugPrint('Loading extension script for ${context.extensionId}');
  }
}

class ExtensionContext {
  final String extensionId;
  final Extension extension;
  
  ExtensionContext({
    required this.extensionId,
    required this.extension,
  });
  
  Future<dynamic> executeAPI(String method, Map<String, dynamic> params) async {
    // Mock API execution
    debugPrint('Executing $method with params: $params');
    return {'success': true};
  }
  
  Future<void> dispose() async {
    // Clean up extension resources
    debugPrint('Disposing extension context for $extensionId');
  }
}

class ExtensionManifest {
  final String id;
  final String name;
  final String version;
  final String description;
  final List<String> permissions;
  
  ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.permissions,
  });
}

class ExtensionException implements Exception {
  final String message;
  ExtensionException(this.message);
  
  @override
  String toString() => 'ExtensionException: $message';
}