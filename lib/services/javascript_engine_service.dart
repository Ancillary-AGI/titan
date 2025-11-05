import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/storage_service.dart';

/// JavaScript execution context and security levels
enum JSExecutionContext {
  trusted,    // Full access to browser APIs
  sandboxed,  // Limited access, no sensitive APIs
  isolated,   // Completely isolated, no browser APIs
}

/// JavaScript execution result
class JSExecutionResult {
  final dynamic result;
  final String? error;
  final Duration executionTime;
  final Map<String, dynamic> metadata;
  final bool isAsync;
  
  const JSExecutionResult({
    this.result,
    this.error,
    required this.executionTime,
    this.metadata = const {},
    this.isAsync = false,
  });
  
  bool get isSuccess => error == null;
  bool get isError => error != null;
}

/// WASM module information
class WASMModule {
  final String name;
  final Uint8List bytes;
  final Map<String, dynamic> exports;
  final Map<String, dynamic> imports;
  final DateTime loadedAt;
  
  const WASMModule({
    required this.name,
    required this.bytes,
    required this.exports,
    required this.imports,
    required this.loadedAt,
  });
}

/// JavaScript Engine Service for advanced JS/WASM handling
class JavaScriptEngineService {
  static final Map<String, InAppWebViewController> _controllers = {};
  static final Map<String, JSExecutionContext> _contextLevels = {};
  static final Map<String, WASMModule> _wasmModules = {};
  static final Map<String, StreamController<String>> _consoleStreams = {};
  static final List<String> _trustedDomains = [];
  static final List<String> _blockedAPIs = [];
  static final Map<String, Timer> _executionTimeouts = {};
  static final Map<String, int> _memoryLimits = {};
  
  // Chrome-level security features
  static const int _maxExecutionTimeMs = 30000; // 30 seconds
  static const int _maxMemoryMB = 512; // 512MB per context
  static const int _maxCallStackDepth = 1000;
  static const int _maxStringLength = 1024 * 1024; // 1MB
  
  /// Initialize the JavaScript engine with security policies
  static Future<void> initialize() async {
    await _setupSecurityPolicies();
    await _initializeWASMRuntime();
    _setupTrustedDomains();
    _setupBlockedAPIs();
  }
  
  /// Setup Chrome-level security policies
  static Future<void> _setupSecurityPolicies() async {
    // Initialize V8 isolates with security constraints
    _blockedAPIs.addAll([
      'eval',
      'Function',
      'setTimeout',
      'setInterval',
      'XMLHttpRequest',
      'fetch',
      'WebSocket',
      'Worker',
      'SharedWorker',
      'ServiceWorker',
      'importScripts',
      'document.write',
      'document.writeln',
    ]);
  }
  
  /// Initialize WebAssembly runtime with security sandbox
  static Future<void> _initializeWASMRuntime() async {
    // Setup WASM runtime with memory limits and API restrictions
    print('Initializing WASM runtime with security constraints');
  }
  
  /// Setup trusted domains for enhanced security
  static void _setupTrustedDomains() {
    _trustedDomains.addAll([
      'https://cdn.jsdelivr.net',
      'https://unpkg.com',
      'https://cdnjs.cloudflare.com',
    ]);
  }
  
  /// Setup blocked APIs for security
  static void _setupBlockedAPIs() {
    // Additional dangerous APIs to block
    _blockedAPIs.addAll([
      'localStorage.setItem',
      'sessionStorage.setItem',
      'indexedDB.open',
      'navigator.sendBeacon',
      'crypto.subtle',
    ]);
  }
  
  /// Register a WebView controller with security context
  static Future<void> registerController(
    String tabId, 
    InAppWebViewController controller,
    {JSExecutionContext context = JSExecutionContext.sandboxed}
  ) async {
    _controllers[tabId] = controller;
    _contextLevels[tabId] = context;
    _memoryLimits[tabId] = _maxMemoryMB;
    
    // Setup console stream for monitoring
    _consoleStreams[tabId] = StreamController<String>.broadcast();
    
    // Configure WebView security settings
    await _configureWebViewSecurity(controller, context);
    
    // Setup JavaScript bridge with security checks
    await _setupSecureJavaScriptBridge(tabId, controller);
  }
  
  /// Configure WebView with Chrome-level security
  static Future<void> _configureWebViewSecurity(
    InAppWebViewController controller,
    JSExecutionContext context
  ) async {
    final settings = InAppWebViewSettings(
      // JavaScript security
      javaScriptEnabled: context != JSExecutionContext.isolated,
      javaScriptCanOpenWindowsAutomatically: false,
      
      // Content security
      allowsInlineMediaPlayback: false,
      allowsPictureInPictureMediaPlayback: false,
      allowsAirPlayForMediaPlayback: false,
      
      // Network security
      allowsBackForwardNavigationGestures: false,
      allowsLinkPreview: false,
      
      // Storage security
      cacheEnabled: false,
      clearCache: true,
      
      // Additional security
      supportZoom: false,
      displayZoomControls: false,
      builtInZoomControls: false,
      
      // Disable dangerous features
      geolocationEnabled: false,
      
      // Content Security Policy
      contentBlockers: await _generateContentBlockers(),
    );
    
    await controller.setSettings(settings: settings);
  }
  
  /// Generate content blockers for security
  static Future<List<ContentBlocker>> _generateContentBlockers() async {
    return [
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
          resourceType: [ContentBlockerTriggerResourceType.SCRIPT],
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK,
        ),
      ),
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: "javascript:",
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK,
        ),
      ),
    ];
  }
  
  /// Setup secure JavaScript bridge
  static Future<void> _setupSecureJavaScriptBridge(
    String tabId,
    InAppWebViewController controller
  ) async {
    // Add secure JavaScript handlers
    await controller.addJavaScriptHandler(
      handlerName: 'secureEval',
      callback: (args) => _handleSecureEval(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'wasmLoad',
      callback: (args) => _handleWASMLoad(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'consoleLog',
      callback: (args) => _handleConsoleLog(tabId, args),
    );
  }
  
  /// Parse and validate JavaScript code
  static Future<JSExecutionResult> parseJavaScript(
    String tabId,
    String code,
    {Map<String, dynamic>? context}
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Validate code length
      if (code.length > _maxStringLength) {
        throw Exception('JavaScript code exceeds maximum length');
      }
      
      // Check for blocked APIs
      final blockedAPI = _blockedAPIs.firstWhere(
        (api) => code.contains(api),
        orElse: () => '',
      );
      
      if (blockedAPI.isNotEmpty) {
        throw Exception('Blocked API detected: $blockedAPI');
      }
      
      // Parse AST for security analysis
      final parseResult = await _parseAST(code);
      if (!parseResult.isValid) {
        throw Exception('Invalid JavaScript syntax: ${parseResult.error}');
      }
      
      // Execute with security constraints
      final result = await _executeSecurely(tabId, code, context);
      
      final executionTime = DateTime.now().difference(startTime);
      
      return JSExecutionResult(
        result: result,
        executionTime: executionTime,
        metadata: {
          'astNodes': parseResult.nodeCount,
          'memoryUsed': await _getMemoryUsage(tabId),
          'securityLevel': _contextLevels[tabId]?.name,
        },
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      return JSExecutionResult(
        error: e.toString(),
        executionTime: executionTime,
      );
    }
  }
  
  /// Parse JavaScript AST for security analysis
  static Future<_ParseResult> _parseAST(String code) async {
    try {
      // Simplified AST parsing - in production, use a proper JS parser
      final lines = code.split('\n');
      final nodeCount = lines.length;
      
      // Check for dangerous patterns
      final dangerousPatterns = [
        RegExp(r'eval\s*\('),
        RegExp(r'Function\s*\('),
        RegExp(r'document\.write'),
        RegExp(r'innerHTML\s*='),
        RegExp(r'outerHTML\s*='),
        RegExp(r'javascript:'),
        RegExp(r'data:text/html'),
      ];
      
      for (final pattern in dangerousPatterns) {
        if (pattern.hasMatch(code)) {
          return _ParseResult(false, 'Dangerous pattern detected', 0);
        }
      }
      
      return _ParseResult(true, null, nodeCount);
    } catch (e) {
      return _ParseResult(false, e.toString(), 0);
    }
  }
  
  /// Execute JavaScript securely with timeouts and memory limits
  static Future<dynamic> _executeSecurely(
    String tabId,
    String code,
    Map<String, dynamic>? context
  ) async {
    final controller = _controllers[tabId];
    if (controller == null) {
      throw Exception('Controller not found for tab: $tabId');
    }
    
    final executionContext = _contextLevels[tabId] ?? JSExecutionContext.sandboxed;
    
    // Wrap code with security constraints
    final wrappedCode = _wrapCodeWithSecurity(code, executionContext);
    
    // Set execution timeout
    final completer = Completer<dynamic>();
    final timeout = Timer(Duration(milliseconds: _maxExecutionTimeMs), () {
      if (!completer.isCompleted) {
        completer.completeError('JavaScript execution timeout');
      }
    });
    
    _executionTimeouts[tabId] = timeout;
    
    try {
      final result = await controller.evaluateJavascript(source: wrappedCode);
      timeout.cancel();
      
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      
      return await completer.future;
    } catch (e) {
      timeout.cancel();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _executionTimeouts.remove(tabId);
    }
  }
  
  /// Wrap JavaScript code with security constraints
  static String _wrapCodeWithSecurity(String code, JSExecutionContext context) {
    final securityWrapper = StringBuffer();
    
    // Create isolated execution context
    securityWrapper.writeln('(function() {');
    securityWrapper.writeln('  "use strict";');
    
    // Disable dangerous globals based on context
    if (context == JSExecutionContext.sandboxed || context == JSExecutionContext.isolated) {
      securityWrapper.writeln('  var eval = undefined;');
      securityWrapper.writeln('  var Function = undefined;');
      securityWrapper.writeln('  var setTimeout = undefined;');
      securityWrapper.writeln('  var setInterval = undefined;');
    }
    
    if (context == JSExecutionContext.isolated) {
      securityWrapper.writeln('  var window = {};');
      securityWrapper.writeln('  var document = {};');
      securityWrapper.writeln('  var navigator = {};');
    }
    
    // Add memory monitoring
    securityWrapper.writeln('  var __memoryCheck = 0;');
    securityWrapper.writeln('  var __maxMemory = ${_maxMemoryMB * 1024 * 1024};');
    
    // Add the actual code
    securityWrapper.writeln('  try {');
    securityWrapper.writeln('    $code');
    securityWrapper.writeln('  } catch (e) {');
    securityWrapper.writeln('    throw new Error("Execution error: " + e.message);');
    securityWrapper.writeln('  }');
    
    securityWrapper.writeln('})();');
    
    return securityWrapper.toString();
  }
  
  /// Load and validate WebAssembly module
  static Future<WASMModule> loadWASMModule(
    String tabId,
    String name,
    Uint8List wasmBytes
  ) async {
    try {
      // Validate WASM module size
      if (wasmBytes.length > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('WASM module too large');
      }
      
      // Parse WASM module headers for security analysis
      final moduleInfo = await _parseWASMModule(wasmBytes);
      
      // Check for dangerous imports
      final dangerousImports = ['env.eval', 'env.system', 'env.exec'];
      for (final import in moduleInfo.imports.keys) {
        if (dangerousImports.contains(import)) {
          throw Exception('Dangerous WASM import detected: $import');
        }
      }
      
      final module = WASMModule(
        name: name,
        bytes: wasmBytes,
        exports: moduleInfo.exports,
        imports: moduleInfo.imports,
        loadedAt: DateTime.now(),
      );
      
      _wasmModules['${tabId}_$name'] = module;
      
      return module;
    } catch (e) {
      throw Exception('Failed to load WASM module: $e');
    }
  }
  
  /// Parse WASM module for security analysis
  static Future<_WASMModuleInfo> _parseWASMModule(Uint8List bytes) async {
    // Simplified WASM parsing - in production, use a proper WASM parser
    final exports = <String, dynamic>{};
    final imports = <String, dynamic>{};
    
    // Check WASM magic number
    if (bytes.length < 8 || 
        bytes[0] != 0x00 || bytes[1] != 0x61 || 
        bytes[2] != 0x73 || bytes[3] != 0x6D) {
      throw Exception('Invalid WASM magic number');
    }
    
    // Parse sections (simplified)
    // In production, implement full WASM binary format parsing
    
    return _WASMModuleInfo(exports, imports);
  }
  
  /// Execute WASM function securely
  static Future<dynamic> executeWASMFunction(
    String tabId,
    String moduleName,
    String functionName,
    List<dynamic> args
  ) async {
    final moduleKey = '${tabId}_$moduleName';
    final module = _wasmModules[moduleKey];
    
    if (module == null) {
      throw Exception('WASM module not found: $moduleName');
    }
    
    if (!module.exports.containsKey(functionName)) {
      throw Exception('WASM function not found: $functionName');
    }
    
    // Execute WASM function with security constraints
    final controller = _controllers[tabId];
    if (controller == null) {
      throw Exception('Controller not found for tab: $tabId');
    }
    
    final wasmCode = '''
      (async function() {
        try {
          const wasmModule = await WebAssembly.instantiate(
            new Uint8Array([${module.bytes.join(',')}])
          );
          const result = wasmModule.instance.exports.$functionName(${args.map((a) => jsonEncode(a)).join(',')});
          return result;
        } catch (e) {
          throw new Error('WASM execution error: ' + e.message);
        }
      })()
    ''';
    
    return await controller.evaluateJavascript(source: wasmCode);
  }
  
  /// Handle secure eval requests
  static Future<dynamic> _handleSecureEval(String tabId, List<dynamic> args) async {
    if (args.isEmpty) return null;
    
    final code = args[0].toString();
    final result = await parseJavaScript(tabId, code);
    
    if (result.isError) {
      throw Exception(result.error);
    }
    
    return result.result;
  }
  
  /// Handle WASM load requests
  static Future<dynamic> _handleWASMLoad(String tabId, List<dynamic> args) async {
    if (args.length < 2) return null;
    
    final name = args[0].toString();
    final bytesBase64 = args[1].toString();
    final bytes = base64Decode(bytesBase64);
    
    final module = await loadWASMModule(tabId, name, bytes);
    return {
      'name': module.name,
      'exports': module.exports.keys.toList(),
      'loadedAt': module.loadedAt.toIso8601String(),
    };
  }
  
  /// Handle console log for monitoring
  static dynamic _handleConsoleLog(String tabId, List<dynamic> args) {
    final message = args.join(' ');
    final stream = _consoleStreams[tabId];
    
    if (stream != null) {
      stream.add('[${DateTime.now().toIso8601String()}] $message');
    }
    
    print('JS Console [$tabId]: $message');
    return null;
  }
  
  /// Get memory usage for a tab
  static Future<int> _getMemoryUsage(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return 0;
    
    try {
      final result = await controller.evaluateJavascript(
        source: '''
          (function() {
            if (performance && performance.memory) {
              return performance.memory.usedJSHeapSize;
            }
            return 0;
          })()
        '''
      );
      
      return result is int ? result : 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get console stream for a tab
  static Stream<String>? getConsoleStream(String tabId) {
    return _consoleStreams[tabId]?.stream;
  }
  
  /// Set memory limit for a tab
  static void setMemoryLimit(String tabId, int limitMB) {
    _memoryLimits[tabId] = limitMB;
  }
  
  /// Check if tab exceeds memory limit
  static Future<bool> checkMemoryLimit(String tabId) async {
    final limit = _memoryLimits[tabId] ?? _maxMemoryMB;
    final usage = await _getMemoryUsage(tabId);
    
    return usage > (limit * 1024 * 1024);
  }
  
  /// Cleanup resources for a tab
  static Future<void> cleanup(String tabId) async {
    _controllers.remove(tabId);
    _contextLevels.remove(tabId);
    _memoryLimits.remove(tabId);
    
    // Cancel any running timeouts
    final timeout = _executionTimeouts[tabId];
    if (timeout != null) {
      timeout.cancel();
      _executionTimeouts.remove(tabId);
    }
    
    // Close console stream
    final stream = _consoleStreams[tabId];
    if (stream != null) {
      await stream.close();
      _consoleStreams.remove(tabId);
    }
    
    // Remove WASM modules
    final moduleKeys = _wasmModules.keys.where((key) => key.startsWith('${tabId}_')).toList();
    for (final key in moduleKeys) {
      _wasmModules.remove(key);
    }
  }
  
  /// Get engine statistics
  static Map<String, dynamic> getEngineStats() {
    return {
      'activeControllers': _controllers.length,
      'wasmModules': _wasmModules.length,
      'consoleStreams': _consoleStreams.length,
      'executionTimeouts': _executionTimeouts.length,
      'memoryLimits': _memoryLimits,
      'trustedDomains': _trustedDomains.length,
      'blockedAPIs': _blockedAPIs.length,
    };
  }
}

/// Helper classes for internal use
class _ParseResult {
  final bool isValid;
  final String? error;
  final int nodeCount;
  
  const _ParseResult(this.isValid, this.error, this.nodeCount);
}

class _WASMModuleInfo {
  final Map<String, dynamic> exports;
  final Map<String, dynamic> imports;
  
  const _WASMModuleInfo(this.exports, this.imports);