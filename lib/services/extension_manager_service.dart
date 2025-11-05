import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../models/extension.dart';
import '../services/storage_service.dart';
import '../services/browser_security_service.dart';
import '../services/javascript_engine_service.dart';

/// Extension execution context
class ExtensionContext {
  final String extensionId;
  final String tabId;
  final Map<String, dynamic> apis;
  final Map<String, dynamic> storage;
  final StreamController<Map<String, dynamic>> messageStream;
  
  ExtensionContext({
    required this.extensionId,
    required this.tabId,
    required this.apis,
    this.storage = const {},
  }) : messageStream = StreamController<Map<String, dynamic>>.broadcast();
  
  void dispose() {
    messageStream.close();
  }
}

/// Extension API provider
abstract class ExtensionAPI {
  String get name;
  Map<String, Function> get methods;
  List<ExtensionPermission> get requiredPermissions;
}

/// Extension Manager Service - Core extension system
class ExtensionManagerService {
  static final Map<String, Extension> _installedExtensions = {};
  static final Map<String, ExtensionContext> _extensionContexts = {};
  static final Map<String, List<ExtensionAPI>> _extensionAPIs = {};
  static final StreamController<Extension> _extensionStateStream = 
      StreamController<Extension>.broadcast();
  
  // Extension directories
  static late String _extensionsDir;
  static late String _tempDir;
  static late String _cacheDir;
  
  // Security settings
  static bool _allowUnsignedExtensions = false;
  static bool _enableDeveloperMode = false;
  static final Set<String> _trustedDevelopers = {};
  static final Set<String> _blockedExtensions = {};
  
  // API registry
  static final Map<String, ExtensionAPI> _availableAPIs = {};
  
  /// Initialize extension manager
  static Future<void> initialize() async {
    await _setupDirectories();
    await _loadSettings();
    await _registerBuiltinAPIs();
    await _loadInstalledExtensions();
    await _startExtensionWatcher();
    
    print('Extension Manager initialized');
  }
  
  /// Setup extension directories
  static Future<void> _setupDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    _extensionsDir = '${appDir.path}/extensions';
    _tempDir = '${appDir.path}/temp/extensions';
    _cacheDir = '${appDir.path}/cache/extensions';
    
    // Create directories if they don't exist
    await Directory(_extensionsDir).create(recursive: true);
    await Directory(_tempDir).create(recursive: true);
    await Directory(_cacheDir).create(recursive: true);
  }
  
  /// Load extension settings
  static Future<void> _loadSettings() async {
    try {
      final settings = StorageService.getSetting<String>('extension_settings');
      if (settings != null) {
        final data = jsonDecode(settings);
        _allowUnsignedExtensions = data['allowUnsignedExtensions'] ?? false;
        _enableDeveloperMode = data['enableDeveloperMode'] ?? false;
        _trustedDevelopers.addAll(List<String>.from(data['trustedDevelopers'] ?? []));
        _blockedExtensions.addAll(List<String>.from(data['blockedExtensions'] ?? []));
      }
    } catch (e) {
      print('Error loading extension settings: $e');
    }
  }
  
  /// Register built-in extension APIs
  static Future<void> _registerBuiltinAPIs() async {
    // Register core APIs
    registerAPI(_TabsAPI());
    registerAPI(_StorageAPI());
    registerAPI(_NotificationsAPI());
    registerAPI(_ContextMenusAPI());
    registerAPI(_WebRequestAPI());
    registerAPI(_BookmarksAPI());
    registerAPI(_HistoryAPI());
    registerAPI(_WindowsAPI());
    registerAPI(_RuntimeAPI());
    registerAPI(_AIAnalysisAPI());
  }
  
  /// Load installed extensions
  static Future<void> _loadInstalledExtensions() async {
    try {
      final extensionsData = StorageService.getSetting<String>('installed_extensions');
      if (extensionsData != null) {
        final extensionsList = List<Map<String, dynamic>>.from(jsonDecode(extensionsData));
        
        for (final extensionData in extensionsList) {
          final extension = Extension.fromJson(extensionData);
          _installedExtensions[extension.id] = extension;
          
          // Load extension if enabled
          if (extension.isEnabled) {
            await _loadExtension(extension);
          }
        }
      }
    } catch (e) {
      print('Error loading installed extensions: $e');
    }
  }
  
  /// Start extension file watcher
  static Future<void> _startExtensionWatcher() async {
    // Watch for changes in extensions directory
    final watcher = Directory(_extensionsDir).watch(recursive: true);
    watcher.listen((event) {
      _handleFileSystemEvent(event);
    });
  }
  
  /// Handle file system events
  static void _handleFileSystemEvent(FileSystemEvent event) {
    // Handle extension file changes for hot reload in developer mode
    if (_enableDeveloperMode && event.type == FileSystemEvent.modify) {
      final extensionId = _getExtensionIdFromPath(event.path);
      if (extensionId != null && _installedExtensions.containsKey(extensionId)) {
        _reloadExtension(extensionId);
      }
    }
  }
  
  /// Get extension ID from file path
  static String? _getExtensionIdFromPath(String path) {
    final parts = path.split('/');
    final extensionsIndex = parts.indexOf('extensions');
    if (extensionsIndex >= 0 && extensionsIndex < parts.length - 1) {
      return parts[extensionsIndex + 1];
    }
    return null;
  }
  
  /// Register extension API
  static void registerAPI(ExtensionAPI api) {
    _availableAPIs[api.name] = api;
  }
  
  /// Install extension from file
  static Future<String> installExtension(String filePath, {bool force = false}) async {
    try {
      // Read extension file
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Extension file not found');
      }
      
      final bytes = await file.readAsBytes();
      return await installExtensionFromBytes(bytes, force: force);
    } catch (e) {
      throw Exception('Failed to install extension: $e');
    }
  }
  
  /// Install extension from bytes
  static Future<String> installExtensionFromBytes(Uint8List bytes, {bool force = false}) async {
    try {
      // Extract extension archive
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find and parse manifest
      final manifestEntry = archive.findFile('manifest.json');
      if (manifestEntry == null) {
        throw Exception('Extension manifest not found');
      }
      
      final manifestContent = utf8.decode(manifestEntry.content as List<int>);
      final manifestJson = jsonDecode(manifestContent);
      final manifest = ExtensionManifest.fromJson(manifestJson);
      
      // Generate extension ID
      final extensionId = _generateExtensionId(manifest.name, manifest.version);
      
      // Check if extension is blocked
      if (_blockedExtensions.contains(extensionId)) {
        throw Exception('Extension is blocked');
      }
      
      // Security validation
      await _validateExtensionSecurity(manifest, archive);
      
      // Check if already installed
      if (_installedExtensions.containsKey(extensionId) && !force) {
        throw Exception('Extension already installed');
      }
      
      // Create extension directory
      final extensionDir = Directory('$_extensionsDir/$extensionId');
      if (await extensionDir.exists()) {
        await extensionDir.delete(recursive: true);
      }
      await extensionDir.create(recursive: true);
      
      // Extract files
      for (final file in archive) {
        if (file.isFile) {
          final filePath = '${extensionDir.path}/${file.name}';
          final fileDir = Directory(filePath).parent;
          if (!await fileDir.exists()) {
            await fileDir.create(recursive: true);
          }
          
          final outputFile = File(filePath);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      // Create extension object
      final extension = Extension(
        id: extensionId,
        manifest: manifest,
        status: ExtensionStatus.installed,
        securityRating: await _calculateSecurityRating(manifest),
        installedAt: DateTime.now(),
        installPath: extensionDir.path,
      );
      
      // Store extension
      _installedExtensions[extensionId] = extension;
      await _saveInstalledExtensions();
      
      // Notify listeners
      _extensionStateStream.add(extension);
      
      return extensionId;
    } catch (e) {
      throw Exception('Failed to install extension: $e');
    }
  }
  
  /// Generate extension ID
  static String _generateExtensionId(String name, String version) {
    final input = '$name-$version-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }
  
  /// Validate extension security
  static Future<void> _validateExtensionSecurity(ExtensionManifest manifest, Archive archive) async {
    // Check manifest version
    if (manifest.manifestVersion < 2) {
      throw Exception('Unsupported manifest version');
    }
    
    // Check permissions
    for (final permission in manifest.permissions) {
      if (!_isPermissionAllowed(permission)) {
        throw Exception('Permission not allowed: ${permission.name}');
      }
    }
    
    // Scan for malicious content
    await _scanExtensionContent(archive);
    
    // Check developer signature (if required)
    if (!_allowUnsignedExtensions && !_enableDeveloperMode) {
      await _validateDeveloperSignature(manifest, archive);
    }
  }
  
  /// Check if permission is allowed
  static bool _isPermissionAllowed(ExtensionPermission permission) {
    // Define restricted permissions
    const restrictedPermissions = [
      ExtensionPermission.nativeMessaging,
      ExtensionPermission.debugger,
      ExtensionPermission.desktopCapture,
      ExtensionPermission.system,
      ExtensionPermission.management,
    ];
    
    if (restrictedPermissions.contains(permission) && !_enableDeveloperMode) {
      return false;
    }
    
    return true;
  }
  
  /// Scan extension content for malicious code
  static Future<void> _scanExtensionContent(Archive archive) async {
    for (final file in archive) {
      if (file.isFile && (file.name.endsWith('.js') || file.name.endsWith('.html'))) {
        final content = utf8.decode(file.content as List<int>);
        
        // Check for dangerous patterns
        final dangerousPatterns = [
          RegExp(r'eval\s*\('),
          RegExp(r'Function\s*\('),
          RegExp(r'document\.write'),
          RegExp(r'innerHTML\s*='),
          RegExp(r'outerHTML\s*='),
          RegExp(r'javascript:'),
          RegExp(r'data:text/html'),
          RegExp(r'XMLHttpRequest'),
          RegExp(r'fetch\s*\('),
        ];
        
        for (final pattern in dangerousPatterns) {
          if (pattern.hasMatch(content)) {
            // Log security warning but don't block (allow with warning)
            print('Security warning in ${file.name}: ${pattern.pattern}');
          }
        }
      }
    }
  }
  
  /// Validate developer signature
  static Future<void> _validateDeveloperSignature(ExtensionManifest manifest, Archive archive) async {
    // Check if developer is trusted
    if (manifest.author != null && _trustedDevelopers.contains(manifest.author)) {
      return;
    }
    
    // Look for signature file
    final signatureEntry = archive.findFile('signature.json');
    if (signatureEntry == null) {
      throw Exception('Extension signature not found');
    }
    
    // Validate signature (simplified - in production, use proper cryptographic verification)
    final signatureContent = utf8.decode(signatureEntry.content as List<int>);
    final signature = jsonDecode(signatureContent);
    
    if (signature['developer'] != manifest.author) {
      throw Exception('Invalid developer signature');
    }
  }
  
  /// Calculate security rating
  static Future<SecurityRating> _calculateSecurityRating(ExtensionManifest manifest) async {
    int score = 100;
    
    // Check permissions
    for (final permission in manifest.permissions) {
      switch (permission) {
        case ExtensionPermission.allUrls:
          score -= 20;
          break;
        case ExtensionPermission.webRequestBlocking:
          score -= 15;
          break;
        case ExtensionPermission.nativeMessaging:
          score -= 30;
          break;
        case ExtensionPermission.debugger:
          score -= 25;
          break;
        case ExtensionPermission.system:
          score -= 20;
          break;
        default:
          score -= 5;
      }
    }
    
    // Check if official
    if (manifest.author != null && _trustedDevelopers.contains(manifest.author)) {
      score += 20;
    }
    
    // Determine rating based on score
    if (score >= 90) return SecurityRating.safe;
    if (score >= 70) return SecurityRating.trusted;
    if (score >= 50) return SecurityRating.reviewed;
    if (score >= 30) return SecurityRating.unverified;
    if (score >= 10) return SecurityRating.warning;
    return SecurityRating.dangerous;
  }
  
  /// Load extension into runtime
  static Future<void> _loadExtension(Extension extension) async {
    try {
      // Create extension context
      final context = ExtensionContext(
        extensionId: extension.id,
        tabId: 'global', // Global context for background scripts
        apis: _buildExtensionAPIs(extension),
      );
      
      _extensionContexts[extension.id] = context;
      
      // Load background scripts
      if (extension.manifest.background.isNotEmpty) {
        await _loadBackgroundScript(extension, context);
      }
      
      // Load content scripts (will be injected when tabs load)
      if (extension.manifest.contentScripts.isNotEmpty) {
        await _registerContentScripts(extension);
      }
      
      // Setup browser action
      if (extension.manifest.browserAction.isNotEmpty) {
        await _setupBrowserAction(extension);
      }
      
      // Update status
      final updatedExtension = extension.copyWith(status: ExtensionStatus.enabled);
      _installedExtensions[extension.id] = updatedExtension;
      _extensionStateStream.add(updatedExtension);
      
    } catch (e) {
      print('Error loading extension ${extension.id}: $e');
      final errorExtension = extension.copyWith(
        status: ExtensionStatus.error,
        errors: [...extension.errors, e.toString()],
      );
      _installedExtensions[extension.id] = errorExtension;
      _extensionStateStream.add(errorExtension);
    }
  }
  
  /// Build extension APIs based on permissions
  static Map<String, dynamic> _buildExtensionAPIs(Extension extension) {
    final apis = <String, dynamic>{};
    
    for (final permission in extension.manifest.permissions) {
      final apiName = _getAPINameForPermission(permission);
      if (apiName != null && _availableAPIs.containsKey(apiName)) {
        final api = _availableAPIs[apiName]!;
        apis[apiName] = _createAPIProxy(api, extension.id);
      }
    }
    
    return apis;
  }
  
  /// Get API name for permission
  static String? _getAPINameForPermission(ExtensionPermission permission) {
    switch (permission) {
      case ExtensionPermission.tabs:
        return 'tabs';
      case ExtensionPermission.storage:
        return 'storage';
      case ExtensionPermission.notifications:
        return 'notifications';
      case ExtensionPermission.contextMenus:
        return 'contextMenus';
      case ExtensionPermission.webRequest:
        return 'webRequest';
      case ExtensionPermission.bookmarks:
        return 'bookmarks';
      case ExtensionPermission.history:
        return 'history';
      case ExtensionPermission.aiAnalysis:
        return 'aiAnalysis';
      default:
        return null;
    }
  }
  
  /// Create API proxy for extension
  static Map<String, Function> _createAPIProxy(ExtensionAPI api, String extensionId) {
    final proxy = <String, Function>{};
    
    for (final entry in api.methods.entries) {
      proxy[entry.key] = (List<dynamic> args) async {
        try {
          return await entry.value(args);
        } catch (e) {
          print('API error in extension $extensionId: $e');
          rethrow;
        }
      };
    }
    
    return proxy;
  }
  
  /// Load background script
  static Future<void> _loadBackgroundScript(Extension extension, ExtensionContext context) async {
    final scriptPath = extension.manifest.background['service_worker'] ?? 
                     extension.manifest.background['scripts']?.first;
    
    if (scriptPath != null) {
      final scriptFile = File('${extension.installPath}/$scriptPath');
      if (await scriptFile.exists()) {
        final scriptContent = await scriptFile.readAsString();
        
        // Execute background script in secure context
        await JavaScriptEngineService.parseJavaScript(
          extension.id,
          _wrapExtensionScript(scriptContent, context),
        );
      }
    }
  }
  
  /// Register content scripts
  static Future<void> _registerContentScripts(Extension extension) async {
    // Content scripts will be injected when tabs match the patterns
    // This is handled by the browser engine when loading pages
  }
  
  /// Setup browser action
  static Future<void> _setupBrowserAction(Extension extension) async {
    // Register browser action button in toolbar
    // This would integrate with the browser UI
  }
  
  /// Wrap extension script with API access
  static String _wrapExtensionScript(String script, ExtensionContext context) {
    final apiNames = context.apis.keys.join(', ');
    
    return '''
      (function() {
        // Extension API access
        const chrome = {
          ${context.apis.entries.map((e) => '${e.key}: ${jsonEncode(e.value)}').join(',\n          ')}
        };
        
        // Titan-specific APIs
        const titan = chrome;
        
        // Extension script
        $script
      })();
    ''';
  }
  
  /// Uninstall extension
  static Future<void> uninstallExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) {
      throw Exception('Extension not found');
    }
    
    try {
      // Disable extension first
      await disableExtension(extensionId);
      
      // Remove extension files
      final extensionDir = Directory(extension.installPath);
      if (await extensionDir.exists()) {
        await extensionDir.delete(recursive: true);
      }
      
      // Remove from installed extensions
      _installedExtensions.remove(extensionId);
      await _saveInstalledExtensions();
      
      // Cleanup context
      _extensionContexts[extensionId]?.dispose();
      _extensionContexts.remove(extensionId);
      
    } catch (e) {
      throw Exception('Failed to uninstall extension: $e');
    }
  }
  
  /// Enable extension
  static Future<void> enableExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) {
      throw Exception('Extension not found');
    }
    
    if (extension.status == ExtensionStatus.enabled) {
      return; // Already enabled
    }
    
    await _loadExtension(extension);
  }
  
  /// Disable extension
  static Future<void> disableExtension(String extensionId) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) {
      throw Exception('Extension not found');
    }
    
    // Cleanup extension context
    _extensionContexts[extensionId]?.dispose();
    _extensionContexts.remove(extensionId);
    
    // Update status
    final updatedExtension = extension.copyWith(status: ExtensionStatus.disabled);
    _installedExtensions[extensionId] = updatedExtension;
    await _saveInstalledExtensions();
    
    _extensionStateStream.add(updatedExtension);
  }
  
  /// Reload extension (for development)
  static Future<void> _reloadExtension(String extensionId) async {
    if (!_enableDeveloperMode) return;
    
    final extension = _installedExtensions[extensionId];
    if (extension == null || !extension.isEnabled) return;
    
    try {
      // Disable and re-enable
      await disableExtension(extensionId);
      await enableExtension(extensionId);
      
      print('Extension $extensionId reloaded');
    } catch (e) {
      print('Error reloading extension $extensionId: $e');
    }
  }
  
  /// Update extension
  static Future<void> updateExtension(String extensionId, Uint8List newExtensionBytes) async {
    final extension = _installedExtensions[extensionId];
    if (extension == null) {
      throw Exception('Extension not found');
    }
    
    try {
      // Install new version
      await installExtensionFromBytes(newExtensionBytes, force: true);
      
      // Update timestamp
      final updatedExtension = extension.copyWith(lastUpdated: DateTime.now());
      _installedExtensions[extensionId] = updatedExtension;
      await _saveInstalledExtensions();
      
      _extensionStateStream.add(updatedExtension);
      
    } catch (e) {
      throw Exception('Failed to update extension: $e');
    }
  }
  
  /// Save installed extensions to storage
  static Future<void> _saveInstalledExtensions() async {
    final extensionsList = _installedExtensions.values.map((e) => e.toJson()).toList();
    await StorageService.setSetting('installed_extensions', jsonEncode(extensionsList));
  }
  
  /// Get installed extensions
  static List<Extension> getInstalledExtensions() {
    return _installedExtensions.values.toList();
  }
  
  /// Get extension by ID
  static Extension? getExtension(String extensionId) {
    return _installedExtensions[extensionId];
  }
  
  /// Get enabled extensions
  static List<Extension> getEnabledExtensions() {
    return _installedExtensions.values.where((e) => e.isEnabled).toList();
  }
  
  /// Get extension state stream
  static Stream<Extension> get extensionStateStream => _extensionStateStream.stream;
  
  /// Configure extension settings
  static Future<void> configureExtensionSettings({
    bool? allowUnsignedExtensions,
    bool? enableDeveloperMode,
    List<String>? trustedDevelopers,
    List<String>? blockedExtensions,
  }) async {
    if (allowUnsignedExtensions != null) _allowUnsignedExtensions = allowUnsignedExtensions;
    if (enableDeveloperMode != null) _enableDeveloperMode = enableDeveloperMode;
    if (trustedDevelopers != null) {
      _trustedDevelopers.clear();
      _trustedDevelopers.addAll(trustedDevelopers);
    }
    if (blockedExtensions != null) {
      _blockedExtensions.clear();
      _blockedExtensions.addAll(blockedExtensions);
    }
    
    // Save settings
    final settings = {
      'allowUnsignedExtensions': _allowUnsignedExtensions,
      'enableDeveloperMode': _enableDeveloperMode,
      'trustedDevelopers': _trustedDevelopers.toList(),
      'blockedExtensions': _blockedExtensions.toList(),
    };
    
    await StorageService.setSetting('extension_settings', jsonEncode(settings));
  }
  
  /// Get extension statistics
  static Map<String, dynamic> getExtensionStats() {
    final extensions = _installedExtensions.values.toList();
    
    return {
      'totalExtensions': extensions.length,
      'enabledExtensions': extensions.where((e) => e.isEnabled).length,
      'disabledExtensions': extensions.where((e) => e.status == ExtensionStatus.disabled).length,
      'errorExtensions': extensions.where((e) => e.status == ExtensionStatus.error).length,
      'extensionsByType': _groupExtensionsByType(extensions),
      'extensionsBySecurityRating': _groupExtensionsBySecurityRating(extensions),
      'settings': {
        'allowUnsignedExtensions': _allowUnsignedExtensions,
        'enableDeveloperMode': _enableDeveloperMode,
        'trustedDevelopers': _trustedDevelopers.length,
        'blockedExtensions': _blockedExtensions.length,
      },
    };
  }
  
  /// Group extensions by type
  static Map<String, int> _groupExtensionsByType(List<Extension> extensions) {
    final groups = <String, int>{};
    for (final extension in extensions) {
      final type = extension.manifest.type.name;
      groups[type] = (groups[type] ?? 0) + 1;
    }
    return groups;
  }
  
  /// Group extensions by security rating
  static Map<String, int> _groupExtensionsBySecurityRating(List<Extension> extensions) {
    final groups = <String, int>{};
    for (final extension in extensions) {
      final rating = extension.securityRating.name;
      groups[rating] = (groups[rating] ?? 0) + 1;
    }
    return groups;
  }
  
  /// Cleanup extension manager
  static Future<void> cleanup() async {
    // Dispose all extension contexts
    for (final context in _extensionContexts.values) {
      context.dispose();
    }
    _extensionContexts.clear();
    
    // Close streams
    await _extensionStateStream.close();
  }
}

// Built-in Extension APIs

class _TabsAPI extends ExtensionAPI {
  @override
  String get name => 'tabs';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.tabs];
  
  @override
  Map<String, Function> get methods => {
    'query': (List<dynamic> args) async {
      // Return tab information
      return [];
    },
    'create': (List<dynamic> args) async {
      // Create new tab
      return {'id': 'new-tab'};
    },
    'update': (List<dynamic> args) async {
      // Update tab
      return {'success': true};
    },
    'remove': (List<dynamic> args) async {
      // Remove tab
      return {'success': true};
    },
  };
}

class _StorageAPI extends ExtensionAPI {
  @override
  String get name => 'storage';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.storage];
  
  @override
  Map<String, Function> get methods => {
    'get': (List<dynamic> args) async {
      // Get stored data
      return {};
    },
    'set': (List<dynamic> args) async {
      // Set stored data
      return {'success': true};
    },
    'remove': (List<dynamic> args) async {
      // Remove stored data
      return {'success': true};
    },
    'clear': (List<dynamic> args) async {
      // Clear all stored data
      return {'success': true};
    },
  };
}

class _NotificationsAPI extends ExtensionAPI {
  @override
  String get name => 'notifications';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.notifications];
  
  @override
  Map<String, Function> get methods => {
    'create': (List<dynamic> args) async {
      // Create notification
      return {'id': 'notification-id'};
    },
    'clear': (List<dynamic> args) async {
      // Clear notification
      return {'success': true};
    },
  };
}

class _ContextMenusAPI extends ExtensionAPI {
  @override
  String get name => 'contextMenus';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.contextMenus];
  
  @override
  Map<String, Function> get methods => {
    'create': (List<dynamic> args) async {
      // Create context menu item
      return {'id': 'menu-item-id'};
    },
    'update': (List<dynamic> args) async {
      // Update context menu item
      return {'success': true};
    },
    'remove': (List<dynamic> args) async {
      // Remove context menu item
      return {'success': true};
    },
  };
}

class _WebRequestAPI extends ExtensionAPI {
  @override
  String get name => 'webRequest';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.webRequest];
  
  @override
  Map<String, Function> get methods => {
    'onBeforeRequest': (List<dynamic> args) async {
      // Handle before request
      return {'success': true};
    },
    'onHeadersReceived': (List<dynamic> args) async {
      // Handle headers received
      return {'success': true};
    },
  };
}

class _BookmarksAPI extends ExtensionAPI {
  @override
  String get name => 'bookmarks';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.bookmarks];
  
  @override
  Map<String, Function> get methods => {
    'get': (List<dynamic> args) async {
      // Get bookmarks
      return [];
    },
    'create': (List<dynamic> args) async {
      // Create bookmark
      return {'id': 'bookmark-id'};
    },
    'update': (List<dynamic> args) async {
      // Update bookmark
      return {'success': true};
    },
    'remove': (List<dynamic> args) async {
      // Remove bookmark
      return {'success': true};
    },
  };
}

class _HistoryAPI extends ExtensionAPI {
  @override
  String get name => 'history';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.history];
  
  @override
  Map<String, Function> get methods => {
    'search': (List<dynamic> args) async {
      // Search history
      return [];
    },
    'addUrl': (List<dynamic> args) async {
      // Add URL to history
      return {'success': true};
    },
    'deleteUrl': (List<dynamic> args) async {
      // Delete URL from history
      return {'success': true};
    },
  };
}

class _WindowsAPI extends ExtensionAPI {
  @override
  String get name => 'windows';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.tabs];
  
  @override
  Map<String, Function> get methods => {
    'getAll': (List<dynamic> args) async {
      // Get all windows
      return [];
    },
    'create': (List<dynamic> args) async {
      // Create new window
      return {'id': 'window-id'};
    },
    'update': (List<dynamic> args) async {
      // Update window
      return {'success': true};
    },
  };
}

class _RuntimeAPI extends ExtensionAPI {
  @override
  String get name => 'runtime';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [];
  
  @override
  Map<String, Function> get methods => {
    'sendMessage': (List<dynamic> args) async {
      // Send message to extension
      return {'success': true};
    },
    'getManifest': (List<dynamic> args) async {
      // Get extension manifest
      return {};
    },
    'reload': (List<dynamic> args) async {
      // Reload extension
      return {'success': true};
    },
  };
}

class _AIAnalysisAPI extends ExtensionAPI {
  @override
  String get name => 'aiAnalysis';
  
  @override
  List<ExtensionPermission> get requiredPermissions => [ExtensionPermission.aiAnalysis];
  
  @override
  Map<String, Function> get methods => {
    'analyzePage': (List<dynamic> args) async {
      // Analyze current page with AI
      return {'analysis': 'page analysis result'};
    },
    'extractContent': (List<dynamic> args) async {
      // Extract content from page
      return {'content': 'extracted content'};
    },
    'summarize': (List<dynamic> args) async {
      // Summarize page content
      return {'summary': 'page summary'};
    },
  };
}